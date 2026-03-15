import 'package:flutter_test/flutter_test.dart';
import 'package:ren_qing_note/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RenQingNoteApp());
    expect(find.text('流水'), findsOneWidget);
  });
}
