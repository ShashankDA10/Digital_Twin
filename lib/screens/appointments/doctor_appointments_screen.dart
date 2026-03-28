import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/appointment.dart';
import '../../services/appointment_reminder_service.dart';
import '../../services/appointment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/app_user.dart';

// Same time slots as the booking screen
const _slots = [
  '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
  '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM',
  '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM',
  '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM',
];

class DoctorAppointmentsScreen extends StatelessWidget {
  final AppUser doctor;
  const DoctorAppointmentsScreen({super.key, required this.doctor});

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _updateStatus(
      BuildContext context, Appointment appt, String status, String label) async {
    try {
      await AppointmentService.updateStatus(appt.id, status);
      if (status == 'approved') {
        await AppointmentReminderService.scheduleDoctorReminder(appt);
      } else {
        await AppointmentReminderService.cancelReminders(appt.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Appointment $label.'),
          backgroundColor: status == 'approved'
              ? const Color(0xFF10b981)
              : const Color(0xFFf43f5e),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _showRescheduleDialog(
      BuildContext context, Appointment appt) async {
    DateTime selectedDate = appt.date.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(days: 1))
        : appt.date;
    String? selectedSlot;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Propose New Time',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Date row
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      builder: (_, child) => Theme(
                        data: ThemeData.dark(),
                        child: child!,
                      ),
                    );
                    if (d != null) setS(() => selectedDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Text(
                        '${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][selectedDate.month-1]} ${selectedDate.day}, ${selectedDate.year}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, size: 16,
                          color: Colors.white.withValues(alpha: 0.4)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Select Time',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                const SizedBox(height: 8),
                // Time slot grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: _slots.length,
                  itemBuilder: (_, i) {
                    final slot = _slots[i];
                    final sel  = selectedSlot == slot;
                    return GestureDetector(
                      onTap: () => setS(() => selectedSlot = slot),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.accent.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel ? AppColors.accent : Colors.white12,
                          ),
                        ),
                        child: Text(slot,
                            style: TextStyle(
                                color: sel ? AppColors.accent : Colors.white70,
                                fontSize: 11,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                      ),
                    );
                  },
                ),
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            ),
            TextButton(
              onPressed: selectedSlot == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: Text('Send Proposal',
                  style: TextStyle(
                      color: selectedSlot != null
                          ? AppColors.accent
                          : Colors.white30,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedSlot != null && context.mounted) {
      try {
        await AppointmentService.proposeReschedule(
            appt.id, selectedDate, selectedSlot!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reschedule proposal sent to patient.'),
            backgroundColor: Color(0xFF3b82f6),
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed: $e'), backgroundColor: AppColors.danger));
        }
      }
    }
  }

  Future<void> _confirmCancelByDoctor(
      BuildContext context, Appointment appt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Cancel ${appt.patientName}\'s appointment on ${_formatDate(appt.date)} at ${appt.time}?\n\nThe patient will be notified.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel it',
                style: TextStyle(color: Color(0xFFf43f5e), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await AppointmentService.cancelByDoctor(appt.id);
        await AppointmentReminderService.cancelReminders(appt.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Appointment cancelled.'),
            backgroundColor: Color(0xFFf43f5e),
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed: $e'), backgroundColor: AppColors.danger));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Appointment Requests'),
            Text('Manage incoming bookings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted)),
          ],
        ),
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: AppointmentService.doctorStream(doctor.id),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text('Error loading appointments: ${snap.error}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          final all = snap.data ?? [];
          if (all.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_outlined, size: 64,
                      color: Colors.white.withValues(alpha: 0.25)),
                  const SizedBox(height: 16),
                  Text('No appointment requests',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Requests from patients will appear here',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                ],
              ),
            );
          }

          final pending   = all.where((a) => a.status == 'pending').toList();
          // Approved appointments the doctor can still act on
          final approved  = all.where((a) => a.status == 'approved').toList();
          // Awaiting patient's response on a reschedule proposal
          final awaitingResponse = all.where((a) => a.isReschedulePending).toList();
          // Terminal states
          final resolved  = all.where((a) =>
              a.status == 'rejected' ||
              a.status == 'cancelled' ||
              a.isCancelledByDoctor).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionTitle('Pending', pending.length, AppColors.accentAmber),
                const SizedBox(height: 10),
                ...pending.asMap().entries.map((e) => _RequestCard(
                  appt:        e.value,
                  dateLabel:   _formatDate(e.value.date),
                  index:       e.key,
                  onApprove:   () => _updateStatus(context, e.value, 'approved', 'approved'),
                  onReject:    () => _updateStatus(context, e.value, 'rejected', 'rejected'),
                  showActions: true,
                )),
                const SizedBox(height: 20),
              ],
              if (approved.isNotEmpty) ...[
                _SectionTitle('Approved', approved.length, const Color(0xFF10b981)),
                const SizedBox(height: 10),
                ...approved.asMap().entries.map((e) => _RequestCard(
                  appt:        e.value,
                  dateLabel:   _formatDate(e.value.date),
                  index:       e.key,
                  onApprove:   () {},
                  onReject:    () {},
                  showActions: false,
                  onReschedule: () => _showRescheduleDialog(context, e.value),
                  onCancelByDoctor: () => _confirmCancelByDoctor(context, e.value),
                )),
                const SizedBox(height: 20),
              ],
              if (awaitingResponse.isNotEmpty) ...[
                _SectionTitle('Awaiting Patient', awaitingResponse.length,
                    const Color(0xFF3b82f6)),
                const SizedBox(height: 10),
                ...awaitingResponse.asMap().entries.map((e) => _RequestCard(
                  appt:        e.value,
                  dateLabel:   _formatDate(e.value.date),
                  index:       e.key,
                  onApprove:   () {},
                  onReject:    () {},
                  showActions: false,
                )),
                const SizedBox(height: 20),
              ],
              if (resolved.isNotEmpty) ...[
                _SectionTitle('Resolved', resolved.length,
                    Colors.white.withValues(alpha: 0.4)),
                const SizedBox(height: 10),
                ...resolved.asMap().entries.map((e) => _RequestCard(
                  appt:        e.value,
                  dateLabel:   _formatDate(e.value.date),
                  index:       e.key,
                  onApprove:   () {},
                  onReject:    () {},
                  showActions: false,
                )),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final Appointment  appt;
  final String       dateLabel;
  final int          index;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool         showActions;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancelByDoctor;

  const _RequestCard({
    required this.appt,
    required this.dateLabel,
    required this.index,
    required this.onApprove,
    required this.onReject,
    required this.showActions,
    this.onReschedule,
    this.onCancelByDoctor,
  });

  static Color _statusColor(Appointment appt) {
    if (appt.isApproved && appt.rescheduleAccepted) return const Color(0xFF06b6d4);
    switch (appt.status) {
      case 'approved':            return const Color(0xFF10b981);
      case 'rejected':            return const Color(0xFFf43f5e);
      case 'cancelled':           return const Color(0xFF94a3b8);
      case 'cancelled_by_doctor': return const Color(0xFFf43f5e);
      case 'reschedule_pending':  return const Color(0xFF3b82f6);
      default:                    return const Color(0xFFf59e0b);
    }
  }

  static String _statusLabel(Appointment appt) {
    if (appt.isApproved && appt.rescheduleAccepted) return 'Accepted by Patient';
    switch (appt.status) {
      case 'approved':            return 'Approved';
      case 'rejected':            return 'Rejected';
      case 'cancelled':           return 'Cancelled';
      case 'cancelled_by_doctor': return 'Cancelled';
      case 'reschedule_pending':  return 'Awaiting Patient';
      default:                    return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sColor    = _statusColor(appt);
    final showMenu  = onReschedule != null && onCancelByDoctor != null;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient + status + optional 3-dot menu
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentViolet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.person, color: AppColors.accentViolet, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(appt.patientName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.calendar_today, size: 11,
                      color: Colors.white.withValues(alpha: 0.45)),
                  const SizedBox(width: 4),
                  Text(dateLabel,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
                  const SizedBox(width: 10),
                  Icon(Icons.access_time, size: 11,
                      color: Colors.white.withValues(alpha: 0.45)),
                  const SizedBox(width: 4),
                  Text(appt.time,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
                ]),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: sColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: sColor.withValues(alpha: 0.35)),
              ),
              child: Text(_statusLabel(appt),
                  style: TextStyle(
                      color: sColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            // Three-dot menu (only for approved appointments)
            if (showMenu) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: Colors.white.withValues(alpha: 0.5), size: 20),
                color: AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'reschedule') onReschedule!();
                  if (v == 'cancel') onCancelByDoctor!();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'reschedule',
                    child: Row(children: [
                      const Icon(Icons.schedule, color: Color(0xFF3b82f6), size: 18),
                      const SizedBox(width: 10),
                      Text('Reschedule',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(children: [
                      Icon(Icons.cancel_outlined, color: Color(0xFFf43f5e), size: 18),
                      SizedBox(width: 10),
                      Text('Cancel appointment',
                          style: TextStyle(color: Color(0xFFf43f5e), fontSize: 14)),
                    ]),
                  ),
                ],
              ),
            ],
          ]),

          // Reschedule proposal info (for awaiting-patient cards)
          if (appt.isReschedulePending &&
              appt.rescheduleDate != null &&
              appt.rescheduleTime != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3b82f6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3b82f6).withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.schedule, size: 14, color: Color(0xFF3b82f6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Proposed: ${_fmtDate(appt.rescheduleDate!)} at ${appt.rescheduleTime}',
                    style: const TextStyle(
                        color: Color(0xFF3b82f6), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ]),
            ),
          ],

          // Approve / Reject buttons (pending only)
          if (showActions) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check, size: 15),
                  label: const Text('Approve'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10b981),
                    side: const BorderSide(color: Color(0xFF10b981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: onApprove,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 15),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFf43f5e),
                    side: const BorderSide(color: Color(0xFFf43f5e)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: onReject,
                ),
              ),
            ]),
          ],
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms, duration: 300.ms);
  }

  static String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int    count;
  final Color  color;
  const _SectionTitle(this.title, this.count, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$count',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    ),
  ]);
}
