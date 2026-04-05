simport 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/attendance_proof_model.dart';
import '../services/attendance_proof_service.dart';

class AttendanceProofScreen extends StatefulWidget {
  const AttendanceProofScreen({super.key});

  @override
  State<AttendanceProofScreen> createState() => _AttendanceProofScreenState();
}

class _AttendanceProofScreenState extends State<AttendanceProofScreen> {
  List<AttendanceProof> _proofs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProofs();
  }

  Future<void> _loadProofs() async {
    final proofs = await AttendanceProofService.getProofs();
    if (!mounted) return;
    setState(() {
      _proofs = proofs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Attendance Proofs', 
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            onPressed: () async {
              await AttendanceProofService.clearProofs();
              _loadProofs();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _proofs.isEmpty
              ? _buildEmptyState()
              : _buildProofList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, 
                size: 64, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 24),
          const Text('No Proofs Found', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
          const SizedBox(height: 8),
          const Text('Your attendance records will appear here.', 
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildProofList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _proofs.length,
      itemBuilder: (context, index) {
        final proof = _proofs[index];
        return _ProofCard(proof: proof).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
      },
    );
  }
}

class _ProofCard extends StatefulWidget {
  final AttendanceProof proof;
  const _ProofCard({required this.proof});

  @override
  State<_ProofCard> createState() => _ProofCardState();
}

class _ProofCardState extends State<_ProofCard> {
  bool _showDetails = false;
  bool _showQRCode = false;

  @override
  Widget build(BuildContext context) {
    final proof = widget.proof;
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(proof.timestamp);
    final timeStr = DateFormat('hh:mm a').format(proof.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 24),
            ),
            title: Text(proof.subjectName, 
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFFFFFFFF))),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('$dateStr • $timeStr', 
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 2),
                Text('Session: ${proof.sessionID}', 
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
              ],
            ),
            trailing: IconButton(
              icon: Icon(_showDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              onPressed: () => setState(() => _showDetails = !_showDetails),
            ),
          ),
          if (_showDetails) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Color(0xFFFFFFFF)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Device Integrity ID', proof.deviceID),
                  _detailRow('Verification Hash', proof.hashSignature, isMonospace: true),
                  _detailRow('Session Token', proof.token, isMonospace: true),
                  const SizedBox(height: 16),
                  
                  // Verifiable QR Toggle
                  Center(
                    child: Column(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _showQRCode = !_showQRCode),
                          icon: Icon(_showQRCode ? Icons.visibility_off_rounded : Icons.qr_code_2_rounded),
                          label: Text(_showQRCode ? 'Hide QR Proof' : 'Show QR Proof'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2C2C2C),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        if (_showQRCode) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: QrImageView(
                              data: '${proof.sessionID}|${proof.hashSignature}',
                              version: QrVersions.auto,
                              size: 150.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('TEACHER VERIFIABLE QR', 
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(value, 
              style: TextStyle(
                fontSize: 11, 
                color: const Color(0xFF111827),
                fontFamily: isMonospace ? 'monospace' : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
