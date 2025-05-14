import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gasto.dart';
import '../models/categoria.dart';
import '../services/local_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
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
    initializeDateFormatting('es_ES');
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

  void _mostrarModal({Gasto? gasto}) {
    final descripcionController = TextEditingController(
      text: gasto != null ? gasto.descripcion : '',
    );
    final montoController = TextEditingController(
      text: gasto != null ? gasto.monto.toString() : '',
    );
    int? selectedCategoriaId =
        gasto?.categoriaId ?? _categorias.firstOrDefault()?.id;
    DateTime? selectedDateLocal = gasto?.fecha;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(gasto == null ? 'Nuevo Gasto' : 'Editar Gasto',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: montoController,
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedCategoriaId,
                      items: _categorias.map((cat) {
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
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
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
                            : 'Fecha: ${DateFormat('dd MMMM yyyy', 'es_ES').format(selectedDateLocal!)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
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
                    final descripcion = descripcionController.text.trim();
                    final monto =
                        double.tryParse(montoController.text.trim()) ?? 0.0;

                    if (descripcion.isEmpty) {
                      _mostrarError('Ingrese una descripción');
                      return;
                    }

                    if (selectedCategoriaId == null) {
                      _mostrarError('Seleccione una categoría');
                      return;
                    }

                    if (monto <= 0) {
                      _mostrarError('El monto debe ser mayor a cero');
                      return;
                    }

                    if (selectedDateLocal == null) {
                      _mostrarError('Seleccione una fecha');
                      return;
                    }

                    if (!_esFechaValida(selectedDateLocal!)) {
                      _mostrarError('No puede seleccionar fechas futuras');
                      return;
                    }

                    if (gasto == null) {
                      // Crear nuevo gasto
                      final nuevo = Gasto(
                        id: DateTime.now().millisecondsSinceEpoch,
                        descripcion: descripcion,
                        monto: monto,
                        categoriaId: selectedCategoriaId!,
                        fecha: selectedDateLocal!,
                      );
                      _gastos.add(nuevo);
                      _mostrarExito('Gasto creado exitosamente');
                    } else {
                      // Actualizar gasto existente
                      final index = _gastos.indexWhere((g) => g.id == gasto.id);
                      if (index != -1) {
                        _gastos[index] = Gasto(
                          id: gasto.id,
                          descripcion: descripcion,
                          monto: monto,
                          categoriaId: selectedCategoriaId!,
                          fecha: selectedDateLocal!,
                        );
                        _mostrarExito('Gasto actualizado exitosamente');
                      }
                    }

                    await _storage.guardarGastos(_gastos);
                    final homeProvider = Provider.of<HomeProvider>(
                      context,
                      listen: false,
                    );
                    await homeProvider.loadData();

                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      setState(() {});
                    }
                  },
                  child: const Text('GUARDAR',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _eliminarGasto(int id) async {
    final gasto = _gastos.firstWhere((g) => g.id == id);
    
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Eliminar el gasto "${gasto.descripcion}"?'),
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
        _gastos.removeWhere((g) => g.id == id);
      });
      await _storage.guardarGastos(_gastos);
      final homeProvider = Provider.of<HomeProvider>(
        context,
        listen: false,
      );
      await homeProvider.loadData();
      _mostrarExito('Gasto eliminado exitosamente');
    }
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
      appBar: AppBar(
        title: const Text('Gastos',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
      ),
      body: _gastos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long,
                      size: 64,
                      color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  const SizedBox(height: 20),
                  Text(
                    'No hay gastos registrados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Presiona el botón + para registrar tu primer gasto',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _gastos.length,
              itemBuilder: (_, index) {
                final gasto = _gastos[index];
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
                      gasto.descripcion,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '\$${gasto.monto.toStringAsFixed(2)} - ${_nombreCategoria(gasto.categoriaId)}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(gasto.fecha)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit,
                              color: Theme.of(context).primaryColor),
                          onPressed: () => _mostrarModal(gasto: gasto),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarGasto(gasto.id),
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

extension FirstOrDefault<T> on List<T> {
  T? firstOrDefault() => isNotEmpty ? first : null;
}