import 'package:flutter/material.dart';

import '../utils/units.dart';
import 'app_text_form_field.dart';

/// Whole inches typed on the number pad, sixteenths picked from a list. The
/// number keypad has no '/' or space, so a fraction cannot be typed at all; the
/// two halves are joined back into the one string ('47 7/8') that [controller],
/// [validator] and [callback] all see, which keeps every caller unaware of the
/// split.
/// Width of the fraction picker, so that callers sizing a whole row can add it
/// to the width they want the typed part to have. Wide enough for the longest
/// label, '15/16', plus the arrow: anything narrower clips the denominator.
const double INCH_FRACTION_WIDTH = 76;

/// Gap between the typed part and the picker, kept small because the two share
/// a row that also has to hold a label on its border.
const double INCH_FRACTION_GAP = 4;

class InchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final String labelText;
  final String? Function(String) validator;
  final void Function(String) callback;

  const InchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.validator,
    required this.callback,
    this.nextFocusNode,
  });

  @override
  State<InchField> createState() => _InchFieldState();
}

class _InchFieldState extends State<InchField> {
  final _whole = TextEditingController();
  int _sixteenths = 0;
  String _mirrored = '';
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _pull();
    widget.controller.addListener(_onOutsideChange);
    _whole.addListener(_mirror);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onOutsideChange);
    _whole.dispose();
    super.dispose();
  }

  // The screens rewrite the shared controller when the unit system changes.
  void _onOutsideChange() {
    if (widget.controller.text == _mirrored) return;
    setState(_pull);
  }

  void _pull() {
    _syncing = true;
    final inches = parseInches(widget.controller.text);
    if (inches == null) {
      _whole.text = '';
      _sixteenths = 0;
    } else {
      final sixteenths = (inches * INCH_DENOMINATOR).round();
      _whole.text = '${sixteenths ~/ INCH_DENOMINATOR}';
      _sixteenths = sixteenths % INCH_DENOMINATOR;
    }
    _mirrored = widget.controller.text;
    _syncing = false;
  }

  String _combine(String whole) {
    final text = whole.trim();
    if (_sixteenths == 0) return text;
    final fraction = fractionLabel(_sixteenths);
    return text.isEmpty ? fraction : '$text $fraction';
  }

  // Every keystroke reaches the shared controller, valid or not, because the
  // screens decide whether the Next button is enabled by reading its text.
  void _mirror() {
    if (_syncing) return;
    _mirrored = _combine(_whole.text);
    widget.controller.text = _mirrored;
  }

  void _pickFraction(int sixteenths) {
    setState(() => _sixteenths = sixteenths);
    _mirror();
    if (_mirrored.isNotEmpty && widget.validator(_mirrored) == null) {
      widget.callback(_mirrored);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextFormField(
            controller: _whole,
            focusNode: widget.focusNode,
            nextFocusNode: widget.nextFocusNode,
            labelText: widget.labelText,
            validator: (value) => widget.validator(_combine(value ?? '')),
            callback: (value) => widget.callback(_combine(value)),
          ),
        ),
        SizedBox(width: INCH_FRACTION_GAP),
        SizedBox(
          width: INCH_FRACTION_WIDTH,
          // The same decoration as the field beside it, minus the label: that
          // is what puts the fraction on the typed line and gives the two
          // boxes one outline.
          child: InputDecorator(
            decoration: appInputDecoration().copyWith(
              // '15/16' plus the arrow leave nothing to spare in a box this
              // narrow, so the picker keeps only the padding it needs.
              contentPadding: EdgeInsets.fromLTRB(4, 12, 0, 12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _sixteenths,
                isExpanded: true,
                isDense: true,
                iconSize: 14,
                items: [
                  for (var n = 0; n < INCH_DENOMINATOR; n++)
                    DropdownMenuItem(
                      value: n,
                      child: Text(n == 0 ? '0' : fractionLabel(n)),
                    ),
                ],
                onChanged: (value) => _pickFraction(value ?? 0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
