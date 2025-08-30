// lib/services/generative_ai_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/payment_item.dart';

class GenerativeAIService {
  static const String _apiKey = "YOUR_GOOGLE_AI_STUDIO_API_KEY";

  static Future<Map<String, dynamic>> analyzeReceiptFromImage(File image) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey);
      final bytes = await image.readAsBytes();
      final prompt = TextPart(        '''
        Analyze the following receipt image and return a structured JSON.
        The JSON must include: store, totalAmount, foodAmount, and purchaseDate (in YYYY-MM-DD format).
        It must also include a list of items, where each item has: name, price, category, and expiryDate (in YYYY-MM-DD format or null).

        Follow these strict rules for each item:
        1.  **Category**: Classify each item into one of three categories: '식자재' (fresh ingredients like meat, vegetables), '가공품' (processed foods like snacks, ramen, canned goods), or '기타' (non-food items).
        2.  **expiryDate**:
            - If the item is '가공품' and a use-by date is visible on the receipt, extract that date.
            - If the item is '식자재', estimate a general best-before date based on the purchaseDate. For example, meat is 3 days, vegetables are 7 days.
            - If an expiry date cannot be determined, the value must be null.

        Ensure the response is ONLY the raw JSON object without any markdown formatting like ```json.
        ''');
      final imagePart = DataPart('image/jpeg', bytes);
      final response = await model.generateContent([Content.multi([prompt, imagePart])]);
      final content = response.text;
      if (content != null) {
        final cleanJson = content.replaceAll("```json", "").replaceAll("```", "").trim();
        return json.decode(cleanJson) as Map<String, dynamic>;
      } else {
        throw Exception('분석 실패: 응답 내용이 없습니다.');
      }
    } catch (e) {
      print('Google AI API 호출 중 오류 발생: $e');
      throw Exception('분석 실패: API 호출 중 오류가 발생했습니다.');
    }
  }

  static Future<Map<String, dynamic>> interpretUserIntent(String userMessage) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey);
      final prompt = '''
      Analyze the user's message and determine their intent.
      The intent can be one of: 'delete_item', 'update_date', or 'chat'.
      - If the intent is 'delete_item', extract the item name into a 'target' field.
      - If the intent is 'update_date', extract the date into a 'target' field in 'YYYY-MM-DD' format.
      - If it's a general question, the intent is 'chat'.

      Respond with ONLY a raw JSON object.

      Examples:
      - User: "양파 삭제해줘" -> {"intent": "delete_item", "target": "양파"}
      - User: "이거 날짜 2025-08-29로 바꿔줘" -> {"intent": "update_date", "target": "2025-08-29"}
      - User: "남은 재료로 만들 수 있는 요리 추천해줘" -> {"intent": "chat"}

      User's message: "$userMessage"
      ''';
      final response = await model.generateContent([Content.text(prompt)]);
      final content = response.text;
      if (content != null) {
        return json.decode(content) as Map<String, dynamic>;
      } else {
        return {'intent': 'chat'}; // 실패 시 기본값
      }
    } catch (e) {
      print('사용자 의도 파악 API 호출 중 오류 발생: $e');
      return {'intent': 'chat'}; // 예외 발생 시 기본값
    }
  }

  static Future<String> getChatResponse(String userMessage, List<PaymentItem> ingredients) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey);
      final ingredientsContext = ingredients.map((item) {
        return "- ${item.name} (소비기한: ${item.expiryDate ?? '알 수 없음'})";
      }).join('\n');
      final prompt = '''
      당신은 친절한 요리 및 식자재 관리 어시스턴트입니다.
      사용자가 보유한 식자재 목록을 바탕으로 질문에 답변해주세요.
      답변은 한국어로, 친절하고 이해하기 쉽게 설명해주세요.

      [현재 보유 식자재 목록]
      $ingredientsContext

      [사용자 질문]
      $userMessage
      ''';
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? '죄송합니다. 답변을 생성할 수 없습니다.';
    } catch (e) {
      print('Google AI 채팅 API 호출 중 오류 발생: $e');
      throw Exception('채팅 API 호출 중 오류가 발생했습니다.');
    }
  }
}
