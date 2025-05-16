import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'categorias_page.dart';
import 'gastos_page.dart';
import '../models/gasto.dart';
import '../models/categoria.dart';
import '../services/local_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'animated_refreshbutton.dart';

class HomeProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  List<Gasto> _gastos = [];
  List<Categoria> _categorias = [];

  List<Gasto> get gastos => _gastos;
  List<Categoria> get categorias => _categorias;

  Future<void> loadData() async {
    _gastos = await _storage.cargarGastos();
    _categorias = await _storage.cargarCategorias();
    notifyListeners();
  }

  Future<void> addGasto(Gasto nuevoGasto) async {
    _gastos.add(nuevoGasto);
    await _storage.guardarGastos(_gastos);
    notifyListeners();
  }

  Map<String, double> getMonthlySummary() {
    final Map<String, double> resumen = {};
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    for (var categoria in _categorias) {
      final gastosCategoria = _gastos.where(
        (g) =>
            g.categoriaId == categoria.id &&
            DateTime(g.fecha.year, g.fecha.month) == currentMonth,
      );
      resumen[categoria.nombre] = gastosCategoria.fold(
        0.0,
        (sum, g) => sum + g.monto,
      );
    }
    return resumen;
  }

  double getTotalSpent() {
    return getMonthlySummary().values.fold(0.0, (sum, value) => sum + value);
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializa los formatos de fecha en español
    initializeDateFormatting('es_ES', null);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GASTOS PERSONALES',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: 'Courier New',
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3F0563), // Morado
                Color(0xFF515FC9), // Azul
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        actions: [
          AnimatedRefreshButton(
            onPressed: () => context.read<HomeProvider>().loadData(),
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          final resumen = provider.getMonthlySummary();
          final totalMes = provider.getTotalSpent();
          final now = DateTime.now();

          return RefreshIndicator(
            onRefresh: () => provider.loadData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Gastos de ${DateFormat('MMMM yyyy', 'es_ES').format(now)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: _buildBarChart(resumen, context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Resumen por Categoría',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          ...resumen.entries.map(
                            (e) => _buildCategoryRow(e.key, e.value),
                          ),
                          const Divider(),
                          _buildTotalRow('Total del mes', totalMes),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.category),
                        label: const Text('Categorías'),
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CategoriasPage(),
                              ),
                            ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.money),
                        label: const Text('Gastos'),
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GastosPage(),
                              ),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> data, BuildContext context) {
    final maxValue = data.values.fold(0.0, (max, e) => e > max ? e : max);
    final entries = data.entries.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children:
              entries.map((e) {
                final double height =
                    maxValue > 0
                        ? (e.value / maxValue) * constraints.maxHeight * 0.8
                        : 0.0;

                return Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.key.substring(0, 3),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                      Text(
                        '\$${e.value.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildCategoryRow(String category, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(category),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: amount > 100 ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double total) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
