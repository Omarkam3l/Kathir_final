import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../utils/auth_logger.dart';

class AiMealService {
  final String apiKey;
  late final GenerativeModel _model;

  /// Use SLUG categories (stable, easy to map to DB)
  static const List<String> allowedCategories = [
    'meals',
    'bakery',
    'meat_poultry',
    'seafood',
    'vegetables',
    'desserts',
    'groceries',
  ];

  AiMealService({required this.apiKey}) {
    _model = GenerativeModel(
      model: "gemini-2.5-flash",
      apiKey: apiKey,
      generationConfig:  GenerationConfig(
        temperature: 0.7,
      ),
    );
  }

  /// Analyze meal from a public URL:
  /// 1) Fetch image bytes
  /// 2) Detect mime type from response header (fallback from URL extension)
  /// 3) Send image bytes as DataPart (real vision input)
  Future<AiMealData> extractMealInfoFromUrl(String imageUrl) async {
    final start = DateTime.now();
    try {
      AuthLogger.info('ai.meal.extract.start', ctx: {
        'source': 'url',
        'imageUrl': imageUrl,
      });

      final uri = Uri.parse(imageUrl);
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        throw Exception('Failed to fetch image. status=${res.statusCode}');
      }

      String mimeType = _mimeFromContentTypeHeader(res.headers['content-type']);
      if (mimeType.isEmpty) {
        mimeType = _mimeFromUrl(imageUrl);
      }
      if (mimeType.isEmpty) {
        mimeType = 'image/jpeg';
      }

      final data = await extractMealInfoFromBytes(
        res.bodyBytes,
        mimeType: mimeType,
      );

      final ms = DateTime.now().difference(start).inMilliseconds;
      AuthLogger.info('ai.meal.extract.success', ctx: {
        'source': 'url',
        'ms': ms,
        'title': data.mealTitle,
        'category': data.categorySlug,
      });

      return data;
    } catch (e, stackTrace) {
      final ms = DateTime.now().difference(start).inMilliseconds;
      AuthLogger.errorLog(
        'ai.meal.extract.failed',
        error: e,
        stackTrace: stackTrace,
      );
      AuthLogger.info('ai.meal.extract.failed.meta', ctx: {
        'source': 'url',
        'ms': ms,
      });
      rethrow;
    }
  }

  /// Analyze meal from bytes (recommended flow for your "solution 2"):
  /// - Image is picked from device, kept in memory
  /// - We send bytes directly to Gemini (no need to upload to Supabase first)
  Future<AiMealData> extractMealInfoFromBytes(
    Uint8List imageBytes, {
    required String mimeType,
  }) async {
    final start = DateTime.now();
    try {
      AuthLogger.info('ai.meal.extract.start', ctx: {
        'source': 'bytes',
        'mimeType': mimeType,
        'sizeBytes': imageBytes.length,
      });

      final prompt = _buildPrompt();

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);

      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Avoid logging huge responses
      AuthLogger.info('ai.meal.extract.response', ctx: {
        'length': text.length,
        'preview': text.substring(0, text.length.clamp(0, 300)),
      });

      final data = AiMealData.fromJson(text);

      // Normalize category if AI returns weird value
      if (!allowedCategories.contains(data.categorySlug)) {
        AuthLogger.info('ai.meal.category.invalid', ctx: {
          'provided': data.categorySlug,
          'defaultedTo': 'meals',
        });
        final fixed = data.copyWith(categorySlug: 'meals');
        return fixed;
      }

      final ms = DateTime.now().difference(start).inMilliseconds;
      AuthLogger.info('ai.meal.extract.success', ctx: {
        'source': 'bytes',
        'ms': ms,
        'title': data.mealTitle,
        'category': data.categorySlug,
        'original': data.priceSuggestions.originalPriceEgp,
        'discounted': data.priceSuggestions.discountedPriceEgp,
      });

      return data;
    } catch (e, stackTrace) {
      final ms = DateTime.now().difference(start).inMilliseconds;
      AuthLogger.errorLog('ai.meal.extract.failed', error: e, stackTrace: stackTrace);
      AuthLogger.info('ai.meal.extract.failed.meta', ctx: {
        'source': 'bytes',
        'ms': ms,
      });
      rethrow;
    }
  }

  String _buildPrompt() {
    return '''
You are extracting meal information from a food image for a restaurant app in Egypt.

Return ONLY valid JSON. No additional text before or after.

Rules:
- meal_title: Meal name in Arabic (short and direct)
- description: Creative and appetizing description in Arabic (1-2 sentences). Make it enticing and marketing-focused.
- category_slug: Choose ONE from this list: ${allowedCategories.join(', ')}
- price_suggestions: Suggest realistic prices in Egyptian Pounds (EGP)
- discounted_price_egp must be <= 0.5 * original_price_egp
- price_range_egp: [minimum, maximum] around your estimate
- confidence: Numbers from 0 to 1 expressing confidence in each element

Return JSON EXACTLY in this format:
{
  "meal_title": "string",
  "description": "string",
  "category_slug": "string",
  "price_suggestions": {
    "original_price_egp": number,
    "discounted_price_egp": number,
    "price_range_egp": [number, number]
  },
  "confidence": {
    "meal_title": number,
    "description": number,
    "category_slug": number,
    "prices": number
  }
}
''';
  }

  String _mimeFromContentTypeHeader(String? header) {
    if (header == null || header.trim().isEmpty) return '';
    return header.split(';').first.trim().toLowerCase();
  }

  String _mimeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return '';
  }
}

