## `Seohtracker logic <https://github.com/gradha/seohtracker-logic>`_ database
## module.
##
## Contains all the SQL related code. Most of the time you should not be
## importing this directly, unless you are a test case or want to do something
## evil. Instead use the exported procs from the `l_main module
## <l_main.html>`_.

import db_sqlite, times, strutils, l_types, l_log, streams,
  parsecsv, parseutils
import posix except EOVERFLOW, EIO

var
  USE_GMT_TIME = false

const
  update_queries = [
    [sql"""INSERT INTO Globals (id, int_val, text_val)
      VALUES (1, 1, 'DB version')"""], # 0
    [sql"""ALTER TABLE Weights ADD COLUMN
        weight_type INT NOT NULL DEFAULT 0"""], # 1
    ]

  page_query_columns = "id, date, weight, weight_type"
  page_query = sql("SELECT " & page_query_columns & """
    FROM Weights
    ORDER BY date ASC LIMIT ?""")

type
  CSV_tuple = tuple[date: TTime, weight: float, typ: Weight_type]
    ## Special temporary structure used while parsing csv files.

proc safe_try_insert_id(conn: TDbConn, query: TSqlQuery,
    final_date: TTime, weight: float, typ: Weight_type): int64
    {.raises: [].} =
  ## Safe wrapper around tryInsertID, to avoid raising exceptions.
  ##
  ## This should be removed whenever pull request
  ## https://github.com/Araq/Nimrod/pull/855 is merged.
  try:
    result = conn.try_insert_id(query, int(final_date), weight, typ.ord)
  except EDb:
    exlog "Error in safe_try_insert_id for ", int(final_date), " weight ",
      weight, " type ", typ
    result = -1

proc open_database*(path): Tdb_conn {.raises: [EDb].} =
  ## Creates or opens the database.
  ##
  ## If the database doesn't exist it will be created.
  ##
  ## Once the database has been opened, you should run `update() <#update>`_ on
  ## it.
  let
    conn = open(path, "user", "pass", "db")
    queries = [sql"""CREATE TABLE IF NOT EXISTS Weights (
        id INTEGER PRIMARY KEY,
        date INTEGER NOT NULL,
        weight REAL NOT NULL,
        CONSTRAINT Weights UNIQUE (id, date))""",
      sql"""CREATE TABLE IF NOT EXISTS Globals (
        id INTEGER PRIMARY KEY,
        int_val INTEGER,
        real_val REAL,
        text_val TEXT)""",
      ]

  for query in queries: conn.exec(query)
  result = conn


proc get_db_version(db_conn: Tdb_conn): int {.raises: [].} =
  ## Returns the integer version of the database.
  ##
  ## Will return zero if anything goes wrong or there is no db version info yet.
  if db_conn.isNil:
    assert false, "Shouldn't be passing nil database here!"
    return
  try:
    let row = db_conn.get_row(sql"""SELECT int_val FROM Globals WHERE id = 1""")
    try:
      result = row[0].parse_int
    except EInvalidValue, EOverflow:
      dlog "get_db_version() could not parse value '", row[0], "'"
  except EDb:
    exlog "Couldn't ask db about its version"
    return


proc update*(db_conn: Tdb_conn) {.raises: [EDb].} =
  ## Run on an open database to update the schema and everything else needed.
  ##
  ## If there is any problem updating the database, meaning that you should not
  ## continue, EDB will be raised.
  if db_conn.isNil: raise newException(EDB, "Can't update nil database")
  # Figure out the current version.
  var version = db_conn.get_db_version()
  while version < update_queries.len:
    dlog "Database at version ", version, ", performing upgrade"
    var step = 1
    for query in update_queries[version]:
      dlog "Step ", step
      db_conn.exec(query)
      step += 1

    version += 1
    db_conn.exec(sql"UPDATE Globals SET int_val = ? WHERE id = 1", version)
    dlog "Database upgraded to version ", version

  # At this point the database version should be equal to the last known.
  let last_version = db_conn.get_db_version()
  if last_version != update_queries.len:
    raise newException(EDB, "Final version " & $last_version &
      " doesn't match expected version " & $update_queries.len)


