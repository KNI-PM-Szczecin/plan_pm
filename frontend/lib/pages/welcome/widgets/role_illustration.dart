// Dekoracyjna ilustracja na stronie wyboru roli — dwie "karteczki" z ikonami na granatowym tle.
// [_RoleCard] to prywatny widżet używany wyłącznie przez [RoleIllustration].
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RoleIllustration extends StatelessWidget {
  const RoleIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(20, -8),
            child: Transform.rotate(
              angle: 0.12,
              child: const _RoleCard(icon: LucideIcons.bookOpen),
            ),
          ),
          Transform.translate(
            offset: const Offset(-18, 8),
            child: Transform.rotate(
              angle: -0.08,
              child: const _RoleCard(icon: LucideIcons.graduationCap),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 30),
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 38,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
