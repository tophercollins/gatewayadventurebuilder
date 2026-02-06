import 'package:google_generative_ai/google_generative_ai.dart';

import '../../config/env_config.dart';
import 'entity_response_models.dart';
import 'llm_response_models.dart';

/// Result of an LLM generation request.
class LLMResult<T> {
  const LLMResult.success(this.data) : error = null, isSuccess = true;
  const LLMResult.failure(this.error) : data = null, isSuccess = false;

  final T? data;
  final String? error;
  final bool isSuccess;
}

/// Abstract interface for LLM providers.
/// Allows swapping Gemini for other providers without changing consuming code.
abstract class LLMService {
  /// Generates a session summary from transcript text.
  Future<LLMResult<SummaryResponse>> generateSummary({
    required String transcript,
    required String prompt,
  });

  /// Identifies scenes within a transcript.
  Future<LLMResult<ScenesResponse>> extractScenes({
    required String transcript,
    required String prompt,
  });

  /// Extracts entities (NPCs, locations, items) from transcript.
  Future<LLMResult<EntitiesResponse>> extractEntities({
    required String transcript,
    required String prompt,
  });

  /// Extracts action items and plot threads.
  Future<LLMResult<ActionItemsResponse>> extractActionItems({
    required String transcript,
    required String prompt,
  });

  /// Extracts player moments and highlights.
  Future<LLMResult<PlayerMomentsResponse>> extractPlayerMoments({
    required String transcript,
    required String prompt,
  });

  /// Extracts NPCs from transcript (dedicated call).
  Future<LLMResult<NpcsResponse>> extractNpcs({
    required String transcript,
    required String prompt,
  });

  /// Extracts locations from transcript (dedicated call).
  Future<LLMResult<LocationsResponse>> extractLocations({
    required String transcript,
    required String prompt,
  });

  /// Extracts items from transcript (dedicated call).
  Future<LLMResult<ItemsResponse>> extractItems({
    required String transcript,
    required String prompt,
  });

  /// Raw text generation for custom prompts.
  Future<LLMResult<String>> generateText({required String prompt});

  /// Check if the service is available (API key configured).
  Future<bool> isAvailable();
}

/// Google Gemini 2.5 Flash implementation of LLMService.
class GeminiService implements LLMService {
  GeminiService();

  GenerativeModel? _model;
  String? _cachedApiKey;

