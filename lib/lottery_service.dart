import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

// Cache constants
const String _CACHE_PREFIX = 'lottery_history_';
const int _CACHE_DURATION_MINUTES = 30;

/// 彩票类型枚举
enum LotteryType { SSQ, DLT }

/// 缓存管理器
class CacheManager {
  static String _getCacheKey(String type, int limit) {
    return '$_CACHE_PREFIX${type}_${limit}';
  }

  static String _getTimestampKey(String type, int limit) {
    return '${_CACHE_PREFIX}timestamp_${type}_${limit}';
  }

  static Future<void> saveToCache(
    String type,
    int limit,
    String jsonString,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(type, limit);
      final timestampKey = _getTimestampKey(type, limit);

      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Cache save error: $e');
    }
  }

  static Future<String?> getFromCache(String type, int limit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(type, limit);
      final timestampKey = _getTimestampKey(type, limit);

      final cachedData = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);

      if (cachedData == null || timestamp == null) {
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheAgeMinutes = (now - timestamp) / (1000 * 60);

      if (cacheAgeMinutes > _CACHE_DURATION_MINUTES) {
        // Cache expired, remove it
        await prefs.remove(cacheKey);
        await prefs.remove(timestampKey);
        return null;
      }

      return cachedData;
    } catch (e) {
      print('Cache retrieval error: $e');
      return null;
    }
  }

  static Future<void> clearCache(String type, int limit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(type, limit);
      final timestampKey = _getTimestampKey(type, limit);

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
    } catch (e) {
      print('Cache clear error: $e');
    }
  }
}

// ==================== API Response Models ====================

/// 彩票历史记录API响应
class LotteryHistoryResponse {
  final int code;
  final String info;
  final LotteryHistoryData data;

  LotteryHistoryResponse({
    required this.code,
    required this.info,
    required this.data,
  });

  factory LotteryHistoryResponse.fromJson(Map<String, dynamic> json) {
    return LotteryHistoryResponse(
      code: json['code'] ?? 0,
      info: json['info'] ?? '',
      data: LotteryHistoryData.fromJson(json['data'] ?? {}),
    );
  }
}

/// 彩票历史数据
class LotteryHistoryData {
  final LotteryItem? last;
  final LotteryListData data;

  LotteryHistoryData({required this.last, required this.data});

  factory LotteryHistoryData.fromJson(Map<String, dynamic> json) {
    return LotteryHistoryData(
      last: json['last'] != null ? LotteryItem.fromJson(json['last']) : null,
      data: LotteryListData.fromJson(json['data'] ?? {}),
    );
  }
}

/// 彩票列表数据
class LotteryListData {
  final List<LotteryItem> list;
  final int currentPage;
  final int currentLimit;
  final int totalPage;
  final int totalCount;

  LotteryListData({
    required this.list,
    required this.currentPage,
    required this.currentLimit,
    required this.totalPage,
    required this.totalCount,
  });

  factory LotteryListData.fromJson(Map<String, dynamic> json) {
    var listData = json['list'] as List? ?? [];
    return LotteryListData(
      list: listData.map((item) => LotteryItem.fromJson(item)).toList(),
      currentPage: int.tryParse(json['currentPage'].toString()) ?? 1,
      currentLimit: int.tryParse(json['currentLimit'].toString()) ?? 10,
      totalPage: int.tryParse(json['totalPage'].toString()) ?? 0,
      totalCount: int.tryParse(json['totalCount'].toString()) ?? 0,
    );
  }
}

/// 单期彩票数据
class LotteryItem {
  final String code;
  final String day;
  final String one;
  final String two;
  final String three;
  final String four;
  final String five;
  final String six;
  final String? seven; // 蓝球或大乐透后区第二个球

  LotteryItem({
    required this.code,
    required this.day,
    required this.one,
    required this.two,
    required this.three,
    required this.four,
    required this.five,
    required this.six,
    this.seven,
  });

  factory LotteryItem.fromJson(Map<String, dynamic> json) {
    return LotteryItem(
      code: json['code']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      one: json['one']?.toString() ?? '0',
      two: json['two']?.toString() ?? '0',
      three: json['three']?.toString() ?? '0',
      four: json['four']?.toString() ?? '0',
      five: json['five']?.toString() ?? '0',
      six: json['six']?.toString() ?? '0',
      seven: json['seven']?.toString(),
    );
  }

