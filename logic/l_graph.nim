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
  defaultMaxTicks* = 10

type NiceScale* = object ## \
  ## Stores the input and output parameters of the scale computation.
  ##
  ## You need to initialize a NiceScale object and then call the ``calculate``
  ## proc to contain meaningful output values. Call ``calculate`` again if you
  ## modify the input parameters.
  minPoint*: float ## Input, the minimum point to be displayed by the graph.
  maxPoint*: float ## Input, the maximum point to be displayed by the graph.
  maxTicks*: int ## Input, maximum number of ticks in the axis.
  tickSpacing*: float ## Output, distance between ticks on the ideal axis.
  niceMin*: float ## Output, optimal minimum value to start the axis.
  niceMax*: float ## Output, optimal maximum value to end the axis.

proc ff(x: float): string =
  ## Wrapper around strutils.formatFloat for less typing.
  result = x.formatFloat(ffDecimal, 3)

proc `$`*(x: NiceScale): string =
  ## Debug formatter of the NiceScale structure.
  result = "Input minPoint: " & x.minPoint.ff &
    "\nInput maxPoint: " & x.maxPoint.ff &
    "\nInput maxTicks: " & $x.maxTicks &
    "\nOutput niceMin: " & x.niceMin.ff &
    "\nOutput niceMax: " & x.niceMax.ff &
    "\nOutput tickSpacing: " & x.tickSpacing.ff &
    "\n"

proc calculate*(x: var NiceScale)

proc init*(x: var NiceScale; minPoint, maxPoint: float;
    maxTicks = defaultMaxTicks) =
  ## Initializes a NiceScale variable.
  ##
  ## Pass the minimum and maximum values of the axis and the number of ticks.
  ## The initialisation will automatically call ``calculate()`` for you so you
  ## can already grab the output values.
  x.minPoint = minPoint
  x.maxPoint = maxPoint
  x.maxTicks = defaultMaxTicks
  x.calculate

proc initScale*(minPoint, maxPoint: float;
    maxTicks = defaultMaxTicks): NiceScale =
  ## Shortcut for initialisations in variable blocks.
  result.init(minPoint, maxPoint, maxTicks)

proc niceNum(scaleRange: float; doRound: bool): float =
  ## Calculates a nice number for `scaleRange`.
  ##
  ## Returns a *nice* number approximately equal to `scaleRange`. Rounds the
  ## number if ``doRound = true``. Takes the ceiling if ``doRound = false``.
  var
    exponent: float ## Exponent of scaleRange.
    fraction: float ## Fractional part of scaleRange.
    niceFraction: float ## Nice, rounded fraction.

  exponent = floor(log10(scaleRange));
  fraction = scaleRange / pow(10, exponent);

  if doRound:
    if fraction < 1.5:
      niceFraction = 1
    elif fraction < 3:
      niceFraction = 2
    elif fraction < 7:
      niceFraction = 5
    else:
      niceFraction = 10
  else:
    if fraction <= 1:
      niceFraction = 1
    elif fraction <= 2:
      niceFraction = 2
    elif fraction <= 5:
      niceFraction = 5
    else:
      niceFraction = 10

  return niceFraction * pow(10, exponent)

proc calculate*(x: var NiceScale) =
  ## Calculates the value of output fields based on the input fields.
  ##
  ## Feel free to modify any of `minPoint`, `maxPoint` or `maxTicks` before
  ## calling this. Then the proc will modify the `tickSpacing`, `niceMax` and
  ## `niceMax` fields.
  ##
  ## The `maxTicks` field has to be zero or positive. The `maxPoint` field has
  ## to be always bigger than `minPoint`.
  assert x.maxPoint > x.minPoint, "Wrong input range!"
  assert x.maxTicks >= 0, "Sorry, can't have imaginary ticks!"
  let scaleRange = niceNum(x.maxPoint - x.minPoint, false)
  if x.maxTicks < 2:
    x.niceMin = floor(x.minPoint)
    x.niceMax = ceil(x.maxPoint)
    x.tickSpacing = (x.niceMax - x.niceMin) /
      (if x.maxTicks == 1: 2.0 else: 1.0)
  else:
    x.tickSpacing = niceNum(scaleRange / (float(x.maxTicks - 1)), true)
    x.niceMin = floor(x.minPoint / x.tickSpacing) * x.tickSpacing
    x.niceMax = ceil(x.maxPoint / x.tickSpacing) * x.tickSpacing

when isMainModule:
  var s = initScale(97.2, 103.3)
  echo "Using default spacing:"
  echo s
  echo "Try now a single and zero ticks!"
  s.maxTicks = 1
  s.calculate
  echo s
  s.maxTicks = 0
  s.calculate
  echo s
  #echo "Now we will crash in debug versions!"
  #s.maxTicks = -42
  #s.calculate
  #echo s
