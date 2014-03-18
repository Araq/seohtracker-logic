## Small interactive test of the database.
##
## This requires some *semi public* procs from l_db and l_types.
import l_main, db_sqlite, l_db, strutils, times

proc show_paged_results(conn: Tdb_conn) =
  ## Shows the contents of the database in pages of specified size.
  ##
  ## This tests the  blah blah
  var
    page = 0
    last_row = -1
    rows = conn.get_weights_page

  while rows.len > 0:
    echo "page " & $page
    for row in rows:
      # Force calculation of day date.
      discard(row.day_date)
      echo "row $1, date $2, weight $3" % [$row[].id, $row.date,
        row.weight.format_float(ffDecimal, num_decimals)]
      last_row = row[].id
    rows = conn.get_weights_page(last_row)
    page = page + 1


proc interactive_test() =
  ## Does some testing with a database based on user input.
  doAssert open_db("")
  echo "Current database contains " & $get_num_weights() & " rows."

  show_paged_results(get_db())

  var weight : float = -1
  while weight < 0:
    echo("Enter the weight you want to add to the database (return to abort):")
    let input_line = stdin.read_line
    try:
      weight = input_line.parse_float
    except EInvalidValue:
      if input_line.len < 1: break
      echo("could not convert string to float, please repeat!")

  if weight >= 0:
    let pos = add_weight(weight)
    echo "Insertion of " & weight.format_float(ffDecimal, num_decimals) &
      " into position " & $pos
    echo "Current database contains " & $get_num_weights() & " rows."


when isMainModule:
  interactive_test()
