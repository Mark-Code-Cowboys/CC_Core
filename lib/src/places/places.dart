/// places module of cc_core: the "you are here" start of a visit.
/// One foreground fix, then the app's saved places in range of it, and
/// what a confirmed on-site visit does to a place's pin — generic over
/// the app's own place type. Built on the geo module's geometry.
///
/// - [matchPlacesHere]: one foreground fix, then the places in range.
/// - [pinUpdateFor]: the pin a confirmed on-site visit leaves behind.
/// - [checkPinFields]: readable errors for half a pin.
/// - [PlacePolicy]: the app's numbers (radius, refine threshold, fix
///   age); no defaults.
///
/// Apps own their place tables and everything after "you are here".
/// No location plugin and no network: [LocationSource] is the seam,
/// and matching is local geometry.
library;

import '../geo/geo.dart';
import 'place_matching.dart';

export 'place_matching.dart';
