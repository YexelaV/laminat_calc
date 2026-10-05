// The white card a parameters screen is typed into.
//
// There are two of them now — the room and the laminate — and they are the same
// card down to the corner radius: a title with the settings button beside it,
// the boxes, and a Next button that is grey until every box is a number the
// engine will take. Written once here so the two cannot drift apart, and so
// that a third screen costs its fields and nothing else.
import 'package:flutter/material.dart';

import 'package:floor_calculator/l10n/app_localizations.dart';
import 'package:floor_calculator/widgets/app_background.dart';

// One rhythm for every form. The labels ride on the field borders, so every
// title and every row above one needs clearance or the label lands on it.
const double kFormGap = 12;
const double kFormSectionGap = 20;

class ParametersCard extends StatelessWidget {
  final String title;
  final IconData icon;

  /// The boxes, in the order they are read and typed.
  final List<Widget> children;

  /// Whether every box holds a number the engine will take. The Next button is
  /// grey and dead until it does — a value a field rejects never reaches the
  /// state, so without this the button would stay lit while the box under it
  /// went red.
  final bool canProceed;

  final VoidCallback onNext;

  /// The language and the unit system are answered once on the way in; the
  /// cog in the title row is the only way back to them.
  final VoidCallback onSettings;

  const ParametersCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    required this.canProceed,
    required this.onNext,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    // A bar with nothing in it but the way back, which is why it is see-through
    // and flat — and why there is none at all where there is nowhere to go
    // back to. The room is reached by replacing the screen that asked for the
    // units, so it has no bar and keeps the 56 px; the laminate is pushed on
    // top of the room, so it has one. The same card, asking the route it is in
    // rather than being told by each screen.
    //
    // These two were the only screens in the app without a bar, which made them
    // the only ones a user could not step back from. The cog in the card is a
    // way to the settings, not a way back.
    final goesBack = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar:
            goesBack ? AppBar(backgroundColor: Colors.transparent, elevation: 0) : null,
        // Centred while the card fits, scrollable when it does not: the
        // imperial form is several rows taller than the metric one and the
        // keyboard takes half the screen away while a field is focused.
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20), color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      sectionTitle(
                        title,
                        icon,
                        trailing: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.black54),
                          onPressed: onSettings,
                          // A default IconButton is 48 high and would make the
                          // title row taller than the section below it.
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints.tightFor(width: 36, height: 36),
                        ),
                      ),
                      ...children,
                      const SizedBox(height: 30),
                      TextButton(
                        onPressed: canProceed
                            ? () {
                                FocusScope.of(context).unfocus();
                                onNext();
                              }
                            : null,
                        child: Container(
                          alignment: Alignment.center,
                          width: 140,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: canProceed ? Colors.blue : Colors.grey,
                          ),
                          child: Text(
                            AppStrings.of(context).next,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The heading of a section, with its icon and whatever rides on the right of
/// the row.
Widget sectionTitle(String title, IconData icon, {Widget? trailing}) {
  return Row(
    children: [
      Text(title, style: const TextStyle(fontSize: 20).copyWith(color: Colors.blue)),
      const SizedBox(width: 8),
      Icon(icon, size: 20, color: Colors.blue),
      if (trailing != null) ...[const Spacer(), trailing],
    ],
  );
}

/// A size typed into several controls needs a name of its own and an echo of
/// what the controls add up to; the boxes below it are then free to be labelled
/// with bare units.
Widget sizeTitle(String title, String? value) => Row(
      children: [
        Text(title,
            style: TextStyle(color: Colors.black.withValues(alpha: 0.8), fontSize: 16)),
        // The echo shares the title's line because the form has no room to
        // spare on a short screen.
        if (value != null) ...[
          const SizedBox(width: 8),
          Text('= $value',
              style:
                  TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 14)),
        ],
      ],
    );
