import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

/// زرار يتحط في actions بتاعة أي AppBar، بيديك تختار: حسب الموبايل / فاتح / غامق
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _labelFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'غامق';
      case ThemeMode.system:
        return 'حسب الموبايل';
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<ThemeProvider>().themeMode;

    return PopupMenuButton<ThemeMode>(
      tooltip: 'شكل التطبيق: ${_labelFor(current)}',
      icon: Icon(_iconFor(current)),
      onSelected: (mode) => context.read<ThemeProvider>().setThemeMode(mode),
      itemBuilder: (context) => ThemeMode.values.map((mode) {
        return PopupMenuItem<ThemeMode>(
          value: mode,
          child: Row(
            children: [
              Icon(
                _iconFor(mode),
                color: mode == current ? Colors.purple : null,
              ),
              const SizedBox(width: 10),
              Text(
                _labelFor(mode),
                style: TextStyle(
                  color: mode == current ? Colors.purple : null,
                  fontWeight: mode == current ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (mode == current) ...[
                const Spacer(),
                const Icon(Icons.check, color: Colors.purple, size: 18),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
