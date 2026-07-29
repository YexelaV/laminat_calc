import 'package:flutter/material.dart';

/// The look every input in the form shares: a rounded box with the label
/// riding on its top edge. [InchField] builds its fraction picker from the
/// same decoration, which is what keeps the two halves of an inch value on
/// one line.
InputDecoration appInputDecoration({String? labelText}) => InputDecoration(
      // Horizontal room is what the labels are short of, not vertical: keep
      // the side padding small enough that 'Ширина' still fits on the border
      // of a box that shares its row with a fraction picker.
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      isDense: true,
      // 'Nieprawidłowa wartość' under a box two digits wide: without this the
      // message is one line and ends up as 'Не боле…'.
      errorMaxLines: 4,
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.03),
      border: _border(Colors.black.withValues(alpha: 0.3), 1),
      enabledBorder: _border(Colors.black.withValues(alpha: 0.3), 1),
      focusedBorder: _border(Colors.blue, 1.5),
      // Scaled down rather than clipped: the boxes are half a row wide and
      // 'Pezzi per confezione' does not fit one at full size.
      label: labelText == null
          ? null
          : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(labelText),
            ),
      labelStyle: TextStyle(color: Colors.black.withValues(alpha: 0.8), fontSize: 16),
    );

OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );

class AppTextFormField extends StatelessWidget {
  final FocusNode focusNode;
  final String labelText;
  final Function(String?) validator;
  final Function(String) callback;
  final FocusNode? nextFocusNode;
  final TextEditingController controller;

  const AppTextFormField({
    super.key,
    required this.focusNode,
    required this.labelText,
    required this.validator,
    required this.callback,
    required this.controller,
    this.nextFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: appInputDecoration(labelText: labelText),
      keyboardType: TextInputType.number,
      textInputAction: nextFocusNode == null ? TextInputAction.done : TextInputAction.next,
      validator: (value) => validator(value),
      onChanged: (value) {
        if (validator(value) == null && value.isNotEmpty) {
          callback(value);
        }
      },
      onFieldSubmitted: (value) {
        if (validator(value) == null && value.isNotEmpty) {
          callback(value);
        }
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
    );
  }
}
