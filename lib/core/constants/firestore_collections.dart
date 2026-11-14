/// Nombres de las colecciones de Cloud Firestore.
abstract final class FirestoreCollections {
  static const String users = 'usuarios';
  static const String housings = 'viviendas';
  static const String incidents = 'incidencias';
  /// Subcolección `incidencias/{id}/mensajes` con el chat de cada incidencia
  /// (HU-5.1).
  static const String messages = 'mensajes';
  static const String conductReports = 'reportesConducta';
  static const String notifications = 'notificaciones';

  /// Contadores para números consecutivos, como el folio de incidencias.
  static const String counters = 'contadores';
}
