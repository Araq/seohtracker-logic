import strutils, os

## Tests template to prevent https://github.com/Araq/Nimrod/issues/908.

const
  out_filename = "dummy.tmp"

template memento(body: stmt): stmt {.immediate.} =
  ## Like finally as a statement but without warts.
  try: discard finally: discard
  finally: body

proc test_memento(): bool =
  ## Returns true if the file was written properly.
  ##
  ## This test the memento template, it should inject a discard to allow the
  ## out_file.close not execute until the proc has really finished.
  var out_file: TFile
  try:
    if not out_file.open(out_filename, fmWrite):
      echo "Could not open ", out_filename, " for writing."
      return
    echo "File opened for memento"
  except EOutOfMemory:
    return

  memento:
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
  assert test_memento(), "Why did the memento template fail?"
  echo "Success testing memento"
