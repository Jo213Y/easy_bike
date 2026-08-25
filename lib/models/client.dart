import 'package:cloud_firestore/cloud_firestore.dart';

/// موديل يمثل بيانات المتدرب (العميل) وحجوزاته
class ClientModel {
  final String id;
  final String name; // اسم المتدرب
  final String referredBy; // جاي من طرف مين
  final String phone; // رقم التلفون
  final int totalSessions; // إجمالي عدد السيشنات المتفق عليها
  final int usedSessions; // عدد السيشنات اللي اتعملت
  final double amountPaid; // المبلغ المدفوع
  final double totalPrice; // السعر الكلي المتفق عليه
  final DateTime day; // يوم الموعد
  final String startTime; // بداية الساعة "HH:mm"
  final String endTime; // نهاية الساعة "HH:mm"
  final String vehicleType; // "scooter" أو "motorcycle"
  final bool isCancelled; // الموعد اتلغى (مش هيظهر في التايم لاين) لكن بيانات المتدرب متحفوظة
  final DateTime createdAt;

  ClientModel({
    required this.id,
    required this.name,
    required this.referredBy,
    required this.phone,
    required this.totalSessions,
    required this.usedSessions,
    required this.amountPaid,
    required this.totalPrice,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.vehicleType,
    this.isCancelled = false,
    required this.createdAt,
  });

  // كام سيشن فاضل
  int get remainingSessions => (totalSessions - usedSessions).clamp(0, totalSessions);

  // باقي كام فلوس
  double get remainingAmount => (totalPrice - amountPaid).clamp(0, totalPrice);

  // هل خلص الدفع بالكامل؟ (يستخدم لتحديد لون الفريم: أخضر / برتقالي)
  bool get isFullyPaid => remainingAmount <= 0;

  factory ClientModel.fromMap(String id, Map<String, dynamic> map) {
    return ClientModel(
      id: id,
      name: map['name'] ?? '',
      referredBy: map['referredBy'] ?? '',
      phone: map['phone'] ?? '',
      totalSessions: map['totalSessions'] ?? 0,
      usedSessions: map['usedSessions'] ?? 0,
      amountPaid: (map['amountPaid'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      day: (map['day'] as Timestamp).toDate(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      vehicleType: map['vehicleType'] ?? 'scooter',
      isCancelled: map['isCancelled'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'referredBy': referredBy,
      'phone': phone,
      'totalSessions': totalSessions,
      'usedSessions': usedSessions,
      'amountPaid': amountPaid,
      'totalPrice': totalPrice,
      'day': Timestamp.fromDate(day),
      'startTime': startTime,
      'endTime': endTime,
      'vehicleType': vehicleType,
      'isCancelled': isCancelled,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ClientModel copyWith({
    int? usedSessions,
    double? amountPaid,
    DateTime? day,
    String? startTime,
    String? endTime,
    String? vehicleType,
    bool? isCancelled,
  }) {
    return ClientModel(
      id: id,
      name: name,
      referredBy: referredBy,
      phone: phone,
      totalSessions: totalSessions,
      usedSessions: usedSessions ?? this.usedSessions,
      amountPaid: amountPaid ?? this.amountPaid,
      totalPrice: totalPrice,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      vehicleType: vehicleType ?? this.vehicleType,
      isCancelled: isCancelled ?? this.isCancelled,
      createdAt: createdAt,
    );
  }
}

/// موديل السيشن الواحدة (لما تتضاف جلسة جديدة للمتدرب)
class SessionModel {
  final String id;
  final String clientId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int sessionsCount; // كام حصة اتخصمت (ساعتين = 2 حصة مثلاً)
  final bool attended; // حضر ولا لأ

  SessionModel({
    required this.id,
    required this.clientId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.sessionsCount = 1,
    this.attended = true,
  });

  factory SessionModel.fromMap(String id, Map<String, dynamic> map) {
    return SessionModel(
      id: id,
      clientId: map['clientId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      sessionsCount: map['sessionsCount'] ?? 1,
      attended: map['attended'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'sessionsCount': sessionsCount,
      'attended': attended,
    };
  }
}
