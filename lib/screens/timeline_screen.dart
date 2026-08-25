import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/firestore_service.dart';
import '../utils/time_format.dart';
import '../theme/theme_toggle_button.dart';

/// شاشة التايم لاين: بتعرض اليوم بالساعات، وكل متدرب موعده في مكانه
/// حسب بداية ونهاية السيشن بتاعته. أخضر = مدفوع بالكامل، برتقالي = باقيله فلوس،
/// أحمر = خلص كل السيشنات المتفق عليها.
/// لو في أكتر من موعد في نفس الوقت، بيتحطوا جمب بعض تلقائي.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

/// نتيجة حساب مكان كل موعد على المحور الأفقي (عمود رقم كام من كام عمود)
class _AppointmentLayout {
  final ClientModel client;
  final int column;
  final int totalColumns;
  _AppointmentLayout(this.client, this.column, this.totalColumns);
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _service = FirestoreService();
  DateTime _selectedDay = DateTime.now();

  static const double hourHeight = 90;
  static const int startHour = 7; // أول ساعة تظهر في التايم لاين
  static const int endHour = 23; // آخر ساعة
  static const double labelWidth = 60; // عرض عمود أرقام الساعات
  static const double minBlockHeight = 68; // أقل ارتفاع لكارت الموعد (عشان مايحصلش overflow)

  int _timeToMinutes(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // كل ساعة حجز = حصة. موعد الساعتين بيتخصم منه حصتين مرة واحدة.
  int _sessionsCountFor(ClientModel client) {
    final minutes = _timeToMinutes(client.endTime) - _timeToMinutes(client.startTime);
    final hours = (minutes / 60).round();
    return hours < 1 ? 1 : hours;
  }

  void _changeDay(int deltaDays) {
    setState(() => _selectedDay = _selectedDay.add(Duration(days: deltaDays)));
  }

  // بيحسب مكان كل موعد أفقيًا: لو في تعارض وقت بين موعدين أو أكتر، بيوزع بينهم الأعمدة
  List<_AppointmentLayout> _layoutAppointments(List<ClientModel> clients) {
    if (clients.isEmpty) return [];

    final sorted = [...clients]
      ..sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));

    final columnEndTimes = <int>[];
    final columnOf = <String, int>{};

    for (final c in sorted) {
      final start = _timeToMinutes(c.startTime);
      final end = _timeToMinutes(c.endTime);
      int assigned = -1;
      for (int i = 0; i < columnEndTimes.length; i++) {
        if (columnEndTimes[i] <= start) {
          assigned = i;
          break;
        }
      }
      if (assigned == -1) {
        columnEndTimes.add(end);
        assigned = columnEndTimes.length - 1;
      } else {
        columnEndTimes[assigned] = end;
      }
      columnOf[c.id] = assigned;
    }

    // تجميع المواعيد المتداخلة زمنيًا مع بعض في "كلاستر" واحد عشان نحسب عدد الأعمدة المطلوبة
    final clusters = <List<ClientModel>>[];
    List<ClientModel> current = [];
    int clusterEnd = -1;
    for (final c in sorted) {
      final start = _timeToMinutes(c.startTime);
      final end = _timeToMinutes(c.endTime);
      if (current.isEmpty || start < clusterEnd) {
        current.add(c);
        clusterEnd = clusterEnd == -1 ? end : (end > clusterEnd ? end : clusterEnd);
      } else {
        clusters.add(current);
        current = [c];
        clusterEnd = end;
      }
    }
    if (current.isNotEmpty) clusters.add(current);

