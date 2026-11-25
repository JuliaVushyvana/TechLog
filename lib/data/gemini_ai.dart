import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:http/http.dart' as http;

import 'feedback_ai.dart';

const geminiModel = 'gemini-3.5-flash-lite';

/// Фідбек через Gemini Developer API у Firebase AI Logic (працює на плані Spark).
/// Ключ API зберігається у Firebase, у коді застосунку його немає.
class GeminiFeedbackAi implements FeedbackAi {
  const GeminiFeedbackAi({this.model = geminiModel});
  final String model;

  @override
  bool get available => true;

  @override
  Future<String> generate({required String system, required String prompt}) async {
    final gemini = FirebaseAI.googleAI().generativeModel(
      model: model,
      systemInstruction: Content.system(system),
      generationConfig: GenerationConfig(temperature: .7, maxOutputTokens: 1500),
    );
    final response = await gemini.generateContent([Content.text(prompt)]);
    final text = response.text?.trim() ?? '';
    if (text.isEmpty) throw Exception('модель повернула порожню відповідь');
    return text;
  }
}

/// Фідбек через Gemini API напряму з ключем із Google AI Studio (безкоштовний рівень).
/// Ключ вводить вчитель у налаштуваннях фідбеку; він зберігається лише на телефоні.
class GeminiKeyFeedbackAi implements FeedbackAi {
  GeminiKeyFeedbackAi(this.apiKey, {this.model = geminiModel, http.Client? client}) : _client = client ?? http.Client();
  final String apiKey;
  final String model;
  final http.Client _client;

  @override
  bool get available => true;

  @override
  Future<String> generate({required String system, required String prompt}) async {
    final res = await _client.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': system},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': .7, 'maxOutputTokens': 1500},
      }),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      final message = (body['error'] as Map?)?['message'] ?? 'помилка ${res.statusCode}';
      throw Exception(switch (res.statusCode) {
        400 || 401 || 403 => 'ключ Gemini API не підходить ($message)',
        429 => 'вичерпано безкоштовний ліміт запитів, спробуйте трохи пізніше',
        _ => message,
      });
    }
    final parts = ((body['candidates'] as List?)?.firstOrNull as Map?)?['content']?['parts'] as List? ?? const [];
    final text = parts.map((p) => (p as Map)['text'] ?? '').join().trim();
    if (text.isEmpty) throw Exception('модель повернула порожню відповідь');
    return text;
  }
}
