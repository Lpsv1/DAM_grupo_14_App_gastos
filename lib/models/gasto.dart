import 'dart:convert';

class Gasto {
  final int id;
  final String descripcion;
  final double monto;
  final int categoriaId;
  final DateTime fecha;

  Gasto({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.categoriaId,
    required this.fecha,
  });

  // Método para convertir un JSON a una instancia de Gasto
  factory Gasto.fromJson(Map<String, dynamic> json) {
    return Gasto(
      id: json['id'],
      descripcion: json['descripcion'],
      monto: json['monto'].toDouble(),
      categoriaId: json['categoriaId'],
      fecha: DateTime.parse(json['fecha']),
    );
  }

  // Método para convertir una instancia de Gasto a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descripcion': descripcion,
      'monto': monto,
      'categoriaId': categoriaId,
      'fecha': fecha.toIso8601String(),
    };
  }
}