  /// Gets or creates the Gemini model instance.
  Future<GenerativeModel?> _getModel() async {
    final apiKey = await EnvConfig.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    // Recreate model if API key changed
    if (_model == null || _cachedApiKey != apiKey) {
      _cachedApiKey = apiKey;
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 8192,
        ),
      );
    }
    return _model;
  }

  @override
  Future<bool> isAvailable() async {
    final model = await _getModel();
    return model != null;
  }

  @override
  Future<LLMResult<String>> generateText({required String prompt}) async {
    try {
      final model = await _getModel();
      if (model == null) {
        return const LLMResult.failure('Gemini API key not configured');
      }

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) {
        return const LLMResult.failure('Empty response from Gemini');
      }
      return LLMResult.success(text);
    } on GenerativeAIException catch (e) {
      return LLMResult.failure(_handleGeminiError(e));
    } catch (e) {
      return LLMResult.failure('Unexpected error: $e');
    }
  }

  @override
  Future<LLMResult<SummaryResponse>> generateSummary({
    required String transcript,
    required String prompt,
  }) async {
    final fullPrompt = '$prompt\n\nTranscript:\n$transcript';
    final result = await generateText(prompt: fullPrompt);

    if (!result.isSuccess) {
      return LLMResult.failure(result.error!);
    }

    final parsed = SummaryResponse.tryParse(result.data!);
    if (parsed == null) {
      return const LLMResult.failure('Failed to parse summary response');
    }
    return LLMResult.success(parsed);
  }

  @override
  Future<LLMResult<ScenesResponse>> extractScenes({
    required String transcript,
    required String prompt,
  }) async {
    final fullPrompt = '$prompt\n\nTranscript:\n$transcript';
    final result = await generateText(prompt: fullPrompt);

    if (!result.isSuccess) {
      return LLMResult.failure(result.error!);
    }

    final parsed = ScenesResponse.tryParse(result.data!);
    if (parsed == null) {
      return const LLMResult.failure('Failed to parse scenes response');
    }
    return LLMResult.success(parsed);
  }

  @override
  Future<LLMResult<EntitiesResponse>> extractEntities({
    required String transcript,
    required String prompt,
  }) async {
    final fullPrompt = '$prompt\n\nTranscript:\n$transcript';
    final result = await generateText(prompt: fullPrompt);

    if (!result.isSuccess) {
      return LLMResult.failure(result.error!);
    }

    final parsed = EntitiesResponse.tryParse(result.data!);
    if (parsed == null) {
      return const LLMResult.failure('Failed to parse entities response');
    }
    return LLMResult.success(parsed);
  }

  @override
  Future<LLMResult<ActionItemsResponse>> extractActionItems({
    required String transcript,
    required String prompt,
  }) async {
    final fullPrompt = '$prompt\n\nTranscript:\n$transcript';
    final result = await generateText(prompt: fullPrompt);

    if (!result.isSuccess) {
      return LLMResult.failure(result.error!);
    }

    final parsed = ActionItemsResponse.tryParse(result.data!);
    if (parsed == null) {
      return const LLMResult.failure('Failed to parse action items response');
    }
    return LLMResult.success(parsed);
  }

  @override
  Future<LLMResult<PlayerMomentsResponse>> extractPlayerMoments({
    required String transcript,
    required String prompt,
  }) async {
    final fullPrompt = '$prompt\n\nTranscript:\n$transcript';
    final result = await generateText(prompt: fullPrompt);

    if (!result.isSuccess) {
      return LLMResult.failure(result.error!);
    }

    final parsed = PlayerMomentsResponse.tryParse(result.data!);
    if (parsed == null) {
      return const LLMResult.failure('Failed to parse player moments response');
    }
    return LLMResult.success(parsed);
  }

  @override
  Future<LLMResult<NpcsResponse>> extractNpcs({
    required String transcript,
    required String prompt,
  }) async {
    final fullPrompt = '$prompt\n\n$transcript';
    final result = await generateText(prompt: fullPrompt);

    if (!result.isSuccess) {
      return LLMResult.failure(result.error!);
    }

    final parsed = NpcsResponse.tryParse(result.data!);
    if (parsed == null) {
      return const LLMResult.failure('Failed to parse NPCs response');
    }
    return LLMResult.success(parsed);
  }

  @override
  Future<LLMResult<LocationsResponse>> extractLocations({
    required String transcript,
    required String prompt,
  }) async {
    final fullPrompt = '$prompt\n\n$transcript';
    final result = await generateText(prompt: fullPrompt);

    if (!result.isSuccess) {
      return LLMResult.failure(result.error!);
    }

    final parsed = LocationsResponse.tryParse(result.data!);
    if (parsed == null) {
      return const LLMResult.failure('Failed to parse locations response');
    }
    return LLMResult.success(parsed);
  }

  @override
  Future<LLMResult<ItemsResponse>> extractItems({
    required String transcript,
    required String prompt,
  }) async {
    final fullPrompt = '$prompt\n\n$transcript';
    final result = await generateText(prompt: fullPrompt);

    if (!result.isSuccess) {
      return LLMResult.failure(result.error!);
    }

    final parsed = ItemsResponse.tryParse(result.data!);
    if (parsed == null) {
      return const LLMResult.failure('Failed to parse items response');
    }
    return LLMResult.success(parsed);
  }

  /// Converts Gemini errors to user-friendly messages.
  String _handleGeminiError(GenerativeAIException e) {
    final message = e.message.toLowerCase();
    if (message.contains('rate limit') || message.contains('quota')) {
      return 'API rate limit reached. Please wait a moment and try again.';
    }
    if (message.contains('invalid') && message.contains('key')) {
      return 'Invalid API key. Please check your Gemini API key in settings.';
    }
    if (message.contains('safety')) {
      return 'Content was blocked by safety filters.';
    }
    return 'Gemini API error: ${e.message}';
  }
}
