/// places module of cc_core: saved places with pins, visits to them,
/// and the "back here again?" flow, generic over each app's own place
/// and item types. Built on the geo module's geometry; additive — apps
/// with their own place tables (Table Encore) are unaffected.
///
/// - [PinnedPlaces] / [PlaceVisits]: drift base tables apps subclass.
/// - [matchPlacesHere]: one foreground fix, then the places in range.
/// - [pinUpdateFor]: what a confirmed on-site visit does to a pin.
/// - [recallAtPlace]: "what did I have here last time?".
///
/// No location plugin and no network: [LocationSource] is the seam,
/// and matching is local geometry.
library;

import '../geo/geo.dart';
import 'place_matching.dart';
import 'place_recall.dart';
import 'place_tables.dart';

export 'place_matching.dart';
export 'place_recall.dart';
export 'place_tables.dart';
