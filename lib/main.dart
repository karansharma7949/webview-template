import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart'; // For SystemNavigator
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'apk',
      home: const MyHomePage(title: 'apk'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final WebViewController controller;
  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    final String initialUrl = dotenv.env['WEBVIEW_URL']!;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));

    // Start 1-minute timer for splash screen
    _splashTimer = Timer(const Duration(minutes: 1), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String logoPath =
        dotenv.env['SPLASH_LOGO'] ?? 'assets/icons/logo.png';
    final Widget splashLogo =
        (logoPath.startsWith('http://') || logoPath.startsWith('https://'))
            ? Image.network(
                logoPath,
                width: 130,
                height: 130,
                fit: BoxFit.contain,
              )
            : Image.asset(
                logoPath,
                width: 130,
                height: 130,
                fit: BoxFit.contain,
              );

    return PopScope(
      canPop: false, // Prevent default pop behavior
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          // Pop was canceled, so handle WebView navigation
          if (await controller.canGoBack()) {
            controller.goBack(); // Go back in WebView
          } else {
            // No back history, exit the app
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _showSplash
              ? Container(
                  color: Colors.white,
                  child: Center(
                    child: splashLogo,
                  ),
                )
              : WebViewWidget(controller: controller),
        ),
      ),
    );
  }
}