proc pos_for_date(conn: Tdb_conn, date: TTime): int {.raises: [].} =
  ## Returns the position for an entry with the given date.
  ##
  ## This works because when listing the database all the rows get sorted by
  ## date. However, it is undefined for the cases where two dates are equal.
  ##
  ## Returns negative if something went wrong, or otherwise the (hopefully
  ## correct) position.
  try:
    let
      pos_query = sql"""SELECT COUNT(id)
        FROM Weights
        WHERE date < ?
        ORDER BY date ASC"""
      row_count = conn.get_row(pos_query, int(date))
    try:
      result = row_count[0].parse_int
    except EInvalidValue, EOverflow:
      exlog "Could not parse position ", row_count[0]
      result = -1
  except EDb:
    exlog "Could not get position for date ", int(date), " aka ", date
    result = -1


proc add_weight*(conn: Tdb_conn; weight: float; typ: Weight_type,
    ddate: TTime = TTime(0)): tuple[w: PWeight, pos: int] {.raises: [].} =
  ## Inserts a weight into the database.
  ##
  ## If the proc succeeds and the just inserted weight can be read back, it
  ## returns the new PWeight object and the position it would have to be
  ## inserted into an array of weights.
  ##
  ## If the proc fails, nil and negative are returned.
  result.pos = -1
  let
    final_date = if TTime(0) == ddate: get_time() else: ddate
    insert_query = sql"""INSERT INTO Weights (date, weight, weight_type)
      VALUES (?, ?, ?)"""
    row_id = conn.safe_try_insert_id(insert_query, final_date, weight, typ)

  if row_id < 0:
    elog "Couldn't add weight ", weight
    return

  # Insertion did work, now try to read it back to get all data.
  try:
    let
      read_query = sql"""SELECT id, date, weight, weight_type
        FROM Weights WHERE id = ?"""
      data = conn.get_row(read_query, row_id)
    try:
      assert data[0].parse_int == row_id
      result.w = init_weight(data[0].parse_int, TTime(data[1].parse_int),
            data[2].parse_float, Weight_type(data[3].parse_int))
    except EInvalidValue, EOverflow:
      exlog "Could not read ", data.join(", ")

    # Finally find the position it should be placed in the global list.
    result.pos = conn.pos_for_date(date(result.w))
  except EDb:
    exlog "Weight ", weight, " added, but failed to read it back!"

proc remove_weight*(conn: Tdb_conn; weight: PWeight): int64 =
  ## Removes the specified weight identifier, returns number of rows removed.
  ##
  ## Look for a value greater than zero for success.
  if weight.isNil: return
  try:
    let query = sql"DELETE FROM Weights WHERE id = ?"
    result = conn.exec_affected_rows(query, weight[].id)
  except EDb:
    exlog "Could not remove weight ", weight[].id


proc update_weight*(conn: Tdb_conn; weight: PWeight,
    value: float, typ: Weight_type): int64 =
  ## Modifies the value of the weight, returns the number of rows updated.
  ##
  ## Note that `weight` is not updated, you have to do it yourself. Returns
  ## zero on failure.
  if weight.isNil: return
  try:
    let query = sql"""UPDATE Weights
      SET weight = ?, weight_type = ?
      WHERE id = ?"""
    result = conn.exec_affected_rows(query, value, typ.ord, weight[].id)
  except EDb:
    exlog "Could not update weight ", weight[].id

