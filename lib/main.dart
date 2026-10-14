
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PdfReaderApp());
}

class PdfReaderApp extends StatefulWidget {
  const PdfReaderApp({super.key});

  @override
  State<PdfReaderApp> createState() => _PdfReaderAppState();
}

class _PdfReaderAppState extends State<PdfReaderApp> {
  ThemeMode themeMode = ThemeMode.system;
  Locale locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      themeMode = prefs.getBool('dark_mode') == true
          ? ThemeMode.dark
          : ThemeMode.light;
      locale = Locale(prefs.getString('language') ?? 'en');
    });
  }

  Future<void> toggleTheme() async {
    final dark = themeMode != ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', dark);
    if (!mounted) return;
    setState(() {
      themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> changeLanguage() async {
    final next = locale.languageCode == 'en' ? 'bn' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', next);
    if (!mounted) return;
    setState(() => locale = Locale(next));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PDF Reader',
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC62828),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF5350),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        locale: locale,
        onLanguage: changeLanguage,
        onTheme: toggleTheme,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Locale locale;
  final VoidCallback onLanguage;
  final VoidCallback onTheme;

  const HomeScreen({
    super.key,
    required this.locale,
    required this.onLanguage,
    required this.onTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? pdfPath;
  String? pdfName;
  bool loading = false;

  bool get bn => widget.locale.languageCode == 'bn';

  Future<void> openPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) return;

      if (!mounted) return;
      setState(() {
        pdfPath = result.files.single.path;
        pdfName = result.files.single.name;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open PDF: $e')),
      );
    }
  }

  Future<void> sharePdf() async {
    final path = pdfPath;
    if (path == null) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'PDF Reader',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Reader'),
        actions: [
          IconButton(
            tooltip: bn ? 'ভাষা পরিবর্তন' : 'Change language',
            onPressed: widget.onLanguage,
            icon: const Icon(Icons.translate),
          ),
          IconButton(
            tooltip: bn ? 'থিম পরিবর্তন' : 'Change theme',
            onPressed: widget.onTheme,
            icon: const Icon(Icons.dark_mode_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 64,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bn ? 'আপনার PDF লাইব্রেরি' : 'Your PDF Library',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bn
                          ? 'ফোন থেকে PDF খুলুন ও পড়ুন'
                          : 'Open and read PDF files on your phone',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: openPdf,
                      icon: const Icon(Icons.folder_open),
                      label: Text(
                        bn ? 'PDF খুলুন' : 'Open PDF',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                bn ? 'বর্তমান PDF' : 'Current PDF',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (pdfPath == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      bn
                          ? 'এখনো কোনো PDF নির্বাচন করা হয়নি।'
                          : 'No PDF selected yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                    title: Text(
                      pdfName ?? 'PDF',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      bn ? 'পড়তে চাপ দিন' : 'Tap to read',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(
                            path: pdfPath!,
                            name: pdfName ?? 'PDF',
                            bn: bn,
                            onShare: sharePdf,
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      onPressed: sharePdf,
                      icon: const Icon(Icons.share),
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                bn
                    ? 'PDF Reader • অফলাইনে পড়ুন'
                    : 'PDF Reader • Read offline',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String path;
  final String name;
  final bool bn;
  final VoidCallback onShare;

  const PdfViewerScreen({
    super.key,
    required this.path,
    required this.name,
    required this.bn,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: onShare,
            icon: const Icon(Icons.share),
            tooltip: bn ? 'শেয়ার' : 'Share',
          ),
        ],
      ),
      body: PdfViewer.file(
        path,
        params: const PdfViewerParams(
          enableTextSelection: true,
        ),
      ),
    );
  }
}
