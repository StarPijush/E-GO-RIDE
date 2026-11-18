import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_go/app/theme/index.dart';

Future<void> _loadFonts() async {
  await _loadFontFamily('Poppins', const [
    'assets/fonts/Poppins-Regular.ttf',
    'assets/fonts/Poppins-Medium.ttf',
    'assets/fonts/Poppins-SemiBold.ttf',
    'assets/fonts/Poppins-Bold.ttf',
    'assets/fonts/Poppins-ExtraBold.ttf',
  ]);
  await _loadFontFamily('Inter', const [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
}

Future<void> _loadFontFamily(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    final bytes = await File(asset).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

class _FoundationPreview extends StatelessWidget {
  const _FoundationPreview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('E-GO')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EGoSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move your way',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: EGoSpacing.sm),
              Text(
                'Phase 1 design system foundation',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: EGoColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: EGoSpacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(EGoSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poppins for headings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: EGoSpacing.xs),
                      Text(
                        'Inter for body, inputs, buttons, and navigation.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: EGoSpacing.lg),
                      const Row(
                        children: [
                          _ColorSwatch(
                            color: EGoColors.brandPrimary,
                            label: 'Yellow',
                          ),
                          SizedBox(width: EGoSpacing.lg),
                          _ColorSwatch(
                            color: EGoColors.brandBackground,
                            label: 'Canvas',
                            border: true,
                          ),
                          SizedBox(width: EGoSpacing.lg),
                          _ColorSwatch(
                            color: EGoColors.brandNavy,
                            label: 'Navy',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: EGoSpacing.lg),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  hintText: '98765 43210',
                ),
              ),
              const SizedBox(height: EGoSpacing.md),
              const Wrap(
                spacing: EGoSpacing.sm,
                runSpacing: EGoSpacing.sm,
                children: [
                  _StatusPill(
                    label: 'Success',
                    foreground: EGoColors.success,
                    background: EGoColors.successLight,
                  ),
                  _StatusPill(
                    label: 'Warning',
                    foreground: EGoColors.warning,
                    background: EGoColors.warningLight,
                  ),
                  _StatusPill(
                    label: 'Error',
                    foreground: EGoColors.error,
                    background: EGoColors.errorLight,
                  ),
                  _StatusPill(
                    label: 'Info',
                    foreground: EGoColors.info,
                    background: EGoColors.infoLight,
                  ),
                ],
              ),
              const SizedBox(height: EGoSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: EGoSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.label,
    this.border = false,
  });

  final Color color;
  final String label;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: EGoSpacing.xxxl,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(EGoSpacing.radiusMedium),
              border: border
                  ? Border.all(color: EGoColors.outlineVariant)
                  : null,
            ),
          ),
          const SizedBox(height: EGoSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EGoSpacing.md,
        vertical: EGoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(EGoSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

Future<void> _captureScreen({
  required WidgetTester tester,
  required Size logicalSize,
  required String outputPath,
}) async {
  await tester.runAsync(_loadFonts);

  const pixelRatio = 2.0;
  tester.view.physicalSize = logicalSize * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(() => tester.view.resetPhysicalSize());

  final repaintKey = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: EGoTheme.light,
      home: MediaQuery(
        data: MediaQueryData(size: logicalSize),
        child: RepaintBoundary(
          key: repaintKey,
          child: SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: const _FoundationPreview(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.runAsync(() async {
    final boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    expect(file.existsSync(), isTrue);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures the design system foundation at 393x852', (
    tester,
  ) async {
    await _captureScreen(
      tester: tester,
      logicalSize: const Size(393, 852),
      outputPath: 'test/screenshots/design_system_foundation_393x852.png',
    );
  });

  testWidgets('captures the design system foundation at 375x667', (
    tester,
  ) async {
    await _captureScreen(
      tester: tester,
      logicalSize: const Size(375, 667),
      outputPath: 'test/screenshots/design_system_foundation_375x667.png',
    );
  });
}
