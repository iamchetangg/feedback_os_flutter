import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/roadmap.dart';
import '../repositories/board_repository.dart';

class GetRoadmapUseCase {
  final BoardRepository _repository;

  GetRoadmapUseCase(this._repository);

  Future<Either<Failure, Roadmap>> call({
    CancelToken? cancelToken,
  }) {
    return _repository.getRoadmap(cancelToken: cancelToken);
  }
}
