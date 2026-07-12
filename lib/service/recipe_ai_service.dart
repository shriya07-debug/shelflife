import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import '../model/recipe.dart';

class RecipeAiService {
  final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.1-flash-lite',
  );

  Future<Recipe?> generateRecipe(List<String> pantryItems) async {
    final prompt = '''
Suggest one simple recipe using some or all of these ingredients: ${pantryItems.join(", ")}.

Respond with ONLY valid JSON, no markdown, no extra text, in this exact shape:
{
  "title": "Recipe Name",
  "timeMinutes": 20,
  "difficulty": "Easy",
  "description": "One sentence description.",
  "ingredients": ["item 1", "item 2"],
  "tags": ["quick", "vegetarian"]
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return null;

      final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      final timeMinutes = json['timeMinutes'] as int;
      return Recipe(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] as String,
        time: '$timeMinutes mins',
        timeMinutes: timeMinutes,
        difficulty: json['difficulty'] as String? ?? 'Easy',
        description: json['description'] as String? ?? '',
        ingredients: List<String>.from(json['ingredients'] ?? []),
        tags: List<String>.from(json['tags'] ?? []),
        allFound: true,
      );
    } catch (e) {
      debugPrint('Recipe generation failed: $e');
      return null;
    }
  }
}