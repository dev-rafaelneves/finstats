import 'package:flutter/material.dart';

/// Renderiza vetorialmente o mesmo ícone com fundo squircle e cartão de crédito esmeralda
/// com chip EMV dourado, idêntico à filosofia do [BioStatsAppIcon].
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

          // Central Financial Card Pass (#10B981 -> #047857)
          Container(
            width: 300 * s,
            height: 260 * s,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF047857),
                ],
              ),
              borderRadius: BorderRadius.circular(52 * s),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF047857).withValues(alpha: 0.32),
                  blurRadius: 20 * s,
                  offset: Offset(0, 14 * s),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Display / Balance Screen Pill
                Positioned(
                  left: 65 * s,
                  top: 24 * s,
                  width: 170 * s,
                  height: 54 * s,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(18 * s),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'R\$ FIN',
                      style: TextStyle(
                        fontSize: 24 * s,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5 * s,
                        color: const Color(0xFF047857),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

                // EMV Gold Chip
                Positioned(
                  left: 32 * s,
                  top: 96 * s,
                  width: 60 * s,
                  height: 46 * s,
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
                  left: 104 * s,
                  top: 105 * s,
                  child: Icon(
                    Icons.contactless_rounded,
                    size: 28 * s,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),

                // Embossed Dots & Card Number
                Positioned(
                  left: 32 * s,
                  bottom: 22 * s,
                  right: 32 * s,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          4,
                          (i) => Container(
                            margin: EdgeInsets.only(right: 4 * s),
                            width: 6 * s,
                            height: 6 * s,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '•••• 8829',
                        style: TextStyle(
                          fontSize: 16 * s,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1 * s,
                          color: Colors.white.withValues(alpha: 0.85),
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
