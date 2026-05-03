import 'package:flutter/material.dart';

/// Kirish / ro‘yxatdan o‘tish fonlari — bitta vizual zanjir.
abstract final class AuthBrandGradients {
  static const Color lavenderTop = Color(0xFFF5F0FF);
  static const Color lavenderMid = Color(0xFFE8E0F5);
  static const Color lavenderBottom = Color(0xFFFCE4F0);

  static const LinearGradient scaffold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lavenderTop, lavenderMid, lavenderBottom],
  );
}
