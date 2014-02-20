## `Seohtracker logic <https://github.com/gradha/seohtracker-logic>`_ main
## module.
##
## This is the module that clients have to import. It keeps some global
## variables around to preserve the state between calls and simplify the API. A
## client should first open a database connection with ``open_db`` passing a
## platform specific path for file storage. The ``close_db`` proc can be used
## to cleanly close the database.
##
## Some global variables are used for localization and formatting, so you might
## need to set those, preferably before opening the database connection.  These
## are ``set_decimal_separator`` and ``specify_metric_use``.
##
## Once the database is open, you can use different procs to access the stored
## data: ``add_weight``, ``remove_weight``, ``get_num_weights``, ``find_pos``,
## ``modify_weight_date``, ``modify_weight_value``, etc. See all the other
## exported procs for information.
##
## To browse the constants and other types used here, browse the `l_types
## module <l_types.html>`_.

import db_sqlite, strutils, times, os, l_db, l_types, parseutils, l_log

export l_types
export l_log

var
  DB_PATH = ""
  DB_CONN: Tdb_conn ## Stores the database connection, convenience for objc.
  VALUES: seq[PWeight] = @[]
  DECIMAL_SEPARATOR = nim_decimal_separator
  WEIGHT_DEFAULT = pounds
  INVALID_CHARS = AllChars - ({nim_decimal_separator} + Digits)


proc get_weight_string*(): string {.raises: [].} =
  ## Allows C code know the string for the current WEIGHT_DEFAULT setting.
  result = short(WEIGHT_DEFAULT)


proc format_weight_with_current_unit*(s: PWeight): string {.raises: [].} =
  ## Formats the weight for the UI.
  ##
  ## The difference from other methods is that this one convers the weight to
  ## the current mass of unit if different according to WEIGHT_DEFAULT.
  ##
  ## If s is nil, the value zero is returned.
  var ret: string
  if s.isNil:
    ret = "0" & DECIMAL_SEPARATOR & repeat_char(num_decimals, '0')
  else:
    ret = formatFloat(to_unit(s, WEIGHT_DEFAULT), ffDecimal, num_decimals)

  # Replace dots in the float if the user locale has a different value.
  if nim_decimal_separator != DECIMAL_SEPARATOR:
    ret = ret.replace(nim_decimal_separator, DECIMAL_SEPARATOR)

  result = ret


proc format_weight*(s: PWeight, add_mass: bool): string {.raises: [].} =
  ## Formats the weight for the UI.
  ##
  ## If s is nil, the value zero is returned. If add_mass is true, the string
  ## of the weight type is appended.
  var ret: string
  if s.isNil:
    ret = "0" & DECIMAL_SEPARATOR & repeat_char(num_decimals, '0')
  else:
    ret = formatFloat(s.weight, ffDecimal, num_decimals)

  # Replace dots in the float if the user locale has a different value.
  if nim_decimal_separator != DECIMAL_SEPARATOR:
    ret = ret.replace(nim_decimal_separator, DECIMAL_SEPARATOR)

  if (not s.isNil) and add_mass:
    ret.add(" " & s[].typ_str)
  result = ret


proc open_db*(path: string): bool {.raises: [].} =
  ## Opens the database.
  ##
  ## Pass the directory where you want the database to be opened. The filename
  ## is always a constant you can't change, and will be appended to the
  ## provided `path`.
  ##
  ## Returns true if the database was opened and loaded into memory.
  DB_PATH = if path.isNil: "" else: path
  try:
    DB_CONN = open_database(DB_PATH/db_name)
    DB_CONN.update
    result = true
  except EDb:
    exlog "Could not open database at '", DB_PATH, "'"
    return
  VALUES = DB_CONN.get_weights_page(-1, high(int))


proc close_db*() {.raises: [].} =
  ## Mostly for unit tests, closes the sqlite and clears the global variables.
  ##
  ## Problems are logged and ignored.
  try: DB_CONN.close()
  except EDb: exlog "Error closing global db?"
  DB_CONN = nil


proc get_db*(): Tdb_conn =
  ## For unit testing, returns the current global database connection.
  ##
  ## This allows unit tests to execute special queries not part of the default
  ## database logic module.
  result = DB_CONN


proc db_exists*(path: string): bool {.raises: [].} =
  ## Returns true if the database exists at the specified path.
  ##
  ## Use this before calling open_db, since opening an sqlite database already
  ## generates a zero byte file. This proc doesn't modify the current DB_PATH
  ## global.
  if path.isNil: return false
  let db_path = path / db_name
  result = db_path.existsFile


