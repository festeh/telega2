import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telega2/core/theme/appearance.dart';
import 'package:telega2/presentation/providers/app_providers.dart';

ProviderContainer _container(SharedPreferences prefs) {
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults when SharedPreferences is empty', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = _container(prefs);
    addTearDown(container.dispose);

    expect(container.read(appearanceProvider), AppearanceSettings.defaults);
  });

  test('round-trips every knob across containers', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // First container: mutate every field.
    final c1 = _container(prefs);
    await c1.read(appearanceProvider.notifier).setAccent(AccentPreset.crimson);
    await c1
        .read(appearanceProvider.notifier)
        .setBubble(BubbleStyle.minimalLine);
    await c1.read(appearanceProvider.notifier).setDensity(Density.compact);
    await c1
        .read(appearanceProvider.notifier)
        .setChatBackground(ChatBackground.midnightBlue);
    await c1
        .read(appearanceProvider.notifier)
        .setIncomingBubbleFill(IncomingBubbleFill.accentTint);
    c1.dispose();

    // Second container reading the same prefs: every value restored.
    final c2 = _container(prefs);
    addTearDown(c2.dispose);
    final restored = c2.read(appearanceProvider);
    expect(restored.accent, AccentPreset.crimson);
    expect(restored.bubble, BubbleStyle.minimalLine);
    expect(restored.density, Density.compact);
    expect(restored.chatBackground, ChatBackground.midnightBlue);
    expect(restored.incomingBubbleFill, IncomingBubbleFill.accentTint);
  });

  test('unknown stored values fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'appearance.accent': 'mythicalColor',
      'appearance.bubble': 'shape8',
      'appearance.density': 'mega',
      'appearance.chatBackground': 'cosmicVoid',
      'appearance.incomingBubbleFill': 'gradientFlare',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = _container(prefs);
    addTearDown(container.dispose);

    expect(container.read(appearanceProvider), AppearanceSettings.defaults);
  });

  test('partially stored values: missing keys fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'appearance.accent': AccentPreset.teal.name,
      'appearance.chatBackground': ChatBackground.forestNight.name,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = _container(prefs);
    addTearDown(container.dispose);

    final settings = container.read(appearanceProvider);
    expect(settings.accent, AccentPreset.teal);
    expect(settings.chatBackground, ChatBackground.forestNight);
    expect(settings.bubble, AppearanceSettings.defaults.bubble);
    expect(settings.density, AppearanceSettings.defaults.density);
    expect(
      settings.incomingBubbleFill,
      AppearanceSettings.defaults.incomingBubbleFill,
    );
  });
}
