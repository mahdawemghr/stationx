import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/app/stationx_app.dart';

void main() {
  testWidgets('app boots to the landing screen', (tester) async {
    await tester.pumpWidget(const StationXApp());
    await tester.pump();
    expect(find.byType(StationXApp), findsOneWidget);
  });
}