proc add_weight*(weight: float): int {.raises: [].} =
  ## Adds a new weight to the database.
  ##
  ## Returns the position of the weight in the list if the addition succeeded,
  ## negative otherwise.
  assert (not DB_CONN.isNil)
  result = -1
  try:
    let (w, pos) = DB_CONN.add_weight(weight, WEIGHT_DEFAULT)
    if pos >= 0:
      assert (not w.isNil)
      VALUES.insert(w, pos)
      result = pos
  except EDb:
    exlog "Could not add weight ", weight

proc remove_weight*(weight: PWeight): int {.discardable, raises: [].} =
  ## Removes the specified weight from the database.
  ##
  ## Returns the position of the entry in the global list before removal if it
  ## was successful, or negative if the removal could not be made.
  assert (not DB_CONN.isNil)
  result = -1
  if weight.isNil: return

  let affected = DB_CONN.remove_weight(weight)
  if affected == 1:
    var f = 0
    while f < VALUES.len:
      if VALUES[f][].id == weight[].id:
        VALUES.delete(f)
        result = f
        return
      else:
        f += 1
  else:
    elog "Could not remove weight ", weight[].id
    elog "Rows affected were ", affected

proc get_num_weights*(): int {.raises: [].} =
  ## Returns the number of weights stored in the database.
  assert (not DB_CONN.isNil)
  result = VALUES.len

proc find_pos*(w: PWeight): int {.raises: [].} =
  ## Finds the position of the weight in based on the identifier.
  ##
  ## If the weight is not found, negative is returned.
  if not w.isNil:
    let value = w[].id
    for f in 0..VALUES.high:
      if VALUES[f][].id == value:
        result = f
        return
  result = -1

proc modify_weight_date*(w: PWeight, value: TTime,
    old_pos, new_pos: var int) {.raises: [].} =
  ## Modifies the date of a weight entry.
  ##
  ## Since weights are sorted by date, this could change their position.
  ## Therefore the method stores into old_pos and new_pos the old/new positions
  ## in VALUES. If anything goes wrong, negative values will be stored. Pass
  ## the weight you want to modify, and the new date.
  assert (not DB_CONN.isNil)
  old_pos = w.find_pos
  if old_pos < 0:
    elog "Could not find weight to modify ", w[].id
    return
  assert VALUES[old_pos] == w

  new_pos = int(DB_CONN.update_date(w, value))
  if new_pos >= 0:
    let old_weight = VALUES[old_pos]
    VALUES.delete(old_pos)
    w[].date = value
    assert old_weight.date == value
    VALUES.insert(old_weight, new_pos)
  else:
    new_pos = -1
    elog "Could not update weight date ", w[].id

proc modify_weight_value*(w: PWeight, value: float): int {.raises: [].} =
  ## Changes the weight of an existing weight element.
  ##
  ## Returns the position of the weight in the global array, or negative if it
  ## wasn't found there.
  assert (not DB_CONN.isNil)
  let affected = DB_CONN.update_weight(w, value, WEIGHT_DEFAULT)
  if affected == 1:
    result = w.find_pos
    w[].weight = value
    w[].typ = WEIGHT_DEFAULT
  else:
    result = -1
    elog "Could not update weight value ", w[].id

proc get_last_weight*(): PWeight {.raises: [].} =
  ## Returns the last weight or nil if none was available.
  assert (not DB_CONN.isNil)
  let total = VALUES.len
  if total > 0:
    result = VALUES[total - 1]

proc get_weight*(pos: int): PWeight {.raises: [].} =
  ## Returns the weight at the specified position or nil for out of bounds.
  assert (not DB_CONN.isNil)
  if pos >= 0 and pos < VALUES.len:
    result = VALUES[pos]

proc get_localized_weight*(s: PWeight): float {.raises: [].} =
  ## Returns the localized weight to the current global weight unit.
  ##
  ## If `s` is nil, a default weight is returned for the UI to not start the
  ## weight selectors at zero.
  if s.isNil:
    case WEIGHT_DEFAULT:
    of kilograms: result = 60
    of pounds: result = 140
  else:
    result = s.to_unit(WEIGHT_DEFAULT)


