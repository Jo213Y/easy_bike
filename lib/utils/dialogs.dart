import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/firestore_service.dart';

/// دايلوج مشترك لإضافة سيشنات زيادة (تجديد/تمديد الباقة) لمتدرب موجود
/// مستخدم في أكتر من شاشة (الإضافة، وشاشة كل المتدربين)
Future<void> showAddSessionsDialog(
  BuildContext context,
  FirestoreService service,
  ClientModel client,
) async {
  final extraSessionsCtrl = TextEditingController();
  final extraPaymentCtrl = TextEditingController();
  final extraPriceCtrl = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('إضافة سيشنات لـ ${client.name}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'دلوقتي: ${client.totalSessions}/${client.usedSessions} حصة، والفلوس: ${client.totalPrice.toStringAsFixed(0)}/${client.amountPaid.toStringAsFixed(0)} ج',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: extraSessionsCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(labelText: 'عدد السيشنات الجديدة'),
            ),
            TextField(
              controller: extraPriceCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(labelText: 'السعر بتاعها (لو أضاف على السعر الكلي)'),
            ),
            TextField(
              controller: extraPaymentCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(labelText: 'المبلغ اللي دفعه دلوقتي (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final extraSessions = int.tryParse(extraSessionsCtrl.text) ?? 0;
              final extraPrice = double.tryParse(extraPriceCtrl.text) ?? 0;
              final extraPayment = double.tryParse(extraPaymentCtrl.text) ?? 0;
              if (extraSessions <= 0) {
                Navigator.pop(context);
                return;
              }
              await service.addExtraSessions(
                client,
                extraSessions: extraSessions,
                extraPrice: extraPrice,
                extraPayment: extraPayment,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      );
    },
  );
}
