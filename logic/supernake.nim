## Contains common code used by client nakefiles.
##
## Import the supernake and show off!

import packages/docutils/rst, packages/docutils/rstast, nake, sequtils, posix,
  strutils, parseopt, tables, os, rdstdin, times, osproc, rester

export rst, rstast, nake, sequtils,
  strutils, parseopt, tables, os, rdstdin, times, osproc, rester

import htmlparser, xmltree, strtabs

type
  In_out* = tuple[src, dest, options: string]
    ## The tuple only contains file paths.


var
  CONFIGS = newStringTable(modeCaseInsensitive)
    ## Stores previously read configuration files.


template glob_rst*(basedir: string): expr =
  ## Shortcut to simplify getting lists of files.
  to_seq(walk_files(basedir/"*.rst"))


proc update_timestamp*(path: string) =
  ## Wrapper over utimes from posix,
  discard utimes(path, nil)


proc load_config(path: string): string =
  ## Loads the config at path and returns it.
  ##
  ## Uses the CONFIGS variable to cache contents. Returns nil if path is nil.
  if path.isNil: return
  if CONFIGS.hasKey(path): return CONFIGS[path]
  CONFIGS[path] = path.readFile
  result = CONFIGS[path]


proc rst2html*(src: string, out_path = ""): bool =
  ## Converts the filename `src` into `out_path` or src with extension changed.
  let output = safe_rst_file_to_html(src)
  if output.len > 0:
    let dest = if out_path.len > 0: out_path else: src.changeFileExt("html")
    dest.writeFile(output)
    result = true


proc change_rst_links_to_html*(html_file: string) =
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


proc needs_refresh*(target: In_out): bool =
  ## Wrapper around the normal needs_refresh for In_out types.
  if target.options.isNil:
    result = target.dest.needs_refresh(target.src)
  else:
    assert target.options.exists_file
    result = target.dest.needs_refresh(target.src, target.options)


proc nimrod_doc*(nim_file, html_file: string) =
  ## Runs ``nimrod doc`` on the input file, quitting if something goes wrong.
  assert (not nim_file.isNil)
  assert (not html_file.isNil)
  assert nim_file.len > 0 and html_file.len > 0
  if not shell("nimrod doc --verbosity:0 -o:" & html_file, nim_file):
    quit("Could not generate html doc for " & nim_file)
  else:
    echo "Generated " & html_file


proc test_rst*(filename: string): bool {.discardable.} =
  ## Calls the rst2html.py script to verify rst compilance of a file.
  ##
  ## The proc will indicate which files pass the test or not to the user on top
  ## of returning the value to the caller.
  echo "Testing ", filename
  let (output, exit) = execCmdEx("rst2html.py " & filename & " /dev/null")
  if output.len > 0 or exit != 0:
    echo "Failed python processing of " & filename
    echo output
  else:
    result = true


proc rst2html*(file: In_out) =
  ## Converts the rst file to html, setting options in the process if not nil.
  ##
  ## Pass in `file.src` the path to the source rst file, and `file.dest` should
  ## contain the filename for the output. `file.options` can be nil, if not, it
  ## should point to a configuration file which will be loaded before
  ## processing the rst file.
  ##
  ## Files which don't have `file.options` will be further processed to modify
  ## with ``change_rst_links_to_html``. Those which have a configuration file
  ## won't, since the processing might alter the css/xhtml structure badly.
  if not file.needs_refresh:
    return

  discard change_rst_options(file.options.load_config)
  if not rst2html(file.src, file.dest):
    quit("Could not generate html doc for " & file.src)
  else:
    if file.options.isNil:
      change_rst_links_to_html(file.dest)
    echo file.src & " -> " & file.dest
