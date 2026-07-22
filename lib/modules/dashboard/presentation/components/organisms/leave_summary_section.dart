import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/core/responsive_helper.dart';
import 'package:hrportalv2/modules/leave/domain/leave.dart';

class LeaveSummarySection extends StatefulWidget {
  final int sisaCuti;
  final int cutiDiambil;
  final int cutiPending;
  final List<CutiTypeSummary> summaries;

  const LeaveSummarySection({
    super.key,
    required this.sisaCuti,
    required this.cutiDiambil,
    required this.cutiPending,
    this.summaries = const [],
  });

  @override
  State<LeaveSummarySection> createState() => _LeaveSummarySectionState();
}

class _LeaveSummarySectionState extends State<LeaveSummarySection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(int total) {
    if (_currentPage < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.secondary;
    final primaryColor = Theme.of(context).colorScheme.primary;

    List<CutiTypeSummary> items = widget.summaries;
    if (items.isEmpty) {
      items = [
        CutiTypeSummary(
          id: 1,
          name: "Tahunan",
          sisa: widget.sisaCuti,
          diambil: widget.cutiDiambil,
          pending: widget.cutiPending,
          quota: 12,
        )
      ];
    }

    final currentYear = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ringkasan Cuti',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
            if (items.length > 1)
              Row(
                children: [
                  IconButton(
                    onPressed: _currentPage > 0 ? _prevPage : null,
                    icon: Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: _currentPage > 0 ? primaryColor : Colors.grey[300],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentPage + 1}/${items.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _currentPage < items.length - 1
                        ? () => _nextPage(items.length)
                        : null,
                    icon: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: _currentPage < items.length - 1
                          ? primaryColor
                          : Colors.grey[300],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 136,
          child: PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final item = items[index];

              final leftCard = Container(
                height: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.infoContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.quota > 0
                          ? 'SISA CUTI ${item.name.toUpperCase()}'
                          : 'CUTI ${item.name.toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.quota > 0 ? '${item.sisa} Hari' : '${item.diambil} Hari',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 13, color: AppTheme.secondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.quota > 0
                                ? 'Quota: ${item.quota} hari/thn'
                                : 'Berlaku hingga Des $currentYear',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final cardDiambil = Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Diambil',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.diambil}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              final cardPending = Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pending',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.pending}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              final rightColumn = Column(
                children: [
                  cardDiambil,
                  const SizedBox(height: 8),
                  cardPending,
                ],
              );

              return Flex(
                direction: context.isWatch ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  context.isWatch ? leftCard : Expanded(flex: 3, child: leftCard),
                  SizedBox(
                    width: context.isWatch ? 0 : 16,
                    height: context.isWatch ? 12 : 0,
                  ),
                  context.isWatch
                      ? Row(
                          children: [
                            cardDiambil,
                            const SizedBox(width: 8),
                            cardPending,
                          ],
                        )
                      : Expanded(flex: 2, child: rightColumn),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
