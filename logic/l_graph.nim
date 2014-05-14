## `Seohtracker logic <https://github.com/gradha/seohtracker-logic>`_ graph
## module.
##
## Contains graphical related code. Not directly used in the logical operation
## of Seohtracker but common code for many if not all clients. Also, some of
## this code is more optimal in Nimrod just because you don't have the
## interface call overhead to obtain data.
##
## Some reference code used to implement the code here include:
##
## * http://stackoverflow.com/questions/8506881/nice-label-algorithm-for-charts-with-minimum-ticks/16363437#16363437

import math, strutils, l_log

const
  default_max_ticks* = 10

type
  Nice_scale* {.exportc.} = object ## \
    ## Stores the input and output parameters of the scale computation.
    ##
    ## You need to initialize a Nice_scale object and then call the
    ## ``calculate`` proc to contain meaningful output values. Call
    ## ``calculate`` again if you modify the input parameters.
    min_point*: float ## Input, the minimum point to be displayed by the graph.
    max_point*: float ## Input, the maximum point to be displayed by the graph.
    max_ticks*: int ## Input, maximum number of ticks in the axis.
    tick_spacing*: float ## Output, distance between ticks on the ideal axis.
    nice_min*: float ## Output, optimal minimum value to start the axis.
    nice_max*: float ## Output, optimal maximum value to end the axis.
  PNice_scale* {.exportc.} = ref Nice_scale

proc ff(x: float): string =
  ## Wrapper around strutils.formatFloat for less typing.
  result = x.formatFloat(ffDecimal, 3)

proc `$`*(x: Nice_scale): string =
  ## Debug formatter of the Nice_scale structure.
  result = "Input min_point: " & x.min_point.ff &
    "\nInput max_point: " & x.max_point.ff &
    "\nInput max_ticks: " & $x.max_ticks &
    "\nOutput nice_min: " & x.nice_min.ff &
    "\nOutput nice_max: " & x.nice_max.ff &
    "\nOutput tick_spacing: " & x.tick_spacing.ff &
    "\n"

proc calculate*(X: var Nice_scale) {.raises: [].}

proc init*(X: var Nice_scale; min_point, max_point: float;
    max_ticks = default_max_ticks) =
  ## Initializes a Nice_scale variable.
  ##
  ## Pass the minimum and maximum values of the axis and the number of ticks.
  ## The initialisation will automatically call ``calculate()`` for you so you
  ## can already grab the output values.
  X.min_point = min_point
  X.max_point = max_point
  X.max_ticks = max_ticks
  X.calculate

proc init_nice_scale*(min_point, max_point: float;
    max_ticks = default_max_ticks): Nice_scale =
  ## Shortcut for initialisations in variable blocks.
  result.init(min_point, max_point, max_ticks)

proc nice_num(scale_range: float; doRound: bool): float =
  ## Calculates a nice number for `scale_range`.
  ##
  ## Returns a *nice* number approximately equal to `scale_range`. Rounds the
  ## number if ``doRound = true``. Takes the ceiling if ``doRound = false``.
  let
    exponent = floor(log10(scale_range)) ## Exponent of scale_range.
    fraction = scale_range / pow(10, exponent)## Fractional part of scale_range.

  var NICE_FRACTION: float ## Nice, rounded fraction.

  if doRound:
    if fraction < 1.5:
      NICE_FRACTION = 1
    elif fraction < 3:
      NICE_FRACTION = 2
    elif fraction < 7:
      NICE_FRACTION = 5
    else:
      NICE_FRACTION = 10
  else:
    if fraction <= 1:
      NICE_FRACTION = 1
    elif fraction <= 2:
      NICE_FRACTION = 2
    elif fraction <= 5:
      NICE_FRACTION = 5
    else:
      NICE_FRACTION = 10

  return NICE_FRACTION * pow(10, exponent)

proc calculate*(X: var Nice_scale) =
  ## Calculates the value of output fields based on the input fields.
  ##
  ## Feel free to modify any of `min_point`, `max_point` or `max_ticks` before
  ## calling this. Then the proc will modify the `tick_spacing`, `nice_max` and
  ## `nice_max` fields.
  ##
  ## The `max_ticks` field has to be zero or positive. The `max_point` field
  ## has to be always bigger than `min_point`.
  assert X.max_point >= X.min_point, "Wrong input range!"
  assert X.max_ticks >= 0, "Sorry, can't have imaginary ticks!"
  let scale_range = nice_num(X.max_point - X.min_point, false)
  if X.max_ticks < 2:
    X.nice_min = floor(X.min_point)
    X.nice_max = ceil(X.max_point)
    X.tick_spacing = (X.nice_max - X.nice_min) /
      (if X.max_ticks == 1: 2.0 else: 1.0)
  else:
    X.tick_spacing = nice_num(scale_range / (float(X.max_ticks - 1)), true)
    X.nice_min = floor(X.min_point / X.tick_spacing) * X.tick_spacing
    X.nice_max = ceil(X.max_point / X.tick_spacing) * X.tick_spacing

when isMainModule:
  var S = init_nice_scale(97.2, 103.3)
  echo "Using default spacing:"
  echo S
  echo "Try now a single and zero ticks!"
  S.max_ticks = 1
  S.calculate
  echo S
  S.max_ticks = 0
  S.calculate
  echo S
  #echo "Now we will crash in debug versions!"
  #S.max_ticks = -42
  #S.calculate
  #echo S
