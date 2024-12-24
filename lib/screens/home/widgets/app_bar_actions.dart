import 'package:chromaniac/services/premium_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:chromaniac/providers/debug_provider.dart';

class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer<PremiumService>(
          builder: (context, premiumService, _) => IconButton(
            onPressed: () => context.read<DebugProvider>().isDebugEnabled 
              ? premiumService.togglePremiumStatus()
              : premiumService.unlockPremium(),
            icon: Icon(
              premiumService.isPremium ? Icons.star : Icons.star_border,
              color: premiumService.isPremium ? Colors.amber : null,
            ),
          ),
        ),
        if (kDebugMode)
          Consumer<DebugProvider>(
            builder: (context, debugProvider, _) => IconButton(
              onPressed: () => debugProvider.toggleDebug(),
              icon: Icon(
                debugProvider.isDebugEnabled ? Icons.bug_report : Icons.bug_report_outlined,
                color: debugProvider.isDebugEnabled ? Colors.red : null,
              ),
            ),
          ),
      ],
    );
  }
}
