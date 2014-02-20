## `Seohtracker logic <https://github.com/gradha/seohtracker-logic>`_ logging
## module.
##
## Provides a few templates and procs for debug and error logging.

const
  err_prefix = "nim-err: "
  normal_prefix = "nim-log: "

import strutils
proc `$`*(e: ref E_base): string {.inline.} =
  ## Remove this when https://github.com/Araq/Nimrod/issues/749 is fixed.
  return repr(e).strip

proc elog*(x: varargs[string, `$`]) =
  # Logs always with an error prefix.
  case x.len
  of 0: discard
  of 1: echo err_prefix & x[0]
  else:
    var tmp = err_prefix & x[0]
    for f in 1.. <x.len: tmp.add x[f]
    echo tmp

proc log*(x: varargs[string, `$`]) =
  case x.len
  of 0: discard
  of 1: echo normal_prefix & x[0]
  else:
    var tmp = normal_prefix & x[0]
    for f in 1.. <x.len: tmp.add x[f]
    echo tmp

template dlog*(x: varargs[string, `$`]) =
  ## Debug logging, goes away in release builds.
  when not defined(release):
    log x

template exlog*(x: varargs[string, `$`]) =
  ## Exception template, use inside except handlers to log exception message.
  let
    pos = instantiationInfo()
    e = getCurrentException()
  elog "Exception ", e, ": '", e.msg, "' in ", pos.filename, ":", pos.line
  elog x
