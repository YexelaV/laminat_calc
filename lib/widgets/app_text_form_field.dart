import 'package:flutter/material.dart';

class AppTextFormField extends StatelessWidget {
  final GlobalKey<FormFieldState> formKey;
  final FocusNode focusNode;
  final String labelText;
  final Function(String?) validator;
  final Function(String?) callback;
  final FocusNode? nextFocusNode;

  const AppTextFormField({
    Key? key,
    required this.formKey,
    required this.focusNode,
    required this.labelText,
    required this.validator,
    required this.callback,
    this.nextFocusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: formKey,
      focusNode: focusNode,
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
        formKey.currentState?.validate();
      },
      onFieldSubmitted: (value) {
        if (formKey.currentState?.validate() ?? false) {
          callback(value);
        }
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
    );
  }
}
