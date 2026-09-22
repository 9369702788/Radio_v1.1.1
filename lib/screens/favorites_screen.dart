import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../widgets/station_card.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            AppStrings.favorites,
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: 'المفضلة'),
              Tab(icon: Icon(Icons.history), text: 'سجل الاستماع'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            radio.favorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.favorite_border, size: 64, color: AppColors.surfaceLight),
                        SizedBox(height: 14),
                        Text(AppStrings.noFavorites, style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90, top: 10),
                    itemCount: radio.favorites.length,
                    itemBuilder: (context, index) {
                      final station = radio.favorites[index];
                      return StationCard(
                        station: station,
                        isCurrent: radio.currentStation?.uuid == station.uuid,
                        isPlaying: radio.isPlaying,
                        onTap: () => radio.playStation(station),
                        onFavoriteToggle: () => radio.toggleFavorite(station),
                      );
                    },
                  ),
            radio.history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.history, size: 64, color: AppColors.surfaceLight),
                        SizedBox(height: 14),
                        Text('لا يوجد سجل استماع بعد', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90, top: 10),
                    itemCount: radio.history.length,
                    itemBuilder: (context, index) {
                      final station = radio.history[index];
                      return StationCard(
                        station: station,
                        isCurrent: radio.currentStation?.uuid == station.uuid,
                        isPlaying: radio.isPlaying,
                        onTap: () => radio.playStation(station),
                        onFavoriteToggle: () => radio.toggleFavorite(station),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
