import nake, os, times, osproc, htmlparser, xmltree, strtabs, strutils,
  rester, sequtils, packages/docutils/rst, packages/docutils/rstast, posix

type
  In_out = tuple[src, dest, options: string]

template glob_rst(basedir: string): expr =
  ## Shortcut to simplify getting lists of files.
  to_seq(walk_files(basedir/"*.rst"))

let
  normal_rst_files = concat(glob_rst("."), glob_rst("docs"))

proc update_timestamp(path: string) =
  discard utimes(path, nil)

proc rst2html(src: string, out_path = ""): bool =
  ## Converts the filename `src` into `out_path` or src with extension changed.
  let output = safe_rst_file_to_html(src)
  if output.len > 0:
    let dest = if out_path.len > 0: out_path else: src.changeFileExt("html")
    dest.writeFile(output)
    result = true

proc change_rst_links_to_html(html_file: string) =
  ## Opens the file, iterates hrefs and changes them to .html if they are .rst.
  let html = loadHTML(html_file)
  var DID_CHANGE: bool

  for a in html.findAll("a"):
    let href = a.attrs["href"]
    if not href.isNil:
      let (dir, filename, ext) = splitFile(href)
      if cmpIgnoreCase(ext, ".rst") == 0:
        a.attrs["href"] = dir / filename & ".html"
        DID_CHANGE = true

  if DID_CHANGE:
    writeFile(html_file, $html)

proc needs_refresh(target: string, src: varargs[string]): bool =
  # Returns true if any of `src` has an older timestamp than `target`.
  assert len(src) > 0, "Pass some parameters to check for"
  var targetTime: float
  try:
    targetTime = toSeconds(getLastModificationTime(target))
  except EOS:
    return true

  for s in src:
    let srcTime = toSeconds(getLastModificationTime(s))
    if srcTime > targetTime:
      return true

proc needs_refresh(target: In_out): bool =
  ## Wrapper around the normal needs_refresh for In_out types.
  result = target.dest.needs_refresh(target.src)


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
  # Generate html files from the rst docs.
  for f in build_all_rst_files():
    let (rst_file, html_file, options) = f
    if not html_file.needs_refresh(rst_file): continue
    discard change_rst_options(options)
    if not rst2html(rst_file, html_file):
      quit("Could not generate html doc for " & rst_file)
    else:
      if options.isNil:
        change_rst_links_to_html(html_file)
      #doc_build_dir.update_timestamp
      echo rst_file & " -> " & html_file

  echo "All docs generated"

task "check_doc", "Validates rst format for a subset of documentation":
  for f in build_all_rst_files():
    let (rst_file, html_file, options) = f
    echo "Testing ", rst_file
    let (output, exit) = execCmdEx("rst2html.py " & rst_file & " /dev/null")
    if output.len > 0 or exit != 0:
      echo "Failed python processing of " & rst_file
      echo output

task "clean", "Removes temporal files, mainly":
  for path in walkDirRec("."):
    let (dir, name, ext) = splitFile(path)
    if ext == ".html":
      echo "Removing ", path
      path.removeFile()
