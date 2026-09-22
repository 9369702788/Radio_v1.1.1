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

  Future<List<RadioStation>> _fetch(String endpoint) async {
    for (int attempt = 0; attempt < _mirrors.length; attempt++) {
      try {
        final url = Uri.parse('$_currentBaseUrl/$endpoint');
        final response = await http.get(
          url,
          headers: {'User-Agent': 'WorldRadioApp/1.0.0'},
        ).timeout(const Duration(seconds: 12));

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

  Future<List<RadioStation>> getTopStations({int limit = 60}) async {
    return _fetch('stations/topvote?limit=$limit&hidebroken=true');
  }

  Future<List<RadioStation>> searchStations(String query, {int limit = 60}) async {
    final cleanQuery = Uri.encodeComponent(query.trim());
    return _fetch('stations/byname/$cleanQuery?limit=$limit&hidebroken=true&order=votes&reverse=true');
  }

  Future<List<RadioStation>> getStationsByCountry(String countryCode, {int limit = 60}) async {
    final code = countryCode.trim().toUpperCase();
    return _fetch('stations/bycountrycodeexact/$code?limit=$limit&hidebroken=true&order=votes&reverse=true');
  }

  Future<List<RadioStation>> getStationsByTag(String tag, {int limit = 60}) async {
    final cleanTag = Uri.encodeComponent(tag.trim().toLowerCase());
    return _fetch('stations/bytag/$cleanTag?limit=$limit&hidebroken=true&order=votes&reverse=true');
  }

  Future<List<RadioStation>> getStationsByLanguage(String language, {int limit = 60}) async {
    final cleanLang = Uri.encodeComponent(language.trim().toLowerCase());
    return _fetch('stations/bylanguage/$cleanLang?limit=$limit&hidebroken=true&order=votes&reverse=true');
  }
}
