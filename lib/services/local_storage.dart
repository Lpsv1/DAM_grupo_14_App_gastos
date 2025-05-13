import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/categoria.dart';
import '../models/gasto.dart';

class LocalStorageService {
  Future<List<Categoria>> cargarCategorias() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('categorias');
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Categoria.fromJson(e)).toList();
  }

  Future<void> guardarCategorias(List<Categoria> categorias) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(categorias.map((e) => e.toJson()).toList());
    await prefs.setString('categorias', data);
  }

  Future<List<Gasto>> cargarGastos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('gastos');
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Gasto.fromJson(e)).toList();
  }

  Future<void> guardarGastos(List<Gasto> gastos) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(gastos.map((e) => e.toJson()).toList());
    await prefs.setString('gastos', data);
  }
}
