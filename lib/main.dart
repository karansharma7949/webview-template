import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart'; // For SystemNavigator
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      title: 'Jeeto360',
      home: const MyHomePage(title: 'Jeeto360'),
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
  bool _isInitialPageLoading = true;
  bool _hasCompletedFirstLoad = false;
  int _loadProgress = 0;

  @override
  void initState() {
    super.initState();
    final String initialUrl = dotenv.env['WEBVIEW_URL']!;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (!_hasCompletedFirstLoad && mounted) {
              setState(() {
                _loadProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (!_hasCompletedFirstLoad && mounted) {
              setState(() {
                _isInitialPageLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isInitialPageLoading = false;
                _hasCompletedFirstLoad = true;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (!_hasCompletedFirstLoad && mounted) {
              // Only keep splash for main-frame load failures; ignore subresource errors
              final bool isMainFrame = (error.isForMainFrame == true);
              if (isMainFrame) {
                setState(() {
                  _isInitialPageLoading = true;
                });
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    final String logoPath =
        dotenv.env['SPLASH_LOGO'] ?? 'assets/icons/logo.png';
    final Widget splashLogo =
        (logoPath.startsWith('http://') || logoPath.startsWith('https://'))
            ? Image.network(
                logoPath,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              )
            : Image.asset(
                logoPath,
                width: 120,
                height: 120,
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
          child: Stack(
            children: <Widget>[
              WebViewWidget(controller: controller),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_isInitialPageLoading,
                  child: AnimatedOpacity(
                    opacity: _isInitialPageLoading ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            splashLogo,
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                value: (_hasCompletedFirstLoad
                                    ? 1.0
                                    : (_loadProgress > 0 && _loadProgress < 100)
                                        ? _loadProgress / 100.0
                                        : null),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
