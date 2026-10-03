import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/views/catalog_view.dart';

class PlantDetailView extends StatefulWidget {
  final Plant plant;
  const PlantDetailView({super.key, required this.plant});

  @override
  State<PlantDetailView> createState() => _PlantDetailViewState();
}

class _PlantDetailViewState extends State<PlantDetailView> {
  bool _favorite = false;
  bool _requestSent = false;

  bool get _isAvailable => widget.plant.estado.toUpperCase() == 'DISPONIBLE';

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: _DetailAppBar(plant: plant),
      ),
      bottomNavigationBar: _RequestBar(
        enabled: _isAvailable && !_requestSent,
        label: _requestSent
            ? 'Solicitud enviada'
            : _isAvailable
            ? 'Solicitar adopción  →'
            : 'No disponible para adopción',
        onPressed: _requestAdoption,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Gallery(
              plant: plant,
              favorite: _favorite,
              onFavorite: () => setState(() => _favorite = !_favorite),
            ),
            const SizedBox(height: 24),
            _StatusChip(
              label: _isAvailable ? 'Disponible para adopción' : plant.estado,
            ),
            const SizedBox(height: 12),
            Text(
              plant.nombre,
              style: const TextStyle(
                fontSize: 32,
                height: 1.08,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${plant.nombre} Liebmann',
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(Icons.grid_view_rounded, 'Características'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.25,
              children: [
                _FeatureTile(
                  icon: Icons.home_work_outlined,
                  title: 'Tipo',
                  value: plant.categoria == 'Interior'
                      ? 'Interior'
                      : plant.categoria,
                ),
                _FeatureTile(
                  icon: Icons.straighten,
                  title: 'Tamaño',
                  value: '${plant.tamano} 60cm',
                ),
                _FeatureTile(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Luz',
                  value: 'Luz ${plant.luz.toLowerCase()}',
                ),
                _FeatureTile(
                  icon: Icons.spa_outlined,
                  title: 'Cuidado',
                  value: plant.nivelCuidado,
                ),
                const _FeatureTile(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Salud',
                  value: 'Excelente',
                  valueColor: AppColors.accent,
                ),
                _FeatureTile(
                  icon: Icons.location_on_outlined,
                  title: 'Zona',
                  value: plant.ubicacion,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _sectionTitle(
              Icons.description_outlined,
              'Descripción de la planta',
            ),
            const SizedBox(height: 12),
            _SoftPanel(
              child: Text(
                'Una compañera verde sana y cuidada, lista para encontrar un nuevo hogar. La ${plant.nombre} disfruta de espacios luminosos sin sol directo y es una excelente elección para llenar tu casa de vida.',
                style: const TextStyle(
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _sectionTitle(Icons.water_drop_outlined, 'Cuidados recomendados'),
            const SizedBox(height: 12),
            _SoftPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riega cuando la capa superior de la tierra esté seca. Evita encharcar la maceta y limpia sus hojas con suavidad para mantenerlas saludables.',
                    style: TextStyle(
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CareChip(
                        icon: Icons.water_drop_outlined,
                        label: 'Riego: Cada 6-8 días',
                      ),
                      _CareChip(
                        icon: Icons.cloud_outlined,
                        label: 'Humedad: Media-alta',
                      ),
                      _CareChip(
                        icon: Icons.pets_outlined,
                        label: 'Mantener fuera de mascotas',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _InfoCard(
              icon: Icons.people_outline,
              title: '3 solicitudes en revisión',
              description: 'Hay otras personas interesadas. Tu solicitud se gestiona de forma justa y transparente.',
            ),
            _InfoCard(
              icon: Icons.shield_outlined,
              title: 'Garantía de Adopción Ética',
              description: 'Promovemos entregas responsables y acompañamos a ambas partes durante el proceso.',
            ),
            _DonorCard(),
            _InfoCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacidad protegida',
              description: 'Tus datos de contacto solo se comparten cuando ambas partes aceptan continuar.',
            ),
            const _StatusLegend(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) => Row(
    children: [
      Icon(icon, color: AppColors.accent, size: 20),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    ],
  );

  void _requestAdoption() {
    if (!_isAvailable || _requestSent) return;
    setState(() => _requestSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tu solicitud de adopción fue enviada.')),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  final Plant plant;
  const _DetailAppBar({required this.plant});
  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: AppColors.background,
    elevation: 0,
    automaticallyImplyLeading: false,
    titleSpacing: 4,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      'Volver a Explorar',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    ),
    actions: [
      const Icon(
        Icons.visibility_outlined,
        size: 16,
        color: AppColors.textSecondary,
      ),
      const SizedBox(width: 4),
      const Text(
        '142 visitas recientes',
        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
      const SizedBox(width: 12),
      Text(
        'REF: PH-${plant.id.toString().padLeft(4, '0')}',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(width: 4),
      IconButton(
        icon: const Icon(Icons.notifications_none, color: AppColors.primary),
        onPressed: () {},
      ),
      const SizedBox(width: 4),
    ],
  );
}

class _Gallery extends StatelessWidget {
  final Plant plant;
  final bool favorite;
  final VoidCallback onFavorite;
  const _Gallery({
    required this.plant,
    required this.favorite,
    required this.onFavorite,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 285,
              width: double.infinity,
              color: AppColors.fieldBackground,
              child: const Center(
                child: Icon(
                  Icons.local_florist_outlined,
                  size: 96,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _StatusChip(label: 'Disponible para adopción'),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(
                  favorite ? Icons.favorite : Icons.favorite_border,
                  color: favorite ? Colors.redAccent : AppColors.primary,
                ),
                onPressed: onFavorite,
              ),
            ),
          ),
          const Positioned(
            left: 16,
            bottom: 16,
            child: _GalleryBadge(label: 'Foto auténtica de la donante'),
          ),
          const Positioned(
            right: 16,
            bottom: 16,
            child: _GalleryBadge(
              label: 'Maceta cerámica incluida',
              light: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == 0 ? AppColors.accent : AppColors.fieldBackground,
                  border: Border.all(
                    color: i == 0 ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.local_florist_outlined,
                  size: 25,
                  color: i == 0 ? Colors.white : AppColors.accent,
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _GalleryBadge extends StatelessWidget {
  final String label;
  final bool light;
  const _GalleryBadge({required this.label, this.light = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: light ? Colors.white.withValues(alpha: .9) : AppColors.primary,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: light ? AppColors.primary : Colors.white,
      ),
    ),
  );
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color valueColor;
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor = AppColors.primary,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.fieldBackground,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SoftPanel extends StatelessWidget {
  final Widget child;
  const _SoftPanel({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _CareChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CareChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.fieldBackground,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.accent),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title, description;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.fieldBackground,
          child: Icon(icon, color: AppColors.accent, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DonorCard extends StatelessWidget {
  const _DonorCard();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 23,
          backgroundColor: AppColors.fieldBackground,
          child: Icon(Icons.person, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Donante: Claudia M.  ✓',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Donante verificada · Responde habitualmente',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            backgroundColor: AppColors.fieldBackground,
            foregroundColor: AppColors.primary,
          ),
          child: const Text('Responder'),
        ),
      ],
    ),
  );
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leyenda de estados',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          const _LegendRow(
            color: AppColors.primary,
            label: 'Disponible para adopción',
            text: 'Puedes enviar una solicitud.',
          ),
          const _LegendRow(
            color: Colors.grey,
            label: 'Solicitud en revisión',
            text: 'El donante está evaluando solicitudes.',
          ),
          const _LegendRow(
            color: Colors.black45,
            label: 'Adoptada',
            text: 'La planta ya encontró un hogar.',
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label, text;
  const _LegendRow({
    required this.color,
    required this.label,
    required this.text,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $text',
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RequestBar extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback onPressed;
  const _RequestBar({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: enabled ? onPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Adopción comunitaria gratuita  ·  Sin intermediarios comerciales',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
