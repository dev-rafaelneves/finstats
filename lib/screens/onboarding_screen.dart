import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/finstats_app_icon.dart';
import '../widgets/ios_grouped_section.dart';

class OnboardingScreen extends StatefulWidget {
  final AppState appState;

  const OnboardingScreen({super.key, required this.appState});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  int _currentIndex = 0;
  bool _isLoading = false;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      badge: '100% PESSOAL & PRIVADO',
      title: 'Controle Financeiro na Palma da Mão',
      description:
          'Gerencie contas, saldos, despesas e receitas com privacidade absoluta: seus dados ficam salvos apenas no seu dispositivo, sem compartilhamento com nuvens externas.',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: AppColors.emeraldDark,
      highlights: [
        'Banco de dados local SQLite criptografado no seu celular',
        'Proteção total com Bloqueio por PIN e Biometria nativa',
      ],
    ),
    _OnboardingSlide(
      badge: 'APPLE WALLET & CRÉDITO',
      title: 'Gestão de Cartões e Ciclo de Faturas',
      description:
          'Acompanhe faturas abertas, fechadas e pagas com cálculo do melhor dia de compra e conciliação bancária de extratos OFX e planilhas CSV.',
      icon: Icons.credit_card_rounded,
      accentColor: AppColors.indigo,
      highlights: [
        'Cartão virtual estilo Apple Wallet com controle dinâmico de limites',
        'Importação de extratos dos principais bancos brasileiros com detecção de duplicatas',
      ],
    ),
    _OnboardingSlide(
      badge: 'INTELIGÊNCIA ANALÍTICA',
      title: 'Comparador Mensal e Taxa de Poupança',
      description:
          'Acompanhe seu fluxo de caixa, evolução patrimonial acumulada e compare variações de despesas mês a mês para poupar mais.',
      icon: Icons.insights_rounded,
      accentColor: AppColors.amber,
      highlights: [
        'Comparador Mês a Mês inspirado no BioStats com destaque percentual',
        'Exportação executiva de relatórios em PDF com gráficos e planilhas CSV',
      ],
    ),
  ];

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentIndex < _slides.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _skipToFinal() {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      _slides.length,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe seu nome ou como prefere ser chamado.')),
      );
      return;
    }

    final initialBalance = double.tryParse(_balanceController.text.replaceAll(',', '.').trim()) ?? 0.0;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    await widget.appState.completeOnboarding(
      name: name,
      initialBalance: initialBalance,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final totalSteps = _slides.length + 1; // 3 slides conceituais + 1 tela de perfil

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                // Barra Superior no estilo BioStats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const FinStatsAppIcon(size: 34),
                          const SizedBox(width: 10),
                          Text(
                            'FinStats',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (_currentIndex < totalSteps - 1)
                        TextButton(
                          onPressed: _skipToFinal,
                          child: Text(
                            'Pular',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Conteúdo deslizante (PageView)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: totalSteps,
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    itemBuilder: (context, index) {
                      // Slides Informativos (0, 1, 2)
                      if (index < _slides.length) {
                        final slide = _slides[index];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: slide.accentColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    slide.icon,
                                    size: 42,
                                    color: slide.accentColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: slide.accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    slide.badge,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: slide.accentColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  slide.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  slide.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.5,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                ...slide.highlights.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 18,
                                            color: slide.accentColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              item,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Slide 4: Configuração Inicial de Perfil & Saldo
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldDark.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: AppColors.emeraldDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldDark.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Text(
                                    'VAMOS COMEÇAR',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: AppColors.emeraldDark,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Personalize sua Experiência',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Defina como gostaria de ser chamado e seu saldo atual para criar sua conta inicial.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              IosGroupedSection(
                                header: 'SEU NOME OU APELIDO',
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    child: CupertinoTextField(
                                      controller: _nameController,
                                      textCapitalization: TextCapitalization.words,
                                      placeholder: 'Ex: Rafael',
                                      prefix: const Icon(Icons.person_outline_rounded, color: Colors.grey, size: 20),
                                      decoration: const BoxDecoration(),
                                      style: TextStyle(fontSize: 15, color: textPrimary),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              IosGroupedSection(
                                header: 'SALDO INICIAL DA CONTA CORRENTE',
                                footer: 'Você pode alterar ou cadastrar novos bancos a qualquer momento.',
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    child: CupertinoTextField(
                                      controller: _balanceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      placeholder: '0,00',
                                      prefix: const Text(
                                        'R\$ ',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      decoration: const BoxDecoration(),
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Indicador de Passos (Dots) + Botão de Ação Inferior
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          totalSteps,
                          (idx) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 7,
                            width: _currentIndex == idx ? 26 : 7,
                            decoration: BoxDecoration(
                              color: _currentIndex == idx
                                  ? AppColors.emeraldDark
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_currentIndex == totalSteps - 1 ? _finish : _next),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emeraldDark,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentIndex == totalSteps - 1
                                          ? 'Começar Minhas Finanças'
                                          : 'Próximo',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _currentIndex == totalSteps - 1
                                          ? Icons.check_circle_rounded
                                          : Icons.arrow_forward_rounded,
                                      size: 19,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String badge;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<String> highlights;

  const _OnboardingSlide({
    required this.badge,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.highlights,
  });
}
