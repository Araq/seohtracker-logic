# `Seohtracker logic <https://github.com/gradha/seohtracker-logic>`_ ObjC
# interface.
#
# For documentation see those moduless API, this is mostly a wrapper around
# their procs with explicit ``exportc`` pragmas.

import l_main, times, l_types, l_graph

proc get_weight_string(): cstring {.exportc, raises: [].} =
  result = l_main.get_weight_string()

proc format_weight_with_current_unit(s: PWeight): cstring
    {.exportc, raises: [].} =
  result = l_main.format_weight_with_current_unit(s)

proc format_weight(s: PWeight, add_mass: bool): cstring
    {.exportc, raises: [].} =
  result = l_main.format_weight(s, add_mass)

proc open_db(path: cstring): bool {.exportc, raises: [].} =
  let p = if path.isNil: nil else: $path
  result = l_main.open_db(p)

proc close_db() {.exportc, raises: [].} =
  l_main.close_db()

proc db_exists(path: cstring): bool {.exportc, raises: [].} =
  let p = if path.isNil: nil else: $path
  result = l_main.db_exists(p)

proc add_weight(weight: float): int {.exportc, raises: [].} =
  result = l_main.add_weight(weight)

proc remove_weight(weight: PWeight): int {.discardable, exportc, raises: [].} =
  result = l_main.remove_weight(weight)

proc get_num_weights(): int {.exportc, raises: [].} =
  result = l_main.get_num_weights()

proc find_pos(w: PWeight): int {.exportc, raises: [].} =
  result = l_main.find_pos(w)

proc modify_weight_date(w: PWeight, value: TTime,
    old_pos, new_pos: var int) {.exportc, raises: [].} =
  l_main.modify_weight_date(w, value, old_pos, new_pos)

proc modify_weight_value(w: PWeight, value: float): int
    {.exportc, raises: [].} =
  result = l_main.modify_weight_value(w, value)

proc get_last_weight(): PWeight {.exportc, raises: [].} =
  result = l_main.get_last_weight()

proc get_weight(pos: int): PWeight {.exportc, raises: [].} =
  result = l_main.get_weight(pos)

proc get_localized_weight(s: PWeight): float {.exportc, raises: [].} =
  result = l_main.get_localized_weight(s)

proc set_decimal_separator(text: cstring): bool
    {.discardable, exportc, raises: [].} =
  if text.isNil: return
  let value = $text
  if value.len != 1: return
  result = l_main.set_decimal_separator(value[0])

proc get_decimal_separator(): char {.exportc, raises: [].} =
  result = l_main.get_decimal_separator()

proc specify_metric_use(uses_metric: bool) {.exportc, raises: [].} =
  l_main.specify_metric_use(uses_metric)

proc get_metric_use(): Weight_type {.exportc, raises: [].} =
  result = l_main.get_metric_use()

proc max_weight(): int {.exportc, raises: [].} =
  result = l_main.max_weight()

proc is_weight_input_valid(future: cstring): bool {.exportc, raises: [].} =
  if future.isNil: return
  result = l_main.is_weight_input_valid($future)

proc export_database_to_csv(csv_filename: cstring):
    bool {.exportc, raises: [].} =
  let p = if csv_filename.isNil: nil else: $csv_filename
  result = l_main.export_database_to_csv(p)

proc scan_csv_for_entries(csv_filename: cstring): int {.exportc, raises: [].} =
  if csv_filename.isNil: return
  result = l_main.scan_csv_for_entries($csv_filename)

proc import_csv_into_db(csv_filename: cstring, replace: bool):
    bool {.exportc, raises: [].} =
  let p = if csv_filename.isNil: nil else: $csv_filename
  result = l_main.import_csv_into_db(p, replace)

# Exports for the l_types module.
proc retain_weight(w: PWeight) {.exportc, raises: [].} =
  l_types.retain_weight(w)

proc release_weight(w: var PWeight) {.exportc, raises: [].} =
  l_types.release_weight(w)

proc date(s: PWeight): TTime {.exportc, raises: [].} =
  result = l_types.date(s)

proc alternating_day(w: PWeight): bool {.exportc, raises: [].} =
  if w.isNil: result = false
  else: result = w[].alternating_day

proc changes_day(w: PWeight): bool {.exportc, raises: [].} =
  if w.isNil: result = false
  else: result = w[].changes_day

proc calculate_scale(X: var Nice_scale;
    min_point, max_point: float; max_ticks: int) {.exportc, raises: [].} =
  X.init(min_point, max_point, max_ticks)
