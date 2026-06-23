import 'package:flutter_test/flutter_test.dart';
import 'package:ofg_mobile/main.dart';

void main() {
  testWidgets('OFG app boots into the splash experience', (tester) async {
    await tester.pumpWidget(const OfgApp());

    expect(find.text('OFG'), findsOneWidget);
    expect(find.text('CONNECTS'), findsOneWidget);
  });
}
