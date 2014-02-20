import l_main, db_sqlite, strutils, os

const
  db_filename = "test.sqlite3"

proc test() =
  ## Checks that newer db versions aren't allowed to be used.
  echo "Step 1"
  db_name.removeFile
  doAssert open_db(nil)
  get_db().exec(sql"UPDATE Globals SET int_val = ? WHERE id = 1", 10_000)
  close_db()
  echo "Step 2"
  doAssert open_db(nil) == false
  echo "Test finished successfully"


when isMainModule:
  test()
