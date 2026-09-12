import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/lifelink_design.dart';

/// The LifeLink brand mark.
///
/// Drawn in code rather than shipped as an asset so it inherits the
/// active theme automatically and stays crisp at any density. A blood
/// drop in the burgundy brand colour, with a link notch cut through it -
/// "LifeLink": the drop is the donation, the link is the coordination.
///
/// Identical in every role module. The role name sits beside it in the
/// app bar, so a user always knows which role they are in without the
/// branding changing shape or colour.
class LLBrandMark extends StatelessWidget {
  const LLBrandMark({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'LifeLink',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(LLRadius.avatar * size / 42),
        ),
        child: Center(
          child: Icon(
            Icons.water_drop_rounded,
            size: size * 0.62,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}

/// The full wordmark, for sign-in and splash surfaces where there is room
/// for it. The app bar uses [LLBrandMark] alone.
class LLWordmark extends StatelessWidget {
  const LLWordmark({super.key, this.markSize = 34});

  final double markSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LLBrandMark(size: markSize),
        const SizedBox(width: LLSpacing.sm),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Life',
                style: TextStyle(
                  fontSize: markSize * 0.62,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: 'Link',
                style: TextStyle(
                  fontSize: markSize * 0.62,
                  fontWeight: FontWeight.w300,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
