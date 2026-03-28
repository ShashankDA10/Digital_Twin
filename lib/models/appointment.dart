import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String    id;
  final String    patientId;
  final String    doctorId;
  final String    patientName;
  final String    doctorName;
  final DateTime  date;
  final String    time;   // e.g. "10:30 AM"
  final String    status; // 'pending' | 'approved' | 'rejected' | 'cancelled' | 'reschedule_pending' | 'cancelled_by_doctor'
  final DateTime  createdAt;
  final DateTime? rescheduleDate;     // proposed new date (set when status == 'reschedule_pending')
  final String?   rescheduleTime;     // proposed new time
  final bool      rescheduleAccepted; // true after patient accepts a reschedule proposal

  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.status,
    required this.createdAt,
    this.rescheduleDate,
    this.rescheduleTime,
    this.rescheduleAccepted = false,
  });

  factory Appointment.fromFirestore(String id, Map<String, dynamic> d) {
    DateTime ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    return Appointment(
      id:                 id,
      patientId:          d['patientId']          as String? ?? '',
      doctorId:           d['doctorId']            as String? ?? '',
      patientName:        d['patientName']         as String? ?? '',
      doctorName:         d['doctorName']          as String? ?? '',
      date:               ts(d['date']),
      time:               d['time']                as String? ?? '',
      status:             d['status']              as String? ?? 'pending',
      createdAt:          ts(d['createdAt']),
      rescheduleDate:     d['rescheduleDate'] != null ? ts(d['rescheduleDate']) : null,
      rescheduleTime:     d['rescheduleTime']      as String?,
      rescheduleAccepted: d['rescheduleAccepted']  as bool? ?? false,
    );
  }

  bool get isPending          => status == 'pending';
  bool get isApproved         => status == 'approved';
  bool get isRejected         => status == 'rejected';
  bool get isReschedulePending => status == 'reschedule_pending';
  bool get isCancelledByDoctor => status == 'cancelled_by_doctor';

  /// True if the appointment date+time is in the past.
  bool get isPast {
    final parts  = time.split(RegExp(r'[: ]'));
    var hour     = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = parts.length > 2 ? parts[2] : 'AM';
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    final dt = DateTime(date.year, date.month, date.day, hour, minute);
    return dt.isBefore(DateTime.now());
  }
}
