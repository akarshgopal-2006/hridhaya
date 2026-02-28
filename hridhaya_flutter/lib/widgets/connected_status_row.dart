import 'package:flutter/material.dart';

class ConnectedStatusRow extends StatelessWidget {
  final bool familySynced;
  final bool hospitalSynced;
  final VoidCallback? onFamilyTap;
  final VoidCallback? onHospitalTap;

  const ConnectedStatusRow({
    super.key,
    required this.familySynced,
    required this.hospitalSynced,
    this.onFamilyTap,
    this.onHospitalTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;
        final isMedium = constraints.maxWidth < 500;

        return Wrap(
          spacing: isCompact ? 6 : 10,
          runSpacing: isCompact ? 6 : 10,
          alignment: WrapAlignment.center,
          children: [
            _Chip(
              icon: Icons.groups_rounded,
              label: 'Family',
              active: familySynced,
              compact: isCompact,
              medium: isMedium,
              onTap: onFamilyTap,
            ),
            _Chip(
              icon: Icons.local_hospital_rounded,
              label: 'Nearest Hospital',
              active: hospitalSynced,
              compact: isCompact,
              medium: isMedium,
              onTap: onHospitalTap,
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool compact;
  final bool medium;
  final VoidCallback? onTap;

  const _Chip({
    required this.icon,
    required this.label,
    required this.active,
    this.compact = false,
    this.medium = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dotColor = active ? const Color(0xFF2E7D32) : scheme.outline;
    final bg = active
        ? scheme.surfaceContainerHigh
        : scheme.surface;

    final horizontalPad = compact ? 8.0 : (medium ? 12.0 : 14.0);
    final verticalPad = compact ? 6.0 : (medium ? 8.0 : 10.0);
    final iconSize = compact ? 14.0 : (medium ? 16.0 : 18.0);
    final dotSize = compact ? 7.0 : (medium ? 8.0 : 10.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: compact ? 140 : double.infinity,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPad,
            vertical: verticalPad,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: scheme.onSurface),
              SizedBox(width: compact ? 4 : 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 11 : (medium ? 13 : null),
                      ),
                ),
              ),
              SizedBox(width: compact ? 5 : 10),
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (onTap != null) ...[
                SizedBox(width: compact ? 2 : 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: compact ? 14 : 16,
                  color: scheme.outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
