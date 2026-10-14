import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/uploads/domain/repositories/upload_repository.dart';
import 'package:feedback_os_flutter/src/features/uploads/domain/usecases/upload_screenshot_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class FakeUploadRepository implements UploadRepository {
  Either<Failure, UploadReservation>? reserveResult;
  Either<Failure, Unit>? uploadResult;

  String? lastReservedContentType;
  int? lastReservedByteSize;
  UploadReservation? lastUploadedReservation;
  Uint8List? lastUploadedBytes;

  @override
  Future<Either<Failure, UploadReservation>> reserveUpload({
    required String contentType,
    required int byteSize,
    CancelToken? cancelToken,
  }) async {
    lastReservedContentType = contentType;
    lastReservedByteSize = byteSize;
    return reserveResult ??
        Right(
          UploadReservation(
            uploadId: 'mock-upload-id-123',
            method: 'PUT',
            url: Uri.parse('https://r2.feedbackos.dev/bucket/upload.png'),
            headers: const {'content-type': 'image/png'},
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
          ),
        );
  }

  @override
  Future<Either<Failure, Unit>> uploadBinary({
    required UploadReservation reservation,
    required Uint8List bytes,
    CancelToken? cancelToken,
  }) async {
    lastUploadedReservation = reservation;
    lastUploadedBytes = bytes;
    return uploadResult ?? const Right(unit);
  }
}

void main() {
  group('UploadScreenshotUseCase', () {
    late FakeUploadRepository repository;
    late UploadScreenshotUseCase useCase;

    setUp(() {
      repository = FakeUploadRepository();
      useCase = UploadScreenshotUseCase(repository);
    });

    test('successfully reserves and uploads valid PNG screenshot', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final attachment = ScreenshotAttachment(
        fileName: 'screen.png',
        contentType: 'image/png',
        bytes: bytes,
      );

      final result = await useCase(attachment: attachment);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => ''), 'mock-upload-id-123');
      expect(repository.lastReservedContentType, 'image/png');
      expect(repository.lastReservedByteSize, 5);
      expect(repository.lastUploadedBytes, bytes);
      expect(
        repository.lastUploadedReservation?.uploadId,
        'mock-upload-id-123',
      );
    });

    test('successfully reserves and uploads valid JPEG screenshot', () async {
      final bytes = Uint8List.fromList([10, 20, 30]);
      final attachment = ScreenshotAttachment(
        fileName: 'photo.jpg',
        contentType: 'image/jpeg',
        bytes: bytes,
      );

      final result = await useCase(attachment: attachment);

      expect(result.isRight(), isTrue);
      expect(repository.lastReservedContentType, 'image/jpeg');
    });

    test('fails validation when MIME type is unsupported', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final attachment = ScreenshotAttachment(
        fileName: 'anim.gif',
        contentType: 'image/gif',
        bytes: bytes,
      );

      final result = await useCase(attachment: attachment);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Unsupported image type'));
        },
        (_) => fail('Should not succeed'),
      );
    });

    test('fails validation when byte size is 0', () async {
      final attachment = ScreenshotAttachment(
        fileName: 'empty.png',
        contentType: 'image/png',
        bytes: Uint8List(0),
      );

      final result = await useCase(attachment: attachment);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('cannot be empty'));
        },
        (_) => fail('Should not succeed'),
      );
    });

    test('fails validation when image exceeds 5 MiB', () async {
      final oversizedBytes = Uint8List(ScreenshotAttachment.maxByteSize + 1);
      final attachment = ScreenshotAttachment(
        fileName: 'huge.png',
        contentType: 'image/png',
        bytes: oversizedBytes,
      );

      final result = await useCase(attachment: attachment);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('maximum allowed size'));
        },
        (_) => fail('Should not succeed'),
      );
    });

    test('returns failure when reservation fails', () async {
      repository.reserveResult = const Left(
        AuthenticationFailure('Invalid key'),
      );
      final attachment = ScreenshotAttachment(
        fileName: 'screen.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      final result = await useCase(attachment: attachment);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<AuthenticationFailure>()),
        (_) => fail('Should not succeed'),
      );
      expect(repository.lastUploadedBytes, isNull);
    });

    test('returns failure when binary upload fails', () async {
      repository.uploadResult = const Left(
        NetworkFailure('Cloudflare R2 connection timed out'),
      );
      final attachment = ScreenshotAttachment(
        fileName: 'screen.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      final result = await useCase(attachment: attachment);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, contains('Cloudflare R2'));
        },
        (_) => fail('Should not succeed'),
      );
    });
  });
}
