/// Type of feedback submission supported by FeedbackOS.
enum FeedbackType {
  bug('bug'),
  feature('feature');

  final String value;
  const FeedbackType(this.value);

  static FeedbackType fromString(String value) {
    return switch (value.toLowerCase()) {
      'bug' => FeedbackType.bug,
      'feature' => FeedbackType.feature,
      _ => throw ArgumentError('Unsupported feedback type: $value'),
    };
  }
}
