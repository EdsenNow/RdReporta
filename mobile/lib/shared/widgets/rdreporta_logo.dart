import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RdReportaLogo extends StatelessWidget {
  const RdReportaLogo({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = Theme.of(context).brightness == Brightness.dark
        ? 'assets/branding/rdreporta_dark_flutter.svg'
        : 'assets/branding/rdreporta_light_flutter.svg';

    return Semantics(
      image: true,
      label: 'Logo de RDReporta',
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: SvgPicture.asset(
            asset,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
