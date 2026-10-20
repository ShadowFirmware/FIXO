import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/housing.dart';

/// Convierte los documentos de la colección `viviendas` en [Housing].
class HousingModel extends Housing {
  const HousingModel({
    required super.id,
    required super.type,
    required super.number,
    super.building,
    super.active,
    super.residentId,
  });

  factory HousingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw FormatException('La vivienda ${doc.id} no existe');
    }
    return HousingModel.fromMap(doc.id, data);
  }

  /// Lanza [FormatException] si el documento no tiene un tipo válido.
  factory HousingModel.fromMap(String id, Map<String, dynamic> data) {
    final type = HousingType.fromValue(data['tipo'] as String?);
    if (type == null) {
      throw FormatException('Tipo de vivienda no válido: ${data['tipo']}');
    }

    return HousingModel(
      id: id,
      type: type,
      number: data['numero'] as String? ?? '',
      building: data['edificio'] as String?,
      active: data['activa'] as bool? ?? true,
      residentId: data['residenteActivoId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tipo': type.value,
      'edificio': building,
      'numero': number,
      'activa': active,
      'residenteActivoId': residentId,
    };
  }
}