  /// 转换为LotteryResult用于显示
  LotteryResult toLotteryResult(LotteryType type) {
    final List<int> front;
    final List<int> back;

    if (type == LotteryType.SSQ) {
      // 双色球: 6个红球 + 1个蓝球
      front = [
        int.tryParse(one) ?? 0,
        int.tryParse(two) ?? 0,
        int.tryParse(three) ?? 0,
        int.tryParse(four) ?? 0,
        int.tryParse(five) ?? 0,
        int.tryParse(six) ?? 0,
      ];
      back = seven != null ? [int.tryParse(seven!) ?? 0] : [];
    } else {
      // 大乐透: 5个篮球 + 2个黄球
      front = [
        int.tryParse(one) ?? 0,
        int.tryParse(two) ?? 0,
        int.tryParse(three) ?? 0,
        int.tryParse(four) ?? 0,
        int.tryParse(five) ?? 0,
      ];
      back = [
        int.tryParse(six) ?? 0,
        if (seven != null) int.tryParse(seven!) ?? 0,
      ];
    }

    return LotteryResult(
      issue: code,
      date: DateTime.tryParse(day) ?? DateTime.now(),
      front: front,
      back: back,
    );
  }
}

// ==================== Data Models ====================

/// 彩票开奖结果
class LotteryResult {
  final String issue;
  final DateTime date;
  final List<int> front;
  final List<int> back;

  const LotteryResult({
    required this.issue,
    required this.date,
    required this.front,
    required this.back,
  });
}

/// 推荐号码结果
class LotteryRecommendation {
  final String algorithmName;
  final List<int> frontNumbers;
  final List<int> backNumbers;

  LotteryRecommendation({
    required this.algorithmName,
    required this.frontNumbers,
    required this.backNumbers,
  });
}

/// 号码分类（热/温/冷号）
class NumberCategory {
  final List<int> hot; // 热号：高频出现的号码
  final List<int> warm; // 温号：中等频率的号码
  final List<int> cold; // 冷号：低频或未出现的号码

  NumberCategory({required this.hot, required this.warm, required this.cold});
}

// ==================== Recommendation Engine ====================

/// 彩票推荐引擎
class LotteryRecommendationEngine {
  /// 将号码转换为唯一key用于比较
  static String _numbersToKey(List<int> front, List<int> back) {
    final sortedFront = List<int>.from(front)..sort();
    final sortedBack = List<int>.from(back)..sort();
    return '${sortedFront.join(",")}_${sortedBack.join(",")}';
  }

  /// 检查生成的号码是否与历史开奖号码重复
  static bool _isDuplicateWithHistory(
    List<int> front,
    List<int> back,
    Set<String> historyKeys,
  ) {
    final key = _numbersToKey(front, back);
    return historyKeys.contains(key);
  }

  /// 构建历史开奖号码key集合
  static Set<String> _buildHistoryKeySet(List<LotteryResult> historyData) {
    final keys = <String>{};
    for (final result in historyData) {
      keys.add(_numbersToKey(result.front, result.back));
    }
    return keys;
  }

  /// 将号码按频率分类为热/温/冷号
  static NumberCategory categorizeNumbers(Map<int, int> frequency, int maxNum) {
    // Ensure all numbers are in the frequency map
    for (int i = 1; i <= maxNum; i++) {
      frequency.putIfAbsent(i, () => 0);
    }

    // Sort numbers by frequency (descending)
    final sortedEntries = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalCount = sortedEntries.length;
    final hotCount = (totalCount / 3).ceil();
    final warmCount = (totalCount / 3).ceil();

    final hot = <int>[];
    final warm = <int>[];
    final cold = <int>[];

    for (int i = 0; i < sortedEntries.length; i++) {
      if (i < hotCount) {
        hot.add(sortedEntries[i].key);
      } else if (i < hotCount + warmCount) {
        warm.add(sortedEntries[i].key);
      } else {
        cold.add(sortedEntries[i].key);
      }
    }

    return NumberCategory(hot: hot, warm: warm, cold: cold);
  }

  /// 计算号码出现频率
  static Map<int, int> calculateFrequency(
    List<LotteryResult> history,
    bool isFront,
    int maxNum,
  ) {
    final freq = <int, int>{};
    for (int i = 1; i <= maxNum; i++) {
      freq[i] = 0;
    }
    for (final result in history) {
      final numbers = isFront ? result.front : result.back;
      for (final num in numbers) {
        freq[num] = (freq[num] ?? 0) + 1;
      }
    }
    return freq;
  }

