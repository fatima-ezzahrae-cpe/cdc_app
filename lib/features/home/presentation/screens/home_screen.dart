import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cdc_app/core/theme/app_colors.dart';
import 'package:cdc_app/core/theme/app_text_styles.dart';
import 'package:cdc_app/core/constants/app_constants.dart';
import 'package:cdc_app/core/widgets/shared_widgets.dart';
import 'package:cdc_app/data/models/models.dart';
import 'package:cdc_app/data/services/supabase_service.dart';
import 'package:cdc_app/features/admin/presentation/screens/admin_screen.dart';
import 'package:cdc_app/features/missions/presentation/screens/mission_form_screen.dart';
import 'package:cdc_app/features/events/presentation/screens/event_form_screen.dart';
import 'package:cdc_app/features/events/presentation/screens/event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  DateTime _month = DateTime.now();
  String _search = '';
  String _filter = 'tout';
  bool _loading = true;
  List<Mission>  _missions = [];
  List<AppEvent> _events   = [];
  int _unreadNotifs = 3; 

  AppUser? get _user => SupabaseService().currentUser;
  bool get _isAdmin => _user?.role == UserRole.admin || _user?.role == UserRole.president;
  bool get _isSuperAdmin => _user?.role == UserRole.admin; // Uniquement l'admin
  bool get _isMag   => _user?.role == UserRole.magistrat || _user?.role == UserRole.directeur;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final m = await SupabaseService().getMissions();
    final e = await SupabaseService().getEvents();
    if (mounted) setState(() { _missions = m; _events = e; _loading = false; });
  }

  List<dynamic> get _combinedItems {
    List<dynamic> items = [];
    final q = _search.toLowerCase().trim();
    
    if (_filter == 'tout' || _filter == 'missions') {
      var ms = _missions;
      if (q.isNotEmpty) {
        ms = ms.where((m) =>
          m.titre.toLowerCase().contains(q) ||
          m.ville.toLowerCase().contains(q) ||
          m.region.toLowerCase().contains(q) ||
          m.organisme.toLowerCase().contains(q) ||
          m.equipe.any((e) => e.toLowerCase().contains(q))).toList();
      }
      items.addAll(ms);
    }

    if (_filter == 'tout' || _filter == 'events') {
      var es = _events;
      if (q.isNotEmpty) {
        es = es.where((e) =>
          e.titre.toLowerCase().contains(q) ||
          e.lieu.toLowerCase().contains(q) ||
          e.participants.any((p) => p.toLowerCase().contains(q))).toList();
      }
      items.addAll(es);
    }

    items.sort((a, b) {
      final da = a is Mission ? a.dateDebut : (a as AppEvent).date;
      final db = b is Mission ? b.dateDebut : (b as AppEvent).date;
      return db.compareTo(da);
    });

    return items;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.offWhite,
    body: Column(children: [
      _topBar(),
      if (_tab == 0) _searchBar(),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.maroon))
        : IndexedStack(index: _tab, children: [
            _homeTab(),
            _missionsTab(),
            _calendarTab(),
            _eventsTab(),
            if (_isSuperAdmin) const AdminScreen(isTab: true),
            _profileTab(),
          ])),
    ]),
    bottomNavigationBar: _bottomNav(),
    floatingActionButton: _isMag && (_tab == 0 || _tab == 1 || _tab == 3) ? _fab() : null,
  );

  Widget _fab() => FloatingActionButton.extended(
    onPressed: _openForm,
    backgroundColor: AppColors.maroon, foregroundColor: Colors.white,
    elevation: 2,
    icon: const Icon(Icons.add_rounded, size: 20),
    label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
  );

  void _openForm() => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _FormTypeSheet(
      onMission: () { Navigator.pop(context); _openMissionForm(); },
      onEvent:   () { Navigator.pop(context); _openEventForm(); },
    ));

  void _openMissionForm() => Navigator.push(context, MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => MissionFormScreen(onCreated: () { Navigator.pop(context); _load(); }))).then((_) => _load());

  void _openEventForm() => Navigator.push(context, MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => EventFormScreen(onCreated: () { Navigator.pop(context); _load(); }))).then((_) => _load());

  Widget _homeTab() => RefreshIndicator(onRefresh: _load,
    child: ListView(padding: EdgeInsets.zero, children: [
      _calendarWidget(),
      Padding(padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Activités & Missions', style: T.bold(AppColors.textPrimary)),
            if (_search.isNotEmpty || _filter != 'tout')
              Text('${_combinedItems.length} résultat(s)', style: T.micro(AppColors.maroon)),
          ],
        )),
      if (_combinedItems.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(40),
          child: Text('Aucun élément trouvé', style: T.body(AppColors.textMuted))))
      else ..._combinedItems.map((item) => item is Mission ? _missionCard(item) : _eventCard(item as AppEvent)),
      const SizedBox(height: 80),
    ]));

  Widget _missionsTab() => RefreshIndicator(onRefresh: _load,
    child: ListView(padding: const EdgeInsets.fromLTRB(12, 10, 12, 80), children: [
      Text('${_missions.length} mission(s)', style: T.label(AppColors.textMuted)),
      const SizedBox(height: 10),
      if (_missions.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(30),
          child: Text('Aucune mission', style: T.body(AppColors.textMuted))))
      else ..._missions.map(_missionCard),
    ]));

  Widget _calendarTab() => RefreshIndicator(onRefresh: _load,
    child: ListView(padding: EdgeInsets.zero, children: [
      _calendarWidget(), const SizedBox(height: 80),
    ]));

  Widget _eventsTab() => RefreshIndicator(onRefresh: _load,
    child: ListView(padding: const EdgeInsets.fromLTRB(12, 10, 12, 80), children: [
      Text('${_events.length} événement(s)', style: T.label(AppColors.textMuted)),
      const SizedBox(height: 10),
      if (_events.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(30),
          child: Text('Aucun événement', style: T.body(AppColors.textMuted))))
      else ..._events.map(_eventCard),
    ]));

  Widget _profileTab() {
    final u = _user;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            UserAvatar(initials: u?.initials ?? '?', size: 80, bg: AppColors.maroon),
            const SizedBox(height: 16),
            Text(u?.fullName ?? '', style: T.h2(AppColors.textPrimary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.maroonPale, borderRadius: BorderRadius.circular(20)),
              child: Text(u?.role.label.toUpperCase() ?? '', style: T.micro(AppColors.maroon)),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        _sectionTitle('INFORMATIONS PERSONNELLES'),
        _infoTile(Icons.email_outlined, 'Email professionnel', u?.email ?? '-'),
        _infoTile(Icons.business_outlined, 'Département / Structure', u?.department ?? '-'),
        const SizedBox(height: 24),
        _sectionTitle('NOTIFICATIONS'),
        _profileTile(
          Icons.notifications_active_outlined,
          'Autorisations de notification',
          subtitle: 'Gérer les permissions système',
          onTap: _showNotifSettings,
        ),
        const SizedBox(height: 24),
        _sectionTitle('PARAMÈTRES ET APPLICATION'),
        _profileTile(
          Icons.lock_outline,
          'Sécurité du compte',
          subtitle: 'Changer le mot de passe',
          onTap: () => Navigator.pushNamed(context, '/change-password'),
        ),
        _profileTile(
          Icons.info_outline,
          'À propos de l\'application',
          subtitle: 'Cour des Comptes · Version 1.0.0',
        ),
        const SizedBox(height: 32),
        _logoutBtn(),
      ]),
    );
  }

  void _showNotifSettings() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 32, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const Icon(Icons.notifications_none_rounded, size: 50, color: AppColors.maroon),
        const SizedBox(height: 16),
        Text('Notifications', style: T.h2(AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Voulez-vous autoriser l\'application à vous envoyer des alertes pour les nouvelles missions et événements ?',
          textAlign: TextAlign.center, style: T.body(AppColors.textMuted)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('REFUSER'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications activées'), backgroundColor: AppColors.success)); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.maroon, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('AUTORISER'))),
        ]),
      ]),
    ));
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(t, style: T.label(AppColors.textMuted).copyWith(letterSpacing: 1.2)),
    ),
  );

  Widget _infoTile(IconData icon, String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(children: [
      Icon(icon, color: AppColors.maroon.withOpacity(0.6), size: 20),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: T.micro(AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: T.bold(AppColors.textPrimary)),
        ],
      )),
    ]),
  );

  Widget _profileTile(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) =>
    Container(margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: ListTile(
        leading: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.maroon, size: 18)),
        title: Text(title, style: T.bold(AppColors.textPrimary)),
        subtitle: subtitle != null ? Text(subtitle, style: T.small(AppColors.textMuted)) : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20) : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  Widget _logoutBtn() => GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULER')),
            TextButton(
              onPressed: () {
                SupabaseService().logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('DÉCONNEXION', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    },
    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.2))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
        const SizedBox(width: 8),
        Text('DÉCONNEXION', style: T.bold(AppColors.danger)),
      ])));

  Widget _topBar() => Container(
    color: AppColors.maroon,
    child: Stack(children: [
      Positioned(top: -30, right: -30, child: Container(
        width: 120, height: 120,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.04)))),
      SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Row(children: [
          Container(width: 34, height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: AppColors.gold.withOpacity(0.5))),
            child: const Icon(Icons.balance, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('COUR DES COMPTES',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            Text('ROYAUME DU MAROC',
              style: TextStyle(color: AppColors.gold, fontSize: 8, letterSpacing: 1.5)),
          ])),
          Stack(clipBehavior: Clip.none, children: [
            UserAvatar(initials: _user?.initials ?? '?', size: 32),
            if (_unreadNotifs > 0 && _isSuperAdmin) // Uniquement admin
              Positioned(right: -2, top: -2, child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                child: Text('$_unreadNotifs', style: const TextStyle(color: AppColors.maroon, fontSize: 7, fontWeight: FontWeight.bold)),
              )),
          ]),
        ])),
      ),
    ]),
  );

  Widget _searchBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
    child: Row(children: [
      Expanded(child: Container(height: 40,
        decoration: BoxDecoration(color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, color: AppColors.textMuted, size: 17),
          const SizedBox(width: 7),
          Expanded(child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: T.body(AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom...',
              hintStyle: T.body(AppColors.textMuted),
              border: InputBorder.none, isDense: true))),
        ]))),
      const SizedBox(width: 8),
      Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: AppColors.maroonPale,
          borderRadius: BorderRadius.circular(9)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: _filter,
          items: const [
            DropdownMenuItem(value: 'tout',     child: Text('Tout',        style: TextStyle(fontSize: 11))),
            DropdownMenuItem(value: 'missions', child: Text('Missions',    style: TextStyle(fontSize: 11))),
            DropdownMenuItem(value: 'events',   child: Text('Événements',  style: TextStyle(fontSize: 11))),
          ],
          onChanged: (v) => setState(() => _filter = v!),
          style: const TextStyle(color: AppColors.maroon, fontWeight: FontWeight.w700, fontSize: 11),
        ))),
    ]));

  Widget _calendarWidget() => Container(
    margin: const EdgeInsets.fromLTRB(11, 10, 11, 0),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Container(
        decoration: const BoxDecoration(color: AppColors.maroon,
          borderRadius: BorderRadius.vertical(top: Radius.circular(13))),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(DateFormat('MMMM yyyy', 'fr').format(_month).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
          Row(children: [
            _calBtn(Icons.chevron_left,  () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
            const SizedBox(width: 6),
            _calBtn(Icons.chevron_right, () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
          ]),
        ])),
      _calGrid(),
      Padding(padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
        child: Row(children: [
          _legend(AppColors.maroonPale, 'Mission'),
          const SizedBox(width: 14),
          _legend(AppColors.eventBg, 'Événement'),
        ])),
    ]));

  Widget _calGrid() {
    final last = DateTime(_month.year, _month.month + 1, 0).day;
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3),
      itemCount: last,
      itemBuilder: (_, i) {
        final day  = i + 1;
        final date = DateTime(_month.year, _month.month, day);
        final hm   = _missions.any((m) => m.isActiveOn(date));
        final he   = _events.any((e) =>
          e.date.year == date.year && e.date.month == date.month && e.date.day == date.day);
        final isToday = day == DateTime.now().day &&
          _month.month == DateTime.now().month && _month.year == DateTime.now().year;
        Color? bg;
        if (isToday)      bg = AppColors.maroon;
        else if (hm && he) bg = const Color(0xFFF0E6F8);
        else if (hm)       bg = AppColors.maroonPale;
        else if (he)       bg = AppColors.eventBg;
        return GestureDetector(
          onTap: () => _dayDetail(date),
          child: Container(
            decoration: BoxDecoration(color: bg ?? Colors.transparent, borderRadius: BorderRadius.circular(7)),
            child: Center(child: Text('$day', style: TextStyle(
              color: isToday ? Colors.white : AppColors.textPrimary,
              fontSize: 10, fontWeight: FontWeight.w700)))));
      });
  }

  void _dayDetail(DateTime day) {
    final ms = _missions.where((m) => m.isActiveOn(day)).toList();
    final es = _events.where((e) =>
      e.date.year == day.year && e.date.month == day.month && e.date.day == day.day).toList();
    if (ms.isEmpty && es.isEmpty) return;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 32, height: 4, margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Text(DateFormat('EEEE d MMMM', 'fr').format(day), style: T.h3(AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...ms.map((m) => ListTile(
            title: Text(m.titre, style: T.bold(AppColors.textPrimary)),
            subtitle: Text('${m.ville} · ${m.region}', style: T.small(AppColors.textMuted)),
            leading: Container(width: 34, height: 34,
              decoration: BoxDecoration(color: AppColors.maroonPale, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.folder_outlined, color: AppColors.maroon, size: 18)),
            onTap: () { Navigator.pop(context);
              Navigator.pushNamed(context, '/mission-detail', arguments: m).then((_) => _load()); })),
          ...es.map((e) => ListTile(
            title: Text(e.titre, style: T.bold(AppColors.textPrimary)),
            subtitle: Text(e.lieu, style: T.small(AppColors.textMuted)),
            leading: Container(width: 34, height: 34,
              decoration: BoxDecoration(color: AppColors.eventBg, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.event_outlined, color: AppColors.event, size: 18)),
            onTap: () { Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => EventDetailScreen(event: e))).then((_) => _load()); })),
        ])));
  }

  Widget _missionCard(Mission m) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, '/mission-detail', arguments: m).then((_) => _load()),
    child: Container(
      margin: const EdgeInsets.fromLTRB(11, 0, 11, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 3, height: 50,
          decoration: BoxDecoration(color: AppColors.maroon, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.titre, style: T.bold(AppColors.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text('${m.ville} · ${m.region}', style: T.small(AppColors.textMuted)),
          Text('${DateFormat('dd/MM/yyyy').format(m.dateDebut)} → ${DateFormat('dd/MM/yyyy').format(m.dateFin)}',
            style: T.micro(AppColors.textMuted)),
        ])),
        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
      ])));

  Widget _eventCard(AppEvent e) => GestureDetector(
    onTap: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: e))).then((_) => _load()),
    child: Container(
      margin: const EdgeInsets.fromLTRB(11, 0, 11, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.event.withOpacity(0.15))),
      child: Row(children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: AppColors.eventBg, borderRadius: BorderRadius.circular(9)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(DateFormat('dd').format(e.date),
              style: const TextStyle(color: AppColors.event, fontSize: 14, fontWeight: FontWeight.w800, height: 1)),
            Text(DateFormat('MMM', 'fr').format(e.date).toUpperCase(),
              style: const TextStyle(color: AppColors.event, fontSize: 8)),
          ])),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.titre, style: T.bold(AppColors.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${e.lieu}${e.heureDebut != null ? " · ${e.heureDebut}" : ""}',
            style: T.small(AppColors.textMuted)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: AppColors.eventBg, borderRadius: BorderRadius.circular(8)),
          child: Text(e.typeLabel, style: T.micro(AppColors.event))),
      ])));

  Widget _bottomNav() => Container(
    decoration: const BoxDecoration(color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.maroon, width: 2))),
    child: SafeArea(top: false, child: SizedBox(height: 58, child: Row(children: [
      _navItem(0, 'Accueil',    Icons.home_outlined),
      _navItem(1, 'Missions',   Icons.folder_outlined),
      _navItem(2, 'Calendrier', Icons.calendar_month_outlined),
      _navItem(3, 'Événements', Icons.event_outlined),
      if (_isSuperAdmin) _navItem(4, 'Comptes', Icons.group_outlined), // Uniquement admin
      _navItem(_isSuperAdmin ? 5 : 4, 'Profil', Icons.person_outline),
    ]))));

  Widget _navItem(int idx, String label, IconData icon) {
    final active = _tab == idx;
    return Expanded(child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _tab = idx),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: active ? AppColors.maroon : AppColors.textMuted, size: 22),
        const SizedBox(height: 2),
        if (active) Container(width: 14, height: 2, color: AppColors.maroon),
        Text(label, style: TextStyle(
          color: active ? AppColors.maroon : AppColors.textMuted,
          fontSize: 8.5, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
      ])));
  }

  Widget _calBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 24, height: 24,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, color: Colors.white, size: 16)));

  Widget _legend(Color color, String label) => Row(children: [
    Container(width: 9, height: 9,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 5),
    Text(label, style: T.micro(AppColors.textMuted)),
  ]);
}

class _FormTypeSheet extends StatelessWidget {
  final VoidCallback onMission, onEvent;
  const _FormTypeSheet({required this.onMission, required this.onEvent});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 32, height: 4, margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
      Text('Ajouter', style: T.h3(AppColors.textPrimary)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _btn(context, Icons.folder_outlined, 'Mission',    AppColors.maroonPale, AppColors.maroon, onMission)),
        const SizedBox(width: 12),
        Expanded(child: _btn(context, Icons.event_outlined,  'Événement',  AppColors.eventBg,   AppColors.event,  onEvent)),
      ]),
      const SizedBox(height: 8),
    ]));

  Widget _btn(BuildContext ctx, IconData icon, String label, Color bg, Color fg, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withOpacity(0.3))),
        child: Column(children: [
          Icon(icon, color: fg, size: 26),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 13)),
        ])));
}