proc update_date*(conn: Tdb_conn; weight: PWeight, value: TTime): int
    {.raises: [].} =
  ## Modifies the value of the weight, returns its new position in the table.
  ##
  ## Note that `weight` is not updated, you have to do it yourself. Returns
  ## negative on error.
  try:
    let
      query = sql"UPDATE Weights SET date = ? WHERE id = ?"
      affected = conn.exec_affected_rows(query, int(value), weight[].id)
    if affected == 1:
      result = conn.pos_for_date(value)
    else:
      elog "Could not update weight date"
      result = -1
  except EDb:
    exlog "Couldn't update weight ", weight[].id
    result = -1

proc get_num_weights*(conn: Tdb_conn): int =
  ## Returns the number of entries in the Weight table.
  ##
  ## If the function succeeds, returns the zero or positive value, if something
  ## goes wrong a negative value is returned.
  let query = sql"""SELECT COUNT(id) FROM Weights"""
  try:
    let row = conn.getRow(query)
    result = row[0].parse_int
  except EDB:
    result = -1

proc get_weights_page*(conn: Tdb_conn;
    last_known_id = -1, page_size = 5): seq[PWeight] {.raises: [].} =
  ## Returns the weights just below the specified identifier.
  ##
  ## Pass a negative identifier to retrieve the "top" of the table, used when
  ## you don't know yet the highest identifier.
  if page_size < high(int):
    dlog "Warning, this proc is broken!"
  try:
    result = @[]
    if last_known_id < 0:
      for row in conn.fast_rows(page_query, page_size):
        try:
          result.add(init_weight(row[0].parse_int, TTime(row[1].parse_int),
            row[2].parse_float, Weight_type(row[3].parse_int)))
        except EInvalidValue, EOverflow:
          exlog "Could not read ", row.join(", ")
    else:
      let query = sql("SELECT " & page_query_columns & """
        FROM Weights WHERE id < ?
        ORDER BY date ASC LIMIT ?""")
      # TODO: remember this is wrong!
      for row in conn.fast_rows(query, last_known_id, page_size):
        try:
          result.add(init_weight(row[0].parse_int, TTime(row[1].parse_int),
            row[2].parse_float, Weight_type(row[3].parse_int)))
        except EInvalidValue, EOverflow:
          exlog "Could not read ", row.join(", ")
  except EDb:
    exlog "Empty results for last id ", last_known_id, " page ", page_size
    result = @[]

proc import_csv_into_db*(conn: TDbConn, values: seq[PWeight],
    replace: bool): bool {.raises: [].} =
  ## Imports the values into the database.
  ##
  ## If replace is true, the database is first deleted. The input PWeight
  ## objects from `values` won't be modified, you have to fetche/refresh the
  ## whole database after this proc is done.
  assert (not values.isNil)
  result = false
  try:
    conn.exec(sql"BEGIN TRANSACTION")
    if replace: conn.exec(sql"DELETE FROM Weights")
    for w in values:
      conn.exec(sql"""INSERT INTO Weights (date, weight, weight_type)
        VALUES (?, ?, ?)""", int(w.date), w.weight, w[].typ.ord)
    conn.exec(sql"END TRANSACTION")
    result = true
  except EDB:
    exlog "Could not import_csv_into_db seq of ", values.len


proc timegm*(a1: var Ttm): TTime  {.importc, header: "<time.h>".}

proc parse_csv_date_column(text: string, target: var TTime): bool =
  ## Attempts to parse text into a valid date for the target.
  ##
  ## Returns true if the parsing was successful storing the final time in
  ## target, false otherwise. The expected parsing format is
  ## YYYY-MM-DD:HH-MM-SS, anything other than that will fail.
  var info: Ttm
  if nil == text.strptime("%F:%H-%M-%S", info):
    return

  if USE_GMT_TIME:
    target = info.timegm
  else:
    target = info.mktime
  result = true


