// Малює PNG для іконки застосунку й нативного splash з того самого логотипа,
// що в застосунку (LogoMark). Запуск: flutter test tool/render_icons_test.dart
// Після цього: dart run flutter_launcher_icons && dart run flutter_native_splash:create
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teachlog/ui/widgets/logo.dart';

const _lavender = Color(0xFFEFE9FD);

Future<void> _render(WidgetTester tester, String path, double size, Widget child) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Center(
      child: RepaintBoundary(
        key: key,
        child: SizedBox.square(dimension: size, child: child),
      ),
    ),
  );
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('render icons', (tester) async {
    tester.view.physicalSize = const Size(1100, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Повна іконка (iOS і старі Android): лавандове тло + значок.
    await _render(
      tester,
      'assets/icon/icon.png',
      1024,
      const ColoredBox(
        color: _lavender,
        child: Center(child: LogoMark(size: 700)),
      ),
    );

    // Передній шар адаптивної іконки Android: значок у безпечній зоні (66%);
    // flutter_launcher_icons ще додає відступ 16%, тому значок великий.
    await _render(tester, 'assets/icon/foreground.png', 1024, const Center(child: LogoMark(size: 780)));

    // Нативний splash: значок на білій картці, як на Flutter-splash.
    await _render(
      tester,
      'assets/splash/splash_logo.png',
      512,
      Center(
        child: Container(
          width: 360,
          height: 360,
          padding: const EdgeInsets.all(54),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(84)),
          child: const LogoMark(size: 252),
        ),
      ),
    );

    // Android 12+: система сама кладе біле коло 640px, значок має вміститися в нього.
    await _render(tester, 'assets/splash/splash_android12.png', 960, const Center(child: LogoMark(size: 420)));

    // Web: значок вкладки й PWA без фону. Малюнок займає ~81% LogoMark, тож
    // збільшуємо його, щоб два вікна заповнили весь квадрат.
    for (final (path, size) in [('web/favicon.png', 64.0), ('web/icons/Icon-192.png', 192.0), ('web/icons/Icon-512.png', 512.0)]) {
      await _render(
        tester,
        path,
        size,
        OverflowBox(maxWidth: double.infinity, maxHeight: double.infinity, child: LogoMark(size: size / .8)),
      );
    }
  });
}
