part of '../../offering_form_screen.dart';

class _LineItemHeaderCell extends StatelessWidget {
  final String label;
  final TextAlign alignment;
  final double horizontalPadding;

  const _LineItemHeaderCell(
    this.label, {
    this.alignment = TextAlign.start,
    this.horizontalPadding = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 9),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment,
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
