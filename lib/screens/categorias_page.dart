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
          title: Text(categoria == null ? 'Nueva Categoría' : 'Editar Categoría'),
          content: TextField(
            controller: nombreController,
            decoration: const InputDecoration(labelText: 'Nombre de categoría'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreController.text.trim();
                if (nombre.isEmpty) return;

                if (categoria == null) {
                  final nueva = Categoria(
                    id: DateTime.now().millisecondsSinceEpoch,
                    nombre: nombre,
                  );
                  _categorias.add(nueva);
                } else {
                  final index = _categorias.indexWhere((c) => c.id == categoria.id);
                  if (index != -1) {
                    _categorias[index] = Categoria(
                      id: categoria.id,
                      nombre: nombre,
                    );
                  }
                }

                await _storage.guardarCategorias(_categorias);
                final homeProvider = Provider.of<HomeProvider>(context, listen: false);
                await homeProvider.loadData();
                
                setState(() {});
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarCategoria(int id) async {
    setState(() {
      _categorias.removeWhere((c) => c.id == id);
    });
    await _storage.guardarCategorias(_categorias);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    await homeProvider.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: ListView.builder(
        itemCount: _categorias.length,
        itemBuilder: (_, i) {
          final cat = _categorias[i];
          return ListTile(
            title: Text(cat.nombre),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _mostrarModal(categoria: cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _eliminarCategoria(cat.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModal(),
        child: const Icon(Icons.add),
      ),
    );
  }
}