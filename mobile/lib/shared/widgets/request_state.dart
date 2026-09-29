import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RequestState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String action;
  const RequestState(
      {super.key,
      required this.message,
      required this.onRetry,
      this.action = 'Volver a intentar'});

  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_outlined,
              size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              backgroundColor: context.isDarkMode
                  ? context.surfaceColor
                  : const Color(0xFFFFFAF3),
              foregroundColor: context.pineColor,
              side: BorderSide(color: context.borderColor, width: 2),
            ),
            child: Text(action),
          ),
        ]),
      ));
}
