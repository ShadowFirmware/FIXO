/// Quién recibe los avisos (HU-6.1). Son funciones puras para poder
/// probarlas sin Firestore.
abstract final class NotificationRecipients {
  /// Residentes a los que se avisa de los cambios de una incidencia: el que
  /// la registró y el residente activo de la vivienda, que pueden ser
  /// distintos si la vivienda cambió de residente. Sin repetidos ni vacíos.
  static List<String> residents({
    required String? createdBy,
    required String? activeResidentId,
  }) => _unique([createdBy, activeResidentId]);

  static List<String> _unique(Iterable<String?> ids) => [
    ...{
      for (final id in ids)
        if (id != null && id.trim().isNotEmpty) id,
    },
  ];
}
