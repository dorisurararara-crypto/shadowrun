import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/features/history/presentation/widgets/analytics_overview.dart';

/// NRC 스타일 섹션 — 이달의 큰 타일, 레벨 배지, 배지 갤러리, 12개월 추세, 태그 요약.
/// 각 섹션은 테마 독립적이며 [AnalyticsPalette] 주입으로 테마 색/폰트 맞춤.

// ───────────────────────────────────────────────────────────
// Shadow Run 고유 레벨 시스템
// ───────────────────────────────────────────────────────────

class LevelTier {
  final String id;
  final String koName;
  final String enName;
  final double minKm;
  final double maxKm; // 다음 레벨까지의 상한
  const LevelTier(this.id, this.koName, this.enName, this.minKm, this.maxKm);
}

const levelTiers = <LevelTier>[
  LevelTier('walker', 'Shadow Walker', 'Shadow Walker', 0, 10),
  LevelTier('runner', 'Shadow Runner', 'Shadow Runner', 10, 50),
  LevelTier('stalker', 'Shadow Stalker', 'Shadow Stalker', 50, 150),
  LevelTier('ghost', 'Shadow Ghost', 'Shadow Ghost', 150, 500),
  LevelTier('master', 'Shadow Master', 'Shadow Master', 500, 999999),
];

LevelTier levelForKm(double km) {
  for (final t in levelTiers.reversed) {
    if (km >= t.minKm) return t;
  }
  return levelTiers.first;
}

// ───────────────────────────────────────────────────────────
// 이달의 큰 타일 (NRC 메인 임팩트)
// ───────────────────────────────────────────────────────────

class MonthTileCard extends StatelessWidget {
  final AnalyticsPalette palette;
  final double thisMonthKm;
  final int runs;
  const MonthTileCard({
    super.key,
    required this.palette,
    required this.thisMonthKm,
    required this.runs,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = S.isKo
        ? '${now.month}월'
        : _monthEn(now.month);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            S.isKo ? '$monthLabel 총거리' : '$monthLabel total',
            style: GoogleFonts.getFont(palette.bodyFamily,
                fontSize: 11,
                color: palette.muted,
                letterSpacing: 2),
          ),
          const SizedBox(height: 14),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: thisMonthKm.toStringAsFixed(1),
                  style: GoogleFonts.getFont(palette.numFamily,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: palette.text,
                      height: 1.0),
                ),
                TextSpan(
                  text: '  km',
                  style: GoogleFonts.getFont(palette.numFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            S.isKo ? '$runs회 달림' : '$runs runs',
            style: GoogleFonts.getFont(palette.bodyFamily,
                fontSize: 12,
                color: palette.muted),
          ),
        ],
      ),
    );
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static String _monthEn(int m) => _months[m - 1];
}

// ───────────────────────────────────────────────────────────
// 레벨 배지 + 다음 레벨 진척도
// ───────────────────────────────────────────────────────────

class LevelCard extends StatelessWidget {
  final AnalyticsPalette palette;
  final double lifetimeKm;
  const LevelCard({super.key, required this.palette, required this.lifetimeKm});