proc parse_csv_weight_column(text: string, target: var CSV_tuple): bool =
  ## Attempts to parse text into the target's weight value and type fields.
  ##
  ## If the parsing was successful returns true and sets the weight and typ
  ## fields to useful values. Otherwise false is returned and the tuple might
  ## not be modified at all.
  assert (not text.isNil)
  var buf = text
  if text.endsWith(kg_str):
    target.typ = kilograms
    buf.delete(text.len - kg_str.len, <text.len)
    assert buf.len == text.len - kg_str.len
  elif text.endsWith(lb_str):
    target.typ = pounds
    buf.delete(text.len - lb_str.len, <text.len)
    assert buf.len == text.len - lb_str.len
  else:
    return

  # At this point we have the type, we only need to parse the value.
  let parsed_chars = buf.parse_float(target.weight)
  if parsed_chars > 0 and buf.len == parsed_chars:
    result = true


proc parse_csv_row(cols: seq[string]): CSV_tuple =
  ## Given a sequence of text columns from a CSV, returns a valid weight tuple.
  ##
  ## To know if the returned weight is valid, check against negative weight
  ## values.
  assert cols.len >= 2
  result.weight = -1
  var did_time, did_weight = false
  for col in cols:
    # Break out, in case there are more columns.
    if did_time and did_weight: break

    if not did_weight and col.parse_csv_weight_column(result):
      did_weight = true
    elif not did_time and col.parse_csv_date_column(result.date):
      did_time = true

  # Final safety check.
  if did_time and did_weight:
    return
  else:
    result.weight = -1

proc parse_csv*(input_filename: string): seq[PWeight] =
  ## Returns the list of weights as read from the input file.
  ##
  ## The imported time is considered according to USE_GMT_TIME.
  assert (not input_filename.isNil)
  if input_filename.isNil: return
  result = @[]
  var s = newFileStream(input_filename, fmRead)
  if s.isNil:
    dlog "Can't read ", input_filename
    return
  var x: TCsvParser
  x.open(s, input_filename, skipInitialSpace = true)
  while readRow(x):
    # Skip rows if they don't contain enough columns.
    if x.row.len < 2: continue
    let (date, weight, weight_type) = parse_csv_row(x.row)
    if weight < 1: continue
    result.add(init_weight(-1, date, weight, weight_type))
  x.close

proc build_csv_file*(conn: TDbConn, out_filename: string): bool {.raises: [].} =
  ## Reads through the open database and dumps it to the specified file.
  ##
  ## Returns true if the exportation was a success, false if there was any
  ## error.
  if conn.isNil or out_filename.isNil or out_filename.len < 1:
    elog "Invalid parameters passed to build_csv_file"
    return
  var out_file: TFile
  try:
    if not out_file.open(out_filename, fmWrite):
      exlog "Could not open ", out_filename, " for writing."
      return
  except EOutOfMemory:
    return

  # Move here finally as statement when
  # https://github.com/Araq/Nimrod/issues/908 works again.
  try:
    try:
      out_file.write("date,weight\n-----\n")
    except EIO:
      exlog "Could not write header"
      return

    try:
      for row in conn.fast_rows(page_query, high(int)):
        try:
          let
            w_type = Weight_type(row[3].parse_int).short
            w_value = row[2]
            time_int = if USE_GMT_TIME: getGMTime(
              TTime(row[1].parse_int)) else: getLocalTime(
              TTime(row[1].parse_int))
            time_str = time_int.format_iso
          out_file.write(time_str, ",", w_value, w_type, "\n")
        except EInvalidValue, EOverflow, EIO, E_Base:
          exlog "Could not process for export '", row.join(", "), "'"
          return
    except EDb:
      exlog "Couldn't scan database for csv export?"
      return
  finally:
    out_file.close

  result = true

proc set_csv_export_gmt_time*(use_gmt: bool) =
  ## Sets the exportation to use getGMTime instead of getLocalTime.
  ##
  ## This is a feature required for the unit tests to pass running in any
  ## timezone, but it is undesirable for the end user, as he tracks the data in
  ## his local time.
  USE_GMT_TIME = use_gmt
