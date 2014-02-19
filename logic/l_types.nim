## Defines global types, enums and consts.
import times, l_log, strutils

type
  TWeight* {.exportc.} = object of TObject
    Fid: int ## Internal db identifier of the object.
    Fdate: TTime ## When was the object recorded.
    Fweight: float ## Weight, according to type.
    Ftyp: Weight_type ## Type of the weight.
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
  #dlog("Getter for weight for " & $s.Fweight)
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
  s.Fdate = value

proc date*(s: PWeight): TTime {.raises:[].} =
  ## Getter for the date attribute.
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

proc short*(x: Weight_type): string =
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
    formatFloat(x.weight, ffDecimal, 4) & ", typ:" & x[].typ_str &
    ", date:" & d & "}"


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
