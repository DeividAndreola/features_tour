import 'package:features_tour/features_tour.dart';
import 'package:features_tour/src/components/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

void main() {
  setUp(() {
    resetPreDialog();
    SharedPreferences.setMockInitialValues({});
    FeaturesTour.setGlobalConfig(
      preDialogConfig: PreDialogConfig(enabled: false),
      nextConfig: NextConfig(text: 'NEXT'),
      skipConfig: SkipConfig(text: 'SKIP'),
      doneConfig: DoneConfig(text: 'DONE'),
    );
  });

  // The cover and the introduction draw above every route, so a tour whose page got covered
  // (the user opened another page while it was waiting to start) used to show over that page.
  testWidgets('A tour whose page is covered by another route stops without being marked as shown', (tester) async {
    final controller = FeaturesTourController('App');
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: App(
          tours: [
            FeaturesTour(
              index: 1,
              name: 'feature_1',
              controller: controller,
              introduce: (_, __, ___) => const Text('a.intro'),
              child: const Text('a'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(App));
    navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('other page'))));
    await tester.pumpAndSettle();

    final states = <TourState>[];
    await tester.runAsync(() => controller.start(context, delay: Duration.zero, onState: states.add));
    await tester.pump();

    expect(find.text('a.intro'), findsNothing);
    expect(states, contains(isA<TourNotCurrent>()));
    expect(await tester.runAsync(() => controller.hasBeenSeen('feature_1')), isFalse);
  });
}
