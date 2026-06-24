import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../../services/cattle_service.dart';
import '../theme/app_theme.dart';

/// Tinder-style swiper for recent cattle detections on the dashboard.
class DetectionSwiper extends StatelessWidget {
  final List<CattleDetection> detections;

  const DetectionSwiper({super.key, required this.detections});

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) return const SizedBox.shrink();

    final cards = detections.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Detections',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: CardSwiper(
            cardsCount: cards.length,
            numberOfCardsDisplayed: cards.length.clamp(1, 3),
            backCardOffset: const Offset(0, 24),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            cardBuilder: (context, index, _, _) {
              final d = cards[index];
              return _DetectionCard(detection: d);
            },
          ),
        ),
      ],
    );
  }
}

class _DetectionCard extends StatelessWidget {
  final CattleDetection detection;

  const _DetectionCard({required this.detection});

  @override
  Widget build(BuildContext context) {
    final isLame = detection.isLame;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLame
              ? [const Color(0xFFE57373), const Color(0xFFEF5350)]
              : [AppTheme.primaryTeal, AppTheme.lightTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLame ? Icons.warning_amber_rounded : Icons.pets,
                color: AppTheme.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detection.cattleId,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLame ? 'Lame' : 'Healthy',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _chip(Icons.format_list_numbered, 'Count ${detection.cattleCount}'),
              const SizedBox(width: 8),
              _chip(Icons.water_drop, detection.milkingStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lameness ${detection.lamenessScore.toStringAsFixed(1)}',
            style: TextStyle(
              color: AppTheme.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
