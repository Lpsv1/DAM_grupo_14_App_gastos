import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gasto.dart';
import '../models/categoria.dart';
import '../services/local_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Nueva importación
import 'home_page.dart';

class GastosPage extends StatefulWidget {
  const GastosPage({Key? key}) : super(key: key);

  @override
  State<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends State<GastosPage> {
  final LocalStorageService _storage = LocalStorageService();
  List<Gasto> _gastos = [];
  List<Categoria> _categorias = [];
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(
      'es_ES',
    ); // Inicializa formatos de fecha en español
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    final gastos = await _storage.cargarGastos();
    final categorias = await _storage.cargarCategorias();
    setState(() {
      _gastos = gastos;
      _categorias = categorias;
    });
  }

  bool _esFechaValida(DateTime fecha) {
    final ahora = DateTime.now();
    final fechaActual = DateTime(ahora.year, ahora.month, ahora.day);
    return fecha.isBefore(fechaActual) || _sonMismasFechas(fecha, fechaActual);
  }

  bool _sonMismasFechas(DateTime fecha1, DateTime fecha2) {
    return fecha1.year == fecha2.year &&
        fecha1.month == fecha2.month &&
        fecha1.day == fecha2.day;
  }

  void _mostrarModal({Gasto? gasto}) {
    final descripcionController = TextEditingController(
      text: gasto != null ? gasto.descripcion : '',
    );
    final montoController = TextEditingController(
      text: gasto != null ? gasto.monto.toString() : '',
    );
    int? selectedCategoriaId =
        gasto?.categoriaId ?? _categorias.firstOrDefault()?.id;
    DateTime? selectedDateLocal = gasto?.fecha ?? selectedDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(gasto == null ? 'Nuevo Gasto' : 'Editar Gasto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    TextField(
                      controller: montoController,
                      decoration: const InputDecoration(labelText: 'Monto'),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedCategoriaId,
                      items:
                          _categorias.map((cat) {
                            return DropdownMenuItem<int>(
                              value: cat.id,
                              child: Text(cat.nombre),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategoriaId = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Categoría'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDateLocal ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          locale: const Locale('es', 'ES'),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDateLocal = picked;
                          });
                        }
                      },
                      child: Text(
                        selectedDateLocal == null
                            ? 'Seleccionar Fecha'
                            : 'Fecha: ${DateFormat('dd MMMM yyyy', 'es_ES').format(selectedDateLocal!)}', // Formato en español
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final descripcion = descripcionController.text.trim();
                    final monto =
                        double.tryParse(montoController.text.trim()) ?? 0.0;

                    if (descripcion.isEmpty || selectedCategoriaId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complete todos los campos'),
                        ),
                      );
                      return;
                    }

                    if (monto <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El monto debe ser mayor a cero'),
                        ),
                      );
                      return;
                    }

                    final fechaSeleccionada =
                        selectedDateLocal ?? DateTime.now();
                    if (!_esFechaValida(fechaSeleccionada)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No puede seleccionar fechas futuras'),
                        ),
                      );
                      return;
                    }

                    final nuevo = Gasto(
                      id: DateTime.now().millisecondsSinceEpoch,
                      descripcion: descripcion,
                      monto: monto,
                      categoriaId: selectedCategoriaId!,
                      fecha: fechaSeleccionada,
                    );

                    _gastos.add(nuevo);
                    await _storage.guardarGastos(_gastos);

                    final homeProvider = Provider.of<HomeProvider>(
                      context,
                      listen: false,
                    );
                    await homeProvider.addGasto(nuevo);

                    Navigator.of(dialogContext).pop();
                    setState(() {});
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _eliminarGasto(int id) async {
    setState(() {
      _gastos.removeWhere((g) => g.id == id);
    });
    await _storage.guardarGastos(_gastos);
  }

  String _nombreCategoria(int id) {
    final cat = _categorias.firstWhere(
      (c) => c.id == id,
      orElse: () => Categoria(id: 0, nombre: 'Desconocido'),
    );
    return cat.nombre;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: ListView.builder(
        itemCount: _gastos.length,
        itemBuilder: (_, i) {
          final gasto = _gastos[i];
          return ListTile(
            title: Text(gasto.descripcion),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${gasto.monto.toStringAsFixed(2)} - ${_nombreCategoria(gasto.categoriaId)}',
                ),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy').format(gasto.fecha)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _mostrarModal(gasto: gasto),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _eliminarGasto(gasto.id),
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

extension FirstOrDefault<T> on List<T> {
  T? firstOrDefault() => isNotEmpty ? first : null;
}
