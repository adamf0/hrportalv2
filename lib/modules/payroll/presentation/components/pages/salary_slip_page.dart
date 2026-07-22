// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/modules/payroll/presentation/payroll_bloc.dart';
import 'package:hrportalv2/modules/attendance/presentation/attendance_bloc.dart';
import 'package:hrportalv2/modules/auth/presentation/auth_bloc.dart';

import 'package:hrportalv2/modules/payroll/presentation/components/organisms/printable_salary_slip.dart';
import 'package:hrportalv2/core/api_client.dart';
import 'package:hrportalv2/modules/payroll/presentation/components/helpers/pdf_generator_helper.dart';
import 'package:open_filex/open_filex.dart';

// Modular Molecule Components
import 'package:hrportalv2/modules/payroll/presentation/components/molecules/year_selector.dart';
import 'package:hrportalv2/modules/payroll/presentation/components/molecules/month_selector.dart';
import 'package:hrportalv2/modules/payroll/presentation/components/molecules/salary_slip_not_found_card.dart';

class SalarySlipPage extends StatefulWidget {
  const SalarySlipPage({super.key});

  @override
  State<SalarySlipPage> createState() => _SalarySlipPageState();
}

class _SalarySlipPageState extends State<SalarySlipPage> {
  final List<String> _months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "Mei",
    "Jun",
    "Jul",
    "Agu",
    "Sep",
    "Okt",
    "Nov",
    "Des"
  ];

  int? _previousTabIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authBloc = context.read<AuthBloc>();
      if (authBloc.isSdmUser) return;
      ApiClient.setActivePageScope('payroll');
      final userNip = authBloc.session?.nip ?? "10616049757";
      context.read<PayrollBloc>().fetchPayroll(userNip);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final attendanceBloc = Provider.of<AttendanceBloc>(context);
    final currentIndex = attendanceBloc.currentTabIndex;
    if (_previousTabIndex != null &&
        _previousTabIndex != 3 &&
        currentIndex == 3) {
      final authBloc = context.read<AuthBloc>();
      if (authBloc.isSdmUser) return;
      ApiClient.setActivePageScope('payroll');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userNip = authBloc.session?.nip ?? "10616049757";
        context.read<PayrollBloc>().fetchPayroll(userNip);
      });
    }
    _previousTabIndex = currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final payrollBloc = Provider.of<PayrollBloc>(context);
    final authBloc = Provider.of<AuthBloc>(context);
    final userNip = authBloc.session?.nip ?? "10616049757";
    final slip = payrollBloc.currentPayrollData;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final background = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payroll',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Icon(Icons.notifications_none,
                        color: onSurface, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              YearSelector(
                selectedYear: payrollBloc.selectedPayrollYear,
                onChanged: (newValue) {
                  if (newValue != null) {
                    payrollBloc.setSelectedYear(newValue, userNip);
                  }
                },
              ),
              const SizedBox(height: 16),
              MonthSelector(
                months: _months,
                selectedMonth: payrollBloc.selectedPayrollMonth,
                onMonthSelected: (m) {
                  payrollBloc.setSelectedMonth(m, userNip);
                },
              ),
              const SizedBox(height: 24),
              payrollBloc.isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60.0),
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    )
                  : slip == null
                      ? const SalarySlipNotFoundCard()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PrintableSalarySlip(slip: slip),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final file = await PdfGeneratorHelper
                                      .generateSalarySlipPdf(slip);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Unduh PDF slip gaji ${slip.bulan} ${slip.tahun} berhasil!'),
                                      backgroundColor: primaryColor,
                                      action: SnackBarAction(
                                        label: 'BUKA',
                                        textColor: Colors.white,
                                        onPressed: () async {
                                          final result =
                                              await OpenFilex.open(file.path);
                                          if (result.type != ResultType.done) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Gagal membuka file: ${result.message}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Gagal mengunduh/membuat file PDF slip gaji.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.download, size: 20),
                              label: Text(
                                'Unduh PDF',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
