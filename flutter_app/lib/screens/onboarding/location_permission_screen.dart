import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/location_helper.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.location_on, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 32),
                Text('Enable Location', style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('Find matches near you', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
                  child: ElevatedButton(
                    onPressed: () async {
                      final hasPermission = await LocationHelper.checkPermission();
                      if (hasPermission && context.mounted) {
                        await LocationHelper.getCurrentLocation();
                        if (context.mounted) Navigator.of(context).pushReplacementNamed('/home');
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
                    child: const Text('Enable Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: () => Navigator.of(context).pushReplacementNamed('/home'), child: const Text('Skip for now', style: TextStyle(color: AppTheme.textSecondary))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