    final result = <_AppointmentLayout>[];
    for (final cluster in clusters) {
      final maxCol = cluster.map((c) => columnOf[c.id]!).reduce((a, b) => a > b ? a : b);
      final totalColumns = maxCol + 1;
      for (final c in cluster) {
        result.add(_AppointmentLayout(c, columnOf[c.id]!, totalColumns));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

    return Scaffold(
      appBar: AppBar(
        actions: const [ThemeToggleButton()],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDay(1)),
            Column(
              children: [
                Text(weekDays[_selectedDay.weekday % 7], style: const TextStyle(fontSize: 14)),
                Text('${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDay(-1)),
          ],
        ),
      ),
      body: StreamBuilder<List<ClientModel>>(
        stream: _service.streamClientsByDay(_selectedDay),
        builder: (context, snapshot) {
          final clients = snapshot.data ?? [];
          final totalHours = endHour - startHour;
          final layout = _layoutAppointments(clients);

          return LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth - labelWidth - 8;

              return SingleChildScrollView(
                child: SizedBox(
                  height: totalHours * hourHeight,
                  child: Stack(
                    children: [
                      // خطوط الساعات والأرقام
                      for (int h = startHour; h < endHour; h++)
                        Positioned(
                          top: (h - startHour) * hourHeight,
                          left: 0,
                          right: 0,
                          child: Row(
                            children: [
                              SizedBox(
                                width: labelWidth,
                                child: Text(
                                  formatTime12h('$h:00'),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(child: Container(height: 1, color: Colors.grey[800])),
                            ],
                          ),
                        ),

                      // كروت المواعيد، كل واحد في عموده المحسوب
                      for (final item in layout) _buildAppointmentBlock(item, availableWidth),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple,
        tooltip: 'إضافة موعد جديد',
        onPressed: () {
          // فتح نموذج إضافة سيشن/موعد جديد على نفس اليوم
          Navigator.of(context).pushNamed('/add');
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة موعد'),
      ),
    );
  }

  Widget _buildAppointmentBlock(_AppointmentLayout item, double availableWidth) {
    final client = item.client;
    final startMin = _timeToMinutes(client.startTime) - startHour * 60;
    final endMin = _timeToMinutes(client.endTime) - startHour * 60;
    final top = (startMin / 60) * hourHeight;
    final rawHeight = ((endMin - startMin) / 60) * hourHeight;
    final blockHeight = rawHeight < minBlockHeight ? minBlockHeight : rawHeight;
    final noSessionsLeft = client.remainingSessions <= 0;
    final color = noSessionsLeft
        ? Colors.red
        : (client.isFullyPaid ? Colors.green : Colors.orange);
    final isScooter = client.vehicleType == 'scooter';

    // كل عمود ياخد نصيبه من العرض المتاح، مع فاصل بسيط بين الأعمدة
    const gap = 4.0;
    final columnWidth = (availableWidth - (gap * (item.totalColumns - 1))) / item.totalColumns;
    final left = labelWidth + 6 + item.column * (columnWidth + gap);

    return Positioned(
      top: top,
      left: left,
      width: columnWidth,
      height: blockHeight,
      child: GestureDetector(
        onTap: () => _openAppointmentActions(client),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
          ),
          // ClipRect + FittedBox يمنعوا أي overflow نهائيًا حتى لو الكارت ضيق جدًا
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showDetails = constraints.maxHeight >= 60;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(isScooter ? Icons.electric_scooter : Icons.two_wheeler,
                            color: Colors.grey, size: 12),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            client.name,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // زرار مسح صريح للموعد، مش محتاج تدوس مطول
                        InkWell(
                          onTap: () => _confirmDelete(client),
                          child: const Icon(Icons.close, color: Colors.grey, size: 14),
                        ),
                      ],
                    ),
                    if (showDetails) ...[
                      Text(
                        '${formatTime12h(client.startTime)} - ${formatTime12h(client.endTime)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        noSessionsLeft
                            ? 'خلص ${client.totalSessions}/${client.usedSessions}'
                            : '${client.totalSessions}/${client.usedSessions} حصة',
                        style: TextStyle(
                          color: noSessionsLeft ? Colors.red : Colors.grey,
                          fontSize: 10,
                          fontWeight: noSessionsLeft ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // دوس على الموعد يظهرلك اختيارات: تسجيل حضور السيشن، أو إلغاء الموعد
  Future<void> _openAppointmentActions(ClientModel client) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(client.name,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${formatTime12h(client.startTime)} - ${formatTime12h(client.endTime)}  |  ${client.totalSessions}/${client.usedSessions} حصة (فاضله ${client.remainingSessions})',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text(
                  'تسجيل حضور السيشن دي (خصم ${_sessionsCountFor(client)} حصة)',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _markSessionAttended(client);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: Text('إلغاء الموعد',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(client);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // بيسجل إن السيشن اتعملت (يخصم من الرصيد حسب عدد ساعات الموعد)، بيسأل اختياريًا هو دفع كام،
  // وبيديك إشعار نهائي فيه عدد الحصص الفاضله وباقي عليه كام فلوس
  Future<void> _markSessionAttended(ClientModel client) async {
    final sessionsCount = _sessionsCountFor(client);
    final session = SessionModel(
      id: '',
      clientId: client.id,
      date: _selectedDay,
      startTime: client.startTime,
      endTime: client.endTime,
      sessionsCount: sessionsCount,
    );
    await _service.addSession(client, session, sessionsCount: sessionsCount);

    if (!mounted) return;

    final usedAfter = client.usedSessions + sessionsCount;
    final remainingSessionsAfter = client.totalSessions - usedAfter;

    // اختياري: اسأل المدرب هو دفع كام دلوقتي
    final paidNow = await _askForPayment(client);
    if (!mounted) return;

    double amountPaidAfter = client.amountPaid;
    if (paidNow != null && paidNow > 0) {
      await _service.addPayment(client.id, client.amountPaid, paidNow);
      amountPaidAfter = client.amountPaid + paidNow;
    }
    final remainingMoneyAfter = (client.totalPrice - amountPaidAfter).clamp(0, client.totalPrice);

    if (!mounted) return;

    final moneyLine = remainingMoneyAfter <= 0
        ? 'مدفوع بالكامل ✅'
        : 'باقي عليه ${remainingMoneyAfter.toStringAsFixed(0)} ج';

    if (remainingSessionsAfter <= 0) {
      // خلص كل السيشنات بتاعته - تنبيه واضح
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('خلص كل السيشنات! 🔴', style: TextStyle(color: Colors.red)),
          content: Text(
            '${client.name} وصل لـ ${client.totalSessions}/$usedAfter — خلص كل السيشنات المتفق عليها.\n$moneyLine\nممكن تفتحله سيشنات جديدة من شاشة "كل المتدربين".',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تمام'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'تم تسجيل الحضور (${sessionsCount} حصة): ${client.totalSessions}/$usedAfter — فاضله $remainingSessionsAfter حصة — $moneyLine'),
        ),
      );
    }
  }

  // دايلوج اختياري بعد تسجيل الحضور: هو دفع كام دلوقتي؟ وبيوريك "باقي عليه كام" لحظيًا وانت بتكتب
  // لو دست "تخطي" أو سبت الحقل فاضي، مفيش أي تغيير في الفلوس
  Future<double?> _askForPayment(ClientModel client) async {
    final paidCtrl = TextEditingController();
    double remaining = client.remainingAmount;

    return showDialog<double?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${client.name} دفع كام دلوقتي؟',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'السعر الكلي ${client.totalPrice.toStringAsFixed(0)} ج، المدفوع لحد دلوقتي ${client.amountPaid.toStringAsFixed(0)} ج',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: const InputDecoration(
                      labelText: 'المبلغ المدفوع دلوقتي (اختياري)',
                    ),
                    onChanged: (value) {
                      final paid = double.tryParse(value) ?? 0;
                      setDialogState(() {
                        remaining = (client.remainingAmount - paid).clamp(0, client.totalPrice);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    remaining <= 0 ? 'هيبقى مدفوع بالكامل ✅' : 'هيفضل عليه: ${remaining.toStringAsFixed(0)} ج',
                    style: TextStyle(
                      color: remaining <= 0 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('تخطي، مش دلوقتي'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, double.tryParse(paidCtrl.text)),
                  child: const Text('تسجيل الدفعة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // دوس على زرار الـ X عشان يظهرلك تأكيد إلغاء الموعد (المتدرب نفسه هيفضل محفوظ)
  Future<void> _confirmDelete(ClientModel client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إلغاء الموعد',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          'هيتشال موعد ${client.name} من التايم لاين بس بيانات المتدرب (السيشنات والفلوس) هتفضل محفوظة، وهتلاقيه في شاشة "كل المتدربين".',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('رجوع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إلغاء الموعد', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // بيتلغي في Firestore مباشرة، فهيختفي الموعد من التايم لاين في كل الأجهزة أوتوماتيك
      // (بدون ما نمسح بيانات المتدرب نفسه)
      await _service.cancelAppointment(client.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء الموعد، وبيانات المتدرب لسه محفوظة')),
        );
      }
    }
  }
}
