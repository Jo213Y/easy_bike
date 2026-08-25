import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // بيتولد أوتوماتيك بأمر flutterfire configure
import 'screens/add_client_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/clients_list_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const TrainerApp(),
    ),
  );
}

class TrainerApp extends StatelessWidget {
  const TrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp(
      title: 'مواعيد المتدربين',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const RootScreen(),
        '/add': (context) => const AddClientScreen(),
        '/timeline': (context) => const TimelineScreen(),
      },
    );
  }
}

/// شاشة رئيسية فيها Tabs للتنقل بين شاشة التايم لاين وشاشة الإضافة وشاشة كل المتدربين
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 1;

  final _screens = const [
    AddClientScreen(),
    TimelineScreen(),
    ClientsListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'إضافة متدرب'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_view_day), label: 'التايم لاين'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'كل المتدربين'),
        ],
      ),
    );
  }
}
