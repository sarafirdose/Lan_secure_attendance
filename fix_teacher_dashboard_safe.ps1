$path = 'c:\flutter_projects\secure_attendance\lib\screens\teacher_dashboard_screen.dart'
$lines = Get-Content $path

$startIndex = -1
$endIndex = -1

for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -like '*void _handleSync()*') {
        $startIndex = $i
    }
    if ($lines[$i] -like '*Widget _sessionButton(*') {
        $endIndex = $i
        break
    }
}

if ($startIndex -ne -1 -and $endIndex -ne -1) {
    $newLines = $lines[0..($startIndex-1)]
    $newLines += '   void _handleSync() {'
    $newLines += '      if (_activeSession == null) return;'
    $newLines += '      '
    $newLines += '      setState(() { _activeSession!.syncStatus = SyncStatus.pending; });'
    $newLines += '      ScaffoldMessenger.of(context).showSnackBar('
    $newLines += '         const SnackBar(content: Text(''Background LAN Sync Started...''), backgroundColor: Color(0xFF4F46E5), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),'
    $newLines += '      );'
    $newLines += ' '
    $newLines += '      // Build adapted mapping native to new Hash structures securely'
    $newLines += '      final adapterSession = AttendanceSessionModel('
    $newLines += '        sessionID: _activeSession!.sessionId,'
    $newLines += '        subject: _activeSession!.subject,'
    $newLines += '        classLabel: _activeSession!.classLabel,'
    $newLines += '        ssid: ''Teacher_Bound_${_activeSession!.subject}'','
    $newLines += '        startTime: _activeSession!.startTime,'
    $newLines += '        active: _activeSession!.isActive,'
    $newLines += '        createdAt: DateTime.now(),'
    $newLines += '        syncStatus: ''pending'','
    $newLines += '      );'
    $newLines += '      '
    $newLines += '      // Fire and forget background handshake'
    $newLines += '      SyncService.executeHandshakePush([], adapterSession).then((success) {'
    $newLines += '        if (mounted) {'
    $newLines += '          setState(() {'
    $newLines += '            _activeSession!.syncStatus = success ? SyncStatus.synced : SyncStatus.failed;'
    $newLines += '          });'
    $newLines += '          if (success) {'
    $newLines += '            ScaffoldMessenger.of(context).showSnackBar('
    $newLines += '              const SnackBar(content: Text(''LAN Synchronization Successful ✓''), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating),'
    $newLines += '            );'
    $newLines += '          } else {'
    $newLines += '            ScaffoldMessenger.of(context).showSnackBar('
    $newLines += '              const SnackBar(content: Text(''LAN Sync Delayed - Will Automatically Retry''), backgroundColor: Color(0xFFEF4444), behavior: SnackBarBehavior.floating),'
    $newLines += '            );'
    $newLines += '          }'
    $newLines += '        }'
    $newLines += '      });'
    $newLines += '   }'
    $newLines += ''
    $newLines += $lines[$endIndex..($lines.Length-1)]
    $newLines | Set-Content $path -Encoding UTF8
    Write-Host "Success: Replaced block from $startIndex to $endIndex"
} else {
    Write-Host "Error: Could not find start ($startIndex) or end ($endIndex) markers"
}
