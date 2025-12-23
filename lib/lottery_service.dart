import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

// ==================== Saved Tickets ====================

/// 保存的彩票号码
class SavedTicket {
  final String id;
  final LotteryType type;
  final List<int> frontNumbers;
  final List<int> backNumbers;
  final DateTime savedAt;
  final String? note;
  final String? targetIssue; // 目标期号

  SavedTicket({
    required this.id,
    required this.type,
    required this.frontNumbers,
    required this.backNumbers,
    required this.savedAt,
    this.note,
    this.targetIssue,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == LotteryType.SSQ ? 'SSQ' : 'DLT',
      'frontNumbers': frontNumbers,
      'backNumbers': backNumbers,
      'savedAt': savedAt.toIso8601String(),
      'note': note,
      'targetIssue': targetIssue,
    };
  }

  factory SavedTicket.fromJson(Map<String, dynamic> json) {
    return SavedTicket(
      id: json['id'] ?? '',
      type: json['type'] == 'SSQ' ? LotteryType.SSQ : LotteryType.DLT,
      frontNumbers: List<int>.from(json['frontNumbers'] ?? []),
      backNumbers: List<int>.from(json['backNumbers'] ?? []),
      savedAt: DateTime.tryParse(json['savedAt'] ?? '') ?? DateTime.now(),
      note: json['note'],
      targetIssue: json['targetIssue'],
    );
  }
}

/// 中奖结果
class PrizeResult {
  final bool isWinner;
  final int? prizeLevel; // 1-9等奖，null表示未中奖
  final String prizeName; // 奖项名称
  final int frontMatch; // 前区匹配数量
  final int backMatch; // 后区匹配数量
  final bool foundResult; // 是否找到开奖结果
  final String? issue; // 验证的期号

  PrizeResult({
    required this.isWinner,
    this.prizeLevel,
    required this.prizeName,
    required this.frontMatch,
    required this.backMatch,
    this.foundResult = true,
    this.issue,
  });
}

/// 保存的彩票服务
class SavedTicketService {
  static const String _fileName = 'saved_tickets.json';
  static File? _cachedFile;

  /// 获取存储文件路径
  static Future<File> _getStorageFile() async {
    if (_cachedFile != null) {
      return _cachedFile!;
    }
    
    // 首先尝试使用 path_provider
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      _cachedFile = file;
      return file;
    } catch (e) {
      print('Get application documents directory error: $e');
    }
    
