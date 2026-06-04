import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Colors are intentionally omitted — inherited from Theme.of(context).textTheme
  static const display = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static const h1 = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const title = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const subtitle = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );

  static const body = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const label = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const caption = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const overline = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: kGold,
    letterSpacing: 1.2,
  );
}
