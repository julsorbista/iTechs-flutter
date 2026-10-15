import 'package:flutter/material.dart';

BoxDecoration studentBackground() {
  return const BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/menu-background.png'),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(Color(0xBA4F3347), BlendMode.srcOver),
    ),
  );
}

BoxDecoration studentPanel() {
  return BoxDecoration(
    color: const Color(0xF0E7CF99),
    border: Border.all(color: const Color(0xFF6B4D72), width: 4),
    boxShadow: const [
      BoxShadow(color: Color(0xFF4A3040), offset: Offset(6, 6)),
    ],
  );
}

Widget studentButton(String label, VoidCallback? action, Color color) {
  return Container(
    decoration: BoxDecoration(
      color: color,
      boxShadow: const [
        BoxShadow(color: Color(0xFF4A3040), offset: Offset(5, 5)),
      ],
    ),
    child: ElevatedButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: const Color(0xFFB5ACA1),
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.white, width: 3),
        ),
      ),
      child: Row(
        mainAxisAlignment: label == 'BACK TO MENU'
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          if (label == 'BACK TO MENU') ...[
            const Icon(Icons.arrow_back, size: 16),
            const SizedBox(width: 10),
          ],
          if (label == 'START MODULE') ...[
            const Icon(Icons.menu_book_outlined, size: 16),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget lessonButton(String label, VoidCallback? action, [IconData? icon]) {
  return ElevatedButton(
    onPressed: action,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF9E6BA),
      foregroundColor: const Color(0xFF3A2921),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF9E6F49), width: 2),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