proc set_decimal_separator*(value: char): bool {.discardable, raises: [].} =
  ## Allow native code to initialize the separator for formatting.
  ##
  ## This proc always works, but it returns false if the previously set global
  ## separator was the same to the new one, returning true if the value did
  ## change.
  if DECIMAL_SEPARATOR != value:
    DECIMAL_SEPARATOR = value
    INVALID_CHARS = AllChars - ({DECIMAL_SEPARATOR} + Digits)
    result = true

proc get_decimal_separator*(): char {.raises: [].} =
  ## Returns the currently used decimal separator.
  result = DECIMAL_SEPARATOR

proc specify_metric_use*(uses_metric: bool) {.raises: [].} =
  ## Allow native code to specify if the metric system is in use.
  ##
  ## This sets the default for input/formatting values. Pass true if the metric
  ## system (kg) is in use vs the US system (lb).
  WEIGHT_DEFAULT = if uses_metric: kilograms else: pounds

proc get_metric_use*(): Weight_type {.raises: [].} =
  ## Returns the current weight default.
  result = WEIGHT_DEFAULT

proc max_weight*(): int {.raises: [].} =
  ## Returns the maximum weight in the current default unit.
  ##
  ## It's amazing what the human body can suffer:
  ## http://mostextreme.org/heaviest_person.php
  case WEIGHT_DEFAULT
  of kilograms: result = 727
  of pounds: result = 1603

proc is_weight_input_valid*(future: string): bool {.raises: [].} =
  ## Validates a future input string as value for user_input_to_float.
  ##
  ## Returns false if the string contains any characters not liked by the proc.
  ## This proc is meant to be as a runtime check for users typing text into a
  ## field, so it will report as valid the empty string.
  if future.isNil: return
  let
    text = $future
    bad_char_pos = text.find(INVALID_CHARS)
  # Special case to allow free text input edition.
  if text.len == 0:
    return true

  if bad_char_pos >= 0: return
  let first_decimal = text.find(DECIMAL_SEPARATOR)
  if first_decimal == 0: return
  if first_decimal > 0:
    # Disallow any more decimal separators.
    let second_decimal = text.find(DECIMAL_SEPARATOR, first_decimal + 1)
    if second_decimal > 0:
      return
    # Also, disallow any more than num_decimals.
    if text.len - 1 - first_decimal > num_decimals:
      return

  # String parsing passed, now check values.
  var value: int
  try:
    if text.parse_int(value) > 0:
      if value > 0 and value < max_weight():
        result = true
  except EInvalidValue, EOverflow:
    dlog "Ignoring int parsing of '", text, "'"


proc export_database_to_csv*(csv_filename: string): bool {.raises: [].} =
  ## Takes the current database content and writes it into csv_filename.
  ##
  ## Pass a full path to csv_filename. Returns true if the proc didn't found
  ## any problems. If false is returned, you may need to remove any half
  ## created file at the specified path.
  if DB_CONN.isNil or csv_filename.isNil: return
  else: result = DB_CONN.build_csv_file(csv_filename)


proc scan_csv_for_entries*(csv_filename: string): int {.raises: [].} =
  ## Returns the number of entries in the file, or zero on error.
  if csv_filename.isNil: return
  try:
    let csv_values = parse_csv(csv_filename)
    result = csv_values.len
  except E_Base, EOutOfMemory:
    discard

proc import_csv_into_db*(csv_filename: string, replace: bool):
    bool {.raises: [].} =
  ## Reads csv_filename and adds its contents to the global database.
  ##
  ## If replace is true, the database will first be deleted. Returns false if
  ## there was any problem during the whole process.
  assert (not DB_CONN.isNil)
  if csv_filename.isNil: return
  var csv_values: seq[PWeight]
  try:
    csv_values = parse_csv($csv_filename)
  except E_Base, EOutOfMemory:
    exlog "Error processing csv values"
    return

  # See if we have to delete from the input existing entries.
  if not replace:
    var pos = 0
    while pos < csv_values.len:
      let input_weight = csv_values[pos]
      if VALUES.exists_value(input_weight):
        csv_values.delete(pos)
      else:
        pos += 1

  if csv_values.len > 0 or replace:
    dlog "Importing ", csv_values.len, " values from csv file"
    result = DB_CONN.import_csv_into_db(csv_values, replace)
    # Refresh globals.
    VALUES = DB_CONN.get_weights_page(-1, high(int))
  else:
    dlog "Didn't do any DB operation, all CSV imported values already there."
    result = true
