part of '../../offering_detail_screen.dart';

class _DescriptionHeader extends StatelessWidget {
  final String label;
  final TextAlign alignment;

  const _DescriptionHeader(this.label, {this.alignment = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        label,
        textAlign: alignment,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
