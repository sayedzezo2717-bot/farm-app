import 'package:flutter/material.dart';
import 'models.dart';
import 'local_storage_service.dart';

// ============================================
// لوحة التحكم الرئيسية (Dashboard)
// ============================================

class DashboardScreen extends StatefulWidget {
  final LocalStorageService storageService;

  const DashboardScreen({
    Key? key,
    required this.storageService,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  BatchConfig? _currentBatch;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveBatch();
  }

  void _loadActiveBatch() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    setState(() {
      _currentBatch = widget.storageService.getActiveBatch();
      _isLoading = false;
    });

    if (_currentBatch == null && mounted) {
      Navigator.of(context).pushReplacementNamed('/setup');
    }
  }

  void _switchBatch() {
    showDialog(
      context: context,
      builder: (context) => _BatchSelectorDialog(
        storageService: widget.storageService,
        onBatchSelected: (batch) {
          setState(() {
            _currentBatch = batch;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _createNewBatch() {
    Navigator.of(context).pushNamed('/setup');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentBatch == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
        ),
        body: const Center(
          child: Text('لا توجد دورة نشطة'),
        ),
      );
    }

    // اختيار الواجهة المناسبة حسب نوع الإنتاج
    return _currentBatch!.productionType == ProductionType.broiler
        ? _BroilerDashboard(
            batch: _currentBatch!,
            storageService: widget.storageService,
            onSwitchBatch: _switchBatch,
            onCreateNew: _createNewBatch,
          )
        : _LayerDashboard(
            batch: _currentBatch!,
            storageService: widget.storageService,
            onSwitchBatch: _switchBatch,
            onCreateNew: _createNewBatch,
          );
  }
}

// ============================================
// لوحة التحكم - إنتاج اللحم (Broiler)
// ============================================

class _BroilerDashboard extends StatefulWidget {
  final BatchConfig batch;
  final LocalStorageService storageService;
  final VoidCallback onSwitchBatch;
  final VoidCallback onCreateNew;

  const _BroilerDashboard({
    Key? key,
    required this.batch,
    required this.storageService,
    required this.onSwitchBatch,
    required this.onCreateNew,
  }) : super(key: key);

  @override
  State<_BroilerDashboard> createState() => _BroilerDashboardState();
}

class _BroilerDashboardState extends State<_BroilerDashboard> {
  late Future<void> _dataLoadingFuture;

  @override
  void initState() {
    super.initState();
    _dataLoadingFuture = Future.value();
  }

  @override
  Widget build(BuildContext context) {
    final breed = widget.batch.breed!;
    final avgWeight = widget.storageService.getAverageWeight(widget.batch.id);
    final totalFeedConsumption = widget.storageService.getTotalFeedConsumption(widget.batch.id);
    final mortality = widget.storageService.getMortalityRate(widget.batch.id);

    // الوزن المتوقع في هذا اليوم
    final expectedWeightPerDay = breed.avgDailyGain;
    final expectedCurrentWeight = (expectedWeightPerDay * widget.batch.currentAgeInDays) * 1000;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batch.farmName),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade700,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('تبديل الدورة'),
                onTap: widget.onSwitchBatch,
              ),
              PopupMenuItem(
                child: const Text('دورة جديدة'),
                onTap: widget.onCreateNew,
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Text('الإعدادات'),
                onTap: () {
                  // اذهب لصفحة الإعدادات
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============ معلومات الدورة الأساسية ============
            _buildBatchInfoCard(),
            const SizedBox(height: 16),

            // ============ المؤشرات الرئيسية للحم ============
            Text(
              '📊 المؤشرات الرئيسية',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // الوزن الحالي vs المتوقع
            _buildWeightComparisonCard(
              currentWeight: avgWeight,
              expectedWeight: expectedCurrentWeight,
            ),
            const SizedBox(height: 12),

            // استهلاك العلف
            _buildFeedConsumptionCard(
              feedConsumption: totalFeedConsumption,
              birdCount: widget.batch.totalBirdCount,
              ageInDays: widget.batch.currentAgeInDays,
            ),
            const SizedBox(height: 12),

            // معدل الوفيات
            _buildMortalityCard(mortality: mortality),
            const SizedBox(height: 16),

            // ============ نقاط الاهتمام ============
            _buildHealthWarnings(
              currentWeight: avgWeight,
              expectedWeight: expectedCurrentWeight,
              mortality: mortality,
            ),
            const SizedBox(height: 16),

            // ============ زر تسجيل القراءات اليومية ============
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  '/daily-record',
                  arguments: widget.batch.id,
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('تسجيل القراءات اليومية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.deepOrange.shade400, Colors.deepOrange.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.batch.breed!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.batch.currentAgeInDays} يوم',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  '🐔 ${widget.batch.totalBirdCount} طائر',
                  Colors.white,
                ),
                _buildInfoChip(
                  '⏱️ يوم ${widget.batch.currentAgeInDays} من ${widget.batch.breed!.productionCycleDays}',
                  Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: widget.batch.cycleProgress,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightComparisonCard({
    required double currentWeight,
    required double expectedWeight,
  }) {
    final difference = currentWeight - expectedWeight;
    final percentageDifference = expectedWeight > 0
        ? (difference / expectedWeight) * 100
        : 0;
    final isAboveTarget = difference >= 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'مقارنة الوزن (غرام)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAboveTarget
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${isAboveTarget ? '+' : ''}${percentageDifference.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isAboveTarget ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeightMetric(
                  'الحالي',
                  '${currentWeight.toStringAsFixed(0)} g',
                  Colors.blue,
                ),
                _buildWeightMetric(
                  'المتوقع',
                  '${expectedWeight.toStringAsFixed(0)} g',
                  Colors.amber,
                ),
                _buildWeightMetric(
                  'الفرق',
                  '${difference.toStringAsFixed(0)} g',
                  isAboveTarget ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedConsumptionCard({
    required double feedConsumption,
    required int birdCount,
    required int ageInDays,
  }) {
    final feedPerBird = birdCount > 0 ? feedConsumption / birdCount : 0;
    final feedPerBirdPerDay = ageInDays > 0 ? feedPerBird / ageInDays : 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'استهلاك العلف (كيلوجرام)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeightMetric(
                  'الإجمالي',
                  '${feedConsumption.toStringAsFixed(1)} kg',
                  Colors.purple,
                ),
                _buildWeightMetric(
                  'لكل طائر',
                  '${feedPerBird.toStringAsFixed(2)} kg',
                  Colors.cyan,
                ),
                _buildWeightMetric(
                  'يومي',
                  '${feedPerBirdPerDay.toStringAsFixed(3)} kg',
                  Colors.indigo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMortalityCard({required double mortality}) {
    final isSafe = mortality < 5; // معدل وفيات آمن أقل من 5%
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'معدل الوفيات',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${mortality.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSafe ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSafe ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                isSafe ? Icons.check_circle : Icons.warning,
                color: isSafe ? Colors.green : Colors.red,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthWarnings({
    required double currentWeight,
    required double expectedWeight,
    required double mortality,
  }) {
    final warnings = <String>[];

    if (currentWeight < expectedWeight * 0.9) {
      warnings.add('⚠️ الوزن أقل من المتوقع بأكثر من 10%');
    }
    if (mortality > 5) {
      warnings.add('⚠️ معدل الوفيات مرتفع (أكثر من 5%)');
    }

    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: warnings
            .map((warning) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    warning,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 13,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Chip(
      label: Text(
        text,
        style: TextStyle(color: color),
      ),
      backgroundColor: Colors.transparent,
      side: BorderSide(color: color),
    );
  }
}

// ============================================
// لوحة التحكم - إنتاج البيض (Layer)
// ============================================

class _LayerDashboard extends StatefulWidget {
  final BatchConfig batch;
  final LocalStorageService storageService;
  final VoidCallback onSwitchBatch;
  final VoidCallback onCreateNew;

  const _LayerDashboard({
    Key? key,
    required this.batch,
    required this.storageService,
    required this.onSwitchBatch,
    required this.onCreateNew,
  }) : super(key: key);

  @override
  State<_LayerDashboard> createState() => _LayerDashboardState();
}

class _LayerDashboardState extends State<_LayerDashboard> {
  @override
  Widget build(BuildContext context) {
    final breed = widget.batch.breed!;
    final totalEggs = widget.storageService.getTotalEggProduction(widget.batch.id);
    final avgEggProduction = widget.storageService.getDailyRecordsByBatch(widget.batch.id)
        .fold<double>(0, (sum, record) => sum + (record.eggProductionPercentage ?? 0)) /
        (widget.storageService.getDailyRecordsByBatch(widget.batch.id).length > 0
            ? widget.storageService.getDailyRecordsByBatch(widget.batch.id).length
            : 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batch.farmName),
        centerTitle: true,
        backgroundColor: Colors.brown.shade700,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('تبديل الدورة'),
                onTap: widget.onSwitchBatch,
              ),
              PopupMenuItem(
                child: const Text('دورة جديدة'),
                onTap: widget.onCreateNew,
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات الدورة
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.brown.shade400, Colors.brown.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          breed.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'أسبوع ${(widget.batch.currentAgeInDays / 7).toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '🐔 ${widget.batch.totalBirdCount} دجاجة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // المؤشرات الرئيسية
            Text(
              '📊 مؤشرات الإنتاج',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // إجمالي البيض
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إجمالي البيض المجمع',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$totalEggs 🥚',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.eggs,
                      size: 48,
                      color: Colors.amber.shade600,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // متوسط الإنتاج اليومي
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'متوسط الإنتاج اليومي',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${avgEggProduction.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'نسبة الإنتاج',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${(totalEggs / widget.batch.totalBirdCount).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'بيضة/دجاجة',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // زر التسجيل
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  '/daily-record',
                  arguments: widget.batch.id,
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('تسجيل الإنتاج اليومي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// حوار اختيار الدورة
// ============================================

class _BatchSelectorDialog extends StatelessWidget {
  final LocalStorageService storageService;
  final Function(BatchConfig) onBatchSelected;

  const _BatchSelectorDialog({
    Key? key,
    required this.storageService,
    required this.onBatchSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final batches = storageService.getAllBatchConfigs();

    if (batches.isEmpty) {
      return AlertDialog(
        title: const Text('لا توجد دورات'),
        content: const Text('لم يتم العثور على دورات محفوظة'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('اختر دورة'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: batches.length,
          itemBuilder: (context, index) {
            final batch = batches[index];
            return ListTile(
              title: Text(batch.breed?.name ?? 'غير معروف'),
              subtitle: Text(
                '${batch.farmName} - العمر: ${batch.currentAgeInDays} يوم',
              ),
              onTap: () {
                onBatchSelected(batch);
              },
            );
          },
        ),
      ),
    );
  }
}
