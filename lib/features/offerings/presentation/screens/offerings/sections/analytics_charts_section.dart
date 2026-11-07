part of '../../offerings_page.dart';

extension _AnalyticsChartsSection on _OfferingsPageState {
  Widget _distributionRow({
    required String label,
    required String value,
    required double ratio,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required String label,
    required int count,
    required Color color,
    required int total,
    double? amount,
  }) {
    final share = total == 0 ? 0 : count / total;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (amount != null) ...[
          Text(
            formatRupiah(amount),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          '$count · ${(share * 100).round()}%',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _segmentedBar(List<_AnalyticsSlice> slices, {double height = 8}) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (total <= 0) {
              return const ColoredBox(color: AppColors.background);
            }
            return Row(
              children: [
                for (final slice in slices)
                  if (slice.value > 0)
                    SizedBox(
                      width: constraints.maxWidth * (slice.value / total),
                      child: ColoredBox(color: slice.color),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _analyticsEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
