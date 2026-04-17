import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cdc_app/core/theme/app_colors.dart';
import 'package:cdc_app/core/theme/app_text_styles.dart';
import 'package:cdc_app/data/models/models.dart';
import 'package:cdc_app/data/services/supabase_service.dart';
import 'package:cdc_app/core/constants/app_constants.dart';

class MissionDetailScreen extends StatefulWidget {
  final Mission mission;
  const MissionDetailScreen({super.key, required this.mission});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  late Mission _m;

  @override
  void initState() {
    super.initState();
    _m = widget.mission;
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la mission'),
        content: const Text('Cette action est irréversible. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await SupabaseService().deleteMission(_m.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService().currentUser;
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.president;
    final isMem = user != null && user.fullName.isNotEmpty && _m.equipe.any((e) => e.contains(user.fullName));
    final canEdit = isAdmin || isMem;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: AppColors.maroon,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 19),
              onPressed: () => Navigator.pop(context),
            ),
            actions: canEdit
                ? [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _delete,
              ),
            ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              centerTitle: false,
              title: Text(
                _m.titre,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                color: AppColors.maroon,
                child: const Opacity(
                  opacity: 0.06,
                  child: Icon(Icons.folder_rounded, size: 140, color: Colors.white),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 13, 13, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard('DÉBUT', DateFormat('dd MMM yyyy', 'fr').format(_m.dateDebut)),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _infoCard('FIN', DateFormat('dd MMM yyyy', 'fr').format(_m.dateFin)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  _card(child: _row(Icons.business_outlined, 'ORGANISME', _m.organisme, AppColors.info)),
                  _card(child: _row(Icons.location_on_outlined, 'LOCALISATION', '${_m.ville} · ${_m.region}', AppColors.maroon)),
                  if (_m.equipe.isNotEmpty)
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ÉQUIPE & STRUCTURES', style: T.label(AppColors.textMuted)),
                          const SizedBox(height: 10),
                          ..._m.equipe.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28, height: 28,
                                      decoration: const BoxDecoration(color: AppColors.maroonPale, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text(
                                          e.isNotEmpty ? e[0].toUpperCase() : '?',
                                          style: const TextStyle(color: AppColors.maroon, fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(e, style: T.body(AppColors.textPrimary))),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  if (_m.description.isNotEmpty)
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DESCRIPTION', style: T.label(AppColors.textMuted)),
                          const SizedBox(height: 7),
                          Text(_m.description, style: T.body(AppColors.textSecond).copyWith(height: 1.6)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.border)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: T.micro(AppColors.textMuted)),
        const SizedBox(height: 3),
        Text(value, style: T.bold(AppColors.textPrimary).copyWith(fontSize: 12)),
      ],
    ),
  );

  Widget _row(IconData icon, String label, String value, Color color) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: T.micro(AppColors.textMuted)),
                Text(value, style: T.bold(AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      );

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(13), margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: child,
  );
}
