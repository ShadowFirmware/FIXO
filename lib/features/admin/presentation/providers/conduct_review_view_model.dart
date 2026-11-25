import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/conduct_report_failure.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../conduct_reports/domain/entities/conduct_report.dart';
import '../../data/repositories/conduct_review_repository_impl.dart';
import '../../domain/repositories/conduct_review_repository.dart';

/// ViewModel de la revisión de reportes de conducta (HU-7.3).
///
/// Escucha Firestore: cuando un reporte se registra o se revisa (incluso
/// desde otra sesión), la lista se actualiza sola.
class ConductReviewViewModel extends ChangeNotifier {
  ConductReviewViewModel({
    ConductReviewRepository? repository,
    String? Function()? currentUserId,
  }) : _repository = repository ?? ConductReviewRepositoryImpl(),
       _currentUserId =
           currentUserId ?? (() => AuthSession.instance.currentUser?.uid);

  final ConductReviewRepository _repository;
  final String? Function() _currentUserId;
  StreamSubscription<List<ConductReport>>? _subscription;
  bool _disposed = false;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<ConductReport> _all = const [];

  /// Todos los reportes registrados, del más reciente al más antiguo.
  List<ConductReport> get all => _all;

  ConductReportStatus? _statusFilter;

  /// Estado por el que se filtra; `null` muestra todos.
  ConductReportStatus? get statusFilter => _statusFilter;

  /// Reportes que cumplen el filtro por estado.
  List<ConductReport> get reports => _statusFilter == null
      ? _all
      : _all.where((r) => r.status == _statusFilter).toList();

  /// Cuántos reportes hay con [status], o en total si es `null`.
  int countOf(ConductReportStatus? status) => status == null
      ? _all.length
      : _all.where((r) => r.status == status).length;

  /// El reporte [id] con sus datos más recientes, o `null` si no está.
  ConductReport? findById(String id) {
    for (final report in _all) {
      if (report.id == id) return report;
    }
    return null;
  }

  void start() {
    if (_subscription != null) return;
    _subscription = _repository.watchAll().listen(
      (reports) {
        _all = reports;
        _isLoading = false;
        _errorMessage = null;
        _notify();
      },
      onError: (Object e) {
        _isLoading = false;
        _errorMessage = e is ConductReportFailure
            ? e.message
            : ConductReportFailure.reportsLoadFailed.message;
        _notify();
      },
    );
  }

  void setStatusFilter(ConductReportStatus? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    _notify();
  }

  Future<bool> validate(ConductReport report) =>
      _review(report, ConductReportStatus.validated);

  Future<bool> reject(ConductReport report) =>
      _review(report, ConductReportStatus.rejected);

  Future<bool> _review(
    ConductReport report,
    ConductReportStatus decision,
  ) async {
    _errorMessage = null;
    _successMessage = null;

    final reviewerId = _currentUserId();
    final invalid = reviewerId == null
        ? ConductReportFailure.notAdmin
        // Se revisa con el estado más reciente que llegó de Firestore.
        : (findById(report.id) ?? report).isPendingReview
        ? null
        : ConductReportFailure.alreadyReviewed;
    if (invalid != null) {
      _errorMessage = invalid.message;
      _notify();
      return false;
    }

    _isSaving = true;
    _notify();
    try {
      await _repository.review(
        reportId: report.id,
        reviewerId: reviewerId!,
        decision: decision,
      );
      _successMessage =
          'Reporte ${report.reportNumber} marcado como ${decision.label}.';
      return true;
    } catch (e) {
      _errorMessage = e is ConductReportFailure
          ? e.message
          : ConductReportFailure.reviewFailed.message;
      return false;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
