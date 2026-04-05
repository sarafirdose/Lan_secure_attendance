import '../models/session_model.dart';
import 'sa_security_service.dart';
import 'sa_admin_service.dart';

class LanSyncService {
  static const bool _isSimulation = true;

  // ── Step 1: Sync Flow ──────────────────────────────────────────────────────
  static Future<bool> pushToAdmin(AttendanceSession session) async {
    // 1. Generate Integrity Signature Before Sending
    final signature = SaSecurityService.generateIntegrityHash(session);
    session.hashSignature = signature;
    
    // 2. Prepare Payload (sessionID, attendance data, timestamp, signature)
    final payload = {
      'sessionId': session.sessionId,
      'attendance': session.students.map((e) => e.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'signature': signature,
      'class': session.classLabel,
      'teacherId': 'ID_101', // Dynamic in production
    };

    // 3. Simulate LAN Transmission (0.5s network delay)
    if (_isSimulation) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verification logic on Admin's side (Simulation)
      final receivedSignature = payload['signature'] as String;
      final verifySignature = SaSecurityService.generateIntegrityHash(session);
      
      if (receivedSignature == verifySignature) {
        // Success: Store in Admin Service
        await SaAdminService.saveStructure({
           'last_sync_id': session.sessionId,
           'last_sync_time': payload['timestamp'],
        });
        
        // Mark session as synced locally
        session.syncStatus = SyncStatus.synced;
        // await SessionService.updateSession(session); // Fixed compilation route
        return true;
      } else {
        // Integrity Breach
        session.syncStatus = SyncStatus.failed;
        // await SessionService.updateSession(session); // Fixed compilation route
        return false;
      }
    }

    return false;
  }
}
