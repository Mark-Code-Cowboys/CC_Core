/// trends module of cc_core: small honest chart widgets for ledger
/// apps — counts per year, a plain line over time, a tile-cartogram
/// coverage map, and the TrendGate that keeps charts from rendering
/// before there's enough data to mean anything. Populated as consumers
/// need pieces (Course Ledger first); the Trace Elements calendar
/// heatmap extraction is still to come.
library;

export 'region_tile_grid.dart';
export 'simple_line_chart.dart';
export 'trend_gate.dart';
export 'yearly_bars.dart';
