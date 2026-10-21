/// Tipo de vivienda (HU-4.7).
enum HousingType {
  apartment('departamento'),
  house('casa');

  const HousingType(this.value);

  /// Valor guardado en Firestore.
  final String value;

  static HousingType? fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Lugar de residencia que el administrador asigna a un residente.
class Housing {
  const Housing({
    required this.id,
    required this.type,
    required this.number,
    this.building,
    this.active = true,
    this.residentId,
  });

  final String id;
  final HousingType type;

  /// Número o identificador dentro del edificio, por ejemplo "4B".
  final String number;

  /// Edificio, torre o sección, cuando corresponda.
  final String? building;

  final bool active;

  /// UID del residente activo, o `null` si está disponible.
  final String? residentId;

  /// Nombre para mostrar, por ejemplo "Torre A – 4B" o "Casa 12".
  String get label {
    final number = this.number.trim();
    final building = this.building?.trim() ?? '';
    if (building.isNotEmpty) return '$building – $number';
    return switch (type) {
      HousingType.apartment => 'Depto $number',
      HousingType.house => 'Casa $number',
    };
  }
}
