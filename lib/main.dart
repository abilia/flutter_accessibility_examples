import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Screen reader examples',
      home: AnnounceStateChangeExample(),
    );
  }
}

class AnnounceStateChangeExample extends StatefulWidget {
  const AnnounceStateChangeExample({super.key});

  @override
  State<AnnounceStateChangeExample> createState() =>
      _AnnounceStateChangeExampleState();
}

class _AnnounceStateChangeExampleState
    extends State<AnnounceStateChangeExample> {
  bool materialChecked = false;
  bool cupertinoChecked = false;
  bool checkedNoSemantics = false;
  bool checkedBasicSemantics = false;
  bool checkedSemanticsFeedbackBroken = false;
  bool checkedSemanticsFeedbackWorking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              width: 320,
              child: Text(
                  'The screen reader should announce the role and state of a checkbox/radio button/switch etc when navigating to it.\n  Also, when the user changes the state, that should be announced. On iOS, this works on all examples expect "No semantics", but on Android it only works on Material/Cupertino checkboxes and "Semantics, feedback working". See comments in code.'),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text('Material/Cupertino checkbox'),
            Checkbox(
              value: materialChecked,
              onChanged: (newValue) =>
                  setState(() => materialChecked = newValue!),
            ),
            CupertinoCheckbox(
              value: cupertinoChecked,
              onChanged: (newValue) =>
                  setState(() => cupertinoChecked = newValue!),
            ),
            const Text('No semantics'),
            CheckBoxNoSemantics(
              checked: checkedNoSemantics,
              onChanged: (newValue) =>
                  setState(() => checkedNoSemantics = newValue),
            ),
            const Text('Semantics, no feedback on change'),
            CheckBoxSemanticsNoFeedback(
              checked: checkedBasicSemantics,
              onChanged: (newValue) =>
                  setState(() => checkedBasicSemantics = newValue),
            ),
            const Text('Semantics, feedback broken'),
            CheckBoxSemanticsFeedbackBroken(
              checked: checkedSemanticsFeedbackBroken,
              onChanged: (newValue) =>
                  setState(() => checkedSemanticsFeedbackBroken = newValue),
            ),
            const Text('Semantics, feedback working'),
            CheckBoxSemanticsFeedbackWorking(
              checked: checkedSemanticsFeedbackWorking,
              onChanged: (newValue) =>
                  setState(() => checkedSemanticsFeedbackWorking = newValue),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

/// We provide no Semantics. The GestureDetector provides some basic Semantics,
/// but it's not helpful by itself.
class CheckBoxNoSemantics extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool>? onChanged;

  const CheckBoxNoSemantics({
    super.key,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!checked),
      child: Container(
        margin: const EdgeInsets.all(8),
        height: 40,
        width: 40,
        color: checked ? Colors.blue : Colors.grey,
        child: Icon(checked ? Icons.check : null),
      ),
    );
  }
}

/// We provide Semantics with [enabled] and [checked]. This enables the screen
/// reader to understand that it's a checkbox and if it is enabled or disabled.
/// But it provides no feedback when the user taps and changes the value of the
/// checkbox.
class CheckBoxSemanticsNoFeedback extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool>? onChanged;

  const CheckBoxSemanticsNoFeedback({
    super.key,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: onChanged != null,
      checked: checked,
      child: CheckBoxNoSemantics(
        checked: checked,
        onChanged: onChanged,
      ),
    );
  }
}

/// We provide Semantics with [enabled] and [checked], as well as send a
/// [TapSemanticEvent] when the value changes, telling the screen reader to
/// read the new state, however we also wrapped it in a [Listener] Widget
/// which for some reasons makes it so the screen reader announces the states
/// of ALL widgets on screen. It also happens with [MouseRegion] and likely
/// many other widgets. I have no idea why. It is fixed by having the [Semantics]
/// Widget be the outermost Widget.
class CheckBoxSemanticsFeedbackBroken extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool>? onChanged;

  const CheckBoxSemanticsFeedbackBroken({
    super.key,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      child: Semantics(
        enabled: onChanged != null,
        checked: checked,
        child: CheckBoxNoSemantics(
          checked: checked,
          onChanged: (value) {
            onChanged?.call(value);
            // Provide feedback on state change
            feedback(context);
          },
        ),
      ),
    );
  }
}

/// Fix feedback by having [Semantics] Widget be above the problematic Widget
/// (in this case a [Listener] Widget.
class CheckBoxSemanticsFeedbackWorking extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool>? onChanged;

  const CheckBoxSemanticsFeedbackWorking({
    super.key,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: onChanged != null,
      checked: checked,
      child: Listener(
        child: CheckBoxNoSemantics(
          checked: checked,
          onChanged: (value) {
            onChanged?.call(value);
            // Provide feedback on state change
            feedback(context);
          },
        ),
      ),
    );
  }
}

void feedback(BuildContext context) {
  // On Android the platform-typical click system sound is played. On iOS this
  // is a no-op as that platform usually doesn't provide feedback for a tap.
  // Also sends TapSemanticEvent that makes the screen reader announce the state.
  Feedback.forTap(context);
  return;

  // If we don't want the system click sound, only the semantic announcement,
  // use this:
  context.findRenderObject()?.sendSemanticsEvent(
        const TapSemanticEvent(),
      );
}
