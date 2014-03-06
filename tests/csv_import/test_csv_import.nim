import l_main, db_sqlite, strutils, os, osproc, md5, l_db

const
  dump_in = ".."/"data"/"csv_export_sql_dump.txt"
  csv_in_kg = ".."/"data"/"csv_import.csv"
  csv_in_lb = ".."/"data"/"csv_import_mixed.csv"
  csv_out = "out.csv"

proc test() =
  db_name.removeFile
  doAssert db_name.existsFile == false
  discard execCmd("sqlite3 -init " & dump_in & " " & db_name & " .quit")
  echo "Opening database…"
  doAssert open_db("."), "Failed opening database!"
  doAssert add_weight(666.0) > 0
  doAssert get_num_weights() == 69

  echo "Attention, this test only works if you are in GMT+1!"
  # TODO: verify timezone and avoid running?
  set_csv_export_gmt_time(false)

  var entries = scan_csv_for_entries(csv_in_kg)
  echo "Parsed ", entries, " from ", csv_in_kg
  doAssert entries == 68
  doAssert import_csv_into_db(csv_in_kg, false), "Could no import csv file"
  doAssert get_num_weights() == 69, "Expected no changes, but there were?"
  doAssert import_csv_into_db(csv_in_kg, true), "Could no replace with csv file"
  doAssert get_num_weights() == 68, "Expected db to have one entry less"
  doAssert import_csv_into_db(csv_in_kg, false), "Could no import csv file"
  doAssert get_num_weights() == 68, "Expected no changes, but there were?"

  # Finally, export to a temporary file and compare with the input csv dump.
  doAssert export_database_to_csv(csv_out)

  let md5_a = csv_in_kg.readFile.getMD5
  let md5_b = csv_out.readFile.getMD5
  doAssert md5_a == md5_b, "Input csv doesn't match output csv md5!"
  echo "Re-dumped csv file matches md5 of input csv file"

  # Now try to mix some lb readings.
  doAssert import_csv_into_db(csv_in_lb, true)
  doAssert get_num_weights() == 68
  doAssert import_csv_into_db(csv_in_kg, false)
  doAssert get_num_weights() == 72
  doAssert import_csv_into_db(csv_in_kg, true)
  doAssert get_num_weights() == 68
  doAssert import_csv_into_db(csv_in_lb, false)
  doAssert get_num_weights() == 72
  echo "Success"


when isMainModule:
  test()
