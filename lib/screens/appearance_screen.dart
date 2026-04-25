import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/appearance.dart';
import '../core/theme/telega_tokens.dart';
import '../presentation/providers/app_providers.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appearanceProvider);
    final actions = ref.read(appearanceProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        children: [
          _SectionHeader('Accent color'),
          _AccentPalette(
            current: settings.accent,
            onPick: actions.setAccent,
          ),
          const Divider(height: 1),
          _SectionHeader('Bubble style'),
          for (final style in BubbleStyle.values)
            _BubbleStyleTile(
              style: style,
              selected: settings.bubble == style,
              onTap: () => actions.setBubble(style),
            ),
          const Divider(height: 1),
          _SectionHeader('Density'),
          RadioGroup<Density>(
            groupValue: settings.density,
            onChanged: (v) {
              if (v != null) actions.setDensity(v);
            },
            child: Column(
              children: [
                for (final density in Density.values)
                  RadioListTile<Density>(
                    value: density,
                    title: Text(_densityLabel(density)),
                    subtitle: Text(_densitySubtitle(density)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SectionHeader('Chat background'),
          _ChatBackgroundPalette(
            current: settings.chatBackground,
            onPick: actions.setChatBackground,
          ),
          const Divider(height: 1),
          _SectionHeader('Incoming bubble fill'),
          for (final fill in IncomingBubbleFill.values)
            _IncomingFillTile(
              fill: fill,
              selected: settings.incomingBubbleFill == fill,
              onTap: () => actions.setIncomingBubbleFill(fill),
            ),
        ],
      ),
    );
  }

  String _densityLabel(Density d) =>
      d == Density.comfortable ? 'Comfortable' : 'Compact';

  String _densitySubtitle(Density d) => d == Density.comfortable
      ? 'Airy spacing, larger avatars'
      : 'Tighter rows, smaller avatars';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AccentPalette extends StatelessWidget {
  const _AccentPalette({required this.current, required this.onPick});

  final AccentPreset current;
  final ValueChanged<AccentPreset> onPick;

  @override
  Widget build(BuildContext context) {
    final ringColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final preset in AccentPreset.values)
            _AccentSwatch(
              color: preset.color,
              selected: current == preset,
              ringColor: ringColor,
              onTap: () => onPick(preset),
              label: preset.name,
            ),
        ],
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.selected,
    required this.ringColor,
    required this.onTap,
    required this.label,
  });

  final Color color;
  final bool selected;
  final Color ringColor;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Accent $label${selected ? ', selected' : ''}',
      button: true,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? ringColor : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleStyleTile extends StatelessWidget {
  const _BubbleStyleTile({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final BubbleStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: _BubbleSilhouette(style: style, color: colorScheme.primary),
      title: Text(_label(style)),
      subtitle: Text(_subtitle(style)),
      trailing: selected
          ? Icon(Icons.check, color: colorScheme.primary)
          : null,
    );
  }

  static String _label(BubbleStyle s) {
    switch (s) {
      case BubbleStyle.classicTail:
        return 'Classic';
      case BubbleStyle.flatRounded:
        return 'Flat rounded';
      case BubbleStyle.minimalLine:
        return 'Minimal line';
    }
  }

  static String _subtitle(BubbleStyle s) {
    switch (s) {
      case BubbleStyle.classicTail:
        return 'Tailed bubbles, Telegram-classic feel';
      case BubbleStyle.flatRounded:
        return 'Uniform rounded corners, no tail';
      case BubbleStyle.minimalLine:
        return 'Outlined bubbles, restrained';
    }
  }
}

class _BubbleSilhouette extends StatelessWidget {
  const _BubbleSilhouette({required this.style, required this.color});

  final BubbleStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final radius = TelegaTokens.from(
      AppearanceSettings.defaults.copyWith(bubble: style),
    ).bubbleRadius(isOutgoing: true);

    final isOutline = style == BubbleStyle.minimalLine;

    return Container(
      width: 36,
      height: 24,
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color,
        borderRadius: radius,
        border: isOutline ? Border.all(color: color, width: 1.5) : null,
      ),
    );
  }
}

class _ChatBackgroundPalette extends StatelessWidget {
  const _ChatBackgroundPalette({required this.current, required this.onPick});

  final ChatBackground current;
  final ValueChanged<ChatBackground> onPick;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ringColor = colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final bg in ChatBackground.values)
            _ChatBackgroundSwatch(
              color: bg.resolve(colorScheme),
              selected: current == bg,
              ringColor: ringColor,
              outlineColor: colorScheme.outline,
              onTap: () => onPick(bg),
              label: _chatBgLabel(bg),
            ),
        ],
      ),
    );
  }

  static String _chatBgLabel(ChatBackground bg) {
    switch (bg) {
      case ChatBackground.defaultDark:
        return 'Default';
      case ChatBackground.deepDark:
        return 'Deep dark';
      case ChatBackground.softDark:
        return 'Soft dark';
      case ChatBackground.midnightBlue:
        return 'Midnight blue';
      case ChatBackground.forestNight:
        return 'Forest night';
      case ChatBackground.plumNight:
        return 'Plum night';
    }
  }
}

class _ChatBackgroundSwatch extends StatelessWidget {
  const _ChatBackgroundSwatch({
    required this.color,
    required this.selected,
    required this.ringColor,
    required this.outlineColor,
    required this.onTap,
    required this.label,
  });

  final Color color;
  final bool selected;
  final Color ringColor;
  final Color outlineColor;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chat background $label${selected ? ', selected' : ''}',
      button: true,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? ringColor : outlineColor,
                  width: selected ? 3 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomingFillTile extends StatelessWidget {
  const _IncomingFillTile({
    required this.fill,
    required this.selected,
    required this.onTap,
  });

  final IncomingBubbleFill fill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: _IncomingFillSwatch(fill: fill, colorScheme: colorScheme),
      title: Text(_label(fill)),
      subtitle: Text(_subtitle(fill)),
      trailing: selected
          ? Icon(Icons.check, color: colorScheme.primary)
          : null,
    );
  }

  static String _label(IncomingBubbleFill f) {
    switch (f) {
      case IncomingBubbleFill.standard:
        return 'Standard';
      case IncomingBubbleFill.subtle:
        return 'Subtle';
      case IncomingBubbleFill.accentTint:
        return 'Accent tint';
      case IncomingBubbleFill.outlined:
        return 'Outlined';
    }
  }

  static String _subtitle(IncomingBubbleFill f) {
    switch (f) {
      case IncomingBubbleFill.standard:
        return 'Light grey, high contrast';
      case IncomingBubbleFill.subtle:
        return 'Dim grey, low contrast';
      case IncomingBubbleFill.accentTint:
        return 'Accent color at low alpha';
      case IncomingBubbleFill.outlined:
        return 'Border-only, no fill';
    }
  }
}

class _IncomingFillSwatch extends StatelessWidget {
  const _IncomingFillSwatch({required this.fill, required this.colorScheme});

  final IncomingBubbleFill fill;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final color = fill.resolve(colorScheme);
    final drawsBorder = fill.drawsBorder;
    return Container(
      width: 36,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: drawsBorder
            ? Border.all(color: colorScheme.outline, width: 1.5)
            : null,
      ),
    );
  }
}
