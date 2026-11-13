import 'package:features_tour/features_tour.dart';
import 'package:features_tour/src/components/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _screen = Size(400, 600);
const _cardKey = Key('card');

typedef _Placed = ({QuadrantAlignment? side, Rect card});

/// Pumps a target [targetTop] px from the top and starts the tour, whose card is [cardHeight] tall
/// and asks for [quadrant]. Returns the side the card ended up on and where it was painted.
Future<_Placed> _start(
  WidgetTester tester, {
  required double targetTop,
  required double cardHeight,
  required QuadrantAlignment quadrant,
  FakeViewPadding safeArea = FakeViewPadding.zero,
  bool stripMediaQueryPadding = false,
}) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  tester.view.viewPadding = safeArea;
  tester.view.padding = safeArea;
  addTearDown(tester.view.reset);

  final controller = FeaturesTourController('App');
  QuadrantAlignment? side;
  Rect? card;

  await tester.pumpWidget(
    MaterialApp(
      builder: stripMediaQueryPadding
          ? (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero),
              child: child!,
            )
          : null,
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.only(top: targetTop),
          child: FeaturesTour(
            index: 1,
            name: 'target',
            controller: controller,
            // Without the pulsing highlight nothing else asks for frames, as on a still screen.
            childConfig: ChildConfig(enableAnimation: false),
            introduceConfig: IntroduceConfig(
              quadrantAlignment: quadrant,
              alignment: quadrant == QuadrantAlignment.bottom ? Alignment.topCenter : Alignment.bottomCenter,
              padding: EdgeInsets.zero,
            ),
            introduce: (_, _, _) => Builder(
              builder: (context) {
                side = FeaturesTourPlacement.maybeOf(context);

                return SizedBox(key: _cardKey, width: 300, height: cardHeight);
              },
            ),
            child: const SizedBox(width: 300, height: 40),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final context = tester.element(find.byType(Scaffold));
  await tester.runAsync(
    () => controller.start(
      context,
      force: true,
      delay: Duration.zero,
      onState: (state) async {
        if (state is! TourIntroducing) {
          return;
        }

        for (var i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        card = tester.getRect(find.byKey(_cardKey));
        controller.done();
      },
    ),
  );
  await tester.pumpAndSettle();

  return (side: side, card: card!);
}

void main() {
  setUp(() {
    resetPreDialog();
    SharedPreferences.setMockInitialValues({});
    FeaturesTour.setGlobalConfig(
      preDialogConfig: PreDialogConfig(enabled: false),
      nextConfig: NextConfig(enabled: false),
      skipConfig: SkipConfig(enabled: false),
      doneConfig: DoneConfig(enabled: false),
    );
  });

  // A fixed quadrant used to push the card off a short screen: below a low target there was not
  // enough room, the card overflowed the bottom edge and its buttons could not be reached.
  group('requested side', () {
    testWidgets('flips to the other side when the card does not fit and the other side is taller', (tester) async {
      // Target 380..420: 180 below, 380 above; a 300 card only fits above.
      final (:side, :card) = await _start(tester, targetTop: 380, cardHeight: 300, quadrant: QuadrantAlignment.bottom);

      expect(side, QuadrantAlignment.top);
      expect(card.bottom, lessThanOrEqualTo(380));
      expect(card.top, greaterThanOrEqualTo(0));
    });

    testWidgets('flips a top card down the same way', (tester) async {
      // Target 100..140: 100 above, 460 below.
      final (:side, :card) = await _start(tester, targetTop: 100, cardHeight: 300, quadrant: QuadrantAlignment.top);

      expect(side, QuadrantAlignment.bottom);
      expect(card.top, greaterThanOrEqualTo(140));
      expect(card.bottom, lessThanOrEqualTo(_screen.height));
    });

    testWidgets('flips when the card is a pixel too tall', (tester) async {
      final (:side, card: _) = await _start(tester, targetTop: 380, cardHeight: 181, quadrant: QuadrantAlignment.bottom);

      expect(side, QuadrantAlignment.top);
    });

    testWidgets('stays when the card fits', (tester) async {
      final (:side, :card) = await _start(tester, targetTop: 380, cardHeight: 170, quadrant: QuadrantAlignment.bottom);

      expect(side, QuadrantAlignment.bottom);
      expect(card.top, greaterThanOrEqualTo(420));
    });

    testWidgets('stays when the card fits exactly', (tester) async {
      final (:side, card: _) = await _start(tester, targetTop: 380, cardHeight: 180, quadrant: QuadrantAlignment.bottom);

      expect(side, QuadrantAlignment.bottom);
    });

    testWidgets('stays when the other side is no taller', (tester) async {
      // Target 200..240: 360 below, 200 above; the 400 card fits nowhere, the requested side is still the best.
      final (:side, card: _) = await _start(tester, targetTop: 200, cardHeight: 400, quadrant: QuadrantAlignment.bottom);

      expect(side, QuadrantAlignment.bottom);
    });
  });

  // The status bar and the navigation bar cover the screen's edges: a card laid out under them has
  // its title or its buttons hidden.
  group('safe area', () {
    const safeArea = FakeViewPadding(top: 40, bottom: 30);

    testWidgets('a card above the child stays below the status bar', (tester) async {
      // Target 380..420: 340 above (under a 40 bar), 150 below (over a 30 bar).
      final (:side, :card) = await _start(tester, targetTop: 380, cardHeight: 300, quadrant: QuadrantAlignment.bottom, safeArea: safeArea);

      expect(side, QuadrantAlignment.top);
      expect(card.top, greaterThanOrEqualTo(40));
      expect(card.bottom, lessThanOrEqualTo(380));
    });

    testWidgets('a card under the child stays above the navigation bar', (tester) async {
      // Target 100..140: 430 below the child before the bar; 300 fits.
      final (:side, :card) = await _start(tester, targetTop: 100, cardHeight: 300, quadrant: QuadrantAlignment.bottom, safeArea: safeArea);

      expect(side, QuadrantAlignment.bottom);
      expect(card.bottom, lessThanOrEqualTo(_screen.height - 30));
    });

    testWidgets('the room under the bars does not count as room to fit', (tester) async {
      // 170 would fit in the 180 below the child, but only 150 is above the navigation bar.
      final (:side, card: _) = await _start(tester, targetTop: 380, cardHeight: 170, quadrant: QuadrantAlignment.bottom, safeArea: safeArea);

      expect(side, QuadrantAlignment.top);
    });

    // A tour on a nested navigator sits under a Scaffold body, whose MediaQuery has no top
    // padding; the bars are still there.
    testWidgets('reads the bars from the screen, not from a MediaQuery without padding', (tester) async {
      final (:side, :card) = await _start(
        tester,
        targetTop: 380,
        cardHeight: 500,
        quadrant: QuadrantAlignment.bottom,
        safeArea: safeArea,
        stripMediaQueryPadding: true,
      );

      expect(side, QuadrantAlignment.top);
      expect(card.top, greaterThanOrEqualTo(40));
    });

    testWidgets('a card taller than every side is capped inside the safe area', (tester) async {
      // 340 above is the taller side; the 500 card is cut to it, not to the screen's top.
      final (:side, :card) = await _start(tester, targetTop: 380, cardHeight: 500, quadrant: QuadrantAlignment.bottom, safeArea: safeArea);

      expect(side, QuadrantAlignment.top);
      expect(card.top, greaterThanOrEqualTo(40));
    });
  });
}
