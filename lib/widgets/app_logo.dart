import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/assets.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 34});
  final double height;
  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(Assets.logo, height: height);
}
