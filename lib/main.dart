import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() => runApp(const OpenMedicalApp());

class OpenMedicalApp extends StatelessWidget {
  const OpenMedicalApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Open Medical',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const HomeScreen(),
      );
}

// NOTE: Ye sirf sample ranges hain. Asli app me verified ranges
// (age/gender ke hisab se) ek JSON file me rakhein.
class TestRange {
  final String name;
  final double low, high;
  final String unit;
  const TestRange(this.name, this.low, this.high, this.unit);
}

const ranges = [
  TestRange('Hemoglobin', 12, 17.5, 'g/dL'),
  TestRange('Glucose', 70, 100, 'mg/dL'),
  TestRange('Cholesterol', 0, 200, 'mg/dL'),
  TestRange('TSH', 0.4, 4.0, 'mIU/L'),
];

class Result {
  final TestRange test;
  final double value;
  Result(this.test, this.value);

  String get status => value < test.low
      ? 'Low'
      : value > test.high
          ? 'High'
          : 'Normal';
}

List<Result> analyze(String text) {
  final out = <Result>[];
  for (final line in text.split('\n')) {
    final lower = line.toLowerCase();
    for (final t in ranges) {
      final i = lower.indexOf(t.name.toLowerCase());
      if (i == -1) continue;
      final m = RegExp(r'\d+(\.\d+)?')
          .firstMatch(line.substring(i + t.name.length));
      if (m != null) out.add(Result(t, double.parse(m.group(0)!)));
    }
  }
  return out;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  final _ocr = TextRecognizer(script: TextRecognitionScript.latin);
  List<Result> results = [];
  bool loading = false;
  bool scanned = false;

  Future<void> _scan(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    if (file == null) return;
    setState(() => loading = true);
    final text = await _ocr.processImage(InputImage.fromFilePath(file.path));
    setState(() {
      results = analyze(text.text);
      loading = false;
      scanned = true;
    });
  }

  @override
  void dispose() {
    _ocr.close();
    super.dispose();
  }

  Color _color(String s) => s == 'Normal'
      ? Colors.green
      : s == 'High'
          ? Colors.red
          : Colors.orange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Medical')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _scan(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _scan(ImageSource.gallery),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (loading) const LinearProgressIndicator(),
            if (scanned && results.isEmpty && !loading)
              const Text('Koi known test nahi mila. Saaf photo try karein.'),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (_, i) {
                  final r = results[i];
                  return Card(
                    child: ListTile(
                      title: Text(r.test.name),
                      subtitle: Text(
                          '${r.value} ${r.test.unit}  (Normal: ${r.test.low}-${r.test.high})'),
                      trailing: Chip(
                        label: Text(r.status),
                        backgroundColor: _color(r.status).withOpacity(0.2),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Text(
              'Ye sirf jaankari ke liye hai, diagnosis nahi. Doctor se zaroor milein.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