  /// 确保推荐号码不与历史开奖重复
  static LotteryRecommendation _ensureNotDuplicate(
    LotteryRecommendation rec,
    Set<String> historyKeys,
    int frontMax,
    int backMax,
    int frontCount,
    int backCount,
  ) {
    var front = List<int>.from(rec.frontNumbers);
    var back = List<int>.from(rec.backNumbers);
    final rng = Random();
    int attempts = 0;
    const maxAttempts = 100;

    while (_isDuplicateWithHistory(front, back, historyKeys) &&
        attempts < maxAttempts) {
      // Try to replace one number in front area
      if (front.isNotEmpty) {
        final indexToReplace = rng.nextInt(front.length);
        final usedNumbers = front.toSet();
        final available = <int>[];
        for (int i = 1; i <= frontMax; i++) {
          if (!usedNumbers.contains(i)) {
            available.add(i);
          }
        }
        if (available.isNotEmpty) {
          front[indexToReplace] = available[rng.nextInt(available.length)];
        }
      }
      attempts++;
    }

    // Sort in ascending order (from small to large)
    front.sort();
    back.sort();

    return LotteryRecommendation(
      algorithmName: rec.algorithmName,
      frontNumbers: front,
      backNumbers: back,
    );
  }

  /// 生成5种不同算法的推荐号码
  static List<LotteryRecommendation> generateRecommendations(
    List<LotteryResult> historyData,
    LotteryType type,
  ) {
    if (historyData.isEmpty) return [];

    final frontMax = type == LotteryType.SSQ ? 33 : 35;
    final backMax = type == LotteryType.SSQ ? 16 : 12;
    final frontCount = type == LotteryType.SSQ ? 6 : 5;
    final backCount = type == LotteryType.SSQ ? 1 : 2;

    // Build history key set for duplicate checking
    final historyKeys = _buildHistoryKeySet(historyData);

    // Calculate frequency and categorize numbers
    final frontFreq = calculateFrequency(historyData, true, frontMax);
    final backFreq = calculateFrequency(historyData, false, backMax);
    final frontCategory = categorizeNumbers(frontFreq, frontMax);
    final backCategory = categorizeNumbers(backFreq, backMax);

    final recommendations = <LotteryRecommendation>[];

    // Algorithm 1: Hot numbers only (热号优先)
    recommendations.add(
      _hotNumberSelection(frontCategory, backCategory, frontCount, backCount),
    );

    // Algorithm 2: Cold numbers only (冷号优先)
    recommendations.add(
      _coldNumberSelection(frontCategory, backCategory, frontCount, backCount),
    );

    // Algorithm 3: Balanced mix - hot + warm + cold (均衡组合)
    recommendations.add(
      _balancedMixSelection(frontCategory, backCategory, frontCount, backCount),
    );

    // Algorithm 4: Hot + Warm combination (热温组合)
    recommendations.add(
      _hotWarmSelection(frontCategory, backCategory, frontCount, backCount),
    );

    // Algorithm 5: Warm + Cold combination (温冷组合)
    recommendations.add(
      _warmColdSelection(frontCategory, backCategory, frontCount, backCount),
    );

    // Process all recommendations: sort and ensure no duplicates with history
    return recommendations.map((rec) {
      return _ensureNotDuplicate(
        rec,
        historyKeys,
        frontMax,
        backMax,
        frontCount,
        backCount,
      );
    }).toList();
  }

  /// 算法1：热号优先
  static LotteryRecommendation _hotNumberSelection(
    NumberCategory frontCat,
    NumberCategory backCat,
    int frontCount,
    int backCount,
  ) {
    final rng = Random();
    final hotFront = List<int>.from(frontCat.hot)..shuffle(rng);
    final hotBack = List<int>.from(backCat.hot)..shuffle(rng);

    // If hot numbers are not enough, supplement with warm numbers
    final warmFront = List<int>.from(frontCat.warm)..shuffle(rng);
    final warmBack = List<int>.from(backCat.warm)..shuffle(rng);

    final frontNums = <int>[];
    frontNums.addAll(hotFront.take(frontCount));
    if (frontNums.length < frontCount) {
      frontNums.addAll(warmFront.take(frontCount - frontNums.length));
    }

    final backNums = <int>[];
    backNums.addAll(hotBack.take(backCount));
    if (backNums.length < backCount) {
      backNums.addAll(warmBack.take(backCount - backNums.length));
    }

    return LotteryRecommendation(
      algorithmName: '热号优先',
      frontNumbers: frontNums.take(frontCount).toList(),
      backNumbers: backNums.take(backCount).toList(),
    );
  }

