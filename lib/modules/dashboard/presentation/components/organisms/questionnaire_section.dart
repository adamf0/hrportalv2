import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class QuestionnaireSection extends StatefulWidget {
  const QuestionnaireSection({super.key});

  @override
  State<QuestionnaireSection> createState() => _QuestionnaireSectionState();
}

class _QuestionnaireSectionState extends State<QuestionnaireSection> {
  int _completedLpm = 0;
  final int _totalLpm = 3;

  void _fillQuestionnaire() {
    if (_completedLpm < _totalLpm) {
      setState(() {
        _completedLpm++;
      });
    }
  }

  void _resetQuestionnaire() {
    setState(() {
      _completedLpm = 0;
    });
  }

  /// Checks if current date is within the quarterly audit window (months 3, 6, 9, 12)
  bool get _isQuarterlyAuditPeriod {
    final now = DateTime.now();
    final auditMonths = [3, 6, 9, 12];
    debugPrint("now.month: ${now.month}");
    return auditMonths.contains(now.month);
  }

  Future<void> _openGoogleForm(BuildContext context) async {
    if (!_isQuarterlyAuditPeriod) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kuesioner evaluasi hanya dapat diisi pada periode audit kuartalan (Maret, Juni, September, Desember).',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.amber[900],
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final Uri url = Uri.parse('https://forms.gle/9tsDoM5B9imup9ch8');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal membuka browser untuk: https://forms.gle/9tsDoM5B9imup9ch8',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuka tautan: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = _completedLpm >= _totalLpm;
    final progress = _totalLpm > 0 ? _completedLpm / _totalLpm : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          'Kuesioner Akademik & Layanan',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        // Main LPM Questionnaire Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isFinished
                  ? [Colors.teal[50]!, Colors.green[50]!]
                  : [Colors.blue[50]!, Colors.indigo[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFinished ? Colors.green[200]! : Colors.blue[100]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stateful Illustration / Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFinished ? Colors.green[100] : Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFinished ? Icons.task_alt : Icons.rate_review_outlined,
                      color: isFinished ? Colors.green[700] : Colors.blue[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFinished
                              ? 'Sudah Tidak Ada Kuesioner LPM'
                              : 'Belum Isi Kuesioner LPM',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isFinished
                                ? Colors.green[900]
                                : Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFinished
                              ? 'Terima kasih! Anda telah menyelesaikan seluruh pengisian evaluasi penjaminan mutu.'
                              : 'Terdapat kuesioner aktif dari Lembaga Penjaminan Mutu (LPM) yang perlu Anda lengkapi.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isFinished
                                ? Colors.green[800]!.withOpacity(0.8)
                                : Colors.blue[800]!.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            isFinished ? Colors.green[100] : Colors.blue[100],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isFinished ? Colors.green : Colors.blue[700]!,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_completedLpm/$_totalLpm',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isFinished ? Colors.green[800] : Colors.blue[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons for Interactive Simulation
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isFinished)
                    TextButton.icon(
                      onPressed: _resetQuestionnaire,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        'Reset Simulasi',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green[800],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _fillQuestionnaire,
                      icon: const Icon(Icons.edit, size: 14),
                      label: Text(
                        'Isi Kuesioner',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Quarterly Evaluation Card (Only shown in months 3, 6, 9, 12)
        if (_isQuarterlyAuditPeriod) ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _openGoogleForm(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Purple Google Form Icon container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: Colors.purple[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Description and Call to Action
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evaluasi Aplikasi (Google Form)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Seberapa baik/buruk aplikasi HR Portal? Bantu kami meningkatkan layanan (3 Bulanan).',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Open button
                  IconButton(
                    onPressed: () => _openGoogleForm(context),
                    icon: Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.purple[700]),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.purple[50],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
