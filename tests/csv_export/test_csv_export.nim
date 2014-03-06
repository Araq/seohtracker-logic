import l_main, db_sqlite, strutils, os, osproc, md5, l_db

const
  test_csv = "dump_out.csv"
  expected_md5 = "777637490dfc28c7f9c0d71f518d957a"
  dump_in = ".."/"data"/"csv_export_sql_dump.txt"

proc test_dump_setup() {.exportc.} =
  echo "Setting up test…"
  db_name.removeFile
  doAssert db_name.existsFile == false
  discard execCmd("sqlite3 -init " & dump_in & " " & db_name & " .quit")
  echo "Opening database…"
  doAssert open_db("."), "Failed opening database!"
  echo "Num entries ", get_num_weights()

proc test_dump_run() {.exportc.} =
  echo "Exporting…"
  set_csv_export_gmt_time(true)
  doAssert export_database_to_csv(test_csv)
  echo "Finished exporting."

proc test_dump_verify() {.exportc.} =
  let dump_md5 = test_csv.readFile.getMD5
  doAssert dump_md5 == expected_md5
  echo "CSV dump matches expectations"

when isMainModule:
  test_dump_setup()
  test_dump_run()
  test_dump_verify()
