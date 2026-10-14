import 'package:equatable/equatable.dart';

/// Request body model for POST /v1/sdk/uploads
class CreateUploadRequestModel extends Equatable {
  final String contentType;
  final int byteSize;

  const CreateUploadRequestModel({
    required this.contentType,
    required this.byteSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'content_type': contentType,
      'byte_size': byteSize,
    };
  }

  factory CreateUploadRequestModel.fromJson(Map<String, dynamic> json) {
    return CreateUploadRequestModel(
      contentType: json['content_type'] as String,
      byteSize: json['byte_size'] as int,
    );
  }

  @override
  List<Object?> get props => [contentType, byteSize];
}
