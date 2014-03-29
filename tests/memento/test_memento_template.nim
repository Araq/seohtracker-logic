import strutils, os, macros

## Tests template to prevent https://github.com/Araq/Nimrod/issues/908.

const
  out_filename = "dummy.tmp"

template memento_te(body: stmt): stmt {.immediate.} =
  ## Like finally as a statement but without warts.
  try: discard finally: discard
  finally: body

macro memento_ma(body: expr): stmt {.immediate.} =
  result = newNimNode(nnkStmtList)
  result.add(newNimNode(nnkDiscardStmt).add(newEmptyNode()))
  result.add(body)

proc test_memento_ma(): bool =
  ## Returns true if the file was written properly.
  ##
  ## This test the memento macro, it should inject a discard to allow the
  ## out_file.close not execute until the proc has really finished.
  var out_file: TFile
  try:
    if not out_file.open(out_filename, fmWrite):
      echo "Could not open ", out_filename, " for writing."
      return
    echo "File opened for macro"
  except EOutOfMemory:
    return

  memento_ma:
    echo "Closing file"
    out_file.close

  try: out_file.write("yeah\n")
  except EIO:
    echo "Error writing to file."
    return

  result = true


proc test_memento_te(): bool =
  ## Returns true if the file was written properly.
  ##
  ## This test the memento template, it should inject a discard to allow the
  ## out_file.close not execute until the proc has really finished.
  var out_file: TFile
  try:
    if not out_file.open(out_filename, fmWrite):
      echo "Could not open ", out_filename, " for writing."
      return
    echo "File opened for template"
  except EOutOfMemory:
    return

  memento_te:
    echo "Closing file"
    out_file.close

  try: out_file.write("yeah\n")
  except EIO:
    echo "Error writing to file."
    return

  result = true


proc test_workaround(): bool =
  ## Returns true if the file was written properly.
  ##
  ## This test the manual workaround, the discard should allow the
  ## out_file.close to not execute until the proc has really finished.
  var out_file: TFile
  try:
    if not out_file.open(out_filename, fmWrite):
      echo "Could not open ", out_filename, " for writing."
      return
    echo "File opened for workaround"
  except EOutOfMemory:
    return

  discard
  finally:
    out_file.close

  try: out_file.write("yeah\n")
  except EIO:
    echo "Error writing to file."
    return

  result = true


when isMainModule:
  assert test_workaround(), "Oh, our workaround failed"
  echo "Workaround did work"
  assert(not test_memento_te(), "Oh, it does work after all?")
  echo "Template failed"
  assert test_memento_ma(), "Macro doesn't work either"
  echo "Success testing macro"