class AiMealData {
  final String mealTitle;
  final String description;
  final String categorySlug;
  final PriceSuggestions priceSuggestions;
  final Confidence confidence;

  AiMealData({
    required this.mealTitle,
    required this.description,
    required this.categorySlug,
    required this.priceSuggestions,
    required this.confidence,
  });

  AiMealData copyWith({
    String? mealTitle,
    String? description,
    String? categorySlug,
    PriceSuggestions? priceSuggestions,
    Confidence? confidence,
  }) {
    return AiMealData(
      mealTitle: mealTitle ?? this.mealTitle,
      description: description ?? this.description,
      categorySlug: categorySlug ?? this.categorySlug,
      priceSuggestions: priceSuggestions ?? this.priceSuggestions,
      confidence: confidence ?? this.confidence,
    );
  }

  factory AiMealData.fromJson(String jsonString) {
    try {
      final json = _parseJson(jsonString);

      final data = AiMealData(
        mealTitle: (json['meal_title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        categorySlug: (json['category_slug'] ?? '').toString(),
        priceSuggestions: PriceSuggestions.fromJson(
          (json['price_suggestions'] as Map).cast<String, dynamic>(),
        ),
        confidence: Confidence.fromJson(
          (json['confidence'] as Map).cast<String, dynamic>(),
        ),
      );

      // Basic structure validation
      if (data.mealTitle.isEmpty || data.description.isEmpty || data.categorySlug.isEmpty) {
        throw Exception('Missing required fields in AI JSON');
      }

      // Enforce discount constraint (safety net)
      final original = data.priceSuggestions.originalPriceEgp;
      final discounted = data.priceSuggestions.discountedPriceEgp;
      if (discounted > original * 0.5) {
        final fixedDiscount = (original * 0.5);
        return data.copyWith(
          priceSuggestions: data.priceSuggestions.copyWith(discountedPriceEgp: fixedDiscount),
        );
      }

      return data;
    } catch (e) {
      AuthLogger.errorLog('ai.meal.parse.failed', error: e);
      rethrow;
    }
  }

  static Map<String, dynamic> _parseJson(String jsonString) {
    String cleaned = jsonString.trim();

    // Remove markdown code blocks if present
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    final dynamic decoded = jsonDecode(cleaned);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid JSON structure');
    }
    return decoded;
  }
}

class PriceSuggestions {
  final double originalPriceEgp;
  final double discountedPriceEgp;
  final List<double> priceRangeEgp;

  PriceSuggestions({
    required this.originalPriceEgp,
    required this.discountedPriceEgp,
    required this.priceRangeEgp,
  });

  PriceSuggestions copyWith({
    double? originalPriceEgp,
    double? discountedPriceEgp,
    List<double>? priceRangeEgp,
  }) {
    return PriceSuggestions(
      originalPriceEgp: originalPriceEgp ?? this.originalPriceEgp,
      discountedPriceEgp: discountedPriceEgp ?? this.discountedPriceEgp,
      priceRangeEgp: priceRangeEgp ?? this.priceRangeEgp,
    );
  }

  factory PriceSuggestions.fromJson(Map<String, dynamic> json) {
    final original = (json['original_price_egp'] as num).toDouble();
    final discounted = (json['discounted_price_egp'] as num).toDouble();

    final range = (json['price_range_egp'] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    return PriceSuggestions(
      originalPriceEgp: original,
      discountedPriceEgp: discounted,
      priceRangeEgp: range,
    );
  }
}

class Confidence {
  final double mealTitle;
  final double description;
  final double categorySlug;
  final double prices;

  Confidence({
    required this.mealTitle,
    required this.description,
    required this.categorySlug,
    required this.prices,
  });

  factory Confidence.fromJson(Map<String, dynamic> json) {
    return Confidence(
      mealTitle: (json['meal_title'] as num).toDouble(),
      description: (json['description'] as num).toDouble(),
      categorySlug: (json['category_slug'] as num).toDouble(),
      prices: (json['prices'] as num).toDouble(),
    );
  }
}
