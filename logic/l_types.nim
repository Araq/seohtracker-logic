## `Seohtracker logic <https://github.com/gradha/seohtracker-logic>`_ types
## module.
##
## Defines global types, enums and consts for the logic. There is no need to
## import this explicitly, the `l_main module <l_main.html>`_ already exports
## the necessary stuff.

import times, l_log, strutils

type
  TWeight* {.exportc.} = object of TObject
    # Fields serialized to the database.
    Fid: int ## Internal db identifier of the object.
    Fdate: TTime ## When was the object recorded.
    Fweight: float ## Weight, according to type.
    Ftyp: Weight_type ## Type of the weight.

    Fday_date: string ## date field in YYYYMMDD format for day comparisons. \
    ##
    ## May be nil, use the accessor to automatically recalculate it. The date
    ## is calculated using the local time by default. This may be problematic
    ## for unit testing, requiring a future l_db.USE_GMT_TIME hack.
    alternating_day*: bool ## Marks entries as odd/even days for colouring.

    changes_day*: bool ## \
    ## Set to true if the immediate previous entry is for a different day.
    ##
    ## A group of three entries with the same day will have the same vale for
    ## `alternating_day`, but only the first will have true in the
    ## `changes_day` field.

  PWeight* {.exportc.} = ref TWeight

  Weight_type* = enum kilograms = 0, pounds = 1 ## \
    ## Enums don't get exported to C at the moment, see
    ## https://github.com/Araq/Nimrod/issues/826. This is patched on the Objc
    ## side for the moment with duplicated C enums. See "n_types.h"

const
  db_name* = "seohyun.sqlite3"
  kg_str* = "kg"
  lb_str* = "lb"
  nim_decimal_separator* = '.'
  num_decimals* = 1


proc retain_weight*(w: PWeight) {.raises:[].} =
  ## Exports to c a way to mark an object retained.
  ##
  ## Nil references are ignored, it is safe to call this proc on them.
  if not w.isNil:
    #dlog cast[int](w), " plus"
    GC_ref(w)

proc release_weight*(w: var PWeight) {.raises:[].} =
  ## Exports to c a way to unmark a retained object.
  ##
  ## The proc unrefs and initializes the variable to zero.
  if not w.isNil:
    #dlog cast[int](w), " minus"
    #GC_unref(w)
    w = nil

proc `weight=`*(s: var TWeight, value: float) =
  ## Setter for the weight attribute.
  ##
  ## Note that this doesn't change the current type!
  s.Fweight = value

proc weight*(s: PWeight): float =
  ## Getter for the weight attribute.
  if s.isNil: return
  return s[].Fweight

proc to_unit*(w: PWeight, unit: Weight_type): float =
  ## Unit aware weight value getter.
  ##
  ## Conversion rates obtained from https://en.wikipedia.org/wiki/Kilogram.
  if w.isNil: return
  if w.Ftyp == unit:
    result = w.Fweight
  else:
    case w.Ftyp
    of kilograms: result = 2.2046 * w.Fweight
    of pounds: result = 0.45359237 * w.Fweight

proc `id=`*(s: var TWeight, value: int) =
  ## Setter for the id attribute.
  s.Fid = value

proc id*(s: TWeight): int =
  ## Getter for the id attribute.
  return s.Fid

proc `date=`*(s: var TWeight; value: TTime) =
  ## Setter for the date attribute.
  ##
  ## Also cleans the day_date field by forcing it to nil.
  s.Fdate = value
  s.Fday_date = nil

proc date*(s: PWeight): TTime {.raises:[].} =
  ## Getter for the Fdate attribute.
  ##
  ## Returns zero if the weight is invalid.
  if not s.isNil:
    result = s[].Fdate

proc `typ=`*(s: var TWeight; value: Weight_type) =
  ## Setter for the type of the weight.
  s.Ftyp = value

proc typ*(s: TWeight): Weight_type =
  ## Getter for the type of weight.
  return s.Ftyp

proc short*(x: Weight_type): string not nil =
  case x:
  of kilograms: result = kg_str
  of pounds: result = lb_str

proc typ_str*(s: TWeight): string =
  ## Returns the string to format the weight according to its type.
  result = short(s.Ftyp)

proc init_weight*(id: int; date: TTime; weight: float, typ: Weight_type):
    PWeight =
  ## Returns a new weight object with the specified weight and date.
  ##
  ## Pass a negative identifier if the object you are creating doesn't have a
  ## database row entry (yet).
  new(result)
  result[].id = id
  result[].date = date
  result[].weight = weight
  result[].typ = typ


proc format_iso*(info: TTimeInfo): string {.raises: [EInvalidValue].} =
  ## Convenience helper to transform a date into the CSV export date format.
  result = info.format("yyyy-MM-dd:HH-mm-ss")


proc safe_str*(s: string): string {.raises: [].} =
  ## Returns the string or "(nil)" if the variable is not initialized.
  result = if s.isNil: "(nil)" else: s

proc `$`*(x: PWeight): string {.raises: [].} =
  ## Debugging/logging helper of weights.
  if x.isNil:
    result = "PWeight {nil}"
    return

  # Attempt to parse date.
  var d = "error"
  try: d = x.date.getGMTime.format_iso
  except EInvalidValue: discard

  # Build debug string.
  result = "PWeight {id:" & $(x[].id) & ", weight:" &
    formatFloat(x.Fweight, ffDecimal, 4) & ", typ:" & x[].typ_str &
    ", date:" & d & ", day_date:" & safe_str(x[].Fday_date) & "}"


proc `==`(x, y: PWeight): bool =
  ## Returns true if both x and y are not nil and have equal values.
  ##
  ## The equality ignores the database identifier field.
  if x.isNil or y.isNil: return
  if x.date == y.date and x.weight == y.weight and x[].typ == y[].typ:
    result = true

proc exists_value*(s: seq[PWeight], x: PWeight): bool =
  ## Iterates s in search of a value x which has the same date, weight and type.
  ##
  ## The comparison ignores the database identifier.
  assert (not s.isNil)
  assert (not x.isNil)
  for y in s:
    if y == x:
      result = true
      return

proc day_date*(w: var TWeight): string {.raises: [EInvalidValue].} =
  ## Returns the day_date field of PWeight, which may need recalculation.
  if w.Fday_date.isNil:
    let info = w.Fdate.get_local_time
    w.Fday_date = info.format("yyyyMMdd")
  assert w.Fday_date.len > 0
  return w.Fday_date


proc day_date*(w: PWeight): string =
  ## Returns the day_date field of PWeight, which may need recalculation.
  ##
  ## Returns the empty string if the weight pointer is nil.
  if w.isNil: return ""
  return day_date(w[])
