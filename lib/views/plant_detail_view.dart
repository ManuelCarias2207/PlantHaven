import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:flutter_app/views/catalog_view.dart';

class PlantDetailView extends StatelessWidget {
  final PlantModel plant;
  const PlantDetailView({super.key, required this.plant});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle de planta')),
    body: ListView(children: [
      SizedBox(height: 300, width: double.infinity, child: PlantImage(url: plant.fotografiaUrl)),
      Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(plant.nombre, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 8), Text('${plant.categoria?.nombre ?? 'Planta'} · ${plant.tamano}', style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 18), Text(plant.descripcion?.isNotEmpty == true ? plant.descripcion! : 'Una compañera verde lista para encontrar un nuevo hogar.', style: const TextStyle(height: 1.5)),
        const SizedBox(height: 24), SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: () {}, child: const Text('Solicitar adopción'))),
      ])),
    ]),
  );
}
