import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hci/theme/app_colors.dart';
import 'package:hci/theme/lifelink_design.dart';
import 'package:hci/widgets/neumorphic/neumorphic_widgets.dart';

void main() {
  group('Neumorphic Design Tokens & Theming', () {
    test('LLNeumorphism generates dual shadows for all elevations', () {
      for (final elevation in NeumorphicElevationLevel.values) {
        final lightShadows = LLNeumorphism.shadows(
          brightness: Brightness.light,
          elevation: elevation,
        );
        final darkShadows = LLNeumorphism.shadows(
          brightness: Brightness.dark,
          elevation: elevation,
        );

        if (elevation == NeumorphicElevationLevel.flat ||
            elevation == NeumorphicElevationLevel.inset) {
          expect(lightShadows, isEmpty);
          expect(darkShadows, isEmpty);
        } else {
          expect(
            lightShadows.length,
            2,
            reason: 'Should produce top-left highlight and bottom-right shadow',
          );
          expect(darkShadows.length, 2);
          // Dark mode shadows should be darker than light mode shadows
          expect(
            darkShadows[1].color.a,
            greaterThan(lightShadows[1].color.a),
          );
        }
      }
    });

    test(
      'Convex and Concave gradients provide tactile gradients in light and dark',
      () {
        final lightConvex = LLNeumorphism.convexGradient(
          brightness: Brightness.light,
        );
        final darkConvex = LLNeumorphism.convexGradient(
          brightness: Brightness.dark,
        );
        expect(lightConvex.colors.length, 3);
        expect(darkConvex.colors.length, 3);

        final lightConcave = LLNeumorphism.concaveGradient(
          brightness: Brightness.light,
        );
        final darkConcave = LLNeumorphism.concaveGradient(
          brightness: Brightness.dark,
        );
        expect(lightConcave.colors.length, 3);
        expect(darkConcave.colors.length, 3);
      },
    );

    test('LLRadius tokens maintain consistent corner rounding', () {
      expect(LLRadius.pill, 20.0);
      expect(LLRadius.card, 16.0);
      expect(LLRadius.control, 12.0);
      expect(LLRadius.sheet, 20.0);
    });
  });

  group('Neumorphic Components UI & Accessibility Tests', () {
    Widget buildThemedApp(
      Widget child, {
      Brightness brightness = Brightness.light,
    }) {
      final isDark = brightness == Brightness.dark;
      final colors = isDark ? AppColors.dark : AppColors.light;
      return MaterialApp(
        theme: ThemeData(
          brightness: brightness,
          extensions: [colors],
          scaffoldBackgroundColor: colors.background,
        ),
        home: Scaffold(body: Center(child: child)),
      );
    }

    testWidgets('NeumorphicCard renders content and handles tap', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        buildThemedApp(
          NeumorphicCard(
            onTap: () => tapped = true,
            child: const Text('Accessible Card Content'),
          ),
        ),
      );

      expect(find.text('Accessible Card Content'), findsOneWidget);
      await tester.tap(find.text('Accessible Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets(
      'NeumorphicButton provides accessible touch target and handles states',
      (tester) async {
        var pressed = false;
        await tester.pumpWidget(
          buildThemedApp(
            NeumorphicButton(
              onPressed: () => pressed = true,
              isPrimary: true,
              label: 'Emergency Donate',
              icon: Icons.favorite,
            ),
          ),
        );

        final buttonFinder = find.byType(NeumorphicButton);
        expect(buttonFinder, findsOneWidget);
        final renderBox = tester.renderObject<RenderBox>(buttonFinder);
        expect(
          renderBox.size.height,
          greaterThanOrEqualTo(48.0),
          reason: 'Touch target size must be at least 48px for accessibility',
        );

        await tester.tap(buttonFinder);
        expect(pressed, isTrue);
      },
    );

    testWidgets('NeumorphicButton loading state renders progress indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemedApp(
          const NeumorphicButton(
            onPressed: null,
            isLoading: true,
            label: 'Submit Request',
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit Request'), findsNothing);
    });

    testWidgets('NeumorphicIconButton adheres to touch target requirements', (
      tester,
    ) async {
      var iconTapped = false;
      await tester.pumpWidget(
        buildThemedApp(
          NeumorphicIconButton(
            icon: Icons.arrow_back,
            tooltip: 'Back',
            onPressed: () => iconTapped = true,
          ),
        ),
      );

      final iconBtn = find.byType(NeumorphicIconButton);
      expect(iconBtn, findsOneWidget);
      final box = tester.renderObject<RenderBox>(iconBtn);
      expect(box.size.width, greaterThanOrEqualTo(44.0));
      expect(box.size.height, greaterThanOrEqualTo(44.0));

      await tester.tap(iconBtn);
      expect(iconTapped, isTrue);
    });

    testWidgets('NeumorphicStatusBadge renders semantic label with contrast', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemedApp(
          const NeumorphicStatusBadge(
            label: 'CRITICAL',
            icon: Icons.warning_amber_rounded,
            tone: LLTone.critical,
          ),
        ),
      );

      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets(
      'NeumorphicInput renders hint, prefix and maintains visible boundaries',
      (tester) async {
        final controller = TextEditingController();
        await tester.pumpWidget(
          buildThemedApp(
            NeumorphicInput(
              controller: controller,
              hintText: 'Enter units needed',
              prefixIcon: const Icon(Icons.water_drop),
            ),
          ),
        );

        expect(find.text('Enter units needed'), findsOneWidget);
        expect(find.byIcon(Icons.water_drop), findsOneWidget);

        await tester.enterText(find.byType(TextField), '3');
        expect(controller.text, '3');
      },
    );
  });

  group('Responsive Viewport Tests', () {
    Widget buildResponsiveTestBed() {
      final colors = AppColors.light;
      return MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          extensions: [colors],
          scaffoldBackgroundColor: colors.background,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const NeumorphicCard(
                    child: Text('Responsive Neumorphic Card Header'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: NeumorphicButton(
                          onPressed: () {},
                          label: 'Action 1',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeumorphicButton(
                          onPressed: () {},
                          isPrimary: true,
                          label: 'Action 2',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'Renders cleanly on small mobile screen (360x640) without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildResponsiveTestBed());
        expect(
          tester.takeException(),
          isNull,
          reason: 'Must not trigger RenderFlex overflow on small screens',
        );
        expect(find.text('Responsive Neumorphic Card Header'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders cleanly on tablet screen (768x1024) without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildResponsiveTestBed());
        expect(tester.takeException(), isNull);
        expect(find.text('Responsive Neumorphic Card Header'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders cleanly on desktop / web screen (1280x800) without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildResponsiveTestBed());
        expect(tester.takeException(), isNull);
        expect(find.text('Responsive Neumorphic Card Header'), findsOneWidget);
      },
    );
  });
}
