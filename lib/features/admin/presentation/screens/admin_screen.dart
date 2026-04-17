import 'package:flutter/material.dart';
import 'package:cdc_app/core/theme/app_colors.dart';
import 'package:cdc_app/core/theme/app_text_styles.dart';
import 'package:cdc_app/core/constants/app_constants.dart';
import 'package:cdc_app/core/widgets/shared_widgets.dart';
import 'package:cdc_app/data/models/models.dart';
import 'package:cdc_app/data/services/supabase_service.dart';

class AdminScreen extends StatefulWidget {
  final bool isTab;
  const AdminScreen({super.key, this.isTab = false});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<AppUser> _users   = [];
  bool          _loading = true;
  String?       _error;

  final _firstC = TextEditingController();
  final _lastC  = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  UserRole _role = UserRole.magistrat;
  String?  _dept;
  bool     _saving = false;

  final _editFirstC = TextEditingController();
  final _editLastC  = TextEditingController();
  final _editEmailC = TextEditingController();
  UserRole _editRole = UserRole.magistrat;
  String?  _editDept;

  final _depts = [
    'Présidence','Administration générale','Audit Financier',
    'Juridiction Financière',"Systèmes d'Information",
    'Relations Institutionnelles','Cours Régionales',
  ];

  @override
  void initState() { super.initState(); Future.microtask(() => _load()); }

