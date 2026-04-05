$path = 'c:\flutter_projects\secure_attendance\lib\screens\teacher_dashboard_screen.dart'
$content = [System.IO.File]::ReadAllText($path)

# Fix 1: AttendanceSessionModel instantiation
$oldModel = @"
      final adapterSession = AttendanceSessionModel(
        sessionID: _activeSession!.sessionId,
        subject: _activeSession!.subject,
        classLabel: _activeSession!.classLabel,
        ssid: 'Teacher_Bound_${_activeSession!.subject}',
        startTime: _activeSession!.startTime,
        durationMinutes: _activeSession!.durationMinutes,
        hashSignature: '',
        syncStatus: 'pending',
        metadata: {}
      );
"@

$newModel = @"
      final adapterSession = AttendanceSessionModel(
        sessionID: _activeSession!.sessionId,
        subject: _activeSession!.subject,
        classLabel: _activeSession!.classLabel,
        ssid: 'Teacher_Bound_${_activeSession!.subject}',
        startTime: _activeSession!.startTime,
        active: _activeSession!.isActive,
        createdAt: DateTime.now(),
        syncStatus: 'pending',
      );
"@

$content = $content.Replace($oldModel, $newModel)

# Fix 2: Stray syntax error block
$oldStray = @"
   }
         ],
       ),
     ).animate().slideY(begin: -0.1).fadeIn();
   }
"@

$newStray = @"
   }
"@

$content = $content.Replace($oldStray, $newStray)

[System.IO.File]::WriteAllText($path, $content)
