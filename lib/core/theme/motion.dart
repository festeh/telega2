import 'package:flutter/widgets.dart';

/// Default duration for micro-interactions (tap, toggle, selection change,
/// chip in/out). Spec: 150–300ms.
const Duration kAppearanceTransitionDuration = Duration(milliseconds: 200);

/// Slightly longer duration for structural transitions (page push, sheet
/// reveal, scroll-to-bottom).
const Duration kAppearanceLongTransitionDuration = Duration(milliseconds: 250);

/// Returns [normal] unless the OS reports a reduced-motion preference, in
/// which case it returns [Duration.zero] so decorative animations are
/// skipped. Use at every animated-widget call site.
Duration motionDurationFor(BuildContext context, Duration normal) {
  final disabled = MediaQuery.maybeDisableAnimationsOf(context);
  return disabled == true ? Duration.zero : normal;
}
