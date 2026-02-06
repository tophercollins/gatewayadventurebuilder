/// Extracts JSON from LLM response text (handles markdown code blocks).
String extractJson(String text) {
  final codeBlockPattern = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
  final match = codeBlockPattern.firstMatch(text);
  if (match != null) {
    return match.group(1)!.trim();
  }
  return text.trim();
}
