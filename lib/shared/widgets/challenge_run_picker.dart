import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// 도플갱어 추격(챌린지) 모드에서 어떤 기록에 도전할지 선택하는 바텀시트.
///
/// 반환: 선택된 run.id (null = 취소 또는 기록 없음).
/// 기록이 하나도 없으면 안내 토스트만 띄우고 null 반환.
Future<int?> pickChallengeRun(BuildContext context) async {
  final runs = await DatabaseHelper.getAllRuns();
  if (!context.mounted) return null;

  if (runs.isEmpty) {
    final themeId = ThemeManager.I.currentId;
    final accent = _accentFor(themeId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surfaceFor(themeId),
        content: Text(
          S.isKo
              ? '아직 도전할 기록이 없어요.\n먼저 자유 러닝을 완료해주세요.'
              : "No runs to challenge yet.\nComplete a free run first.",
          style: GoogleFonts.inter(color: accent, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    return null;
  }

  // 최신순 — getAllRuns는 보통 DESC이지만 재정렬 보장
  final sorted = [...runs]..sort((a, b) => b.date.compareTo(a.date));

  if (!context.mounted) return null;
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _ChallengePickerSheet(runs: sorted),
  );
}

Color _accentFor(ThemeId id) {
  switch (id) {
    case ThemeId.koreanMystic:
      return const Color(0xFFC42029);
    case ThemeId.pureCinematic:
      return const Color(0xFFC83030);
    default:
      return const Color(0xFFFF5262);
  }
}

Color _surfaceFor(ThemeId id) {
  switch (id) {
    case ThemeId.koreanMystic:
      return const Color(0xFF0A0604);
    case ThemeId.pureCinematic:
      return const Color(0xFF0A0A0A);
    default:
      return const Color(0xFF131313);
  }
}

class _ChallengePickerSheet extends StatelessWidget {
  final List<RunModel> runs;
  const _ChallengePickerSheet({required this.runs});

  @override
  Widget build(BuildContext context) {
    final themeId = ThemeManager.I.currentId;
    final mystic = themeId == ThemeId.koreanMystic;
    final pure = themeId == ThemeId.pureCinematic;

    final bg = mystic
        ? const Color(0xFF0A0604)
        : pure
            ? const Color(0xFF0A0A0A)
            : const Color(0xFF161616);
    final fg = mystic
        ? const Color(0xFFF0EBE3)
        : pure
            ? const Color(0xFFF5F5F5)
            : const Color(0xFFE5E2E1);
    final fgDim = mystic
        ? const Color(0xFF9A8A7A)
        : pure
            ? const Color(0xFF888888)
            : const Color(0xFF9E8A8A);
    final accent = _accentFor(themeId);
    final border = mystic
        ? const Color(0xFF2A1518)
        : pure
            ? const Color(0xFF1A1A1A)
            : const Color(0xFF2A2A2A);

    final titleFontFamily = mystic
        ? 'Nanum Myeongjo'
        : pure
            ? 'Playfair Display'
            : 'Space Grotesk';
    final titleStyle = mystic
        ? GoogleFonts.nanumMyeongjo(fontSize: 18, fontWeight: FontWeight.w800, color: fg)
        : pure
            ? GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: fg,
                letterSpacing: -0.5,
              )
            : GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: fg);
    final subStyle = GoogleFonts.inter(fontSize: 11, color: fgDim, letterSpacing: 0.15);

    final maxHeight = MediaQuery.of(context).size.height * 0.72;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: accent, width: 1)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // drag handle
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 6),
              child: Text(
                S.isKo ? '어떤 기록에 도전할까?' : 'Which ghost will you chase?',
                style: titleStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: Text(
                S.isKo
                    ? '선택한 기록의 경로·페이스를 따라 도플갱어가 뛴다.'
                    : 'Your doppelgänger will mimic the chosen run.',
                style: subStyle,
              ),
            ),
            Container(height: 1, color: border),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: runs.length,
                separatorBuilder: (ctx, i) => Container(height: 1, color: border, margin: const EdgeInsets.symmetric(horizontal: 22)),
                itemBuilder: (context, i) {
                  final r = runs[i];
                  return _runTile(
                    context: context,
                    run: r,
                    fg: fg,
                    fgDim: fgDim,
                    accent: accent,
                    numFont: titleFontFamily == 'Space Grotesk' ? 'Space Grotesk' : titleFontFamily,
                    mystic: mystic,
                    pure: pure,
                  );
                },
              ),
            ),
            Container(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  height: 36,
                  child: Center(
                    child: Text(
                      S.isKo ? '취소' : 'CANCEL',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: fgDim,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _runTile({
    required BuildContext context,
    required RunModel run,
    required Color fg,
    required Color fgDim,
    required Color accent,
    required String numFont,
    required bool mystic,
    required bool pure,
  }) {
    final dateLabel = _formatDate(run.date);
    final userName = run.name?.trim() ?? '';
    final autoLoc = run.location?.trim() ?? '';
    final location = userName.isNotEmpty ? userName : autoLoc;
    final locationLabel = location.isEmpty
        ? (S.isKo ? '이름 없는 길' : 'Unnamed route')
        : (location.length > 22 ? '${location.substring(0, 22)}…' : location);
    final distKm = (run.distanceM / 1000).toStringAsFixed(2);
    final durationLabel = _formatDuration(run.durationS);

    String resultLabel;
    Color resultColor;
    if (run.challengeResult == 'win') {
      resultLabel = S.isKo ? '살았다' : 'ESCAPED';
      resultColor = mystic || pure ? fg : const Color(0xFF6BD9C7);
    } else if (run.challengeResult == 'lose') {
      resultLabel = S.isKo ? '잡혔다' : 'CAUGHT';
      resultColor = accent;
    } else {
      resultLabel = S.isKo ? '자유' : 'FREE';
      resultColor = fgDim;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (run.id == null) return;
          Navigator.pop(context, run.id);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            children: [
              // 날짜 배지
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: accent.withValues(alpha: 0.35), width: 1),
                  color: accent.withValues(alpha: 0.06),
                ),
                child: Text(
                  run.id?.toString().padLeft(3, '0') ?? '—',
                  style: TextStyle(
                    fontFamily: numFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontStyle: pure ? FontStyle.italic : FontStyle.normal,
                    color: accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dateLabel · $locationLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$distKm km · $durationLabel',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: fgDim,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                resultLabel,
                style: TextStyle(
                  fontFamily: mystic ? 'Nanum Myeongjo' : 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: resultColor,
                  letterSpacing: mystic ? 0 : 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.length < 10) return raw;
    final m = int.tryParse(raw.substring(5, 7));
    final d = int.tryParse(raw.substring(8, 10));
    if (m == null || d == null) return raw;
    return S.isKo ? '$m월 $d일' : '${_monthEn(m)} $d';
  }

  String _monthEn(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (m < 1 || m > 12) return '';
    return names[m - 1];
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }
}