  @override
  void dispose() {
    _firstC.dispose(); _lastC.dispose(); _emailC.dispose(); _phoneC.dispose();
    _editFirstC.dispose(); _editLastC.dispose(); _editEmailC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final users = await SupabaseService().getAllUsers();
    if (mounted) setState(() { _users = users; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.offWhite,
    body: Column(children: [
      Container(color: AppColors.maroon,
        child: SafeArea(bottom: false, child: Padding(
          padding: EdgeInsets.fromLTRB(14, 12, 14, widget.isTab ? 20 : 16),
          child: Row(children: [
            if (!widget.isTab) ...[
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 19))),
              const SizedBox(width: 12),
            ],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Gestion des comptes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              Text('${_users.length} compte(s)',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            ])),
          ])))),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.maroon))
        : _users.isEmpty
          ? Center(child: Text('Aucun compte', style: T.body(AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 90),
              itemCount: _users.length,
              itemBuilder: (_, i) => _userCard(_users[i]))),
    ]),
    floatingActionButton: Padding(
      padding: EdgeInsets.only(bottom: widget.isTab ? 60 : 0),
      child: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: AppColors.maroon, foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.person_add_outlined, size: 18),
        label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.w800))),
    ));

  Widget _userCard(AppUser u) {
    Color avBg;
    switch (u.role) {
      case UserRole.president: avBg = AppColors.gold; break;
      case UserRole.admin:     avBg = AppColors.maroon; break;
      case UserRole.directeur: avBg = AppColors.info; break;
      default:                 avBg = AppColors.success;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: u.isActive ? Colors.white : const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: u.isActive ? AppColors.border
          : AppColors.gold.withOpacity(0.25))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(children: [
            UserAvatar(initials: u.initials, size: 38, bg: avBg),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.fullName, style: T.bold(AppColors.textPrimary).copyWith(fontSize: 13)),
              Text(u.email, style: T.small(AppColors.textMuted), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: u.role == UserRole.president ? AppColors.goldPale
                      : u.role == UserRole.admin ? AppColors.maroonPale
                      : AppColors.successBg,
                    borderRadius: BorderRadius.circular(9)),
                  child: Text(u.role.label,
                    style: T.micro(u.role == UserRole.president ? const Color(0xFF7A5200)
                      : u.role == UserRole.admin ? AppColors.maroon : AppColors.success))),
                const SizedBox(width: 8),
                Container(width: 6, height: 6, decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: u.isActive ? AppColors.success : AppColors.warning)),
                const SizedBox(width: 4),
                Text(u.isActive ? 'Actif' : 'En attente',
                  style: T.micro(u.isActive ? AppColors.success : AppColors.warning)),
              ]),
            ])),
          ])),
        Container(margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(7)),
          child: Row(children: [
            const Icon(Icons.business_outlined, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(u.department, style: T.small(AppColors.textMuted)),
          ])),
        if (u.role != UserRole.president) ...[
          const Divider(height: 1, color: AppColors.border),
          Row(children: [
            _action('Invitation', Icons.email_outlined, AppColors.info, () => _sendInvite(u)),
            _divV(),
            _action('Modifier', Icons.edit_outlined, AppColors.maroon, () => _openEdit(u)),
            _divV(),
            _action('Supprimer', Icons.delete_outline, AppColors.danger, () => _deleteUser(u)),
          ]),
        ] else ...[
          const Divider(height: 1, color: AppColors.border),
          Row(children: [
            _action('Renvoyer invitation', Icons.email_outlined, AppColors.info, () => _sendInvite(u)),
          ]),
        ],
      ]));
  }

  Widget _action(String label, IconData icon, Color color, VoidCallback onTap) =>
    Expanded(child: GestureDetector(onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis),
        ]))));

  Widget _divV() => Container(width: 1, height: 32, color: AppColors.border);

  void _sendInvite(AppUser u) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Invitation envoyée à ${u.email}'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  Future<void> _deleteUser(AppUser u) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le compte'),
        content: Text('Supprimer le compte de ${u.fullName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger,
              foregroundColor: Colors.white, elevation: 0),
            child: const Text('Supprimer')),
        ]));
    if (ok == true) { await SupabaseService().deleteUser(u.id); _load(); }
  }

  void _openAdd() {
    _firstC.clear(); _lastC.clear(); _emailC.clear(); _phoneC.clear();
    setState(() { _role = UserRole.magistrat; _dept = null; _error = null; });
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => _sheet(ctx, setS, false, null)));
  }

  void _openEdit(AppUser u) {
    final parts = u.fullName.trim().split(' ');
    _editFirstC.text = parts.isNotEmpty ? parts.first : '';
    _editLastC.text  = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    _editEmailC.text = u.email;
    setState(() {
      _editRole = u.role;
      _editDept = _depts.contains(u.department) ? u.department : null;
      _error    = null;
    });
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => _sheet(ctx, setS, true, u)));
  }

  Widget _sheet(BuildContext ctx, StateSetter setS, bool isEdit, AppUser? user) =>
    Container(
      decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 32, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(isEdit ? 'Modifier le compte' : 'Nouveau compte',
              style: T.h3(AppColors.textPrimary)),
            GestureDetector(onTap: () => Navigator.pop(ctx),
              child: Container(width: 28, height: 28,
                decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close, size: 16, color: AppColors.textMuted))),
          ])),
        const Divider(height: 1),
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _sf('PRÉNOM *', isEdit ? _editFirstC : _firstC, 'Youssef')),
              const SizedBox(width: 10),
              Expanded(child: _sf('NOM *', isEdit ? _editLastC : _lastC, 'Benali')),
            ]),
            const SizedBox(height: 10),
            _sf('EMAIL *', isEdit ? _editEmailC : _editEmailC, 'prenom.nom@courdescomptes.ma',
              keyboard: TextInputType.emailAddress),
            if (!isEdit) ...[const SizedBox(height: 10), _sf('TÉLÉPHONE', _phoneC, '+212 6XX XXX XXX')],
            const SizedBox(height: 10),
            Text('DÉPARTEMENT *', style: T.label(AppColors.textSecond)),
            const SizedBox(height: 5),
            Container(decoration: BoxDecoration(color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: isEdit ? _editDept : _dept,
                isExpanded: true,
                hint: Text('Sélectionner', style: T.body(AppColors.textMuted)),
                items: _depts.map((d) => DropdownMenuItem(value: d,
                  child: Text(d, style: T.body(AppColors.textPrimary)))).toList(),
                onChanged: (v) => setS(() => isEdit ? _editDept = v : _dept = v)))),
            const SizedBox(height: 12),
            Text('RÔLE *', style: T.label(AppColors.textSecond)),
            const SizedBox(height: 8),
            Row(children: UserRole.values.map((r) {
              final sel = (isEdit ? _editRole : _role) == r;
              return Expanded(child: GestureDetector(
                onTap: () => setS(() => isEdit ? _editRole = r : _role = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: r != UserRole.directeur ? 7 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.maroonPale : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? AppColors.maroon : AppColors.border,
                      width: sel ? 2 : 1)),
                  child: Column(children: [
                    Text(r == UserRole.president ? '👑'
                      : r == UserRole.admin ? '⚙️'
                      : r == UserRole.directeur ? '📋' : '⚖️',
                      style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(r.label, style: TextStyle(fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: sel ? AppColors.maroon : AppColors.textMuted),
                      textAlign: TextAlign.center),
                  ]))));
            }).toList()),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: T.small(AppColors.danger).copyWith(fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 16),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : () => isEdit ? _submitEdit(ctx, user!) : _submitAdd(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.maroon, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'ENREGISTRER' : 'CRÉER LE COMPTE',
                      style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4)))),
          ]))),
      ]));

  Widget _sf(String label, TextEditingController c, String hint,
      {TextInputType keyboard = TextInputType.text}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: T.label(AppColors.textSecond)), const SizedBox(height: 5),
      TextFormField(controller: c, keyboardType: keyboard,
        style: T.body(AppColors.textPrimary),
        decoration: InputDecoration(hintText: hint, hintStyle: T.body(AppColors.textMuted),
          filled: true, fillColor: AppColors.offWhite,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.maroon, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12))),
    ]);

  Future<void> _submitAdd(BuildContext ctx) async {
    if (_firstC.text.isEmpty || _lastC.text.isEmpty || _emailC.text.isEmpty || _dept == null) {
      setState(() => _error = 'Complétez tous les champs.'); return;
    }
    setState(() { _saving = true; _error = null; });
    final ok = await SupabaseService().createUser(
      fullName: '${_firstC.text.trim()} ${_lastC.text.trim()}',
      email: _emailC.text.trim(), role: _role,
      department: _dept!, phone: _phoneC.text.trim());
    if (mounted) {
      setState(() => _saving = false);
      if (!ok) { setState(() => _error = 'Email déjà existant.'); return; }
      Navigator.pop(ctx); _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Compte créé avec succès'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _submitEdit(BuildContext ctx, AppUser u) async {
    if (_editFirstC.text.isEmpty || _editLastC.text.isEmpty || _editDept == null) {
      setState(() => _error = 'Complétez tous les champs.'); return;
    }
    setState(() { _saving = true; _error = null; });
    await SupabaseService().updateUser(
      id: u.id,
      fullName: '${_editFirstC.text.trim()} ${_editLastC.text.trim()}',
      email: _editEmailC.text.trim(), role: _editRole, department: _editDept!);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(ctx); _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Compte modifié avec succès'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    }
  }
}
