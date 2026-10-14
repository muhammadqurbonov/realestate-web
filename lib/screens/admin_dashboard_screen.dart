import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../models/property.dart';
import '../theme/app_colors.dart';
import 'join_requests_screen.dart';
import 'manager_properties_screen.dart';

enum _Period { today, week, month, all }

/// Статистикаи як менеҷер.
class _Stat {
  final String uid;
  String name;
  UserRole? role;
  int total = 0, active = 0, sold = 0;
  int addedToday = 0, soldToday = 0;
  int addedPeriod = 0, soldPeriod = 0;
  _Stat(this.uid, this.name, this.role);
}

class _Month {
  final DateTime start;
  int added = 0, sold = 0;
  _Month(this.start);
}

/// Дашборд — танҳо барои админ ва суперадмин.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _Period _period = _Period.month;
  final FirestoreService _fs = FirestoreService();

  static const _monthsRu = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
  static const _monthsTj = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  String _compact(double v, bool isRu) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)} ${isRu ? "млрд" : "млрд"}';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)} млн';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)} ${isRu ? "тыс." : "ҳаз."}';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final isRu = t.locale == AppLocale.ru;
    final me = context.watch<AuthService>().currentUser;
    if (me == null) return const SizedBox();
    String L(String tj, String ru) => isRu ? ru : tj;

    return Scaffold(
      appBar: AppBar(title: Text(L('Дашборд', 'Дашборд'))),
      body: StreamBuilder<List<Property>>(
        stream: _fs.allProperties(),
        builder: (context, propSnap) {
          return StreamBuilder<List<AppUser>>(
            stream: _fs.companyUsers(me.companyId),
            builder: (context, userSnap) {
              if (propSnap.hasError || userSnap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('${propSnap.error ?? userSnap.error}',
                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ),
                );
              }
              if (!propSnap.hasData || !userSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final props = propSnap.data!.where((p) => p.companyId == me.companyId).toList();
              final users = userSnap.data!;
              return _buildBody(context, t, isRu, L, me, props, users);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppStrings t, bool isRu, String Function(String, String) L, AppUser me,
      List<Property> props, List<AppUser> users) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final monthStart = DateTime(now.year, now.month, 1);
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);

    DateTime? periodStart;
    switch (_period) {
      case _Period.today:
        periodStart = today;
        break;
      case _Period.week:
        periodStart = weekStart;
        break;
      case _Period.month:
        periodStart = monthStart;
        break;
      case _Period.all:
        periodStart = null;
        break;
    }
    bool inPeriod(DateTime d) => periodStart == null || !d.isBefore(periodStart);
    bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

    final approvedUsers = users.where((u) => u.approved).toList();
    final pendingCount = users.length - approvedUsers.length;

    // --- Статистикаи ҳар менеҷер ---
    final stats = <String, _Stat>{
      for (final u in approvedUsers) u.uid: _Stat(u.uid, u.fullName, u.role),
    };

    // --- Моҳҳои охир (6) ---
    final months = List.generate(6, (i) => _Month(DateTime(now.year, now.month - 5 + i, 1)));

    int total = props.length, active = 0, sold = 0;
    int addedToday = 0, soldToday = 0, addedMonth = 0, soldMonth = 0, addedPrev = 0, soldPrev = 0;
    double activeValue = 0;
    final byCategory = <String, int>{'apartment': 0, 'havli': 0, 'dacha': 0};

    for (final p in props) {
      final s = stats.putIfAbsent(p.addedByUid, () => _Stat(p.addedByUid, p.addedByName, null));
      s.total++;
      if (p.isSold) {
        sold++;
        s.sold++;
      } else {
        active++;
        s.active++;
        activeValue += p.price;
        final key = p.category == ListingCategory.apartment
            ? 'apartment'
            : (p.houseLandType == HouseLandType.dacha ? 'dacha' : 'havli');
        byCategory[key] = (byCategory[key] ?? 0) + 1;
      }

      // Илова шуд
      if (sameDay(p.createdAt, today)) {
        addedToday++;
        s.addedToday++;
      }
      if (!p.createdAt.isBefore(monthStart)) addedMonth++;
      if (!p.createdAt.isBefore(prevMonthStart) && p.createdAt.isBefore(monthStart)) addedPrev++;
      if (inPeriod(p.createdAt)) s.addedPeriod++;
      for (final m in months) {
        if (p.createdAt.year == m.start.year && p.createdAt.month == m.start.month) m.added++;
      }

      // Фурӯхта шуд (танҳо агар санаи фурӯш маълум бошад)
      final sd = p.soldAt;
      if (p.isSold && sd != null) {
        if (sameDay(sd, today)) {
          soldToday++;
          s.soldToday++;
        }
        if (!sd.isBefore(monthStart)) soldMonth++;
        if (!sd.isBefore(prevMonthStart) && sd.isBefore(monthStart)) soldPrev++;
        if (inPeriod(sd)) s.soldPeriod++;
        for (final m in months) {
          if (sd.year == m.start.year && sd.month == m.start.month) m.sold++;
        }
      }
    }

    final managerRows = stats.values.toList()
      ..sort((a, b) {
        final c = b.addedPeriod.compareTo(a.addedPeriod);
        if (c != 0) return c;
        final d = b.soldPeriod.compareTo(a.soldPeriod);
        if (d != 0) return d;
        return b.total.compareTo(a.total);
      });

    final managersCount = approvedUsers.where((u) => u.role == UserRole.manager).length;
    final adminsCount = approvedUsers.where((u) => u.role != UserRole.manager).length;
    final monthNames = isRu ? _monthsRu : _monthsTj;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        // ---------- Дархостҳои интизор ----------
        if (pendingCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinRequestsScreen())),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.orange.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add_alt_1_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isRu ? 'Ожидают принятия: $pendingCount' : 'Интизори қабул: $pendingCount',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),

        // ---------- Умумӣ ----------
        _SectionTitle(L('Умумӣ', 'Общее')),
        _grid([
          _Kpi(Icons.home_work_rounded, '$total', L('Ҳамаи хонаҳо', 'Всего объектов'), AppColors.primary),
          _Kpi(Icons.sell_outlined, '$active', L('Фаъол (дар фурӯш)', 'Активные'), const Color(0xFF12A36B)),
          _Kpi(Icons.check_circle_outline_rounded, '$sold', L('Фурӯхташуда', 'Продано'), Colors.red.shade400),
          _Kpi(Icons.payments_outlined, '${_compact(activeValue, isRu)} ${t.t('somoni')}',
              L('Арзиши хонаҳои фаъол', 'Стоимость активных'), const Color(0xFFB6852C)),
          _Kpi(Icons.badge_outlined, '$managersCount', L('Менеҷерон', 'Менеджеров'), const Color(0xFF14A0C8)),
          _Kpi(Icons.admin_panel_settings_outlined, '$adminsCount', L('Админҳо', 'Админов'), const Color(0xFF9B3FBF)),
        ]),
        const SizedBox(height: 18),

        // ---------- Имрӯз ва ин моҳ ----------
        _SectionTitle(L('Имрӯз ва ин моҳ', 'Сегодня и этот месяц')),
        _grid([
          _Kpi(Icons.add_home_outlined, '$addedToday', L('Имрӯз илова шуд', 'Добавлено сегодня'), AppColors.primary),
          _Kpi(Icons.handshake_outlined, '$soldToday', L('Имрӯз фурӯхта шуд', 'Продано сегодня'), Colors.red.shade400),
          _Kpi(Icons.calendar_month_outlined, '$addedMonth', L('Ин моҳ илова шуд', 'Добавлено за месяц'),
              AppColors.primary, delta: addedMonth - addedPrev, deltaSuffix: L('аз моҳи гузашта', 'к прошлому мес.')),
          _Kpi(Icons.trending_up_rounded, '$soldMonth', L('Ин моҳ фурӯхта шуд', 'Продано за месяц'),
              Colors.red.shade400, delta: soldMonth - soldPrev, deltaSuffix: L('аз моҳи гузашта', 'к прошлому мес.')),
        ]),
        const SizedBox(height: 18),

        // ---------- Динамикаи 6 моҳ ----------
        _SectionTitle(L('Динамика (6 моҳ)', 'Динамика (6 месяцев)')),
        _Glass(
          child: Column(
            children: [
              _MonthsChart(
                months: months,
                labels: [for (final m in months) monthNames[m.start.month - 1]],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Legend(AppColors.primary, L('Илова шуд', 'Добавлено')),
                  const SizedBox(width: 18),
                  _Legend(const Color(0xFFE5645A), L('Фурӯхта шуд', 'Продано')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ---------- Аз рӯи навъ ----------
        _SectionTitle(L('Хонаҳои фаъол аз рӯи навъ', 'Активные по типу')),
        _Glass(
          child: Column(
            children: [
              _CategoryBar(t.t('category_apartment'), byCategory['apartment'] ?? 0, active, const Color(0xFF1E6FD9)),
              const SizedBox(height: 10),
              _CategoryBar(t.t('houseland_havli'), byCategory['havli'] ?? 0, active, const Color(0xFF12A36B)),
              const SizedBox(height: 10),
              _CategoryBar(t.t('houseland_dacha'), byCategory['dacha'] ?? 0, active, const Color(0xFFB6852C)),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ---------- Кормандон ----------
        _SectionTitle(L('Кормандон', 'Сотрудники')),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_Period>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: _Period.today, label: Text(L('Имрӯз', 'Сегодня'))),
              ButtonSegment(value: _Period.week, label: Text(L('7 рӯз', '7 дней'))),
              ButtonSegment(value: _Period.month, label: Text(L('Моҳ', 'Месяц'))),
              ButtonSegment(value: _Period.all, label: Text(L('Ҳама', 'Все'))),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
        ),
        const SizedBox(height: 12),
        if (managerRows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text(t.t('no_results'), style: const TextStyle(color: Colors.grey))),
          ),
        for (var i = 0; i < managerRows.length; i++)
          _ManagerCard(
            rank: i + 1,
            stat: managerRows[i],
            isMe: managerRows[i].uid == me.uid,
            t: t,
            isRu: isRu,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManagerPropertiesListScreen(
                  uid: managerRows[i].uid,
                  name: managerRows[i].name,
                  isOwn: managerRows[i].uid == me.uid,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          L('Эзоҳ: хонаҳои пештара фурӯхташуда, ки санаи фурӯш надоранд, дар шумораи умумии «Фурӯхташуда» ҳисоб мешаванд, аммо дар статистикаи давраҳо не.',
              'Примечание: ранее проданные объекты без даты продажи входят в общее число «Продано», но не попадают в статистику по периодам.'),
          style: TextStyle(fontSize: 11.5, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _grid(List<_Kpi> items) {
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final k in items) SizedBox(width: w, child: _KpiCard(k))],
      );
    });
  }
}

// ======================= Виджетҳо =======================

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.primaryDark)),
      );
}

