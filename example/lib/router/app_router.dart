import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: RouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/board',
      name: RouteNames.board,
      builder: (context, state) {
        final bloc = FeedbackOS.instance.createBoardBloc()..add(const BoardStarted());
        return BlocProvider<BoardBloc>.value(
          value: bloc,
          child: BoardView(onBack: () => context.pop()),
        );
      },
    ),
    GoRoute(
      path: '/roadmap',
      name: RouteNames.roadmap,
      builder: (context, state) {
        final bloc = FeedbackOS.instance.createBoardBloc()..add(const RoadmapStarted());
        return BlocProvider<BoardBloc>.value(
          value: bloc,
          child: RoadmapView(onBack: () => context.pop()),
        );
      },
    ),
    GoRoute(
      path: '/my-feedback',
      name: RouteNames.myFeedback,
      builder: (context, state) {
        final bloc = FeedbackOS.instance.createThreadsBloc()..add(const MyItemsStarted());
        return BlocProvider<ThreadsBloc>.value(
          value: bloc,
          child: MyFeedbackListView(
            onBack: () => context.pop(),
            onItemTap: (id) {
              context.pushNamed(
                RouteNames.threadDetail,
                pathParameters: {'id': id},
              );
            },
          ),
        );
      },
    ),
    GoRoute(
      path: '/thread-detail/:id',
      name: RouteNames.threadDetail,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final bloc = FeedbackOS.instance.createThreadsBloc()..add(ThreadDetailStarted(id));
        return BlocProvider<ThreadsBloc>.value(
          value: bloc,
          child: ThreadDetailView(
            itemId: id,
            onBack: () => context.pop(),
          ),
        );
      },
    ),
  ],
);