  @override
  Widget build(BuildContext context) {
    final tier = levelForKm(lifetimeKm);
    final tierIndex = levelTiers.indexWhere((t) => t.id == tier.id);
    final nextTier = tierIndex < levelTiers.length - 1 ? levelTiers[tierIndex + 1] : null;
    final progress = nextTier == null
        ? 1.0
        : ((lifetimeKm - tier.minKm) / (nextTier.minKm - tier.minKm)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      palette.accent,
                      palette.accent.withValues(alpha: 0.5),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.workspace_premium, color: palette.text, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.isKo ? '레벨' : 'level',
                      style: GoogleFonts.getFont(palette.bodyFamily,
                          fontSize: 10,
                          color: palette.muted,
                          letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      S.isKo ? tier.koName : tier.enName,
                      style: GoogleFonts.getFont(palette.numFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: palette.text),
                    ),
                  ],
                ),
              ),
              Text(
                '${lifetimeKm.toStringAsFixed(1)} km',
                style: GoogleFonts.getFont(palette.numFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: palette.fade.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(palette.accent),
            ),
          ),
          const SizedBox(height: 8),
          if (nextTier != null)
            Text(
              S.isKo
                  ? '${nextTier.koName}까지 ${(nextTier.minKm - lifetimeKm).toStringAsFixed(1)}km'
                  : '${(nextTier.minKm - lifetimeKm).toStringAsFixed(1)}km to ${nextTier.enName}',
              style: GoogleFonts.getFont(palette.bodyFamily,
                  fontSize: 11,
                  color: palette.muted),
            )
          else
            Text(
              S.isKo ? '최고 레벨 달성' : 'max tier reached',
              style: GoogleFonts.getFont(palette.bodyFamily,
                  fontSize: 11,
                  color: palette.accent,
                  fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 배지 갤러리 — 14종 고정, 획득 여부에 따라 컬러/회색
// ───────────────────────────────────────────────────────────

class BadgeDef {
  final String id;
  final IconData icon;
  final String koLabel;
  final String enLabel;
  const BadgeDef(this.id, this.icon, this.koLabel, this.enLabel);
}

const badgeDefs = <BadgeDef>[
  BadgeDef('dist_1k', Icons.directions_walk, '첫 1K', 'First 1K'),
  BadgeDef('dist_5k', Icons.directions_run, '5K', '5K'),
  BadgeDef('dist_10k', Icons.rocket_launch, '10K', '10K'),
  BadgeDef('dist_half', Icons.military_tech, '하프', 'Half'),
  BadgeDef('dist_full', Icons.emoji_events, '풀코스', 'Full'),
  BadgeDef('total_50k', Icons.landscape, '누적 50K', '50K total'),
  BadgeDef('total_200k', Icons.terrain, '누적 200K', '200K total'),
  BadgeDef('total_500k', Icons.local_fire_department, '누적 500K', '500K total'),
  BadgeDef('dopp_first_win', Icons.flash_on, '첫 탈출', 'First escape'),
  BadgeDef('dopp_10_wins', Icons.bolt, '10승', '10 escapes'),
  BadgeDef('dopp_50_wins', Icons.whatshot, '50승', '50 escapes'),
  BadgeDef('streak_3', Icons.looks_3, '3일', '3 streak'),
  BadgeDef('streak_7', Icons.filter_7, '7일', '7 streak'),
  BadgeDef('streak_30', Icons.calendar_month, '30일', '30 streak'),
];

class BadgeGalleryCard extends StatelessWidget {
  final AnalyticsPalette palette;
  final Set<String> earned;
  const BadgeGalleryCard({super.key, required this.palette, required this.earned});

  @override
  Widget build(BuildContext context) {
    final earnedCount = earned.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                S.isKo ? '배지' : 'badges',
                style: GoogleFonts.getFont(palette.bodyFamily,
                    fontSize: 11,
                    color: palette.muted,
                    letterSpacing: 1.5),
              ),
              const Spacer(),
              Text(
                '$earnedCount / ${badgeDefs.length}',
                style: GoogleFonts.getFont(palette.numFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.accent),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final b in badgeDefs)
                _badgeTile(b, earned.contains(b.id)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeTile(BadgeDef b, bool got) {
    final color = got ? palette.accent : palette.fade;
    return SizedBox(
      width: 66,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: got ? color.withValues(alpha: 0.15) : Colors.transparent,
              border: Border.all(color: color, width: 1.4),
            ),
            child: Icon(b.icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            S.isKo ? b.koLabel : b.enLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.getFont(palette.bodyFamily,
                fontSize: 9,
                fontWeight: got ? FontWeight.w700 : FontWeight.w400,
                color: got ? palette.text : palette.muted),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 최근 12개월 막대 — 장기 꾸준함
// ───────────────────────────────────────────────────────────

class Monthly12Card extends StatelessWidget {
  final AnalyticsPalette palette;
  final List<Map<String, dynamic>> monthly;
  const Monthly12Card({super.key, required this.palette, required this.monthly});

  @override
  Widget build(BuildContext context) {
    final maxKm = monthly.fold<double>(
      1.0,
      (p, m) => ((m['distance'] as num?)?.toDouble() ?? 0.0) / 1000 > p
          ? ((m['distance'] as num).toDouble() / 1000)
          : p,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.isKo ? '최근 12개월' : 'last 12 months',
            style: GoogleFonts.getFont(palette.bodyFamily,
                fontSize: 11,
                color: palette.muted,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxKm * 1.15,
                minY: 0,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= monthly.length) return const SizedBox.shrink();
                        final ms = monthly[idx]['monthStart'] as DateTime;
                        // 3개월 간격만 표시 (너무 빽빽)
                        if (idx % 3 != 0 && idx != monthly.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${ms.month}월',
                            style: GoogleFonts.getFont(palette.bodyFamily,
                                fontSize: 9, color: palette.muted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (int i = 0; i < monthly.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: ((monthly[i]['distance'] as num?)?.toDouble() ?? 0.0) / 1000,
                          color: palette.accent,
                          width: 9,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// 러닝 태그(모드)별 요약
// ───────────────────────────────────────────────────────────

class TagSummaryCard extends StatelessWidget {
  final AnalyticsPalette palette;
  final Map<String, Map<String, dynamic>> byMode;
  const TagSummaryCard({super.key, required this.palette, required this.byMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.isKo ? '러닝 카테고리' : 'run categories',
            style: GoogleFonts.getFont(palette.bodyFamily,
                fontSize: 11,
                color: palette.muted,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 14),
          _row(S.isKo ? '도플갱어' : 'doppelgänger', byMode['doppelganger']!, palette.accent),
          const SizedBox(height: 10),
          _row(S.isKo ? '자유' : 'freerun', byMode['freerun']!, palette.muted),
          const SizedBox(height: 10),
          _row(S.isKo ? '전설' : 'legend', byMode['marathon']!, palette.fade),
        ],
      ),
    );
  }

  Widget _row(String label, Map<String, dynamic> data, Color color) {
    final runs = data['runs'] as int;
    final km = (data['distanceM'] as double) / 1000;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.getFont(palette.bodyFamily,
                fontSize: 12, color: palette.text),
          ),
        ),
        Expanded(
          child: Text(
            km.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: GoogleFonts.getFont(palette.numFamily,
                fontSize: 14, fontWeight: FontWeight.w700, color: palette.text),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            'km',
            style: GoogleFonts.getFont(palette.bodyFamily,
                fontSize: 10, color: palette.muted),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$runs${S.isKo ? "회" : " runs"}',
            textAlign: TextAlign.right,
            style: GoogleFonts.getFont(palette.bodyFamily,
                fontSize: 11, color: palette.muted),
          ),
        ),
      ],
    );
  }
}
