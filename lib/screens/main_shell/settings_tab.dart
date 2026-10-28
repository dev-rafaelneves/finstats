import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/import_candidate.dart';
import '../../services/app_state.dart';
import '../../services/backup_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/csv_bank_parser.dart';
import '../../utils/export_csv_generator.dart';
import '../../utils/ofx_parser.dart';
import '../../utils/report_pdf_generator.dart';
import '../../widgets/ios_grouped_section.dart';
import '../../widgets/ios_list_tile.dart';
import '../import_reconciliation_screen.dart';

class SettingsTab extends StatelessWidget {
  final AppState appState;

  const SettingsTab({super.key, required this.appState});

  Future<void> _handleImportStatement(BuildContext context) async {
    const typeGroup = XTypeGroup(
      label: 'Extratos Bancários',
      extensions: <String>['ofx', 'csv', 'txt'],
    );

    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) return;

    final content = await file.readAsString();
    final nameLower = file.name.toLowerCase();

    final List<ImportCandidate> candidates;
    final String fileType;

    if (nameLower.endsWith('.ofx')) {
      fileType = 'OFX';
      candidates = OfxParser.parse(
        content,
        availableCategories: appState.categories,
        existingTransactions: appState.transactions,
      );
    } else {
      fileType = 'CSV';
      candidates = CsvBankParser.parse(
        content,
        availableCategories: appState.categories,
        existingTransactions: appState.transactions,
      );
    }

