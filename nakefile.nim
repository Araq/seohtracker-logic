import supernake

const
  test_dir = "tests"
  logic_dir = "logic"

let
  normal_rst_files = concat(mapIt(
    [".", "docs", "objc_interface"],
    seq[string], glob_rst(it)))


iterator all_rst_files(): In_out =
  ## Iterates over all the rst files.
  ##
  ## Returns In_out tuples, since different rst files have special output
  ## directory rules, it's not as easy as changing just the extension.
  var x: In_out

  for plain_rst in normal_rst_files:
    x.src = plain_rst
    x.dest = plain_rst.changeFileExt("html")
    x.options = nil
    yield x


proc build_all_rst_files(): seq[In_out] =
  ## Wraps iterator to avoid https://github.com/Araq/Nimrod/issues/866.
  ##
  ## The wrapping forces `for` loops to use a single variable and an extra
  ## `let` line to unpack the tuple.
  result = to_seq(all_rst_files())


task "doc", "Generates HTML from the rst files.":
  # Generate documentation for the nim modules.
  for nim_file in to_seq(walk_files(logic_dir/"*.nim")):
    let html_file = nim_file.changeFileExt(".html")
    if not html_file.needs_refresh(nim_file): continue
    nim_file.nimrod_doc(html_file)

  # Generate html files from the rst docs.
  for f in build_all_rst_files():
    if f.needs_refresh:
      rst2html(f)

  echo "All docs generated"

task "check_doc", "Validates rst format for a subset of documentation":
  for f in build_all_rst_files():
    test_rst(f.src)


task "clean", "Removes temporal files, mainly":
  for f in build_all_rst_files():
    if f.dest.exists_file:
      echo "Removing ", f.dest
      f.dest.remove_file

proc compile_logic() =
  withDir(logic_dir):
    echo "Attempting to compile code in ", logic_dir
    direShell("nimrod c --verbosity:0 l_main.nim")

task "c", "Compiles the logic module":
  compile_logic()
  echo "Compiled"

task "test", "Compiles stuff and runs some tests":
  withDir("tests/interactive"):
    echo "Attempting to compile interactive seohyun"
    direShell("nimrod c --verbosity:0 seohyun.nim")

  echo "Running tests…"
  var count = 0
  for path in to_seq(walk_files(test_dir/"*"/"test_*.nim")):
    let (dir, filename) = path.split_path
    withDir dir:
      try:
        direShell "nimrod c --verbosity:0 -r", filename
        count += 1
      except:
        echo "Exception!"
  echo "Finished ", count, " tests successfully."
