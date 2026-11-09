import 'package:shared_preferences/shared_preferences.dart';

class VenueStorage {
  static const String _venueIdKey = 'selected_venue_id';
  static const String _venueNameKey = 'selected_venue_name';

  static Future<void> saveSelectedVenue({
    required String venueId,
    required String venueName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _venueIdKey,
      venueId,
    );

    await prefs.setString(
      _venueNameKey,
      venueName,
    );
  }

  static Future<String?> getSelectedVenueId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_venueIdKey);
  }

  static Future<String?> getSelectedVenueName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_venueNameKey);
  }

  static Future<SelectedVenue?> getSelectedVenue() async {
    final prefs = await SharedPreferences.getInstance();

    final venueId = prefs.getString(_venueIdKey);
    final venueName = prefs.getString(_venueNameKey);

    if (venueId == null || venueId.trim().isEmpty) {
      return null;
    }

    if (venueName == null || venueName.trim().isEmpty) {
      return null;
    }

    return SelectedVenue(
      venueId: venueId,
      venueName: venueName,
    );
  }

  static Future<void> clearSelectedVenue() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_venueIdKey);
    await prefs.remove(_venueNameKey);
  }
}

class SelectedVenue {
  final String venueId;
  final String venueName;

  const SelectedVenue({
    required this.venueId,
    required this.venueName,
  });
}