    if (candidates.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum lançamento legível encontrado no arquivo.')),
        );
      }
      return;
    }

    if (context.mounted) {
      final importedCount = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (_) => ImportReconciliationScreen(
            appState: appState,
            initialCandidates: candidates,
            fileName: file.name,
            fileType: fileType,
          ),
        ),
      );

      if (importedCount != null && importedCount > 0 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$importedCount lançamentos importados com sucesso!')),
        );
      }
    }
  }

  Future<void> _handleExportCsv(BuildContext context) async {
    HapticFeedback.lightImpact();
    await ExportCsvGenerator.shareCsv(
      transactions: appState.transactions,
      categoryMap: appState.categoryMap,
      accountMap: appState.accountMap,
    );
  }

  void _showSetupPinDialog(BuildContext context) {
    final pinController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Definir PIN de Acesso'),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              const Text('Crie um PIN numérico de 4 dígitos para proteger seu aplicativo:'),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                autofocus: true,
                placeholder: '• • • •',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 8),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length == 4) {
                Navigator.of(ctx).pop();
                final success = await appState.setupPin(pin);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'PIN ativado com sucesso!' : 'Erro ao salvar PIN.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Ativar'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: appState.userProfile?.name ?? '');

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Editar Nome do Usuário'),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: 'Seu Nome',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(ctx).pop();
                HapticFeedback.lightImpact();
                await appState.updateProfile(name: newName);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final profile = appState.userProfile;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: isDark
                ? AppColors.darkBackground.withValues(alpha: 0.9)
                : AppColors.lightBackground.withValues(alpha: 0.9),
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              centerTitle: false,
              title: Text(
                'Ajustes',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.6,
                  color: textPrimary,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card de Perfil Apple Settings Style
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Material(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              width: 0.8,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _showEditProfileDialog(context),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppColors.emerald, AppColors.emeraldDark],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      (profile?.name.isNotEmpty == true ? profile!.name[0] : 'U').toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile?.name ?? 'Usuário',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          appState.hasPinLock
                                              ? 'Conta protegida com PIN'
                                              : 'Toque para editar nome do perfil',
                                          style: TextStyle(fontSize: 13, color: textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Seção Apple Grouped: SEGURANÇA & ACESSO
                      IosGroupedSection(
                        header: 'Segurança & Privacidade',
                        children: [
                          IosListTile(
                            icon: Icons.lock_outline_rounded,
                            iconBackgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                            iconColor: AppColors.emeraldDark,
                            title: 'Bloqueio por PIN',
                            subtitle: appState.hasPinLock ? 'PIN de 4 dígitos ativado' : 'Desativado',
                            trailing: CupertinoSwitch(
                              value: appState.hasPinLock,
                              activeTrackColor: AppColors.emeraldDark,
                              onChanged: (val) {
                                if (val) {
                                  _showSetupPinDialog(context);
                                } else {
                                  appState.removePin();
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      // Seção Apple Grouped: NOTIFICAÇÕES & LEMBRETES
                      IosGroupedSection(
                        header: 'Lembretes & Notificações Locais',
                        children: [
                          IosListTile(
                            icon: Icons.alarm_on_rounded,
                            iconBackgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                            iconColor: AppColors.emeraldDark,
                            title: 'Lembrete Diário de Gastos',
                            subtitle: 'Notificação diária às ${appState.dailyReminderHour.toString().padLeft(2, '0')}:${appState.dailyReminderMinute.toString().padLeft(2, '0')}',
                            trailing: CupertinoSwitch(
                              value: appState.dailyReminderEnabled,
                              activeTrackColor: AppColors.emeraldDark,
                              onChanged: (val) async {
                                if (val) {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(
                                      hour: appState.dailyReminderHour,
                                      minute: appState.dailyReminderMinute,
                                    ),
                                  );
                                  if (picked != null) {
                                    await appState.setDailyReminder(
                                      enabled: true,
                                      hour: picked.hour,
                                      minute: picked.minute,
                                    );
                                  }
                                } else {
                                  await appState.setDailyReminder(enabled: false);
                                }
                              },
                            ),
                          ),
                          IosListTile(
                            icon: Icons.event_available_rounded,
                            iconBackgroundColor: AppColors.indigo.withValues(alpha: 0.15),
                            iconColor: AppColors.indigo,
                            title: 'Aviso de Vencimentos & Faturas',
                            subtitle: 'Alerta no dia do corte de cartão e contas fixas',
                            trailing: CupertinoSwitch(
                              value: appState.billReminderEnabled,
                              activeTrackColor: AppColors.emeraldDark,
                              onChanged: (val) => appState.setBillReminder(val),
                            ),
                          ),
                          IosListTile(
                            icon: Icons.notifications_active_rounded,
                            iconBackgroundColor: AppColors.amber.withValues(alpha: 0.15),
                            iconColor: AppColors.amber,
                            title: 'Disparar Notificação de Teste',
                            subtitle: 'Testa sons e banner imediato no dispositivo',
                            showChevron: true,
                            onTap: () async {
                              await NotificationService.instance.showImmediateNotification(
                                title: 'Teste de Lembrete Financeiro 💰',
                                body: 'Suas notificações locais estão funcionando perfeitamente!',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notificação de teste enviada!')),
                                );
                              }
                            },
                          ),
                        ],
                      ),

                      // Seção Apple Grouped: WIDGET DA TELA INICIAL
                      IosGroupedSection(
                        header: 'Widget de Tela Inicial',
                        footer: 'Para adicionar o widget, pressione um espaço vazio na tela inicial do celular, toque em Widgets e selecione Financeiro.',
                        children: [
                          IosListTile(
                            icon: Icons.widgets_rounded,
                            iconBackgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                            iconColor: AppColors.emeraldDark,
                            title: 'Sincronizar Widget Agora',
                            subtitle: 'Atualiza o saldo e gastos no widget compacto',
                            showChevron: true,
                            onTap: () async {
                              await appState.syncHomeWidget();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Dados sincronizados com o widget da Home!')),
                                );
                              }
                            },
                          ),
                        ],
                      ),

                      // Seção Apple Grouped: DADOS & EXTRATOS
                      IosGroupedSection(
                        header: 'Extratos & Exportações',
                        children: [
                          IosListTile(
                            icon: Icons.file_upload_rounded,
                            iconBackgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                            iconColor: AppColors.emeraldDark,
                            title: 'Importar Extrato (OFX / CSV)',
                            subtitle: 'Leitor universal dos bancos brasileiros',
                            showChevron: true,
                            onTap: () => _handleImportStatement(context),
                          ),
                          IosListTile(
                            icon: Icons.table_chart_rounded,
                            iconBackgroundColor: AppColors.indigo.withValues(alpha: 0.15),
                            iconColor: AppColors.indigo,
                            title: 'Exportar Planilha (CSV / Excel)',
                            subtitle: 'Compatível com contabilidade e IRPF',
                            showChevron: true,
                            onTap: () => _handleExportCsv(context),
                          ),
                          IosListTile(
                            icon: Icons.picture_as_pdf_rounded,
                            iconBackgroundColor: AppColors.rose.withValues(alpha: 0.15),
                            iconColor: AppColors.rose,
                            title: 'Gerar Relatório Mensal em PDF',
                            subtitle: 'Documento completo com gráficos e tabelas',
                            showChevron: true,
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await ReportPdfGenerator.printOrShareReport(
                                userName: appState.userProfile?.name ?? 'Usuário',
                                month: appState.selectedMonth,
                                totalIncome: appState.getMonthIncome(appState.selectedMonth),
                                totalExpense: appState.getMonthExpense(appState.selectedMonth),
                                netSavings: appState.getMonthSavings(appState.selectedMonth),
                                transactions: appState.getMonthTransactions(appState.selectedMonth),
                                categoryMap: appState.categoryMap,
                                accountMap: appState.accountMap,
                              );
                            },
                          ),
                          IosListTile(
                            icon: Icons.share_rounded,
                            iconBackgroundColor: AppColors.purple.withValues(alpha: 0.15),
                            iconColor: AppColors.purple,
                            title: 'Backup Completo (JSON)',
                            subtitle: 'Gera cópia de segurança de todos os dados',
                            showChevron: true,
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await BackupService.shareBackupFile();
                            },
                          ),
                        ],
                      ),

                      // Seção Apple Grouped: APARÊNCIA
                      IosGroupedSection(
                        header: 'Aparência',
                        children: [
                          IosListTile(
                            icon: Icons.light_mode_rounded,
                            title: 'Claro (Apple Light)',
                            trailing: appState.themeMode == ThemeMode.light
                                ? const Icon(Icons.check_rounded, color: AppColors.emeraldDark, size: 20)
                                : null,
                            onTap: () => appState.setThemeMode(ThemeMode.light),
                          ),
                          IosListTile(
                            icon: Icons.dark_mode_rounded,
                            title: 'Escuro (Slate Deep)',
                            trailing: appState.themeMode == ThemeMode.dark
                                ? const Icon(Icons.check_rounded, color: AppColors.emeraldDark, size: 20)
                                : null,
                            onTap: () => appState.setThemeMode(ThemeMode.dark),
                          ),
                          IosListTile(
                            icon: Icons.brightness_auto_rounded,
                            title: 'Padrão do Sistema',
                            trailing: appState.themeMode == ThemeMode.system
                                ? const Icon(Icons.check_rounded, color: AppColors.emeraldDark, size: 20)
                                : null,
                            onTap: () => appState.setThemeMode(ThemeMode.system),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Informação de Versão Apple Style
                      Center(
                        child: Text(
                          'Financeiro • Versão 1.0.0\n100% Local-First & Sem Rastreamento',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
