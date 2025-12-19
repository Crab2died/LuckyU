import 'package:flutter/material.dart';
import 'lottery_service.dart';

class LotteryScreen extends StatefulWidget {
  const LotteryScreen({super.key});

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends State<LotteryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
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
            ),
          ],
        ),
      ),
    );
  }
}

class LatestDrawView extends StatefulWidget {
  final LotteryResult result;
  final LotteryType type;

  const LatestDrawView({super.key, required this.result, required this.type});

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

  Widget _buildNumberChip(int n, Color color) {
    // 计算球形渐变的颜色
    final highlightColor = Color.lerp(color, Colors.white, 0.6)!;
    final baseColor = color;
    final shadowColor = Color.lerp(color, Colors.black, 0.4)!;

    // 根据颜色确定文字颜色（黄色球用深色文字）
    final textColor = color == Colors.yellow ? Colors.black87 : Colors.white;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
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
            ),
            child: Stack(
              children: [
                // 高光点 - 模拟光源反射
                Positioned(
                  left: 6,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 6,
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
                      fontSize: 14,
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
          ),
        ),
      ),
    );
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
                            (e) => _buildNumberChip(
                              e.value,
                              _getFrontColor(e.key),
                            ),
                          ),
                          // spacing between front and back
                          if (latestResult.back.isNotEmpty)
                            const SizedBox(width: 12),
                          ...latestResult.back.asMap().entries.map(
                            (e) =>
                                _buildNumberChip(e.value, _getBackColor(e.key)),
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
                            (e) => _buildNumberChip(
                              e.value,
                              _getFrontColor(e.key),
                            ),
                          ),
                          if (item.back.isNotEmpty) SizedBox(width: 12),
                          ...item.back.asMap().entries.map(
                            (e) =>
                                _buildNumberChip(e.value, _getBackColor(e.key)),
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
                TextButton(
                  onPressed: () => setState(() {}), // Refresh recommendations
                  child: const Text('刷新', style: TextStyle(fontSize: 12)),
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
                            Text(
                              rec.algorithmName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ...rec.frontNumbers.asMap().entries.map(
                                  (e) => _buildNumberChip(
                                    e.value,
                                    _getFrontColor(e.key),
                                  ),
                                ),
                                if (rec.backNumbers.isNotEmpty)
                                  SizedBox(width: 12),
                                ...rec.backNumbers.asMap().entries.map(
                                  (e) => _buildNumberChip(
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
