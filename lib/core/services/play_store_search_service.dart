import 'package:dio/dio.dart';

class PlayStoreApp {
  final String title;
  final String packageName;
  final String playStoreUrl;

  const PlayStoreApp({
    required this.title,
    required this.packageName,
    required this.playStoreUrl,
  });

  factory PlayStoreApp.fromAppHighlight(
    Map<String, dynamic> json,
  ) {
    return PlayStoreApp(
      title: json['title'] as String,
      packageName: json['product_id'] as String,
      playStoreUrl: json['link'] as String,
    );
  }

  @override
  String toString() {
    return 'PlayStoreApp('
        'title: $title, '
        'packageName: $packageName, '
        'playStoreUrl: $playStoreUrl'
        ')';
  }
}

class PlayStoreSearchService {
  final Dio _dio;

  PlayStoreSearchService({
    Dio? dio,
  }) : _dio = dio ?? Dio();

  Future<PlayStoreApp?> searchApp(String appName) async {
    try {
      final response = await _dio.get(
        'https://serpapi.com/search',
        queryParameters: {
          'engine': 'google_play',
          'q': appName,
          'store': 'apps',
          'hl': 'en',
          'gl': 'in',

          // Temporary for testing.
          // Do NOT keep the API key directly in the APK
          // for production.
          'api_key': '330b6e9d23cc0ba3c4308d8f03c1ffa548d0bc796598971ab474a796b39e26ea',
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid SerpApi response');
      }

      final appHighlight =
          data['app_highlight'] as Map<String, dynamic>?;

      if (appHighlight == null) {
        return null;
      }

      return PlayStoreApp.fromAppHighlight(appHighlight);
    } on DioException catch (e) {
      throw Exception(
        'Play Store search failed: ${e.message}',
      );
    }
  }
}