import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';

/// كل التعامل مع Firestore بيحصل من هنا
class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _clients => _db.collection('clients');
  CollectionReference get _sessions => _db.collection('sessions');

  // إضافة متدرب جديد
  Future<String> addClient(ClientModel client) async {
    final doc = await _clients.add(client.toMap());
    return doc.id;
  }

  // تعديل بيانات متدرب (زي تسجيل دفعة جديدة أو سيشن جديدة)
  Future<void> updateClient(String id, Map<String, dynamic> data) {
    return _clients.doc(id).update(data);
  }

  // كل المتدربين (يستخدم في شاشة "كل الحاجزين قبل كده")
  Stream<List<ClientModel>> streamAllClients() {
    return _clients.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => ClientModel.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // متدربين يوم معين (لشاشة التايم لاين) - من غير المواعيد الملغية
  Stream<List<ClientModel>> streamClientsByDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _clients
        .where('day', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('day', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClientModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .where((c) => !c.isCancelled)
            .toList());
  }

  // إضافة سيشن جديدة لمتدرب موجود، وبيزود usedSessions حسب عدد الساعات
  // (كل ساعة = سيشن، فلو الموعد ساعتين بيتخصم 2 سيشن مرة واحدة)
  Future<void> addSession(ClientModel client, SessionModel session, {int sessionsCount = 1}) async {
    await _sessions.add({
      ...session.toMap(),
      'sessionsCount': sessionsCount,
    });
    await _clients.doc(client.id).update({
      'usedSessions': client.usedSessions + sessionsCount,
    });
  }

  // تسجيل دفعة جديدة (يزود amountPaid)
  Future<void> addPayment(String clientId, double currentPaid, double extraAmount) {
    return _clients.doc(clientId).update({
      'amountPaid': currentPaid + extraAmount,
    });
  }

  // إضافة سيشنات زيادة لمتدرب موجود (تجديد/تمديد الباقة) + دفعة اختيارية
  Future<void> addExtraSessions(
    ClientModel client, {
    required int extraSessions,
    double extraPayment = 0,
    double extraPrice = 0,
  }) {
    return _clients.doc(client.id).update({
      'totalSessions': client.totalSessions + extraSessions,
      'amountPaid': client.amountPaid + extraPayment,
      'totalPrice': client.totalPrice + extraPrice,
    });
  }

  // إلغاء الموعد: بيشيله من التايم لاين بس، وبيسيب بيانات المتدرب (السيشنات والفلوس) زي ما هي
  Future<void> cancelAppointment(String clientId) {
    return _clients.doc(clientId).update({'isCancelled': true});
  }

  // حذف المتدرب نهائيًا من كل حتة (السيشنات والفلوس بتضيع، استخدمها بحذر)
  Future<void> deleteClientPermanently(String clientId) async {
    final sessions = await _sessions
        .where('clientId', isEqualTo: clientId)
        .get();

    final batch = _db.batch();

    for (final doc in sessions.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_clients.doc(clientId));

    await batch.commit();
  }

  Stream<List<SessionModel>> streamSessionsForClient(String clientId) {
    return _sessions.where('clientId', isEqualTo: clientId).orderBy('date', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => SessionModel.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList(),
        );
  }
}
