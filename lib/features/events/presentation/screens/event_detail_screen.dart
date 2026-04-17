import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cdc_app/core/theme/app_colors.dart';
import 'package:cdc_app/core/theme/app_text_styles.dart';
import 'package:cdc_app/data/models/models.dart';

import '../../../../data/services/supabase_service.dart';

class EventDetailScreen extends StatelessWidget {
  final AppEvent event;
  const EventDetailScreen({super.key, required this.event});

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Supprimer l'événement"),
        content: const Text('Cette action est irréversible. Continuer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger,
              foregroundColor: Colors.white, elevation: 0),
            child: const Text('Supprimer')),
        ]));
    if (ok == true) {
      await SupabaseService().deleteEvent(event.id);
      if (context.mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.offWhite,
    body: Column(children: [
      Container(color: AppColors.maroon,
        child: SafeArea(bottom: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 19))),
              GestureDetector(onTap: () => _delete(context),
                child: Container(padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 17))),
            ]),
            const SizedBox(height: 14),
            Text(event.titre,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ])))),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(13, 13, 13, 40), children: [
        Row(children: [
          Expanded(child: _infoCard('DATE', DateFormat('dd MMM yyyy', 'fr').format(event.date))),
          if (event.heureDebut != null && event.heureDebut!.isNotEmpty) ...[
            const SizedBox(width: 9),
            Expanded(child: _infoCard('HEURE',
              '${event.heureDebut}${event.heureFin != null ? " – ${event.heureFin}" : ""}')),
          ],
        ]),
        const SizedBox(height: 9),
        _card(child: _row(Icons.location_on_outlined, 'LIEU', event.lieu, AppColors.maroon)),
        _card(child: _row(Icons.category_outlined, 'TYPE', event.typeLabel, AppColors.info)),
        if (event.participants.isNotEmpty) _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PARTICIPANTS', style: T.label(AppColors.textMuted)),
            const SizedBox(height: 10),
            ...event.participants.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 28, height: 28,
                  decoration: BoxDecoration(color: AppColors.eventBg, shape: BoxShape.circle),
                  child: Center(child: Text(p[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.event,
                      fontSize: 11, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 10),
                Expanded(child: Text(p, style: T.body(AppColors.textPrimary))),
              ]))),
          ])),
        if (event.description.isNotEmpty) _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DESCRIPTION', style: T.label(AppColors.textMuted)),
            const SizedBox(height: 7),
            Text(event.description, style: T.body(AppColors.textSecond).copyWith(height: 1.6)),
          ])),
      ])),
    ]),
  );

  Widget _infoCard(String label, String value) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: T.micro(AppColors.textMuted)), const SizedBox(height: 3),
      Text(value, style: T.bold(AppColors.textPrimary).copyWith(fontSize: 12)),
    ]));

  Widget _row(IconData icon, String label, String value, Color color) =>
    Row(children: [
      Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 17)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: T.micro(AppColors.textMuted)),
        Text(value, style: T.bold(AppColors.textPrimary)),
      ])),
    ]);

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(13), margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: child);
}
