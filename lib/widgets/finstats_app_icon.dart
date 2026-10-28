import 'package:flutter/material.dart';

/// Renderiza vetorialmente o ícone do FinStats com fundo squircle e cartão de crédito esmeralda
/// retangular (proporção oficial 1.59:1) com chip EMV dourado, sem logos de texto no topo,
/// mantendo a mesma filosofia visual do [BioStatsAppIcon].
class FinStatsAppIcon extends StatelessWidget {
  final double size;

  const FinStatsAppIcon({
    super.key,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    final s = size / 512.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Squircle Background (#F8FAFC -> #E2E8F0)
          Container(
            width: 448 * s,
            height: 448 * s,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFE2E8F0),
                ],
              ),
              borderRadius: BorderRadius.circular(100 * s),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12 * s,
                  offset: Offset(0, 4 * s),
                ),
              ],
            ),
          ),

          // Cartão de Crédito Retangular (#10B981 -> #047857) - Proporção 1.59:1
          Container(
            width: 350 * s,
            height: 220 * s,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF047857),
                ],
              ),
              borderRadius: BorderRadius.circular(28 * s),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF047857).withValues(alpha: 0.35),
                  blurRadius: 20 * s,
                  offset: Offset(0, 14 * s),
                ),
              ],
            ),
            child: Stack(
              children: [
                // EMV Gold Chip
                Positioned(
                  left: 36 * s,
                  top: 46 * s,
                  width: 64 * s,
                  height: 48 * s,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFCD34D),
                          Color(0xFFD97706),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10 * s),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            height: 2 * s,
                            color: const Color(0xFF92400E).withValues(alpha: 0.5),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 2 * s,
                            color: const Color(0xFF92400E).withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Contactless Icon Waves
                Positioned(
                  left: 118 * s,
                  top: 54 * s,
                  child: Icon(
                    Icons.contactless_rounded,
                    size: 32 * s,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),

                // Círculos Holográficos no Canto Superior Direito
                Positioned(
                  right: 36 * s,
                  top: 42 * s,
                  child: SizedBox(
                    width: 54 * s,
                    height: 36 * s,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          child: Container(
                            width: 34 * s,
                            height: 34 * s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: Container(
                            width: 34 * s,
                            height: 34 * s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pontos e Numeração em Relevo na Base
                Positioned(
                  left: 36 * s,
                  bottom: 26 * s,
                  right: 36 * s,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          4,
                          (i) => Container(
                            margin: EdgeInsets.only(right: 5 * s),
                            width: 6 * s,
                            height: 6 * s,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '•••• 8829',
                        style: TextStyle(
                          fontSize: 18 * s,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5 * s,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
