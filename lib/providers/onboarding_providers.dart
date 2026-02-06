import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key for storing onboarding completion state in SharedPreferences.
const String _onboardingCompleteKey = 'has_completed_onboarding';

/// Provider for SharedPreferences instance.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

/// Provider that checks if the user has completed onboarding.
/// Returns true if onboarding has been completed, false otherwise.
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool(_onboardingCompleteKey) ?? false;
});

/// Notifier for managing onboarding completion state.
/// Allows marking onboarding as complete.
class OnboardingCompletionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Marks onboarding as complete and persists the state.
  Future<void> completeOnboarding() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_onboardingCompleteKey, true);
    state = const AsyncValue.data(true);
  }

  /// Resets onboarding state (useful for testing or re-showing onboarding).
  Future<void> resetOnboarding() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_onboardingCompleteKey, false);
    state = const AsyncValue.data(false);
  }
}

/// Provider for managing onboarding completion state with mutations.
final onboardingCompletionProvider =
    AsyncNotifierProvider<OnboardingCompletionNotifier, bool>(
      OnboardingCompletionNotifier.new,
    );

/// Notifier for managing the current onboarding page index.
class OnboardingPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Sets the current page index.
  void setPage(int page) {
    state = page;
  }

  /// Moves to the next page.
  void nextPage() {
    state++;
  }

  /// Moves to the previous page.
  void previousPage() {
    if (state > 0) {
      state--;
    }
  }

  /// Resets to the first page.
  void reset() {
    state = 0;
  }
}

/// Provider for the current onboarding page index.
final onboardingPageProvider = NotifierProvider<OnboardingPageNotifier, int>(
  OnboardingPageNotifier.new,
);
