import 'package:flutter/material.dart';
import '../services/app_state_service.dart';

class SystemStatusBadge extends StatelessWidget {
  const SystemStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStateService(),
      builder: (context, _) {
        final status = AppStateService().status;
        
        Color color;
        String label;
        IconData icon;

        switch (status) {
          case SystemStatus.warning:
            color = const Color(0xFFF59E0B); // Amber
            label = 'SYNC PENDING';
            icon = Icons.sync_problem_rounded;
            break;
          case SystemStatus.error:
            color = const Color(0xFFEF4444); // Red
            label = 'OFFLINE MODE';
            icon = Icons.cloud_off_rounded;
            break;
          case SystemStatus.normal:
            color = const Color(0xFF059669); // Emerald
            label = 'SYSTEM SECURE';
            icon = Icons.verified_user_rounded;
            break;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.8),
              ),
            ],
          ),
        );
      },
    );
  }
}
