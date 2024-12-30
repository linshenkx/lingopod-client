import 'package:flutter/foundation.dart';
import '../models/rss_feed.dart';
import '../services/api_service.dart';

class RssProvider with ChangeNotifier {
  final ApiService _apiService;
  List<RssFeed> _feeds = [];
  bool _isLoading = false;
  String? _error;

  RssProvider(this._apiService);

  List<RssFeed> get feeds => _feeds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFeeds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _feeds = await _apiService.getRssFeeds();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFeed(Map<String, dynamic> feedData) async {
    try {
      final feed = await _apiService.createRssFeed(feedData);
      _feeds.add(feed);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateFeed(int feedId,
      {int? initialEntriesCount, int? updateEntriesCount}) async {
    try {
      final updatedFeed = await _apiService.updateRssFeed(
        feedId,
        initialEntriesCount: initialEntriesCount,
        updateEntriesCount: updateEntriesCount,
      );
      final index = _feeds.indexWhere((feed) => feed.id == feedId);
      if (index != -1) {
        _feeds[index] = updatedFeed;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteFeed(int feedId) async {
    try {
      await _apiService.deleteRssFeed(feedId);
      _feeds.removeWhere((feed) => feed.id == feedId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshFeed(int feedId) async {
    try {
      await _apiService.fetchRssFeed(feedId);
      // 刷新完成后重新加载该订阅源的数据
      final updatedFeed = await _apiService.getRssFeed(feedId);
      final index = _feeds.indexWhere((feed) => feed.id == feedId);
      if (index != -1) {
        _feeds[index] = updatedFeed;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRssFeedEntries(int feedId) async {
    try {
      return await _apiService.getRssFeedEntries(feedId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
