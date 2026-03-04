import 'package:flutter/material.dart';

TextFormField inputField(String hint, IconData icon, {bool isPassword = false, TextEditingController? controller}) {
  return TextFormField(
    obscureText: isPassword,
    controller: controller,
    validator: (value) => value == null || value.isEmpty ? 'Please enter $hint' : null,
    decoration: InputDecoration(
      hintText: hint,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade500, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade500, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: Colors.grey),
    ),
  );
}

Gradient backgroundGradient() {
  return LinearGradient(
    colors: [Color(0xFF6B90AD), Color(0xFF86B599)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
}

ElevatedButton styledButton(String text, VoidCallback onPressed, bool isLoading) {
  return ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
    child: Ink(
      decoration: BoxDecoration(
        gradient: backgroundGradient(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 88, minHeight: 44),
        alignment: Alignment.center,
        child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    ),
  );
}
