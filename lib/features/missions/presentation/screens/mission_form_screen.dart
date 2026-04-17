import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cdc_app/core/theme/app_colors.dart';
import 'package:cdc_app/core/theme/app_text_styles.dart';
import 'package:cdc_app/data/models/models.dart';
import 'package:cdc_app/data/services/supabase_service.dart';
import 'package:cdc_app/core/constants/app_constants.dart';

class MissionFormScreen extends StatefulWidget {
  final VoidCallback onCreated;
  const MissionFormScreen({super.key, required this.onCreated});
  @override
  State<MissionFormScreen> createState() => _MissionFormScreenState();
}

class _MissionFormScreenState extends State<MissionFormScreen> {
  final _fk    = GlobalKey<FormState>();
  final _titC  = TextEditingController();
  final _vilC  = TextEditingController();
  final _orgC  = TextEditingController();
  final _descC = TextEditingController();
  final _partC = TextEditingController();
  String?   _region;
  DateTime? _debut, _fin;
  bool      _saving = false;
  final List<Map<String, String>> _equipe = [];

  final _regions = ['Tanger-Tétouan-Al Hoceïma','Oriental','Fès-Meknès',
    'Rabat-Salé-Kénitra','Béni Mellal-Khénifra','Casablanca-Settat',
    'Marrakech-Safi','Drâa-Tafilalet','Souss-Massa',
    'Guelmim-Oued Noun','Laâyoune-Sakia El Hamra','Dakhla-Oued Ed Dahab'];

  final _structures = ['Audit Financier','Juridiction Financière',
    "Systèmes d'Information",'Administration Générale',
    'Relations Institutionnelles','Cours Régionales'];

  @override
  void dispose() {
    _titC.dispose(); _vilC.dispose(); _orgC.dispose();
    _descC.dispose(); _partC.dispose(); super.dispose();
  }

  Future<void> _submit() async {
    if (!_fk.currentState!.validate() || _region == null || _debut == null || _fin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complétez tous les champs (*)')));
      return;
    }
    setState(() => _saving = true);
    final user   = SupabaseService().currentUser;
    final equipe = _equipe.map((p) => '${p["nom"]} (${p["structure"]})').toList();
    if (user != null && !equipe.any((e) => e.contains(user.fullName))) {
      equipe.insert(0, '${user.fullName} (${user.department})');
    }
    final ok = await SupabaseService().insertMission(Mission(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titre: _titC.text, region: _region!, ville: _vilC.text,
      organisme: _orgC.text, dateDebut: _debut!, dateFin: _fin!,
      equipe: equipe, description: _descC.text,
      
      createdBy: user?.id ?? 'system', createdAt: DateTime.now(),
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
      title: const Text('Nouvelle mission', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
    body: Form(key: _fk,
      child: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 40), children: [
        _field('TITRE *', _titC, 'Audit des comptes 2026',
          validator: (v) => v!.isEmpty ? 'Requis' : null),
        const SizedBox(height: 12),
        _label('RÉGION *'),
        _dropdown(_regions, _region, 'Choisir la région',
          (v) => setState(() => _region = v)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field('VILLE *', _vilC, 'Rabat',
            validator: (v) => v!.isEmpty ? 'Requis' : null)),
          const SizedBox(width: 10),
          Expanded(child: _field('ORGANISME *', _orgC, 'Ministère...',
            validator: (v) => v!.isEmpty ? 'Requis' : null)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('DATE DÉBUT *'), _datePick(true),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('DATE FIN *'), _datePick(false),
          ])),
        ]),
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
              setState(() {
                _equipe.add({'nom': _partC.text.trim(), 'structure': _structures[0]});
                _partC.clear();
              });
            },
            child: Container(width: 44, height: 46,
              decoration: BoxDecoration(color: AppColors.maroon, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add, color: Colors.white))),
        ]),
        if (_equipe.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.border)),
            child: Column(children: _equipe.asMap().entries.map((entry) {
              final i = entry.key; final p = entry.value;
              return Padding(padding: const EdgeInsets.only(bottom: 7),
                child: Row(children: [
                  Expanded(child: Text(p['nom']!,
                    style: T.bold(AppColors.textPrimary).copyWith(fontSize: 12))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                      value: p['structure'], isDense: true, isExpanded: true,
                      items: _structures.map((s) => DropdownMenuItem(value: s,
                        child: Text(s, style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _equipe[i]['structure'] = v!),
                    )))),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 18),
                    onPressed: () => setState(() => _equipe.removeAt(i))),
                ]));
            }).toList())),
        ],
        const SizedBox(height: 12),
        _field('DESCRIPTION', _descC, 'Détails de la mission...', maxLines: 3),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.maroon, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('CRÉER LA MISSION',
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
      borderSide: const BorderSide(color: AppColors.maroon, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12));

  Widget _dropdown(List<String> items, String? value, String hint, void Function(String?) onChange) =>
    Container(decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: value, isExpanded: true,
        hint: Text(hint, style: T.body(AppColors.textMuted)),
        items: items.map((r) => DropdownMenuItem(value: r,
          child: Text(r, style: T.body(AppColors.textPrimary)))).toList(),
        onChanged: onChange)));

  Widget _datePick(bool isStart) {
    final date = isStart ? _debut : _fin;
    return GestureDetector(
      onTap: () async {
        final p = await showDatePicker(context: context,
          initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (p != null) setState(() => isStart ? _debut = p : _fin = p);
      },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(date == null ? 'JJ/MM/AAAA' : DateFormat('dd/MM/yyyy').format(date),
            style: T.body(date == null ? AppColors.textMuted : AppColors.textPrimary)),
        ])));
  }
}
