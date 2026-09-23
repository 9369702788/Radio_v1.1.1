import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/radio_station.dart';

class RadioApiService {
  static const List<String> _mirrors = [
    'https://de1.api.radio-browser.info',
    'https://nl1.api.radio-browser.info',
    'https://at1.api.radio-browser.info',
  ];

  int _mirrorIndex = 0;
  String get _currentBaseUrl => '${_mirrors[_mirrorIndex]}/json';

  void _switchMirror() {
    _mirrorIndex = (_mirrorIndex + 1) % _mirrors.length;
  }

  Future<List<RadioStation>> _fetchUri(Uri uri) async {
    for (int attempt = 0; attempt < _mirrors.length; attempt++) {
      try {
        final response = await http.get(
          uri,
          headers: {'User-Agent': 'WorldRadioApp/1.2.0'},
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
          return data
              .map((item) => RadioStation.fromJson(item))
              .where((st) => st.url.isNotEmpty && st.name.isNotEmpty)
              .toList();
        }
      } catch (e) {
        _switchMirror();
      }
    }
    return [];
  }

  // Unified stations search with massive limits & pagination support
  Future<List<RadioStation>> getStations({
    String? name,
    String? countryCode,
    String? tag,
    String? language,
    String order = 'clickcount',
    bool reverse = true,
    int limit = 500,
    int offset = 0,
  }) async {
    final Map<String, String> params = {
      'limit': limit.toString(),
      'offset': offset.toString(),
      'hidebroken': 'true',
      'order': order,
      'reverse': reverse ? 'true' : 'false',
    };

    if (name != null && name.trim().isNotEmpty) {
      params['name'] = name.trim();
    }
    if (countryCode != null && countryCode.trim().isNotEmpty) {
      params['countrycode'] = countryCode.trim().toUpperCase();
    }
    if (tag != null && tag.trim().isNotEmpty) {
      params['tag'] = tag.trim().toLowerCase();
    }
    if (language != null && language.trim().isNotEmpty) {
      params['language'] = language.trim().toLowerCase();
    }

    final uri = Uri.parse('$_currentBaseUrl/stations/search').replace(queryParameters: params);
    return _fetchUri(uri);
  }

  // Top global stations
  Future<List<RadioStation>> getTopStations({int limit = 500, int offset = 0}) async {
    return getStations(order: 'clickcount', limit: limit, offset: offset);
  }

  // Search by text
  Future<List<RadioStation>> searchStations(String query, {int limit = 500, int offset = 0}) async {
    return getStations(name: query, limit: limit, offset: offset);
  }

  // Stations by country
  Future<List<RadioStation>> getStationsByCountry(String countryCode, {int limit = 500, int offset = 0}) async {
    return getStations(countryCode: countryCode, order: 'clickcount', limit: limit, offset: offset);
  }

  // Stations by tag
  Future<List<RadioStation>> getStationsByTag(String tag, {int limit = 500, int offset = 0}) async {
    return getStations(tag: tag, order: 'clickcount', limit: limit, offset: offset);
  }
}
