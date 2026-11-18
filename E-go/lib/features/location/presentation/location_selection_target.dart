import 'package:flutter/material.dart';

/// The location field currently being edited in the booking flow.
enum LocationSelectionTarget { pickup, destination }

extension LocationSelectionTargetX on LocationSelectionTarget {
  bool get isPickup => this == LocationSelectionTarget.pickup;

  String get fieldLabel => isPickup ? 'Pickup location' : 'Drop location';

  String get shortLabel => isPickup ? 'Pickup' : 'Drop';

  String get hint =>
      isPickup ? 'Choose pickup location' : 'Choose drop location';

  String get mapAction =>
      isPickup ? 'Select pickup on map' : 'Select drop on map';

  String get confirmAction =>
      isPickup ? 'Confirm pickup location' : 'Confirm drop location';

  String get mapTitle => isPickup ? 'Set pickup point' : 'Set drop point';

  String get pinnedLabel =>
      isPickup ? 'Pinned pickup point' : 'Pinned drop point';

  IconData get leadingIcon =>
      isPickup ? Icons.trip_origin : Icons.location_on_outlined;
}
