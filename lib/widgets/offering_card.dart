import 'package:flutter/material.dart';

import '../models/offering.dart';
import '../theme/app_theme.dart';
import '../utils/status_extensions.dart';
import 'status_chip.dart';

class OfferingCard extends StatelessWidget {
  final Offering offering;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool selected;

  const OfferingCard({
    super.key,
    required this.offering,
    this.onTap,
    this.trailing,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.8 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _thumbnail(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          offering.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.apartment,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          offering.owner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          offering.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: offering.status.label,
                        color: offering.status.color,
                      ),
                      StatusChip(
                        label: offering.paidStatus.label,
                        color: offering.paidStatus.color,
                        icon: Icons.payments_outlined,
                      ),
                      if (offering.clientHasRecentOffer)
                        const StatusChip(
                          label: 'Recent offer',
                          color: AppColors.pending,
                          icon: Icons.history,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    return Container(
      height: 96,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -16,
            child: Icon(
              Icons.terrain,
              size: 110,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Row(
              children: [
                const Icon(Icons.eco, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  offering.number.isEmpty ? 'OFFERING' : offering.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (offering.latitude != null && offering.longitude != null)
            Positioned(
              left: 16,
              bottom: 14,
              child: Text(
                '${offering.latitude!.toStringAsFixed(3)}, ${offering.longitude!.toStringAsFixed(3)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
