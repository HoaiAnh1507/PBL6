/*
How To Generate And Convert

- Generate test results JSONL with UTF-8 encoding on Windows PowerShell:
  - flutter test --machine | Out-File -FilePath test_results.jsonl -Encoding utf8
- Convert to CSV:
  - dart run tool/test_results_to_csv.dart test_results.jsonl test_results.csv
*/
import 'dart:convert';
import 'dart:io';

class _TestInfo {
  int id;
  String name;
  int suiteId;
  int? startTime;
  int? endTime;
  String result;
  bool skipped;
  _TestInfo({
    required this.id,
    required this.name,
    required this.suiteId,
    this.startTime,
    this.endTime,
    this.result = '',
    this.skipped = false,
  });
}

void main(List<String> args) {
  final inputPath = args.isNotEmpty ? args[0] : 'test_results.jsonl';
  final outputPath = args.length > 1 ? args[1] : 'test_results.csv';

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Input file not found: $inputPath');
    exit(1);
  }

  List<String> lines;
  try {
    final bytes = inputFile.readAsBytesSync();
    final content = const Utf8Decoder(allowMalformed: true).convert(bytes);
    lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
  } catch (e) {
    stderr.writeln('Failed to read input file: $e');
    exit(2);
  }
  final Map<int, String> suitePaths = {};
  final Map<int, _TestInfo> tests = {};

  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    dynamic obj;
    try {
      obj = jsonDecode(line);
    } catch (_) {
      continue;
    }
    if (obj is! Map) continue;

    final type = obj['type']?.toString();
    final time = obj['time'] is num ? (obj['time'] as num).toInt() : null;

    if (type == 'suite') {
      final suite = obj['suite'];
      if (suite is Map) {
        final id = suite['id'];
        final path = suite['path'];
        if (id is num && path is String) {
          suitePaths[id.toInt()] = path;
        }
      }
      continue;
    }

    if (type == 'testStart') {
      final test = obj['test'];
      if (test is Map) {
        final id = test['id'];
        final name = test['name'];
        final suiteID = test['suiteID'];
        if (id is num && name is String && suiteID is num) {
          tests[id.toInt()] = _TestInfo(
            id: id.toInt(),
            name: name,
            suiteId: suiteID.toInt(),
            startTime: time,
          );
        }
      }
      continue;
    }

    if (type == 'testDone') {
      final id = obj['testID'];
      if (id is num) {
        final info = tests[id.toInt()];
        if (info != null) {
          info.endTime = time;
          info.result = obj['result']?.toString() ?? info.result;
          final skipped = obj['skipped'];
          info.skipped = skipped == true;
        }
      }
      continue;
    }
  }

  final out = StringBuffer();
  out.writeln('suite_path,test_name,result,skipped,duration_ms');
  for (final info in tests.values) {
    final path = suitePaths[info.suiteId] ?? '';
    int duration = 0;
    if (info.startTime != null && info.endTime != null) {
      duration = info.endTime! - info.startTime!;
    }
    final escapedName = info.name.replaceAll('"', '""');
    final escapedPath = path.replaceAll('"', '""');
    out.writeln('"$escapedPath","$escapedName",${info.result},${info.skipped},$duration');
  }

  File(outputPath).writeAsStringSync(out.toString());
  stdout.writeln('Wrote CSV: $outputPath');
}