part of '../../project_detail_screen.dart';

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.textSecondary,
      ),
    );
  }
}
