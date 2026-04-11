import 'package:flutter/material.dart';
import 'package:study_zen/utils/theme.dart';

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
        gradient: buttonGradient,
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

// Reusable course card used in student and teacher screens
Widget courseCard(String title, String subtitle, IconData icon, List<Color> gradientColors, {double width = 130}) {
  return Container(
    width: width,
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 80,
          width: double.infinity,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 40),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1C1C1C)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Reusable task list item
Widget taskItem(String title, String duration, bool isCompleted) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    leading: Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF6CA89D) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCompleted ? const Color(0xFF6CA89D) : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: isCompleted ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
    ),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF2C2C2C)),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        duration,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
    ),
    trailing: Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
    ),
  );
}

// Reusable stat card for dashboards
Widget statCardWidget(IconData icon, String title, String value,
  {Color accent = AppColors.primary, List<Color>? gradientColors, bool whiteBackground = false}) {
  if (whiteBackground) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: accent.withOpacity(0.12), child: Icon(icon, color: accent)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1C))),
        ],
      ),
    );
  }
  final colors = gradientColors ?? [accent, accent.withOpacity(0.85)];
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
      ],
    ),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(backgroundColor: Colors.white.withOpacity(0.12), child: Icon(icon, color: Colors.white)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    ),
  );
}

// Reusable lesson tile used in teacher dashboard
Widget lessonTileWidget(String title, String subtitle, {List<Color>? gradientColors}) {
  final colors = gradientColors ?? const [Color(0xFF669DAB), Color(0xFF81C39A)];
  return Container(
    width: 240,
    margin: const EdgeInsets.only(right: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    ),
  );
}
