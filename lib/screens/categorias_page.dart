import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../services/local_storage.dart';
import 'home_page.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({Key? key}) : super(key: key);

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  final LocalStorageService _storage = LocalStorageService();
  List<Categoria> _categorias = [];

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final data = await _storage.cargarCategorias();
    setState(() {
      _categorias = data;
    });
  }

  void _mostrarModal({Categoria? categoria}) {
    final nombreController = TextEditingController(
      text: categoria != null ? categoria.nombre : '',
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            categoria == null ? 'Nueva Categoría' : 'Editar Categoría',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Comida, Transporte',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final nombre = nombreController.text.trim();
                if (nombre.isEmpty) {
                  _mostrarError('Debe ingresar un nombre para la categoría');
                  return;
                }

                if (categoria == null) {
                  if (_categorias.any((c) =>
                      c.nombre.toLowerCase() == nombre.toLowerCase())) {
                    _mostrarError('Ya existe una categoría con ese nombre');
                    return;
                  }

                  final nueva = Categoria(
                    id: DateTime.now().millisecondsSinceEpoch,
                    nombre: nombre,
                  );
                  _categorias.add(nueva);
                } else {
                  final index = _categorias.indexWhere(
                    (c) => c.id == categoria.id,
                  );
                  if (index != -1) {
                    _categorias[index] = Categoria(
                      id: categoria.id,
                      nombre: nombre,
                    );
                  }
                }

                await _storage.guardarCategorias(_categorias);
                final homeProvider = Provider.of<HomeProvider>(
                  context,
                  listen: false,
                );
                await homeProvider.loadData();

                if (mounted) {
                  setState(() {});
                  Navigator.of(context).pop();
                  _mostrarExito(categoria == null
                      ? 'Categoría creada exitosamente'
                      : 'Categoría actualizada exitosamente');
                }
              },
              child: const Text('GUARDAR',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _eliminarCategoria(int id) async {
    final gastos = await _storage.cargarGastos();
    final tieneGastos = gastos.any((gasto) => gasto.categoriaId == id);

    if (tieneGastos && mounted) {
      _mostrarError('No se puede borrar: existen gastos vinculados');
      return;
    }

    final categoria = _categorias.firstWhere((c) => c.id == id);
    
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Eliminar la categoría "${categoria.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmacion == true && mounted) {
      setState(() {
        _categorias.removeWhere((c) => c.id == id);
      });
      await _storage.guardarCategorias(_categorias);
      final homeProvider = Provider.of<HomeProvider>(
        context,
        listen: false,
      );
      await homeProvider.loadData();
      _mostrarExito('Categoría eliminada exitosamente');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
      ),
      body: _categorias.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined,
                      size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay categorías registradas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Presiona el botón + para agregar una',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _categorias.length,
              itemBuilder: (_, index) {
                final categoria = _categorias[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      categoria.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit,
                              color: Theme.of(context).primaryColor),
                          onPressed: () => _mostrarModal(categoria: categoria),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarCategoria(categoria.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModal(),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}