import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/entities/feedback_submit_result.dart';
import '../domain/entities/feedback_type.dart';
import '../domain/usecases/get_sdk_config_usecase.dart';
import 'feedback_event.dart';
import 'feedback_state.dart';

typedef FeedbackSubmitHandler = Future<FeedbackSubmitResult> Function({
  required FeedbackType type,
  required String title,
  required String description,
  String? category,
});

/// BLoC managing interactive feedback form state, validation, and submission.
class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final FeedbackSubmitHandler _submitHandler;
  final GetSdkConfigUseCase? _getConfigUseCase;
  final String? _publishableKey;

  FeedbackBloc({
    required FeedbackSubmitHandler submitHandler,
    GetSdkConfigUseCase? getConfigUseCase,
    String? publishableKey,
  })  : _submitHandler = submitHandler,
        _getConfigUseCase = getConfigUseCase,
        _publishableKey = publishableKey,
        super(const FeedbackState()) {
    on<FeedbackFormStarted>(_onStarted);
    on<FeedbackTypeChanged>(_onTypeChanged);
    on<FeedbackTitleChanged>(_onTitleChanged);
    on<FeedbackDescriptionChanged>(_onDescriptionChanged);
    on<FeedbackCategoryChanged>(_onCategoryChanged);
    on<FeedbackSubmitted>(_onSubmitted);
    on<FeedbackReset>(_onReset);
  }

  Future<void> _onStarted(
    FeedbackFormStarted event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(state.copyWith(
      status: FeedbackFormStatus.loadingConfig,
      type: event.initialType,
    ));

    List<String> categories = const [];
    if (_getConfigUseCase != null && _publishableKey != null) {
      final configResult = await _getConfigUseCase(_publishableKey);
      configResult.match(
        (failure) {}, // Silently fallback to empty categories if config fails offline
        (config) {
          categories = config.categories;
        },
      );
    }

    emit(state.copyWith(
      status: FeedbackFormStatus.ready,
      availableCategories: categories,
    ));
  }

  void _onTypeChanged(
    FeedbackTypeChanged event,
    Emitter<FeedbackState> emit,
  ) {
    emit(state.copyWith(type: event.type));
  }

  void _onTitleChanged(
    FeedbackTitleChanged event,
    Emitter<FeedbackState> emit,
  ) {
    emit(state.copyWith(title: event.title));
  }

  void _onDescriptionChanged(
    FeedbackDescriptionChanged event,
    Emitter<FeedbackState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onCategoryChanged(
    FeedbackCategoryChanged event,
    Emitter<FeedbackState> emit,
  ) {
    emit(state.copyWith(category: () => event.category));
  }

  Future<void> _onSubmitted(
    FeedbackSubmitted event,
    Emitter<FeedbackState> emit,
  ) async {
    if (!state.canSubmit) return;

    emit(state.copyWith(
      status: FeedbackFormStatus.submitting,
      errorMessage: null,
    ));

    try {
      final result = await _submitHandler(
        type: state.type,
        title: state.title.trim(),
        description: state.description.trim(),
        category: state.category,
      );

      emit(state.copyWith(
        status: FeedbackFormStatus.success,
        submissionResult: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FeedbackFormStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onReset(
    FeedbackReset event,
    Emitter<FeedbackState> emit,
  ) {
    emit(const FeedbackState());
  }
}
