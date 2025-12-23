import 'package:flutter/material.dart';
import 'lottery_service.dart';

// ==================== Common Widgets ====================

/// 构建号码球组件（公共函数）
/// [n] 号码
/// [color] 球的颜色
/// [size] 球的尺寸，如果为null则使用Expanded自适应
/// [margin] 外边距
Widget buildNumberChip(int n, Color color, {double? size, EdgeInsets? margin}) {
  // 计算球形渐变的颜色
  final highlightColor = Color.lerp(color, Colors.white, 0.6)!;
  final baseColor = color;
  final shadowColor = Color.lerp(color, Colors.black, 0.4)!;

  // 根据颜色确定文字颜色（黄色球用深色文字）
  final textColor = color == Colors.yellow ? Colors.black87 : Colors.white;

  // 构建装饰
  final decoration = BoxDecoration(
    shape: BoxShape.circle,
    // 主体渐变 - 模拟球形光影
    gradient: RadialGradient(
      center: const Alignment(-0.3, -0.4),
      radius: 0.9,
      colors: [highlightColor, baseColor, shadowColor],
      stops: const [0.0, 0.5, 1.0],
    ),
    // 外阴影 - 增加立体感
    boxShadow: [
      BoxShadow(
        color: shadowColor.withOpacity(0.5),
        blurRadius: 4,
        offset: const Offset(2, 3),
      ),
      // 内部光泽反射
      BoxShadow(
        color: Colors.white.withOpacity(0.2),
        blurRadius: 1,
        offset: const Offset(-1, -1),
      ),
    ],
  );

  // 构建内容
  Widget content = Container(
    decoration: decoration,
    child: Stack(
      children: [
        // 高光点 - 模拟光源反射（仅在较大尺寸时显示）
        if (size == null || size >= 32)
          Positioned(
            left: size != null ? size * 0.2 : 6,
            top: size != null ? size * 0.15 : 4,
            child: Container(
              width: size != null ? size * 0.25 : 8,
              height: size != null ? size * 0.2 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        // 数字文字
        Center(
          child: Text(
            n.toString().padLeft(2, '0'),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: size != null ? (size * 0.4).clamp(10.0, 14.0) : 14,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // 如果指定了大小，使用固定尺寸
  if (size != null) {
    return Container(
      width: size,
      height: size,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 2),
      child: content,
    );
  }

  // 否则使用Expanded自适应
  return Expanded(
    child: Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 4),
      child: AspectRatio(aspectRatio: 1.0, child: content),
    ),
  );
}

class LotteryScreen extends StatefulWidget {
  const LotteryScreen({super.key});

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends State<LotteryScreen> {
  final GlobalKey<_SavedTicketsViewState> _savedTicketsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('彩票'),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.onPrimary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 16),
            tabs: const [
              Tab(text: '双色球'),
              Tab(text: '大乐透'),
              Tab(text: '我的号码'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 双色球
            LatestDrawView(
              result: LotteryResult(
                issue: '20251211-01',
                date: DateTime.now(),
                front: [3, 9, 12, 18, 25, 31],
                back: [6],
              ),
              type: LotteryType.SSQ,
              onTicketSaved: () {
                _savedTicketsKey.currentState?.refreshTickets();
              },
            ),

            // 大乐透
            LatestDrawView(
              result: LotteryResult(
                issue: '20251210-02',
                date: DateTime.now().subtract(const Duration(days: 1)),
                front: [2, 11, 17, 21, 30],
                back: [4, 9],
              ),
              type: LotteryType.DLT,
              onTicketSaved: () {
                _savedTicketsKey.currentState?.refreshTickets();
              },
            ),

            // 我的号码
            SavedTicketsView(key: _savedTicketsKey),
          ],
        ),
      ),
    );
  }
}

class LatestDrawView extends StatefulWidget {
  final LotteryResult result;
  final LotteryType type;
  final VoidCallback? onTicketSaved;

  const LatestDrawView({
    super.key,
    required this.result,
    required this.type,
    this.onTicketSaved,
  });

  @override
  State<LatestDrawView> createState() => _LatestDrawViewState();
}

class _LatestDrawViewState extends State<LatestDrawView> {
  int _historyCount = 10;
  int _currentPage = 1;
  int _pageSize = 5;

  static const List<int> _pageSizeOptions = [5, 10, 20, 50];

  List<LotteryResult> _historyData = [];
  LotteryResult? _latestResult; // Store the latest draw data
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await LotteryService.fetchHistoryData(
      widget.type,
      _historyCount,
    );

    setState(() {
      _isLoading = false;
      if (result.success) {
        _historyData = result.historyData;
        _latestResult = result.latestResult;
        _currentPage = 1;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _saveRecommendation(
    LotteryRecommendation recommendation,
    LotteryType type,
  ) async {
    // 获取最新期号并计算下一期
    final latestResult = _latestResult ?? widget.result;
    final currentIssue = latestResult.issue;
    final targetIssue =
        SavedTicketService.calculateNextIssue(currentIssue, type) ??
        currentIssue; // 如果无法计算下一期，使用当前期号

    final ticket = SavedTicket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      frontNumbers: List.from(recommendation.frontNumbers)..sort(),
      backNumbers: List.from(recommendation.backNumbers)..sort(),
      savedAt: DateTime.now(),
      note: recommendation.algorithmName,
      targetIssue: targetIssue,
    );

    final success = await SavedTicketService.saveTicket(ticket);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存成功（期号：$targetIssue）')));
        // 通知刷新"我的号码"列表
        widget.onTicketSaved?.call();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败')));
      }
    }
  }

  Future<void> _saveAllRecommendations() async {
    if (_historyData.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂无推荐号码')));
      }
      return;
    }

    // 获取推荐号码
    final recommendations = LotteryRecommendationEngine.generateRecommendations(
      _historyData,
      widget.type,
    );

    if (recommendations.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂无推荐号码')));
      }
      return;
    }

    // 获取最新期号并计算下一期
    final latestResult = _latestResult ?? widget.result;
    final currentIssue = latestResult.issue;
    final targetIssue =
        SavedTicketService.calculateNextIssue(currentIssue, widget.type) ??
        currentIssue;

    // 保存所有推荐号码
    int successCount = 0;
    for (final rec in recommendations) {
      final ticket = SavedTicket(
        id: '${DateTime.now().millisecondsSinceEpoch}_${rec.algorithmName}_${successCount}',
        type: widget.type,
        frontNumbers: List.from(rec.frontNumbers)..sort(),
        backNumbers: List.from(rec.backNumbers)..sort(),
        savedAt: DateTime.now(),
        note: rec.algorithmName,
        targetIssue: targetIssue,
      );

      final success = await SavedTicketService.saveTicket(ticket);
      if (success) {
        successCount++;
      }
    }

    if (mounted) {
      if (successCount == recommendations.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功保存 ${successCount} 组推荐号码（期号：$targetIssue）'),
          ),
        );
        // 通知刷新"我的号码"列表
        widget.onTicketSaved?.call();
      } else if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('部分保存成功：${successCount}/${recommendations.length}'),
          ),
        );
        // 通知刷新"我的号码"列表
        widget.onTicketSaved?.call();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败')));
      }
    }
  }

  Color _getFrontColor(int index) {
    // Front colors: SSQ is red, DLT is blue
    if (widget.type == LotteryType.DLT) {
      return Colors.blue;
    }
    return Colors.red; // SSQ red balls
  }

  Color _getBackColor(int index) {
    // Back colors: SSQ is blue, DLT is yellow
    if (widget.type == LotteryType.DLT) {
      return Colors.yellow;
    }
    return Colors.lightBlue; // SSQ blue ball
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate pagination values
    final total = _historyData.length;
    final totalPages = (total / _pageSize).ceil().clamp(1, 1000);
    final start = (_currentPage - 1) * _pageSize;
    final pageItems = _historyData.skip(start).take(_pageSize).toList();

    // Use the latest result from API or fallback to widget.result
    final latestResult = _latestResult ?? widget.result;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Latest draw card
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '期号: ${latestResult.issue}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${latestResult.date.year}-${latestResult.date.month.toString().padLeft(2, '0')}-${latestResult.date.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '开奖号码',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // front balls
                          ...latestResult.front.asMap().entries.map(
                            (e) =>
                                buildNumberChip(e.value, _getFrontColor(e.key)),
                          ),
                          // spacing between front and back
                          if (latestResult.back.isNotEmpty)
                            const SizedBox(width: 12),
                          ...latestResult.back.asMap().entries.map(
                            (e) =>
                                buildNumberChip(e.value, _getBackColor(e.key)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.type == LotteryType.SSQ
                            ? '说明：双色球（6 红 + 1 蓝）'
                            : '说明：大乐透（前区5球 + 后区2球）',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          // History section header with dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '历史开奖',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                DropdownButton<int>(
                  value: _historyCount,
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('最近 5 期')),
                    DropdownMenuItem(value: 10, child: Text('最近 10 期')),
                    DropdownMenuItem(value: 100, child: Text('最近 100 期')),
                    DropdownMenuItem(value: 500, child: Text('最近 500 期')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _historyCount = value;
                        _currentPage = 1; // Reset to first page
                      });
                      _fetchHistoryData(); // Reload data with new count
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          // Loading/Error/History list
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _fetchHistoryData,
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          else if (_historyData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('暂无历史开奖数据'),
            )
          else
            ...pageItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '期号: ${item.issue}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...item.front.asMap().entries.map(
                            (e) =>
                                buildNumberChip(e.value, _getFrontColor(e.key)),
                          ),
                          if (item.back.isNotEmpty) SizedBox(width: 12),
                          ...item.back.asMap().entries.map(
                            (e) =>
                                buildNumberChip(e.value, _getBackColor(e.key)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),

          // Pagination controls
          if (total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Page size selector and page info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '第 $_currentPage / $totalPages 页',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Row(
                        children: [
                          const Text(
                            '每页 ',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          DropdownButton<int>(
                            value: _pageSize,
                            isDense: true,
                            underline: Container(
                              height: 1,
                              color: Colors.grey[400],
                            ),
                            items: _pageSizeOptions.map((size) {
                              return DropdownMenuItem<int>(
                                value: size,
                                child: Text(
                                  '$size 条',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null && value != _pageSize) {
                                setState(() {
                                  _pageSize = value;
                                  // 重新计算当前页，确保不超出范围
                                  final newTotalPages = (total / value)
                                      .ceil()
                                      .clamp(1, 1000);
                                  _currentPage = _currentPage.clamp(
                                    1,
                                    newTotalPages,
                                  );
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _currentPage > 1
                            ? () {
                                setState(() {
                                  _currentPage = (_currentPage - 1).clamp(
                                    1,
                                    totalPages,
                                  );
                                });
                              }
                            : null,
                        child: const Text('上一页'),
                      ),
                      TextButton(
                        onPressed: _currentPage < totalPages
                            ? () {
                                setState(() {
                                  _currentPage = (_currentPage + 1).clamp(
                                    1,
                                    totalPages,
                                  );
                                });
                              }
                            : null,
                        child: const Text('下一页'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Frequency Statistics section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: const Text(
              '号码频次统计',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          if (_historyData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Builder(
                builder: (context) {
                  // Calculate frequency for all numbers
                  final frontMax = widget.type == LotteryType.SSQ ? 33 : 35;
                  final backMax = widget.type == LotteryType.SSQ ? 16 : 12;

                  // Use service methods to calculate frequency
                  final frontFreq =
                      LotteryRecommendationEngine.calculateFrequency(
                        _historyData,
                        true,
                        frontMax,
                      );
                  final backFreq =
                      LotteryRecommendationEngine.calculateFrequency(
                        _historyData,
                        false,
                        backMax,
                      );

                  // Categorize numbers into hot, warm, cold
                  final frontCategory =
                      LotteryRecommendationEngine.categorizeNumbers(
                        Map.from(frontFreq),
                        frontMax,
                      );
                  final backCategory =
                      LotteryRecommendationEngine.categorizeNumbers(
                        Map.from(backFreq),
                        backMax,
                      );

                  // Helper to get color based on category
                  Color getCategoryColor(int num, NumberCategory category) {
                    if (category.hot.contains(num)) {
                      return Colors.red; // 热号：红色
                    } else if (category.warm.contains(num)) {
                      return Colors.orange; // 温号：橙黄色
                    } else {
                      return Colors.grey; // 冷号：灰色
                    }
                  }

                  // Sort by number value (ascending)
                  final sortedFront = frontFreq.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));
                  final sortedBack = backFreq.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding = (constraints.maxWidth * 0.03)
                          .clamp(8.0, 24.0);

                      // compute adaptive item width based on available space
                      final spacing = 8.0;
                      final minItemWidth = 64.0;

                      final columns =
                          (constraints.maxWidth / (minItemWidth + spacing))
                              .floor();

                      final itemWidth0 = constraints.maxWidth / columns;
                      final itemWidth = itemWidth0 - 12;
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 12.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Legend for colors
                            Row(
                              children: [
                                _buildLegendItem('热号', Colors.red),
                                const SizedBox(width: 16),
                                _buildLegendItem('温号', Colors.orange),
                                const SizedBox(width: 16),
                                _buildLegendItem('冷号', Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Front numbers frequency
                            const Text(
                              '前区号码频次:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sortedFront.map((entry) {
                                final color = getCategoryColor(
                                  entry.key,
                                  frontCategory,
                                );
                                return SizedBox(
                                  width: itemWidth,
                                  height: 36,
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: color,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${entry.key.toString().padLeft(2, '0')} (${entry.value})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            // Back numbers frequency
                            Text(
                              widget.type == LotteryType.SSQ
                                  ? '蓝球号码频次:'
                                  : '后区号码频次:',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sortedBack.map((entry) {
                                final color = getCategoryColor(
                                  entry.key,
                                  backCategory,
                                );
                                return SizedBox(
                                  width: itemWidth,
                                  height: 36,
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: color,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${entry.key.toString().padLeft(2, '0')} (${entry.value})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          // Recommendations section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '推荐号码',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _saveAllRecommendations(),
                      child: const Text('保存', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() {}), // Refresh recommendations
                      child: const Text('刷新', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_historyData.isNotEmpty)
            Builder(
              builder: (context) {
                final recommendations =
                    LotteryRecommendationEngine.generateRecommendations(
                      _historyData,
                      widget.type,
                    );

                return Column(
                  children: recommendations.map((rec) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 6.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey[50],
                        ),
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  rec.algorithmName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _saveRecommendation(rec, widget.type),
                                  icon: const Icon(
                                    Icons.bookmark_add,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    '保存',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ...rec.frontNumbers.asMap().entries.map(
                                  (e) => buildNumberChip(
                                    e.value,
                                    _getFrontColor(e.key),
                                  ),
                                ),
                                if (rec.backNumbers.isNotEmpty)
                                  SizedBox(width: 12),
                                ...rec.backNumbers.asMap().entries.map(
                                  (e) => buildNumberChip(
                                    e.value,
                                    _getBackColor(e.key),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('加载推荐中...', style: TextStyle(color: Colors.grey)),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ==================== Saved Tickets View ====================

class SavedTicketsView extends StatefulWidget {
  const SavedTicketsView({super.key});

  @override
  State<SavedTicketsView> createState() => _SavedTicketsViewState();
}

enum TicketFilter {
  all, // 全部
  winner, // 中奖
  notWinner, // 未中奖
  notDrawn, // 未开奖
}

class _SavedTicketsViewState extends State<SavedTicketsView> {
  List<SavedTicket> _savedTickets = [];
  bool _isLoading = false;
  Map<String, PrizeResult> _prizeResults = {}; // 存储每个ticket的验证结果（缓存）
  TicketFilter _currentFilter = TicketFilter.all;
  LotteryType _selectedType = LotteryType.SSQ; // 当前选择的类型
  int _currentPage = 1;
  int _pageSize = 5;

  static const List<int> _pageSizeOptions = [5, 10, 20, 50];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });
    final tickets = await SavedTicketService.getAllTickets();
    // 按期号从大到小排序（期号为空或null的排在最后）
    tickets.sort((a, b) {
      final issueA = a.targetIssue ?? '';
      final issueB = b.targetIssue ?? '';
      if (issueA.isEmpty && issueB.isEmpty) {
        return b.savedAt.compareTo(a.savedAt); // 都为空时按保存时间倒序
      }
      if (issueA.isEmpty) return 1; // 空期号排在后面
      if (issueB.isEmpty) return -1; // 空期号排在后面
      return issueB.compareTo(issueA); // 期号从大到小排序
    });
    setState(() {
      _savedTickets = tickets;
      _isLoading = false;
      _currentPage = 1; // 重置到第一页
    });
    // 加载完成后验证所有tickets
    _verifyAllTickets();
  }

  /// 公开的刷新方法，供外部调用
  void refreshTickets() {
    _loadTickets();
  }

  List<SavedTicket> _getTicketsByType(LotteryType type) {
    var tickets = _savedTickets.where((t) => t.type == type).toList();

    // 应用过滤
    if (_currentFilter != TicketFilter.all && tickets.isNotEmpty) {
      tickets = tickets.where((ticket) {
        final result = _prizeResults[ticket.id];
        if (result == null) return false;

        switch (_currentFilter) {
          case TicketFilter.winner:
            return result.foundResult && result.isWinner;
          case TicketFilter.notWinner:
            return result.foundResult && !result.isWinner;
          case TicketFilter.notDrawn:
            return !result.foundResult && result.prizeName == '未开奖';
          case TicketFilter.all:
            return true;
        }
      }).toList();
    }

    return tickets;
  }

  Future<void> _verifyAllTickets() async {
    final results = <String, PrizeResult>{};
    for (final ticket in _savedTickets) {
      final result = await SavedTicketService.checkPrizeByIssue(ticket);
      results[ticket.id] = result;
    }
    if (mounted) {
      setState(() {
        _prizeResults = results;
      });
    }
  }

  Color _getFrontColor(LotteryType type) {
    return type == LotteryType.DLT ? Colors.blue : Colors.red;
  }

  Color _getBackColor(LotteryType type) {
    return type == LotteryType.DLT ? Colors.yellow : Colors.lightBlue;
  }

  Future<void> _saveRecommendation(
    LotteryRecommendation recommendation,
    LotteryType type,
  ) async {
    // 获取最新期号并计算下一期
    final result = await LotteryService.fetchHistoryData(type, 1);
    final currentIssue = result.success && result.latestResult != null
        ? result.latestResult!.issue
        : null;
    final targetIssue = currentIssue != null
        ? SavedTicketService.calculateNextIssue(currentIssue, type) ??
              currentIssue
        : null;

    final ticket = SavedTicket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      frontNumbers: List.from(recommendation.frontNumbers)..sort(),
      backNumbers: List.from(recommendation.backNumbers)..sort(),
      savedAt: DateTime.now(),
      note: recommendation.algorithmName,
      targetIssue: targetIssue,
    );

    final success = await SavedTicketService.saveTicket(ticket);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '保存成功${targetIssue != null ? '（期号：$targetIssue）' : ''}',
            ),
          ),
        );
        _loadTickets();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败')));
      }
    }
  }

  Future<void> _deleteTicket(String id) async {
    final success = await SavedTicketService.deleteTicket(id);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除成功')));
        _loadTickets();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除失败')));
      }
    }
  }

  PrizeResult? _getPrizeResult(SavedTicket ticket) {
    return _prizeResults[ticket.id];
  }

  Color _getPrizeColor(PrizeResult? result) {
    if (result == null) {
      return Colors.grey;
    }
    // 如果未开奖，显示蓝色
    if (!result.foundResult && result.prizeName == '未开奖') {
      return Colors.blue;
    }
    // 如果未找到开奖结果，显示橙色警告
    if (!result.foundResult) {
      return Colors.orange;
    }
    if (!result.isWinner) {
      return Colors.grey;
    }
    if (result.prizeLevel == 1) {
      return Colors.red;
    } else if (result.prizeLevel == 2) {
      return Colors.orange;
    } else if (result.prizeLevel == 3) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  Future<void> _showInputDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _InputTicketDialog(
        onSave: (ticket) async {
          final success = await SavedTicketService.saveTicket(ticket);
          if (success) {
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('保存成功')));
              _loadTickets();
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('保存失败')));
            }
          }
        },
      ),
    );
  }

  Widget _buildTicketList(List<SavedTicket> tickets) {
    // 计算分页
    final total = tickets.length;
    final totalPages = (total / _pageSize).ceil().clamp(1, 1000);
    final start = (_currentPage - 1) * _pageSize;
    final pageItems = tickets.skip(start).take(_pageSize).toList();

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '还没有保存的号码',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击右下角按钮可以手动输入号码',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pageItems.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final prizeResult = _getPrizeResult(ticket);
              final prizeColor = _getPrizeColor(prizeResult);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // 期号显示（第二位）
                              if (ticket.targetIssue != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '期号: ${ticket.targetIssue}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                              if (ticket.note != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  ticket.note!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _deleteTicket(ticket.id),
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...ticket.frontNumbers.map(
                            (n) =>
                                buildNumberChip(n, _getFrontColor(ticket.type)),
                          ),
                          const SizedBox(width: 12),
                          ...ticket.backNumbers.map(
                            (n) =>
                                buildNumberChip(n, _getBackColor(ticket.type)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '保存时间: ${ticket.savedAt.year}-${ticket.savedAt.month.toString().padLeft(2, '0')}-${ticket.savedAt.day.toString().padLeft(2, '0')} ${ticket.savedAt.hour.toString().padLeft(2, '0')}:${ticket.savedAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          if (prizeResult != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: prizeColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: prizeColor, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    prizeResult.foundResult
                                        ? (prizeResult.isWinner
                                              ? Icons.emoji_events
                                              : Icons.close)
                                        : (prizeResult.prizeName == '未开奖'
                                              ? Icons.schedule
                                              : Icons.warning_amber_rounded),
                                    size: 14,
                                    color: prizeColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    prizeResult.foundResult
                                        ? (prizeResult.isWinner
                                              ? prizeResult.prizeName
                                              : '未中奖')
                                        : prizeResult.prizeName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: prizeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (prizeResult != null && prizeResult.foundResult)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '匹配: 前区${prizeResult.frontMatch}个, 后区${prizeResult.backMatch}个',
                            style: TextStyle(fontSize: 11, color: prizeColor),
                          ),
                        ),
                      if (prizeResult != null && !prizeResult.foundResult)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            prizeResult.prizeName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // 分页控件
        if (total > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // 每页条数选择和页码信息
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '第 $_currentPage / $totalPages 页',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Row(
                      children: [
                        const Text(
                          '每页 ',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        DropdownButton<int>(
                          value: _pageSize,
                          isDense: true,
                          underline: Container(
                            height: 1,
                            color: Colors.grey[400],
                          ),
                          items: _pageSizeOptions.map((size) {
                            return DropdownMenuItem<int>(
                              value: size,
                              child: Text(
                                '$size 条',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value != _pageSize) {
                              setState(() {
                                _pageSize = value;
                                // 重新计算当前页，确保不超出范围
                                final newTotalPages = (total / value)
                                    .ceil()
                                    .clamp(1, 1000);
                                _currentPage = _currentPage.clamp(
                                  1,
                                  newTotalPages,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 导航按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() {
                                _currentPage = (_currentPage - 1).clamp(
                                  1,
                                  totalPages,
                                );
                              });
                            }
                          : null,
                      child: const Text('上一页'),
                    ),
                    TextButton(
                      onPressed: _currentPage < totalPages
                          ? () {
                              setState(() {
                                _currentPage = (_currentPage + 1).clamp(
                                  1,
                                  totalPages,
                                );
                              });
                            }
                          : null,
                      child: const Text('下一页'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ssqTickets = _getTicketsByType(LotteryType.SSQ);
    final dltTickets = _getTicketsByType(LotteryType.DLT);
    final currentTickets = _selectedType == LotteryType.SSQ
        ? ssqTickets
        : dltTickets;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 类型选择、过滤选项和手动输入按钮
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '类型:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<LotteryType>(
                        value: _selectedType,
                        items: [
                          DropdownMenuItem(
                            value: LotteryType.SSQ,
                            child: Text('双色球'),
                          ),
                          DropdownMenuItem(
                            value: LotteryType.DLT,
                            child: Text('大乐透'),
                          ),
                        ],
                        onChanged: (LotteryType? value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                              _currentPage = 1; // 切换类型时重置到第一页
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '过滤:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<TicketFilter>(
                          value: _currentFilter,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: TicketFilter.all,
                              child: Text('全部'),
                            ),
                            DropdownMenuItem(
                              value: TicketFilter.winner,
                              child: Text('中奖'),
                            ),
                            DropdownMenuItem(
                              value: TicketFilter.notWinner,
                              child: Text('未中奖'),
                            ),
                            DropdownMenuItem(
                              value: TicketFilter.notDrawn,
                              child: Text('未开奖'),
                            ),
                          ],
                          onChanged: (TicketFilter? value) {
                            if (value != null) {
                              setState(() {
                                _currentFilter = value;
                                _currentPage = 1; // 切换过滤时重置到第一页
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showInputDialog,
                        icon: const Icon(Icons.add),
                        tooltip: '手动输入号码',
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadTickets();
                    },
                    child: _buildTicketList(currentTickets),
                  ),
                ),
              ],
            ),
    );
  }
}

// ==================== Input Ticket Dialog ====================

class _InputTicketDialog extends StatefulWidget {
  final Function(SavedTicket) onSave;

  const _InputTicketDialog({required this.onSave});

  @override
  State<_InputTicketDialog> createState() => _InputTicketDialogState();
}

class _InputTicketDialogState extends State<_InputTicketDialog> {
  LotteryType _selectedType = LotteryType.SSQ;
  final TextEditingController _issueController = TextEditingController();
  final List<TextEditingController> _frontControllers = [];
  final List<TextEditingController> _backControllers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // 根据类型初始化控制器
    final frontCount = _selectedType == LotteryType.SSQ ? 6 : 5;
    final backCount = _selectedType == LotteryType.SSQ ? 1 : 2;

    _frontControllers.clear();
    _backControllers.clear();

    for (int i = 0; i < frontCount; i++) {
      _frontControllers.add(TextEditingController());
    }
    for (int i = 0; i < backCount; i++) {
      _backControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _issueController.dispose();
    for (var controller in _frontControllers) {
      controller.dispose();
    }
    for (var controller in _backControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTypeChanged(LotteryType? type) {
    if (type != null) {
      setState(() {
        _selectedType = type;
        _initializeControllers();
        _errorMessage = null;
      });
    }
  }

  bool _validateInput() {
    // 验证期号
    if (_issueController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '请输入期号';
      });
      return false;
    }

    // 验证前区号码
    final frontNumbers = <int>[];
    final frontMax = _selectedType == LotteryType.SSQ ? 33 : 35;
    for (var controller in _frontControllers) {
      final text = controller.text.trim();
      if (text.isEmpty) {
        setState(() {
          _errorMessage = '请完整输入前区号码';
        });
        return false;
      }
      final num = int.tryParse(text);
      if (num == null || num < 1 || num > frontMax) {
        setState(() {
          _errorMessage = '前区号码必须在1-$frontMax之间';
        });
        return false;
      }
      if (frontNumbers.contains(num)) {
        setState(() {
          _errorMessage = '前区号码不能重复';
        });
        return false;
      }
      frontNumbers.add(num);
    }

    // 验证后区号码
    final backNumbers = <int>[];
    final backMax = _selectedType == LotteryType.SSQ ? 16 : 12;
    for (var controller in _backControllers) {
      final text = controller.text.trim();
      if (text.isEmpty) {
        setState(() {
          _errorMessage = '请完整输入后区号码';
        });
        return false;
      }
      final num = int.tryParse(text);
      if (num == null || num < 1 || num > backMax) {
        setState(() {
          _errorMessage = '后区号码必须在1-$backMax之间';
        });
        return false;
      }
      if (backNumbers.contains(num)) {
        setState(() {
          _errorMessage = '后区号码不能重复';
        });
        return false;
      }
      backNumbers.add(num);
    }

    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  void _saveTicket() {
    if (!_validateInput()) {
      return;
    }

    final frontNumbers =
        _frontControllers.map((c) => int.parse(c.text.trim())).toList()..sort();
    final backNumbers =
        _backControllers.map((c) => int.parse(c.text.trim())).toList()..sort();

    final ticket = SavedTicket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      frontNumbers: frontNumbers,
      backNumbers: backNumbers,
      savedAt: DateTime.now(),
      note: '手动输入',
      targetIssue: _issueController.text.trim(),
    );

    widget.onSave(ticket);
  }

  @override
  Widget build(BuildContext context) {
    final frontMax = _selectedType == LotteryType.SSQ ? 33 : 35;
    final backMax = _selectedType == LotteryType.SSQ ? 16 : 12;
    final frontLabel = _selectedType == LotteryType.SSQ ? '红球' : '前区';
    final backLabel = _selectedType == LotteryType.SSQ ? '蓝球' : '后区';

    return AlertDialog(
      title: const Text('手动输入号码'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类型选择
            const Text('彩票类型:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<LotteryType>(
              segments: const [
                ButtonSegment(value: LotteryType.SSQ, label: Text('双色球')),
                ButtonSegment(value: LotteryType.DLT, label: Text('大乐透')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<LotteryType> selection) {
                _onTypeChanged(selection.first);
              },
            ),
            const SizedBox(height: 16),
            // 期号输入
            const Text('期号:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _issueController,
              decoration: const InputDecoration(
                hintText: '请输入期号',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 前区号码输入
            Text(
              '$frontLabel号码 (${_frontControllers.length}个, 范围: 1-$frontMax):',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _frontControllers.asMap().entries.map((entry) {
                return SizedBox(
                  width: 60,
                  child: TextField(
                    controller: entry.value,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '${entry.key + 1}',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 后区号码输入
            Text(
              '$backLabel号码 (${_backControllers.length}个, 范围: 1-$backMax):',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _backControllers.asMap().entries.map((entry) {
                return SizedBox(
                  width: 60,
                  child: TextField(
                    controller: entry.value,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '${entry.key + 1}',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(onPressed: _saveTicket, child: const Text('保存')),
      ],
    );
  }
}
