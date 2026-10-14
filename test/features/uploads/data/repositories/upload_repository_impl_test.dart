import 'dart:typed_data';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/uploads/data/datasources/binary_uploader.dart';
import 'package:feedback_os_flutter/src/features/uploads/data/datasources/upload_remote_data_source.dart';
import 'package:feedback_os_flutter/src/features/uploads/data/models/upload_reservation_model.dart';
import 'package:feedback_os_flutter/src/features/uploads/data/repositories/upload_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUploadRemoteDataSource extends Mock
    implements UploadRemoteDataSource {}

class MockBinaryUploader extends Mock implements BinaryUploader {}

void main() {
  group('UploadRepositoryImpl', () {
    late MockUploadRemoteDataSource mockRemote;
    late MockBinaryUploader mockUploader;
    late UploadRepositoryImpl repository;

    setUp(() {
      mockRemote = MockUploadRemoteDataSource();
      mockUploader = MockBinaryUploader();
      repository = UploadRepositoryImpl(
        remoteDataSource: mockRemote,
        binaryUploader: mockUploader,
      );
    });

    test('reserveUpload returns Right(UploadReservation) on remote success',
        () async {
      final reservationModel = UploadReservationModel(
        uploadId: 'upload-id-999',
        method: 'PUT',
        url: Uri.parse('https://r2.storage.feedbackos.dev/item.png'),
        headers: const {'content-type': 'image/png'},
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      when(
        () => mockRemote.reserveUpload(
          contentType: 'image/png',
          byteSize: 1024,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => reservationModel);

      final result = await repository.reserveUpload(
        contentType: 'image/png',
        byteSize: 1024,
      );

      expect(result.isRight(), isTrue);
      expect(
          result.getOrElse((_) => throw Exception()), equals(reservationModel));
    });

    test(
        'reserveUpload maps FeedbackOsAuthenticationException to AuthenticationFailure',
        () async {
      when(
        () => mockRemote.reserveUpload(
          contentType: 'image/png',
          byteSize: 1024,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        const FeedbackOsAuthenticationException('Invalid key'),
      );

      final result = await repository.reserveUpload(
        contentType: 'image/png',
        byteSize: 1024,
      );

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<AuthenticationFailure>()),
        (_) => fail('Should not succeed'),
      );
    });

    test('uploadBinary returns Right(unit) on success', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final reservation = UploadReservation(
        uploadId: 'upload-123',
        method: 'PUT',
        url: Uri.parse('https://r2.feedbackos.dev/item.png'),
        headers: const {},
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      when(
        () => mockUploader.uploadBinary(
          reservation: reservation,
          bytes: bytes,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.uploadBinary(
        reservation: reservation,
        bytes: bytes,
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => throw Exception()), equals(unit));
    });

    test(
        'uploadBinary maps FeedbackOsUploadNotFoundException to UploadNotFoundFailure',
        () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final reservation = UploadReservation(
        uploadId: 'upload-123',
        method: 'PUT',
        url: Uri.parse('https://r2.feedbackos.dev/item.png'),
        headers: const {},
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      when(
        () => mockUploader.uploadBinary(
          reservation: reservation,
          bytes: bytes,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        const FeedbackOsUploadNotFoundException('Upload expired',
            statusCode: 404),
      );

      final result = await repository.uploadBinary(
        reservation: reservation,
        bytes: bytes,
      );

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<UploadNotFoundFailure>()),
        (_) => fail('Should not succeed'),
      );
    });
  });
}
