import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';

class AppointmentService {
  static final _col = FirebaseFirestore.instance.collection('appointments');

  // ── Create ────────────────────────────────────────────────────────────────

  static Future<String> createAppointment({
    required String patientId,
    required String doctorId,
    required String patientName,
    required String doctorName,
    required DateTime date,
    required String time,
  }) async {
    final doc = await _col.add({
      'patientId':   patientId,
      'doctorId':    doctorId,
      'patientName': patientName,
      'doctorName':  doctorName,
      'date':        Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'time':        time,
      'status':      'pending',
      'createdAt':   FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // ── Read – Patient (real-time stream) ─────────────────────────────────────

  static Stream<List<Appointment>> patientStream(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => Appointment.fromFirestore(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Read – Doctor (real-time stream) ──────────────────────────────────────

  static Stream<List<Appointment>> doctorStream(String doctorId) {
    return _col
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => Appointment.fromFirestore(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Update status ─────────────────────────────────────────────────────────

  static Future<void> updateStatus(String id, String status) =>
      _col.doc(id).update({'status': status});

  // ── Cancel (patient) ─────────────────────────────────────────────────────

  static Future<void> cancel(String id) =>
      _col.doc(id).update({'status': 'cancelled'});

  // ── Reschedule / cancel by doctor ─────────────────────────────────────────

  /// Doctor proposes a new date+time. Status → 'reschedule_pending'.
  static Future<void> proposeReschedule(
      String id, DateTime newDate, String newTime) =>
      _col.doc(id).update({
        'status':         'reschedule_pending',
        'rescheduleDate': Timestamp.fromDate(
            DateTime(newDate.year, newDate.month, newDate.day)),
        'rescheduleTime': newTime,
      });

  /// Doctor cancels an approved appointment.
  static Future<void> cancelByDoctor(String id) =>
      _col.doc(id).update({'status': 'cancelled_by_doctor'});

  // ── Patient responds to reschedule proposal ───────────────────────────────

  /// Patient accepts the proposed reschedule. Date+time updated, status → 'approved'.
  static Future<void> acceptReschedule(
      String id, DateTime newDate, String newTime) =>
      _col.doc(id).update({
        'status':             'approved',
        'date':               Timestamp.fromDate(
            DateTime(newDate.year, newDate.month, newDate.day)),
        'time':               newTime,
        'rescheduleAccepted': true,
        'rescheduleDate':     FieldValue.delete(),
        'rescheduleTime':     FieldValue.delete(),
      });

  /// Patient declines the proposed reschedule. Status → 'cancelled'.
  static Future<void> declineReschedule(String id) =>
      _col.doc(id).update({
        'status':         'cancelled',
        'rescheduleDate': FieldValue.delete(),
        'rescheduleTime': FieldValue.delete(),
      });
}
