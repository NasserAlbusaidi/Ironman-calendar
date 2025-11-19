import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A service for interacting with the Strava API.
///
/// This class handles the authentication and data fetching from the Strava API,
/// including refreshing the access token and retrieving recent activities.
class StravaService {
  // Base URL for Strava API
  final String _authUrl = "https://www.strava.com/oauth/token";
  final String _baseUrl = "https://www.strava.com/api/v3";

  /// Refreshes the Strava access token using the refresh token.
  ///
  /// This method uses the client ID, client secret, and refresh token from the
  /// `.env` file to obtain a new access token from the Strava API.
  ///
  /// Returns the new access token, or `null` if the request fails.
  Future<String?> _getAccessToken() async {
    final String? clientId = dotenv.env['STRAVA_CLIENT_ID'];
    final String? clientSecret = dotenv.env['STRAVA_CLIENT_SECRET'];
    final String? refreshToken = dotenv.env['STRAVA_REFRESH_TOKEN'];

    if (clientId == null || clientSecret == null || refreshToken == null) {
      print("STRAVA ERROR: Missing .env secrets");
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(_authUrl),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        print("Failed to refresh token: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error refreshing token: $e");
      return null;
    }
  }

  /// Fetches the user's recent activities from the Strava API.
  ///
  /// This method first obtains a valid access token and then requests the last
  /// 50 activities from the Strava API.
  ///
  /// Returns a list of maps, where each map represents a Strava activity.
  Future<List<Map<String, dynamic>>> getActivities() async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) return [];

    // We fetch the last 50 activities to cover the training block
    final url = "$_baseUrl/athlete/activities?per_page=50";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        
        return data.map((activity) {
          return {
            'id': activity['id'],
            'name': activity['name'],
            'type': activity['type'], // "Run", "Ride", "Swim"
            'date': DateTime.parse(activity['start_date_local']),
            'moving_time': activity['moving_time'], // Seconds
            'distance': activity['distance'], // Meters
          };
        }).toList();
      } else {
        print("Strava API Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching activities: $e");
      return [];
    }
  }
}