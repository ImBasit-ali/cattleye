export '../data/repositories/cattle_analysis_repository_impl.dart';
export '../domain/repositories/cattle_analysis_repository.dart';

import '../data/repositories/cattle_analysis_repository_impl.dart';

/// Back-compat alias for existing call sites.
typedef CattleAnalysisService = CattleAnalysisRepositoryImpl;