  /// 算法2：冷号优先
  static LotteryRecommendation _coldNumberSelection(
    NumberCategory frontCat,
    NumberCategory backCat,
    int frontCount,
    int backCount,
  ) {
    final rng = Random();
    final coldFront = List<int>.from(frontCat.cold)..shuffle(rng);
    final coldBack = List<int>.from(backCat.cold)..shuffle(rng);

    // If cold numbers are not enough, supplement with warm numbers
    final warmFront = List<int>.from(frontCat.warm)..shuffle(rng);
    final warmBack = List<int>.from(backCat.warm)..shuffle(rng);

    final frontNums = <int>[];
    frontNums.addAll(coldFront.take(frontCount));
    if (frontNums.length < frontCount) {
      frontNums.addAll(warmFront.take(frontCount - frontNums.length));
    }

    final backNums = <int>[];
    backNums.addAll(coldBack.take(backCount));
    if (backNums.length < backCount) {
      backNums.addAll(warmBack.take(backCount - backNums.length));
    }

    return LotteryRecommendation(
      algorithmName: '冷号优先',
      frontNumbers: frontNums.take(frontCount).toList(),
      backNumbers: backNums.take(backCount).toList(),
    );
  }

  /// 算法3：均衡组合（热+温+冷）
  static LotteryRecommendation _balancedMixSelection(
    NumberCategory frontCat,
    NumberCategory backCat,
    int frontCount,
    int backCount,
  ) {
    final rng = Random();

    // For front: distribute evenly among hot, warm, cold
    final hotCount = (frontCount / 3).ceil();
    final warmCount = (frontCount / 3).ceil();
    final coldCount = frontCount - hotCount - warmCount;

    final hotFront = List<int>.from(frontCat.hot)..shuffle(rng);
    final warmFront = List<int>.from(frontCat.warm)..shuffle(rng);
    final coldFront = List<int>.from(frontCat.cold)..shuffle(rng);

    final frontNums = <int>{};
    frontNums.addAll(hotFront.take(hotCount));
    frontNums.addAll(warmFront.take(warmCount));
    frontNums.addAll(coldFront.take(coldCount.abs() + 1));

    // For back: prioritize hot and warm
    final hotBack = List<int>.from(backCat.hot)..shuffle(rng);
    final warmBack = List<int>.from(backCat.warm)..shuffle(rng);
    final coldBack = List<int>.from(backCat.cold)..shuffle(rng);

    final backNums = <int>{};
    if (backCount == 1) {
      // Single back number: randomly choose from hot or warm
      final combined = [...hotBack, ...warmBack]..shuffle(rng);
      backNums.addAll(combined.take(1));
    } else {
      backNums.addAll(hotBack.take(1));
      backNums.addAll(warmBack.take(1));
      if (backNums.length < backCount) {
        backNums.addAll(coldBack.take(backCount - backNums.length));
      }
    }

    return LotteryRecommendation(
      algorithmName: '均衡组合',
      frontNumbers: frontNums.take(frontCount).toList(),
      backNumbers: backNums.take(backCount).toList(),
    );
  }

  /// 算法4：热温组合
  static LotteryRecommendation _hotWarmSelection(
    NumberCategory frontCat,
    NumberCategory backCat,
    int frontCount,
    int backCount,
  ) {
    final rng = Random();

    // Front: 60% hot, 40% warm
    final hotFrontCount = (frontCount * 0.6).ceil();
    final warmFrontCount = frontCount - hotFrontCount;

    final hotFront = List<int>.from(frontCat.hot)..shuffle(rng);
    final warmFront = List<int>.from(frontCat.warm)..shuffle(rng);

    final frontNums = <int>{};
    frontNums.addAll(hotFront.take(hotFrontCount));
    frontNums.addAll(warmFront.take(warmFrontCount));

    // If not enough, supplement from the other category
    if (frontNums.length < frontCount) {
      final remaining = frontCount - frontNums.length;
      final combined = [...hotFront, ...warmFront]
        ..removeWhere((n) => frontNums.contains(n));
      combined.shuffle(rng);
      frontNums.addAll(combined.take(remaining));
    }

    // Back: prioritize hot
    final hotBack = List<int>.from(backCat.hot)..shuffle(rng);
    final warmBack = List<int>.from(backCat.warm)..shuffle(rng);

    final backNums = <int>{};
    backNums.addAll(hotBack.take(backCount));
    if (backNums.length < backCount) {
      backNums.addAll(warmBack.take(backCount - backNums.length));
    }

    return LotteryRecommendation(
      algorithmName: '热温组合',
      frontNumbers: frontNums.take(frontCount).toList(),
      backNumbers: backNums.take(backCount).toList(),
    );
  }

