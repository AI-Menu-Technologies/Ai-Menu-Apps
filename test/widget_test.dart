import 'package:flutter_test/flutter_test.dart';
import 'package:ai_menu_apps/main.dart';

void main() {
  testWidgets('AI Menu Apps entry screen displays all main actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AiMenuApps());

    expect(find.text('AI Menu Apps'), findsOneWidget);
    expect(find.text('Выберите действие'), findsOneWidget);

    expect(find.text('Войти как гость'), findsOneWidget);

    expect(
      find.text('Войти как сотрудник заведения'),
      findsOneWidget,
    );

    expect(
      find.text('Войти как владелец заведения'),
      findsOneWidget,
    );

    expect(
      find.text('Зарегистрировать своё заведение'),
      findsOneWidget,
    );
  });
}