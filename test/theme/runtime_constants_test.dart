import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/get_board_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/get_roadmap_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/unvote_item_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/vote_item_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBoardUseCase extends Mock implements GetBoardUseCase {}

class MockGetRoadmapUseCase extends Mock implements GetRoadmapUseCase {}

class MockVoteItemUseCase extends Mock implements VoteItemUseCase {}

class MockUnvoteItemUseCase extends Mock implements UnvoteItemUseCase {}

void main() {
  group('FeedbackOSTheme Runtime Constants', () {
    test('default constructor provides fallback colors for all properties', () {
      const theme = FeedbackOSTheme();

      expect(theme.primaryColor, equals(FeedbackOSTheme.defaultPrimaryColor));
      expect(theme.primaryLightColor,
          equals(FeedbackOSTheme.defaultPrimaryLightColor));
      expect(theme.primaryDarkColor,
          equals(FeedbackOSTheme.defaultPrimaryDarkColor));
      expect(theme.onPrimaryColor, equals(FeedbackOSTheme.defaultOnPrimaryColor));
      expect(theme.backgroundColor,
          equals(FeedbackOSTheme.defaultBackgroundColor));
      expect(theme.surfaceColor, equals(FeedbackOSTheme.defaultSurfaceColor));
      expect(theme.secondaryBackgroundColor,
          equals(FeedbackOSTheme.defaultSecondaryBackgroundColor));
      expect(theme.borderColor, equals(FeedbackOSTheme.defaultBorderColor));
      expect(theme.borderMutedColor,
          equals(FeedbackOSTheme.defaultBorderMutedColor));
      expect(theme.titleColor, equals(FeedbackOSTheme.defaultTitleColor));
      expect(theme.textColor, equals(FeedbackOSTheme.defaultTextColor));
      expect(theme.secondaryTextColor,
          equals(FeedbackOSTheme.defaultSecondaryTextColor));
      expect(
          theme.mutedTextColor, equals(FeedbackOSTheme.defaultMutedTextColor));
      expect(theme.placeholderColor,
          equals(FeedbackOSTheme.defaultPlaceholderColor));
      expect(theme.errorColor, equals(FeedbackOSTheme.defaultErrorColor));
      expect(theme.errorBackgroundColor,
          equals(FeedbackOSTheme.defaultErrorBackgroundColor));
      expect(theme.successColor, equals(FeedbackOSTheme.defaultSuccessColor));
      expect(theme.successBackgroundColor,
          equals(FeedbackOSTheme.defaultSuccessBackgroundColor));
      expect(theme.warningColor, equals(FeedbackOSTheme.defaultWarningColor));
      expect(theme.warningBackgroundColor,
          equals(FeedbackOSTheme.defaultWarningBackgroundColor));
      expect(theme.infoColor, equals(FeedbackOSTheme.defaultInfoColor));
      expect(theme.infoBackgroundColor,
          equals(FeedbackOSTheme.defaultInfoBackgroundColor));
      expect(theme.buttonColor, equals(FeedbackOSTheme.defaultButtonColor));
      expect(theme.disabledButtonColor,
          equals(FeedbackOSTheme.defaultDisabledButtonColor));
    });

    test('no color is forced: user can override specific colors and fallbacks remain intact', () {
      const customTheme = FeedbackOSTheme(
        primaryColor: Colors.purple,
        backgroundColor: Colors.black,
      );

      // User-defined
      expect(customTheme.primaryColor, equals(Colors.purple));
      expect(customTheme.backgroundColor, equals(Colors.black));
      // Fallback
      expect(customTheme.surfaceColor,
          equals(FeedbackOSTheme.defaultSurfaceColor));
      expect(customTheme.errorColor, equals(FeedbackOSTheme.defaultErrorColor));
      expect(customTheme.borderColor,
          equals(FeedbackOSTheme.defaultBorderColor));
    });

    test('predefined dark factory sets dark palette', () {
      final dark = FeedbackOSTheme.dark();
      expect(dark.backgroundColor, equals(const Color(0xFF111827)));
      expect(dark.surfaceColor, equals(const Color(0xFF1F2937)));
      expect(dark.titleColor, equals(const Color(0xFFF9FAFB)));
    });

    test('fromTheme factory extracts colors from Flutter ThemeData', () {
      final flutterTheme = ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.amber,
          surface: Colors.grey,
        ),
      );
      final derived = FeedbackOSTheme.fromTheme(flutterTheme);
      expect(derived.primaryColor, equals(Colors.amber));
      expect(derived.backgroundColor, equals(Colors.grey));
    });

    test('statusBackgroundColor and statusForegroundColor map correctly', () {
      const theme = FeedbackOSTheme();

      expect(theme.statusBackgroundColor('planned'),
          equals(theme.warningBackgroundColor));
      expect(theme.statusForegroundColor('planned'),
          equals(theme.warningColor));

      expect(theme.statusBackgroundColor('in_progress'),
          equals(theme.infoBackgroundColor));
      expect(theme.statusForegroundColor('in_progress'),
          equals(theme.infoColor));

      expect(theme.statusBackgroundColor('shipped'),
          equals(theme.successBackgroundColor));
      expect(theme.statusForegroundColor('shipped'),
          equals(theme.successColor));

      expect(theme.statusBackgroundColor('unknown'),
          equals(theme.secondaryBackgroundColor));
      expect(theme.statusForegroundColor('unknown'),
          equals(theme.secondaryTextColor));
    });

    test('copyWith updates specified fields', () {
      const theme = FeedbackOSTheme();
      final updated = theme.copyWith(primaryColor: Colors.cyan);

      expect(updated.primaryColor, equals(Colors.cyan));
      expect(updated.backgroundColor, equals(theme.backgroundColor));
    });

    testWidgets('FeedbackOSTheme.of reads from FeedbackOSThemeProvider in widget tree',
        (tester) async {
      const customTheme = FeedbackOSTheme(primaryColor: Colors.orange);
      FeedbackOSTheme? resolvedTheme;

      await tester.pumpWidget(
        FeedbackOSThemeProvider(
          theme: customTheme,
          child: Builder(
            builder: (context) {
              resolvedTheme = FeedbackOSTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedTheme?.primaryColor, equals(Colors.orange));
    });

    testWidgets('FeedbackOSTheme.of falls back to FeedbackOSTheme.current when unprovided',
        (tester) async {
      FeedbackOSTheme? resolvedTheme;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            resolvedTheme = FeedbackOSTheme.of(context);
            return const SizedBox();
          },
        ),
      );

      expect(resolvedTheme, equals(const FeedbackOSTheme()));
    });

    testWidgets('propagates user-defined colors to painted BoardView widgets',
        (tester) async {
      const customTheme = FeedbackOSTheme(
        backgroundColor: Color(0xFF010203),
        surfaceColor: Color(0xFF112233),
      );

      final mockGetBoard = MockGetBoardUseCase();
      final mockGetRoadmap = MockGetRoadmapUseCase();
      final mockVote = MockVoteItemUseCase();
      final mockUnvote = MockUnvoteItemUseCase();

      when(() => mockGetBoard(
            sort: any(named: 'sort'),
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => const Right(BoardPage(items: [])),
      );

      final bloc = BoardBloc(
        getBoardUseCase: mockGetBoard,
        getRoadmapUseCase: mockGetRoadmap,
        voteItemUseCase: mockVote,
        unvoteItemUseCase: mockUnvote,
        initialState: const BoardState(
          status: BoardStatus.success,
          items: [],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FeedbackOSThemeProvider(
            theme: customTheme,
            child: BlocProvider<BoardBloc>.value(
              value: bloc,
              child: const BoardView(),
            ),
          ),
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF010203)));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(const Color(0xFF112233)));
    });

    test('FeedbackOS setTheme and switchTheme helpers work on demand', () {
      final fos = FeedbackOS.instance;
      fos.setTheme(FeedbackOSTheme.light());
      expect(fos.theme.isDark, isFalse);

      // Switch to dark
      fos.switchTheme(isDark: true);
      expect(fos.theme.isDark, isTrue);

      // Switch to light
      fos.switchTheme(isDark: false);
      expect(fos.theme.isDark, isFalse);

      // Toggle from light to dark
      fos.switchTheme();
      expect(fos.theme.isDark, isTrue);

      // Toggle from dark to light
      fos.switchTheme();
      expect(fos.theme.isDark, isFalse);

      // Custom themes
      const customLight = FeedbackOSTheme(primaryColor: Colors.yellow);
      const customDark = FeedbackOSTheme(
        primaryColor: Colors.indigo,
        backgroundColor: Colors.black,
      );

      fos.switchTheme(
        isDark: true,
        lightTheme: customLight,
        darkTheme: customDark,
      );
      expect(fos.theme.primaryColor, equals(Colors.indigo));
      expect(fos.theme.backgroundColor, equals(Colors.black));

      fos.switchTheme(
        isDark: false,
        lightTheme: customLight,
        darkTheme: customDark,
      );
      expect(fos.theme.primaryColor, equals(Colors.yellow));

      // Direct theme override
      const customDirect = FeedbackOSTheme(primaryColor: Colors.teal);
      fos.switchTheme(theme: customDirect);
      expect(fos.theme.primaryColor, equals(Colors.teal));
    });
  });
}
