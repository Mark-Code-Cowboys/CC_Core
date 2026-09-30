/// geo module of cc_core: pin-based place matching, pure Dart.
///
/// A place's pin is where the phone was when the user confirmed being
/// there. Later, saved places within a radius of the current fix are
/// candidates for "back here again?". Core owns the geometry and the
/// decision rules; every policy number (radius, refinement threshold,
/// how old a fix may be) is passed in by the app. Nothing here touches
/// a location plugin: [LocationSource] is the seam, apps implement it.
library;

export 'candidates.dart';
export 'distance.dart';
export 'fake_location_source.dart';
export 'geo_point.dart';
export 'location_source.dart';
export 'pin_refinement.dart';
