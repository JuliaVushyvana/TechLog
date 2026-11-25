import 'package:firebase_ai/firebase_ai.dart';

import 'feedback_ai.dart';

/// Фідбек через Gemini Developer API у Firebase AI Logic (працює на плані Spark).
/// Ключ API зберігається у Firebase, у коді застосунку його немає.
class GeminiFeedbackAi implements FeedbackAi {
  const GeminiFeedbackAi({this.model = 'gemini-3.5-flash-lite'});
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
