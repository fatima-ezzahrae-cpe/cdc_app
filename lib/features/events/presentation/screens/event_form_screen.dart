import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cdc_app/core/theme/app_colors.dart';
import 'package:cdc_app/core/theme/app_text_styles.dart';
import 'package:cdc_app/data/models/models.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../data/services/supabase_service.dart';


class EventFormScreen extends StatefulWidget {
  final VoidCallback onCreated;
  const EventFormScreen({super.key, required this.onCreated});
  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _fk    = GlobalKey<FormState>();
  final _titC  = TextEditingController();
  final _lieuC = TextEditingController();
  final _hDebC = TextEditingController();
  final _hFinC = TextEditingController();
  final _descC = TextEditingController();
  final _partC = TextEditingController();
  DateTime?  _date;
  EventType  _type   = EventType.autre;
  bool       _saving = false;
  final List<String> _parts = [];

  @override
  void dispose() {
    _titC.dispose(); _lieuC.dispose(); _hDebC.dispose();
    _hFinC.dispose(); _descC.dispose(); _partC.dispose(); super.dispose();
  }

  Future<void> _submit() async {
    if (!_fk.currentState!.validate() || _date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complétez tous les champs (*)')));
      return;
    }
    setState(() => _saving = true);
    final ok = await SupabaseService().insertEvent(AppEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titre: _titC.text, lieu: _lieuC.text, date: _date!,
      heureDebut: _hDebC.text.isEmpty ? null : _hDebC.text,
      heureFin:   _hFinC.text.isEmpty ? null : _hFinC.text,
      type: _type, description: _descC.text, participants: _parts,
    ));
    if (mounted) {
      setState(() => _saving = false);
      if (ok) widget.onCreated();
      else ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.offWhite,
    appBar: AppBar(
      backgroundColor: AppColors.maroon, foregroundColor: Colors.white, elevation: 0,
      title: const Text("Nouvel événement", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
    body: Form(key: _fk,
      child: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 40), children: [
        _field('TITRE *', _titC, 'Ex: Conférence annuelle',
          validator: (v) => v!.isEmpty ? 'Requis' : null),
        const SizedBox(height: 12),
        _field('LIEU *', _lieuC, 'Ex: Rabat',
          validator: (v) => v!.isEmpty ? 'Requis' : null),
        const SizedBox(height: 12),
        _label('DATE *'),
        GestureDetector(
          onTap: () async {
            final p = await showDatePicker(context: context,
              initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (p != null) setState(() => _date = p);
          },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border)),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(_date == null ? 'JJ/MM/AAAA' : DateFormat('dd/MM/yyyy').format(_date!),
                style: T.body(_date == null ? AppColors.textMuted : AppColors.textPrimary)),
            ]))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field('HEURE DÉBUT', _hDebC, '09h00')),
          const SizedBox(width: 10),
          Expanded(child: _field('HEURE FIN', _hFinC, '17h00')),
        ]),
        const SizedBox(height: 12),
        _label('TYPE *'),
        Row(children: EventType.values.map((t) {
          final labels = {'conference': 'Conférence', 'reunion': 'Réunion',
            'audit': 'Audit', 'autre': 'Autre'};
          final sel = _type == t;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _type = t),
            child: Container(
              margin: EdgeInsets.only(right: t != EventType.autre ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: sel ? AppColors.eventBg : Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: sel ? AppColors.event : AppColors.border,
                  width: sel ? 1.5 : 1)),
              child: Center(child: Text(labels[t.name] ?? t.name,
                style: TextStyle(color: sel ? AppColors.event : AppColors.textMuted,
                  fontSize: 11, fontWeight: FontWeight.w700))))));
        }).toList()),
        const SizedBox(height: 12),
        _label('PARTICIPANTS'),
        Row(children: [
          Expanded(child: TextFormField(
            controller: _partC, style: T.body(AppColors.textPrimary),
            decoration: _dec('Nom du participant'))),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_partC.text.trim().isEmpty) return;
              setState(() { _parts.add(_partC.text.trim()); _partC.clear(); });
            },
            child: Container(width: 44, height: 46,
              decoration: BoxDecoration(color: AppColors.event, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add, color: Colors.white))),
        ]),
        if (_parts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.border)),
            child: Column(children: _parts.asMap().entries.map((entry) {
              final i = entry.key; final p = entry.value;
              return Row(children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.event),
                const SizedBox(width: 8),
                Expanded(child: Text(p, style: T.body(AppColors.textPrimary))),
                IconButton(icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.danger, size: 18),
                  onPressed: () => setState(() => _parts.removeAt(i))),
              ]);
            }).toList())),
        ],
        const SizedBox(height: 12),
        _field('DESCRIPTION', _descC, 'Description optionnelle...', maxLines: 3),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.event, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("CRÉER L'ÉVÉNEMENT",
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4)))),
      ])));

  Widget _field(String label, TextEditingController c, String hint,
      {int maxLines = 1, String? Function(String?)? validator}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label), const SizedBox(height: 5),
      TextFormField(controller: c, maxLines: maxLines, validator: validator,
        style: T.body(AppColors.textPrimary), decoration: _dec(hint)),
    ]);

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 4),
    child: Text(t, style: T.label(AppColors.textSecond)));

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint, hintStyle: T.body(AppColors.textMuted),
    filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.event, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12));
}
