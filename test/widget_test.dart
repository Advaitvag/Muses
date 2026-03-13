// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muses/core/di.dart';
import 'package:muses/core/audio/audio_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muses/features/theme/theme_bloc.dart';
import 'package:muses/main.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockStorage extends Mock implements Storage {}
class MockAudioHandler extends Mock implements MusesAudioHandler {}
class MockAudioPlayer extends Mock implements AudioPlayer {
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<PlaybackEvent> get playbackEventStream => const Stream.empty();
  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
}

void main() {
  late Storage storage;

  setUp(() {
    storage = MockStorage();
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    
    PathProviderPlatform.instance = FakePathProviderPlatform();
    
    // Setup DI for tests
    getIt.reset();
    setupDI(ThemeBloc(), MockAudioHandler(), MockAudioPlayer());
  });

  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MusesApp());

    // Verify that the app starts (just a basic check since it's a complex app)
    expect(find.byType(MusesApp), findsOneWidget);
  });
}
