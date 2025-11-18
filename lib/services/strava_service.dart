import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StravaService {
  // Base URL for Strava API
  final String _authUrl = "https://www.strava.com/oauth/token";
  final String _baseUrl = "https://www.strava.com/api/v3";

  // 1. Get a temporary Access Token using your permanent Refresh Token
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

  // 2. Fetch Activities (Last 30 days or custom range)
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