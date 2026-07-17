import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _showGoogleFormSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Membuka evaluasi Google Form: https://forms.gle/evaluation-app',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: Colors.purple[700],
        duration: const Duration(seconds: 3),
      ),
    );
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
                          isFinished ? 'Sudah Tidak Ada Kuesioner LPM' : 'Belum Isi Kuesioner LPM',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isFinished ? Colors.green[900] : Colors.blue[900],
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
                        backgroundColor: isFinished ? Colors.green[100] : Colors.blue[100],
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
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
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
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quarterly Evaluation Card (Every 3 months / Google Form evaluation)
        Container(
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
                onPressed: () => _showGoogleFormSnackbar(context),
                icon: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.purple[700]),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.purple[50],
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