    // 如果 path_provider 失败，尝试使用临时目录
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$_fileName');
      _cachedFile = file;
      return file;
    } catch (e) {
      print('Get temporary directory error: $e');
    }
    
    // 如果 path_provider 完全不可用，使用备用方案
    try {
      Directory storageDir;
      if (Platform.isWindows) {
        // Windows: 使用用户文档目录
        final userProfile = Platform.environment['USERPROFILE'] ?? 
                          Platform.environment['HOME'] ?? '';
        if (userProfile.isNotEmpty) {
          storageDir = Directory('$userProfile/Documents/LuckyU');
        } else {
          storageDir = Directory.current;
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        // macOS/Linux: 使用用户主目录
        final home = Platform.environment['HOME'] ?? '';
        if (home.isNotEmpty) {
          storageDir = Directory('$home/.local/share/LuckyU');
        } else {
          storageDir = Directory.current;
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 移动平台：使用应用目录
        storageDir = Directory.current;
      } else {
        // 其他平台：使用当前目录
        storageDir = Directory.current;
      }
      
      // 确保目录存在
      if (!await storageDir.exists()) {
        await storageDir.create(recursive: true);
      }
      
      final file = File('${storageDir.path}/$_fileName');
      _cachedFile = file;
      print('Using fallback storage path: ${file.path}');
      return file;
    } catch (e) {
      print('Get storage file error: $e');
      // 最后的备用方案：使用当前工作目录
      final file = File('$_fileName');
      _cachedFile = file;
      return file;
    }
  }

  /// 从SharedPreferences迁移数据到文件（一次性迁移）
  static Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('saved_tickets');
      if (jsonString != null) {
        // 检查文件是否已存在
        final file = await _getStorageFile();
        if (!await file.exists()) {
          // 文件不存在，迁移数据
          await file.writeAsString(jsonString);
          print('Migrated tickets from SharedPreferences to file');
        }
        // 迁移成功后，可以选择删除SharedPreferences中的数据
        // await prefs.remove('saved_tickets');
      }
    } catch (e) {
      print('Migration error: $e');
    }
  }

  /// 计算下一期期号
  /// 期号格式可能是：YYYYMMDD-NN 或纯数字
  static String? calculateNextIssue(String currentIssue, LotteryType type) {
    if (currentIssue.isEmpty) return null;

    // 尝试解析日期-序号格式 (如: 20251211-01)
    final dashIndex = currentIssue.indexOf('-');
    if (dashIndex > 0) {
      final datePart = currentIssue.substring(0, dashIndex);
      final seqPart = currentIssue.substring(dashIndex + 1);

      // 尝试解析日期部分 (YYYYMMDD)
      if (datePart.length == 8) {
        final year = int.tryParse(datePart.substring(0, 4));
        final month = int.tryParse(datePart.substring(4, 6));
        final day = int.tryParse(datePart.substring(6, 8));
        final seq = int.tryParse(seqPart);

        if (year != null && month != null && day != null && seq != null) {
          // 计算下一期日期
          // 双色球：周二、四、日开奖
          // 大乐透：周一、三、六开奖
          DateTime nextDate;
          if (type == LotteryType.SSQ) {
            // 双色球：找到下一个周二、四或日
            nextDate = DateTime(year, month, day);
            while (true) {
              nextDate = nextDate.add(const Duration(days: 1));
              final weekday = nextDate.weekday;
              if (weekday == 2 || weekday == 4 || weekday == 7) {
                // 周二(2)、周四(4)、周日(7)
                break;
              }
            }
          } else {
            // 大乐透：找到下一个周一、三或六
            nextDate = DateTime(year, month, day);
            while (true) {
              nextDate = nextDate.add(const Duration(days: 1));
              final weekday = nextDate.weekday;
              if (weekday == 1 || weekday == 3 || weekday == 6) {
                // 周一(1)、周三(3)、周六(6)
                break;
              }
            }
          }

          // 格式化下一期期号
          final nextYear = nextDate.year.toString();
          final nextMonth = nextDate.month.toString().padLeft(2, '0');
          final nextDay = nextDate.day.toString().padLeft(2, '0');
          final nextSeq = (seq + 1).toString().padLeft(2, '0');
          return '$nextYear$nextMonth$nextDay-$nextSeq';
        }
      }
    }

    // 尝试纯数字格式，简单递增
    final numValue = int.tryParse(currentIssue);
    if (numValue != null) {
      return (numValue + 1).toString();
    }

    // 如果无法解析，返回null
    return null;
  }

  /// 保存彩票号码
  static Future<bool> saveTicket(SavedTicket ticket) async {
    try {
      // 首次使用时尝试迁移数据
      await _migrateFromSharedPreferences();
      
      final tickets = await getAllTickets();
      tickets.add(ticket);
      final jsonList = tickets.map((t) => t.toJson()).toList();
      final file = await _getStorageFile();
      await file.writeAsString(jsonEncode(jsonList));
      return true;
    } catch (e) {
      print('Save ticket error: $e');
      return false;
    }
  }

  /// 获取所有保存的彩票
  static Future<List<SavedTicket>> getAllTickets() async {
    try {
      // 首次使用时尝试迁移数据
      await _migrateFromSharedPreferences();
      
      final file = await _getStorageFile();
      if (!await file.exists()) {
        return [];
      }
      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) return [];
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => SavedTicket.fromJson(json)).toList();
    } catch (e) {
      print('Get tickets error: $e');
      return [];
    }
  }

  /// 根据类型获取保存的彩票
  static Future<List<SavedTicket>> getTicketsByType(LotteryType type) async {
    final allTickets = await getAllTickets();
    return allTickets.where((t) => t.type == type).toList();
  }

  /// 删除彩票
  static Future<bool> deleteTicket(String id) async {
    try {
      // 首次使用时尝试迁移数据
      await _migrateFromSharedPreferences();
      
      final tickets = await getAllTickets();
      tickets.removeWhere((t) => t.id == id);
      final jsonList = tickets.map((t) => t.toJson()).toList();
      final file = await _getStorageFile();
      await file.writeAsString(jsonEncode(jsonList));
      return true;
    } catch (e) {
      print('Delete ticket error: $e');
      return false;
    }
  }

  /// 验证中奖（根据期号查找开奖结果）
  static Future<PrizeResult> checkPrizeByIssue(SavedTicket ticket) async {
    // 如果没有指定期号，返回未找到
    if (ticket.targetIssue == null || ticket.targetIssue!.isEmpty) {
      return PrizeResult(
        isWinner: false,
        prizeName: '未指定期号',
        frontMatch: 0,
        backMatch: 0,
        foundResult: false,
        issue: null,
      );
    }

    // 获取历史数据，尝试找到对应期号
    final historyCount = 500; // 获取足够多的历史数据
    final result = await LotteryService.fetchHistoryData(
      ticket.type,
      historyCount,
    );

    if (!result.success || result.historyData.isEmpty) {
      return PrizeResult(
        isWinner: false,
        prizeName: '无法获取开奖数据',
        frontMatch: 0,
        backMatch: 0,
        foundResult: false,
        issue: ticket.targetIssue,
      );
    }

    // 获取最新期号
    final latestIssue = result.latestResult?.issue;
    if (latestIssue != null) {
      // 比较期号：如果保存的期号大于最新期号，说明还未开奖
      if (_compareIssue(ticket.targetIssue!, latestIssue) > 0) {
        return PrizeResult(
          isWinner: false,
          prizeName: '未开奖',
          frontMatch: 0,
          backMatch: 0,
          foundResult: false,
          issue: ticket.targetIssue,
        );
      }
    }

    // 查找对应期号的开奖结果
    final winningResult = result.historyData.firstWhere(
      (r) => r.issue == ticket.targetIssue,
      orElse: () => result.historyData.first, // 如果找不到，使用第一个作为占位
    );

    // 检查是否真的找到了对应期号
    final foundExactMatch = winningResult.issue == ticket.targetIssue;

    if (!foundExactMatch) {
      return PrizeResult(
        isWinner: false,
        prizeName: '未找到期号 ${ticket.targetIssue} 的开奖结果',
        frontMatch: 0,
        backMatch: 0,
        foundResult: false,
        issue: ticket.targetIssue,
      );
    }

    // 找到了，进行验证
    return checkPrize(ticket, winningResult, ticket.targetIssue!);
  }

  /// 比较两个期号的大小
  /// 返回: >0 表示 issue1 > issue2, <0 表示 issue1 < issue2, 0 表示相等
  static int _compareIssue(String issue1, String issue2) {
    // 尝试解析日期-序号格式 (如: 20251211-01)
    final dashIndex1 = issue1.indexOf('-');
    final dashIndex2 = issue2.indexOf('-');

    if (dashIndex1 > 0 && dashIndex2 > 0) {
      final datePart1 = issue1.substring(0, dashIndex1);
      final seqPart1 = issue1.substring(dashIndex1 + 1);
      final datePart2 = issue2.substring(0, dashIndex2);
      final seqPart2 = issue2.substring(dashIndex2 + 1);

      // 先比较日期部分
      final dateCompare = datePart1.compareTo(datePart2);
      if (dateCompare != 0) {
        return dateCompare;
      }

      // 日期相同，比较序号
      final seq1 = int.tryParse(seqPart1) ?? 0;
      final seq2 = int.tryParse(seqPart2) ?? 0;
      return seq1.compareTo(seq2);
    }

    // 尝试纯数字格式
    final num1 = int.tryParse(issue1);
    final num2 = int.tryParse(issue2);
    if (num1 != null && num2 != null) {
      return num1.compareTo(num2);
    }

    // 无法解析，使用字符串比较
    return issue1.compareTo(issue2);
  }

  /// 验证中奖
  static PrizeResult checkPrize(
    SavedTicket ticket,
    LotteryResult winningResult,
    String issue,
  ) {
    // 通过前区数量判断类型：双色球6个，大乐透5个
    final resultType = winningResult.front.length == 6
        ? LotteryType.SSQ
        : LotteryType.DLT;

    if (ticket.type != resultType) {
      // 类型不匹配，无法验证
      return PrizeResult(
        isWinner: false,
        prizeName: '类型不匹配',
        frontMatch: 0,
        backMatch: 0,
        foundResult: true,
        issue: issue,
      );
    }

    // 计算匹配数量
    final frontMatch = ticket.frontNumbers
        .where((n) => winningResult.front.contains(n))
        .length;
    final backMatch = ticket.backNumbers
        .where((n) => winningResult.back.contains(n))
        .length;

    PrizeResult prizeResult;
    if (ticket.type == LotteryType.SSQ) {
      prizeResult = _checkSSQPrize(frontMatch, backMatch);
    } else {
      prizeResult = _checkDLTPrize(frontMatch, backMatch);
    }

    // 设置期号
    return PrizeResult(
      isWinner: prizeResult.isWinner,
      prizeLevel: prizeResult.prizeLevel,
      prizeName: prizeResult.prizeName,
      frontMatch: prizeResult.frontMatch,
      backMatch: prizeResult.backMatch,
      foundResult: true,
      issue: issue,
    );
  }

  /// 验证双色球中奖
  static PrizeResult _checkSSQPrize(int frontMatch, int backMatch) {
    // 双色球规则：
    // 一等奖：6红+1蓝
    // 二等奖：6红
    // 三等奖：5红+1蓝
    // 四等奖：5红 或 4红+1蓝
    // 五等奖：4红 或 3红+1蓝
    // 六等奖：2红+1蓝 或 1红+1蓝 或 0红+1蓝 或 1蓝

    if (frontMatch == 6 && backMatch == 1) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 1,
        prizeName: '一等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if (frontMatch == 6 && backMatch == 0) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 2,
        prizeName: '二等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if (frontMatch == 5 && backMatch == 1) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 3,
        prizeName: '三等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if ((frontMatch == 5 && backMatch == 0) ||
        (frontMatch == 4 && backMatch == 1)) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 4,
        prizeName: '四等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if ((frontMatch == 4 && backMatch == 0) ||
        (frontMatch == 3 && backMatch == 1)) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 5,
        prizeName: '五等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if (backMatch == 1 ||
        (frontMatch == 2 && backMatch == 1) ||
        (frontMatch == 1 && backMatch == 1) ||
        (frontMatch == 0 && backMatch == 1)) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 6,
        prizeName: '六等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else {
      return PrizeResult(
        isWinner: false,
        prizeName: '未中奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    }
  }

  /// 验证大乐透中奖
  static PrizeResult _checkDLTPrize(int frontMatch, int backMatch) {
    // 大乐透规则：
    // 一等奖：5前+2后
    // 二等奖：5前+1后
    // 三等奖：5前
    // 四等奖：4前+2后
    // 五等奖：4前+1后
    // 六等奖：3前+2后
    // 七等奖：4前
    // 八等奖：3前+1后 或 2前+2后
    // 九等奖：3前 或 1前+2后 或 2前+1后 或 0前+2后

    if (frontMatch == 5 && backMatch == 2) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 1,
        prizeName: '一等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if (frontMatch == 5 && backMatch == 1) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 2,
        prizeName: '二等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if (frontMatch == 5 && backMatch == 0) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 3,
        prizeName: '三等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if (frontMatch == 4 && backMatch == 2) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 4,
        prizeName: '四等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if (frontMatch == 4 && backMatch == 1) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 5,
        prizeName: '五等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if (frontMatch == 3 && backMatch == 2) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 6,
        prizeName: '六等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if (frontMatch == 4 && backMatch == 0) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 7,
        prizeName: '七等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if ((frontMatch == 3 && backMatch == 1) ||
        (frontMatch == 2 && backMatch == 2)) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 8,
        prizeName: '八等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else if ((frontMatch == 3 && backMatch == 0) ||
        (frontMatch == 1 && backMatch == 2) ||
        (frontMatch == 2 && backMatch == 1) ||
        (frontMatch == 0 && backMatch == 2)) {
      return PrizeResult(
        isWinner: true,
        prizeLevel: 9,
        prizeName: '九等奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    } else {
      return PrizeResult(
        isWinner: false,
        prizeName: '未中奖',
        frontMatch: frontMatch,
        backMatch: backMatch,
      );
    }
  }
}
