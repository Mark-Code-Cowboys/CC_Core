import 'package:flutter/material.dart';

/// One square of a [RegionTileGrid]: a region code at a grid position.
class RegionTile {
  /// Creates the tile.
  const RegionTile(this.code, this.col, this.row);

  /// Short code drawn in the square ("MI").
  final String code;

  /// Zero-based grid column.
  final int col;

  /// Zero-based grid row.
  final int row;
}

/// A tile cartogram — the classic squares-map of a country — filled in
/// where the user has been. Honest and offline: no map tiles, no
/// geo data, every region the same size. "Where have I done X" for any
/// CC ledger; pair with [usStateTiles] for the United States.
class RegionTileGrid extends StatelessWidget {
  /// Creates the grid.
  const RegionTileGrid({
    super.key,
    required this.tiles,
    required this.filled,
    this.spacing = 3,
  });

  /// The map layout.
  final List<RegionTile> tiles;

  /// Codes to fill with the primary color (compared as given — pass
  /// them in the same case as the layout's codes).
  final Set<String> filled;

  /// Gap between squares.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cols =
        tiles.map((t) => t.col).reduce((a, b) => a > b ? a : b) + 1;
    final rows =
        tiles.map((t) => t.row).reduce((a, b) => a > b ? a : b) + 1;
    return AspectRatio(
      aspectRatio: cols / rows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / cols;
          final side = cell - spacing;
          return Stack(
            children: [
              for (final tile in tiles)
                Positioned(
                  left: tile.col * cell,
                  top: tile.row * cell,
                  width: side,
                  height: side,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: filled.contains(tile.code)
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FittedBox(
                      child: Text(
                        tile.code,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: filled.contains(tile.code)
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The 50 US states in the standard tile-cartogram arrangement.
const usStateTiles = [
  RegionTile('AK', 0, 0),
  RegionTile('ME', 10, 0),
  RegionTile('VT', 9, 1),
  RegionTile('NH', 10, 1),
  RegionTile('WA', 1, 2),
  RegionTile('ID', 2, 2),
  RegionTile('MT', 3, 2),
  RegionTile('ND', 4, 2),
  RegionTile('MN', 5, 2),
  RegionTile('WI', 6, 2),
  RegionTile('MI', 8, 2),
  RegionTile('NY', 9, 2),
  RegionTile('MA', 10, 2),
  RegionTile('RI', 11, 2),
  RegionTile('OR', 1, 3),
  RegionTile('NV', 2, 3),
  RegionTile('WY', 3, 3),
  RegionTile('SD', 4, 3),
  RegionTile('IA', 5, 3),
  RegionTile('IL', 6, 3),
  RegionTile('IN', 7, 3),
  RegionTile('OH', 8, 3),
  RegionTile('PA', 9, 3),
  RegionTile('NJ', 10, 3),
  RegionTile('CT', 11, 3),
  RegionTile('CA', 1, 4),
  RegionTile('UT', 2, 4),
  RegionTile('CO', 3, 4),
  RegionTile('NE', 4, 4),
  RegionTile('MO', 5, 4),
  RegionTile('KY', 6, 4),
  RegionTile('WV', 7, 4),
  RegionTile('VA', 8, 4),
  RegionTile('MD', 9, 4),
  RegionTile('DE', 10, 4),
  RegionTile('AZ', 2, 5),
  RegionTile('NM', 3, 5),
  RegionTile('KS', 4, 5),
  RegionTile('AR', 5, 5),
  RegionTile('TN', 6, 5),
  RegionTile('NC', 7, 5),
  RegionTile('SC', 8, 5),
  RegionTile('OK', 3, 6),
  RegionTile('LA', 4, 6),
  RegionTile('MS', 5, 6),
  RegionTile('AL', 6, 6),
  RegionTile('GA', 7, 6),
  RegionTile('HI', 0, 7),
  RegionTile('TX', 3, 7),
  RegionTile('FL', 8, 7),
];
