/// trends module of cc_core: small honest chart widgets for ledger
/// apps — counts per year, a plain line over time, a tile-cartogram
/// coverage map, and the TrendGate that keeps charts from rendering
/// before there's enough data to mean anything. Populated as consumers
/// need pieces (Course Ledger, then Trace Elements' month grid).
library;

export 'calendar_month_grid.dart';
export 'count_headline.dart';
export 'region_tile_grid.dart';
export 'simple_line_chart.dart';
export 'trend_gate.dart';
export 'yearly_bars.dart';
