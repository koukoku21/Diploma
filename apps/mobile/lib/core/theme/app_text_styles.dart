import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const display = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: kTextPrimary,
    height: 1.15,
  );

  static const h1 = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: kTextPrimary,
  );

  static const title = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: kTextPrimary,
  );

  static const subtitle = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: kTextPrimary,
  );

  static const body = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: kTextPrimary,
    height: 1.5,
  );

  static const label = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: kTextPrimary,
  );

  static const caption = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: kTextSecondary,
  );

  static const overline = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: kGold,
    letterSpacing: 1.2,
  );
}
