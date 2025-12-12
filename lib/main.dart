import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

import 'services/image-services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'Random Image'),
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
  late String imageUrl = '';
  PaletteGeneratorMaster? paletteGenerator;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    generatePalette();
  }

  @override
  void dispose() {
    imageCache.clear();
    imageCache.clearLiveImages();
    super.dispose();
  }

  Future<void> generatePalette() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ImageServices.fetchData();

      // Clear old image from cache
      if (imageUrl.isNotEmpty) {
        NetworkImage(imageUrl).evict();
      }

      final ImageProvider imageProvider = NetworkImage(result);

      final pallete = await PaletteGeneratorMaster.fromImageProvider(
        imageProvider,
        size: const Size(150, 150),
        maximumColorCount: 16,
        targets: [PaletteTargetMaster.vibrant, PaletteTargetMaster.darkMuted],
      ).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          imageUrl = result;
          paletteGenerator = pallete;
          isLoading = false;
        });
      }
    } catch (e) {
      log('Error generating palette: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: paletteGenerator?.dominantColor?.color,
        title: Text(widget.title),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        color: paletteGenerator?.dominantColor?.color,
        child: Column(
          crossAxisAlignment: .center,
          mainAxisAlignment: .center,
          children: [
            if (isLoading)
              const Center(heightFactor: 5, child: CircularProgressIndicator())
            else if (errorMessage != null)
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              )
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: SizedBox(
                  key: ValueKey(imageUrl),
                  height: 300,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 800,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 500),
                            child: child,
                          );
                        },
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: isLoading ? null : generatePalette,
              child: Text(errorMessage != null ? 'Retry' : 'Another'),
            ),
          ],
        ),
      ),
    );
  }
}
