import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/appearance.dart';
import '../providers/app_providers.dart';

const _accentKey = 'appearance.accent';
const _bubbleKey = 'appearance.bubble';
const _densityKey = 'appearance.density';
const _chatBgKey = 'appearance.chatBackground';
const _incomingFillKey = 'appearance.incomingBubbleFill';

/// Owns [AppearanceSettings] and persists every change synchronously to
/// SharedPreferences. Boot is non-async because `sharedPreferencesProvider`
/// is initialized in `main()` before `runApp` — see `lib/main.dart`.
class AppearanceNotifier extends Notifier<AppearanceSettings> {
  @override
  AppearanceSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return AppearanceSettings(
      accent: _parseEnum(
        prefs.getString(_accentKey),
        AccentPreset.values,
        AppearanceSettings.defaults.accent,
      ),
      bubble: _parseEnum(
        prefs.getString(_bubbleKey),
        BubbleStyle.values,
        AppearanceSettings.defaults.bubble,
      ),
      density: _parseEnum(
        prefs.getString(_densityKey),
        Density.values,
        AppearanceSettings.defaults.density,
      ),
      chatBackground: _parseEnum(
        prefs.getString(_chatBgKey),
        ChatBackground.values,
        AppearanceSettings.defaults.chatBackground,
      ),
      incomingBubbleFill: _parseEnum(
        prefs.getString(_incomingFillKey),
        IncomingBubbleFill.values,
        AppearanceSettings.defaults.incomingBubbleFill,
      ),
    );
  }

  Future<void> setAccent(AccentPreset accent) async {
    if (state.accent == accent) return;
    state = state.copyWith(accent: accent);
    await ref.read(sharedPreferencesProvider).setString(_accentKey, accent.name);
  }

  Future<void> setBubble(BubbleStyle bubble) async {
    if (state.bubble == bubble) return;
    state = state.copyWith(bubble: bubble);
    await ref.read(sharedPreferencesProvider).setString(_bubbleKey, bubble.name);
  }

  Future<void> setDensity(Density density) async {
    if (state.density == density) return;
    state = state.copyWith(density: density);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_densityKey, density.name);
  }

  Future<void> setChatBackground(ChatBackground bg) async {
    if (state.chatBackground == bg) return;
    state = state.copyWith(chatBackground: bg);
    await ref.read(sharedPreferencesProvider).setString(_chatBgKey, bg.name);
  }

  Future<void> setIncomingBubbleFill(IncomingBubbleFill fill) async {
    if (state.incomingBubbleFill == fill) return;
    state = state.copyWith(incomingBubbleFill: fill);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_incomingFillKey, fill.name);
  }
}

T _parseEnum<T extends Enum>(String? value, List<T> values, T fallback) {
  if (value == null) return fallback;
  for (final v in values) {
    if (v.name == value) return v;
  }
  return fallback;
}