class _Glass extends StatelessWidget {
  final Widget child;
  const _Glass({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: child,
      );
}

class _Kpi {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final int? delta;
  final String deltaSuffix;
  _Kpi(this.icon, this.value, this.label, this.color, {this.delta, this.deltaSuffix = ''});
}

class _KpiCard extends StatelessWidget {
  final _Kpi k;
  const _KpiCard(this.k);

  @override
  Widget build(BuildContext context) {
    final d = k.delta;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [BoxShadow(color: k.color.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: k.color.withOpacity(0.13), borderRadius: BorderRadius.circular(12)),
            child: Icon(k.icon, color: k.color, size: 20),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(k.value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          ),
          const SizedBox(height: 2),
          Text(k.label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          if (d != null) ...[
            const SizedBox(height: 4),
            Text(
              '${d > 0 ? '+' : ''}$d ${k.deltaSuffix}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: d > 0 ? const Color(0xFF12A36B) : (d < 0 ? Colors.red : Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend(this.color, this.text);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      );
}

/// Диаграммаи сутунии 6 моҳа (бе китобхонаи иловагӣ).
class _MonthsChart extends StatelessWidget {
  final List<_Month> months;
  final List<String> labels;
  const _MonthsChart({required this.months, required this.labels});

  @override
  Widget build(BuildContext context) {
    var maxV = 1;
    for (final m in months) {
      if (m.added > maxV) maxV = m.added;
      if (m.sold > maxV) maxV = m.sold;
    }
    const chartH = 120.0;
    return SizedBox(
      height: chartH + 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < months.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: chartH,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _bar(months[i].added, maxV, chartH, AppColors.primary),
                        const SizedBox(width: 4),
                        _bar(months[i].sold, maxV, chartH, const Color(0xFFE5645A)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(int v, int maxV, double chartH, Color color) {
    final h = v == 0 ? 3.0 : (v / maxV) * (chartH - 16);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$v', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Container(
          width: 14,
          height: h,
          decoration: BoxDecoration(
            color: v == 0 ? color.withOpacity(0.25) : color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  const _CategoryBar(this.label, this.value, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final frac = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            Text('$value  (${(frac * 100).toStringAsFixed(0)}%)', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: frac, minHeight: 8, color: color, backgroundColor: color.withOpacity(0.15)),
        ),
      ],
    );
  }
}

class _ManagerCard extends StatelessWidget {
  final int rank;
  final _Stat stat;
  final bool isMe;
  final AppStrings t;
  final bool isRu;
  final VoidCallback onTap;
  const _ManagerCard({
    required this.rank,
    required this.stat,
    required this.isMe,
    required this.t,
    required this.isRu,
    required this.onTap,
  });

  String _role() {
    switch (stat.role) {
      case UserRole.superAdmin:
        return t.t('superadmin_label');
      case UserRole.admin:
        return t.t('admin_label');
      case UserRole.manager:
        return t.t('manager_label');
      case null:
        return isRu ? 'удалён' : 'нест шудааст';
    }
  }

  @override
  Widget build(BuildContext context) {
    String L(String tj, String ru) => isRu ? ru : tj;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text('$rank', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isMe ? '${stat.name} (${t.t('you')})' : stat.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        Text(_role(), style: TextStyle(fontSize: 11.5, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Cell('${stat.total}', L('Ҳама', 'Всего')),
                  _Cell('${stat.active}', L('Фаъол', 'Актив.')),
                  _Cell('${stat.sold}', L('Фурӯхта', 'Продано')),
                  _Cell('+${stat.addedPeriod}', L('Илова', 'Добавл.'), highlight: true),
                  _Cell('${stat.soldPeriod}', L('Фурӯш', 'Продажи'), highlight: true),
                ],
              ),
              if (stat.addedToday > 0 || stat.soldToday > 0) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    L('Имрӯз: +${stat.addedToday} илова, ${stat.soldToday} фурӯхта', 'Сегодня: +${stat.addedToday} добавлено, ${stat.soldToday} продано'),
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF12A36B), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;
  const _Cell(this.value, this.label, {this.highlight = false});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: highlight ? AppColors.primary : AppColors.primaryDark)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey[700]), textAlign: TextAlign.center),
          ],
        ),
      );
}
