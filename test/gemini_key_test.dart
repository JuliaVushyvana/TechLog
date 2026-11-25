import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teachlog/data/feedback_ai.dart';
import 'package:teachlog/data/gemini_ai.dart';
import 'package:teachlog/providers.dart';

void main() {
  test('запит з ключем у заголовку, відповідь розбирається в текст', () async {
    late http.Request sent;
    final ai = GeminiKeyFeedbackAi(
      'test-key',
      client: MockClient((req) async {
        sent = req;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Добрий день! '},
                      {'text': 'Все чудово.'},
                    ],
                  },
                },
              ],
            }),
          ),
          200,
        );
      }),
    );
    final text = await ai.generate(system: 'S', prompt: 'P');
    expect(text, 'Добрий день! Все чудово.');
    expect(sent.headers['x-goog-api-key'], 'test-key');
    expect(sent.url.path, endsWith('/models/$geminiModel:generateContent'));
    final body = jsonDecode(sent.body);
    expect(body['systemInstruction']['parts'][0]['text'], 'S');
    expect(body['contents'][0]['parts'][0]['text'], 'P');
  });

  test('ліміт безкоштовного рівня дає зрозумілу помилку', () async {
    final ai = GeminiKeyFeedbackAi(
      'k',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'quota'},
          }),
          429,
        ),
      ),
    );
    expect(() => ai.generate(system: 'S', prompt: 'P'), throwsA(predicate((e) => '$e'.contains('ліміт'))));
  });

  test('ключ у налаштуваннях вмикає AI', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(await SharedPreferences.getInstance())]);
    addTearDown(c.dispose);
    expect(c.read(feedbackAiProvider), isA<UnconfiguredAi>());
    c.read(deviceProvider)
      ..ai.apiKey = 'abc'
      ..saveAi();
    expect(c.read(feedbackAiProvider), isA<GeminiKeyFeedbackAi>());
  });
}
