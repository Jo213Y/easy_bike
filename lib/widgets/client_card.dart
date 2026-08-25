import 'package:flutter/material.dart';
import '../models/client.dart';
import '../utils/time_format.dart';

/// كارت بيعرض بيانات المتدرب:
/// - أخضر لو الدفع كامل
/// - برتقالي لو باقي فلوس
/// - أحمر لو خلصت السيشنات
/// - رمادي لو الموعد ملغي
///
/// الأزرار:
/// - تعديل الموعد
/// - إضافة سيشنات
/// - حذف المتدرب
class ClientCard extends StatelessWidget {
  final ClientModel client;

  /// تعديل بيانات أو موعد المتدرب
  final VoidCallback? onNewAppointment;

  /// إضافة سيشنات جديدة
  final VoidCallback? onAddSessions;

  /// حذف المتدرب
  final VoidCallback? onDelete;

  const ClientCard({
    super.key,
    required this.client,
    this.onNewAppointment,
    this.onAddSessions,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final noSessionsLeft = client.remainingSessions <= 0;

    final borderColor = client.isCancelled
        ? Colors.grey
        : (noSessionsLeft
        ? Colors.red
        : (client.isFullyPaid ? Colors.green : Colors.orange));

    final isScooter = client.vehicleType == 'scooter';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (client.isCancelled)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 14,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'الموعد ملغي - بياناته محفوظة',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

          /// بيانات المتدرب
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isScooter
                              ? Icons.electric_scooter
                              : Icons.two_wheeler,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            client.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatTime12h(client.startTime)} - ${formatTime12h(client.endTime)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'جاي من: ${client.referredBy.isEmpty ? "-" : client.referredBy}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${client.totalSessions}/${client.usedSessions} حصة',
                    style: TextStyle(
                      color: noSessionsLeft
                          ? Colors.red
                          : Theme.of(context)
                          .colorScheme
                          .onSurface,
                      fontSize: 13,
                      fontWeight: noSessionsLeft
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (noSessionsLeft)
                    const Text(
                      'خلص كل السيشنات',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${_money(client.totalPrice)}/${_money(client.amountPaid)} ج',
                    style: TextStyle(
                      color: client.isFullyPaid
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// الأزرار
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNewAppointment,
                  icon: const Icon(
                    Icons.edit_calendar,
                    size: 16,
                  ),
                  label: Text(
                    client.isCancelled
                        ? 'إعادة الجدولة'
                        : 'تعديل الموعد',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                    Theme.of(context).colorScheme.onSurface,
                    side: const BorderSide(
                      color: Colors.grey,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddSessions,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 16,
                  ),
                  label: const Text(
                    'إضافة سيشنات',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(
                      color: Colors.purple,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              /// زر الحذف
              IconButton(
                tooltip: "حذف المتدرب",
                icon: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("حذف المتدرب"),
                      content: Text(
                        "هل أنت متأكد من حذف ${client.name}؟\nلن يمكن التراجع عن هذه العملية.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text("إلغاء"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text("حذف"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    onDelete?.call();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }


  String _money(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}