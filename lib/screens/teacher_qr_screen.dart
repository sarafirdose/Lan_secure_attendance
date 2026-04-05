import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import '../services/demo_state_service.dart';
import 'teacher_manual_attendance_sheet.dart';
import 'session_summary_screen.dart';

enum SessionState { idle, sessionCreated, qrActive, ended, error }

class TeacherQRScreen extends StatefulWidget {
  final String department;
  final String year;
  final String section;
  final String subject;

  const TeacherQRScreen({
    super.key,
    required this.department,
    required this.year,
    required this.section,
    required this.subject,
  });

  @override
  State<TeacherQRScreen> createState() => _TeacherQRScreenState();
}

class _TeacherQRScreenState extends State<TeacherQRScreen> {
  SessionState _currentState = SessionState.idle;
  AttendanceSession? _session;
  String _qrData = '';
  int _timeLeft = 120;
  Timer? _countdownTimer;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    setState(() {
      _currentState = SessionState.idle;
      _errorMessage = '';
    });

    try {
      setState(() => _currentState = SessionState.sessionCreated);

      final result = await SessionService.startSession(
        department: widget.department,
        year: widget.year,
        section: widget.section,
        subject: widget.subject,
      );

      _session = result['session'];
      _qrData = result['qr_data'];
      _timeLeft = result['expires_in'] ?? 120;

      // Register this session with DemoStateService so students can mark attendance
      DemoStateService().startDemoSession(
        sessionId: _session!.sessionId,
        subject: widget.subject,
        classLabel: '${widget.department}-${widget.year}-${widget.section}',
      );

      setState(() => _currentState = SessionState.qrActive);
      _startTimer();
      
    } catch (e) {
      setState(() {
        _currentState = SessionState.error;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _countdownTimer?.cancel();
          _currentState = SessionState.ended;
        }
      });
    });
  }

  void _endSessionManually() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End Session?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to stop accepting attendance and securely close this session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (mounted) {
                // Merge demo attendees into the session for the summary view
                final attendees = DemoStateService().demoAttendees;
                for (final a in attendees) {
                  final roll = a['roll'] ?? '';
                  if (!_session!.students.any((s) => s.rollNumber == roll)) {
                    _session!.students.add(StudentAttendanceEntry(
                      name: a['name'] ?? 'Demo Student',
                      rollNumber: roll,
                      status: StudentStatus.present,
                    ));
                  }
                }
              }

              setState(() {
                _currentState = SessionState.ended;
                _countdownTimer?.cancel();
              });
              
              if (mounted) {
                 Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SessionSummaryScreen(session: _session!)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('End Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    DemoStateService().endDemoSession();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Live Attendance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: _currentState == SessionState.qrActive ? FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TeacherManualAttendanceSheet(
              session: _session!,
              onUpdate: () => setState(() {}),
            ),
          );
        },
        backgroundColor: const Color(0xFF0056B3),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text('Manual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ) : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStateIdentifier(),
              const SizedBox(height: 32),
              _buildMainCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateIdentifier() {
    Color ring;
    String text;
    switch (_currentState) {
      case SessionState.idle:
         ring = Colors.grey; text = "INITIALIZING"; break;
      case SessionState.sessionCreated:
         ring = const Color(0xFF3B82F6); text = "BINDING SECURE TOKEN"; break;
      case SessionState.qrActive:
         ring = const Color(0xFF059669); text = "SCANNING ACTIVE"; break;
      case SessionState.ended:
         ring = Colors.black; text = "SESSION CLOSED"; break;
      case SessionState.error:
         ring = const Color(0xFFEF4444); text = "SYSTEM ERROR"; break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ring.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ring.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: ring),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: ring, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2)),
        ],
      ),
    ).animate(target: _currentState == SessionState.qrActive ? 1 : 0).shimmer(duration: 2.seconds);
  }

  Widget _buildMainCard() {
    if (_currentState == SessionState.error) {
       return _buildErrorState();
    }
    if (_currentState == SessionState.ended) {
       return _buildEndedState();
    }
    if (_currentState == SessionState.qrActive) {
       return _buildActiveState();
    }
    return const CircularProgressIndicator(color: Color(0xFFFFFFFF));
  }

  Widget _buildActiveState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
          ),
          child: Column(
            children: [
              Text(widget.subject, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              Text('${widget.department} • Year ${widget.year} • Sec ${widget.section}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 40),
              
              // Elite High-Visibility QR
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.08),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 260,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                ),
              ),
              
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: _timeLeft < 30 ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_rounded, color: _timeLeft < 30 ? const Color(0xFFDC2626) : const Color(0xFF1E293B), size: 22),
                    const SizedBox(width: 10),
                    Text('QR Valid For: $_formattedTime', style: TextStyle(
                      fontSize: 17, 
                      fontWeight: FontWeight.w900, 
                      color: _timeLeft < 30 ? const Color(0xFFDC2626) : const Color(0xFF1E293B)
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _endSessionManually,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('End Session Early', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ).animate().scale(begin: const Offset(0.9, 0.9), delay: 200.ms).fadeIn(),

        // ── Live Demo Attendee List ────────────────────────
        const SizedBox(height: 24),
        ListenableBuilder(
          listenable: DemoStateService(),
          builder: (_, __) {
            final attendees = DemoStateService().demoAttendees;
            if (attendees.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_alt_outlined, color: Color(0xFF9CA3AF), size: 20),
                    SizedBox(width: 8),
                    Text('Waiting for students to scan...', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                  ],
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.people_rounded, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 8),
                        Text('${attendees.length} Student${attendees.length == 1 ? '' : 's'} Present',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFFFFFFF)),
                  ...attendees.map((a) => ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFFFFFFF).withOpacity(0.1),
                      child: Text((a['name'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    title: Text(a['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(a['roll'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    trailing: Text(a['time'] ?? '',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                  )),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEndedState() {
     return Column(
       children: [
         const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 64),
         const SizedBox(height: 16),
         const Text('Session Completed', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
         const SizedBox(height: 8),
         const Text('The authentication window has closed.', style: TextStyle(color: Colors.grey)),
         const SizedBox(height: 32),
         ElevatedButton(
           onPressed: () {
              if (_session != null) {
                 Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SessionSummaryScreen(session: _session!)),
                );
              } else {
                 Navigator.pop(context);
              }
           },
           style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFFFFF), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
           child: const Text('View Summary', style: TextStyle(color: Colors.white)),
         )
       ],
     ).animate().fadeIn();
  }

  Widget _buildErrorState() {
     return Column(
       children: [
         const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 64),
         const SizedBox(height: 16),
         const Text('Failed to Start', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
         const SizedBox(height: 8),
         Text(_errorMessage, style: const TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
         const SizedBox(height: 32),
         ElevatedButton.icon(
           onPressed: _startSession,
           icon: const Icon(Icons.refresh_rounded, color: Colors.white),
           label: const Text('Retry Connection', style: TextStyle(color: Colors.white)),
           style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFFFFF), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
         )
       ],
     ).animate().slideY().fadeIn();
  }
}
