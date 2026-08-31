import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muses/features/library/widgets/album_art.dart';

/// Regression test for squished album art in the queue page / mini player.
///
/// Root cause: Image.memory/Image.file with BOTH cacheWidth and cacheHeight
/// decode through ResizeImage with the default ResizeImagePolicy.exact,
/// which rescales the bitmap to exactly WxH (like BoxFit.fill). Non-square
/// art (e.g. 100x60) gets stretched at the pixel level, so the later
/// BoxFit.cover has nothing to crop -> visible squish.
///
/// Fix: AlbumArt now decodes via ResizeImagePolicy.fit, which preserves the
/// source aspect ratio, so BoxFit.cover crops instead of stretching.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AlbumArt crops non-square art instead of squishing it',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    // 100x60 source: white circle (d=60, full height) centered on black.
    final ui.Image art = _makeArt();
    final pngBytes = (await tester.runAsync(
          () => art.toByteData(format: ui.ImageByteFormat.png),
        ))!
        .buffer
        .asUint8List();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: RepaintBoundary(
              key: const Key('art-boundary'),
              child: AlbumArt(artwork: pngBytes, size: 48),
            ),
          ),
        ),
      ),
    );

    // Pre-warm the exact provider AlbumArt builds (48px * dpr=1.0), so the
    // image is decoded and painted deterministically.
    final element = tester.element(find.byType(AlbumArt));
    await tester.runAsync(() => precacheImage(
          ResizeImage(
            MemoryImage(pngBytes),
            width: 48,
            height: 48,
            policy: ResizeImagePolicy.fit,
          ),
          element,
        ));
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('art-boundary')),
    );
    final ui.Image rendered = (await tester.runAsync(
      () => boundary.toImage(pixelRatio: 1.0),
    ))!;
    final byteData = (await tester.runAsync(
      () => rendered.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    final bytes = byteData.buffer.asUint8List();
    const side = 48;

    bool isWhite(int x, int y) {
      final i = (y * side + x) * 4;
      return bytes[i] > 128 && bytes[i + 1] > 128 && bytes[i + 2] > 128;
    }

    // Measure the drawn circle's width (middle row) and height (middle col).
    final drawnWidth =
        List.generate(side, (x) => isWhite(x, side ~/ 2)).where((w) => w).length;
    final drawnHeight =
        List.generate(side, (y) => isWhite(side ~/ 2, y)).where((w) => w).length;

    // Sanity: the art actually rendered (not an all-black/placeholder frame).
    expect(drawnWidth, greaterThan(10), reason: 'artwork should have painted');
    expect(drawnHeight, greaterThan(10), reason: 'artwork should have painted');

    final ratio = drawnWidth / drawnHeight;
    // Squished (exact-policy) render gives ~0.6; a proper center-crop of the
    // circle is ~1.0 (allow a couple of anti-aliased edge pixels).
    expect(ratio, closeTo(1.0, 0.06),
        reason: 'circle should be drawn square (cropped), not squished '
            '(drawn ${drawnWidth}x$drawnHeight)');
    expect(drawnWidth, greaterThanOrEqualTo(side - 3),
        reason: 'circle should fill the box width after cover-crop');
  });

  testWidgets('ResizeImage fit policy preserves aspect; exact does not',
      (tester) async {
    final ui.Image art = _makeArt();
    final pngBytes = (await tester.runAsync(
          () => art.toByteData(format: ui.ImageByteFormat.png),
        ))!
        .buffer
        .asUint8List();

    Future<ui.Image> decode(ResizeImagePolicy policy) async {
      final provider = ResizeImage(
        MemoryImage(pngBytes),
        width: 48,
        height: 48,
        policy: policy,
      );
      final completer = Completer<ui.Image>();
      final stream = provider.resolve(const ImageConfiguration());
      late ImageStreamListener listener;
      listener = ImageStreamListener((info, sync) {
        completer.complete(info.image.clone());
      }, onError: (e, s) => completer.completeError(e, s));
      stream.addListener(listener);
      final image = await completer.future;
      stream.removeListener(listener);
      return image;
    }

    final ui.Image exact = (await tester.runAsync(() => decode(ResizeImagePolicy.exact)))!;
    final ui.Image fit = (await tester.runAsync(() => decode(ResizeImagePolicy.fit)))!;

    // exact: forced square decode of a 100x60 source = the squish.
    expect(exact.width, 48);
    expect(exact.height, 48);
    // fit: aspect-preserved decode (100:60 -> 48:28.8).
    expect(fit.width, 48);
    expect(fit.height, closeTo(48 * 60 / 100, 1.0));
  });
}

ui.Image _makeArt() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 100, 60),
    Paint()..color = const Color(0xFF000000),
  );
  canvas.drawCircle(const Offset(50, 30), 30, Paint()..color = const Color(0xFFFFFFFF));
  return recorder.endRecording().toImageSync(100, 60);
}