  /// 算法5：温冷组合
  static LotteryRecommendation _warmColdSelection(
    NumberCategory frontCat,
    NumberCategory backCat,
    int frontCount,
    int backCount,
  ) {
    final rng = Random();

    // Front: 60% warm, 40% cold
    final warmFrontCount = (frontCount * 0.6).ceil();
    final coldFrontCount = frontCount - warmFrontCount;

    final warmFront = List<int>.from(frontCat.warm)..shuffle(rng);
    final coldFront = List<int>.from(frontCat.cold)..shuffle(rng);

    final frontNums = <int>{};
    frontNums.addAll(warmFront.take(warmFrontCount));
    frontNums.addAll(coldFront.take(coldFrontCount));

    // If not enough, supplement from the other category
    if (frontNums.length < frontCount) {
      final remaining = frontCount - frontNums.length;
      final combined = [...warmFront, ...coldFront]
        ..removeWhere((n) => frontNums.contains(n));
      combined.shuffle(rng);
      frontNums.addAll(combined.take(remaining));
    }

    // Back: mix warm and cold
    final warmBack = List<int>.from(backCat.warm)..shuffle(rng);
    final coldBack = List<int>.from(backCat.cold)..shuffle(rng);

    final backNums = <int>{};
    if (backCount == 1) {
      final combined = [...warmBack, ...coldBack]..shuffle(rng);
      backNums.addAll(combined.take(1));
    } else {
      backNums.addAll(warmBack.take(1));
      backNums.addAll(coldBack.take(1));
    }

    return LotteryRecommendation(
      algorithmName: '温冷组合',
      frontNumbers: frontNums.take(frontCount).toList(),
      backNumbers: backNums.take(backCount).toList(),
    );
  }
}

// ==================== API Service ====================

/// 彩票数据服务
class LotteryService {
  static const String _baseUrl =
      'https://api.huiniao.top/interface/home/lotteryHistory';

  /// 获取彩票历史数据
  static Future<LotteryServiceResult> fetchHistoryData(
    LotteryType type,
    int historyCount,
  ) async {
    final typeStr = type == LotteryType.SSQ ? 'ssq' : 'dlt';

    try {
      // Try to get cached data first
      final cachedJsonString = await CacheManager.getFromCache(
        typeStr,
        historyCount,
      );

      if (cachedJsonString != null) {
        // Use cached data
        final jsonData = jsonDecode(cachedJsonString);
        final apiResponse = LotteryHistoryResponse.fromJson(jsonData);

        if (apiResponse.code == 1 && apiResponse.data.data.list.isNotEmpty) {
          final historyList = apiResponse.data.data.list
              .map((item) => item.toLotteryResult(type))
              .toList();

          return LotteryServiceResult(
            success: true,
            historyData: historyList,
            latestResult: historyList.isNotEmpty ? historyList.first : null,
          );
        }
      }

      // No cache or cache expired, fetch from API
      final url = Uri.parse(
        '$_baseUrl?type=$typeStr&page=1&limit=$historyCount',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Save to cache
        await CacheManager.saveToCache(typeStr, historyCount, response.body);

        final apiResponse = LotteryHistoryResponse.fromJson(jsonData);

        if (apiResponse.code == 1 && apiResponse.data.data.list.isNotEmpty) {
          final historyList = apiResponse.data.data.list
              .map((item) => item.toLotteryResult(type))
              .toList();

          return LotteryServiceResult(
            success: true,
            historyData: historyList,
            latestResult: historyList.isNotEmpty ? historyList.first : null,
          );
        } else {
          return LotteryServiceResult(
            success: false,
            errorMessage: apiResponse.info,
          );
        }
      } else {
        return LotteryServiceResult(
          success: false,
          errorMessage: '网络错误: ${response.statusCode}',
        );
      }
    } catch (e) {
      return LotteryServiceResult(success: false, errorMessage: '获取数据失败: $e');
    }
  }
}

/// 彩票服务返回结果
class LotteryServiceResult {
  final bool success;
  final List<LotteryResult> historyData;
  final LotteryResult? latestResult;
  final String? errorMessage;

  LotteryServiceResult({
    required this.success,
    this.historyData = const [],
    this.latestResult,
    this.errorMessage,
  });
}
