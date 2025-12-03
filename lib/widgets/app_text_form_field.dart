import 'package:flutter/material.dart';

class AppTextFormField extends StatelessWidget {
  final FocusNode focusNode;
  final String labelText;
  final Function(String?) validator;
  final Function(String) callback;
  final FocusNode? nextFocusNode;
  final TextEditingController? controller;

  const AppTextFormField({
    Key? key,
    required this.focusNode,
    required this.labelText,
    required this.validator,
    required this.callback,
    this.nextFocusNode,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 4),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black.withOpacity(0.8), width: 1),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black.withOpacity(0.8), width: 0.5),
        ),
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 16),
      ),
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
