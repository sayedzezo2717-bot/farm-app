// ============================================
// أمثلة عملية وحالات الاستخدام
// ============================================

// ملف: examples.dart

import 'models.dart';
import 'local_storage_service.dart';
import 'package:uuid/uuid.dart';

/// ============================================================
/// مثال 1: إنشاء دورة لحم (Broiler) كاملة مع بطاريات
/// ============================================================

Future<void> example1_CreateBroilerBatch() async {
  final storage = LocalStorageService();
  
  // إنشاء بطاريات
  final cages = [
    CageBattery(
      id: const Uuid().v4(),
      name: 'بطارية الدور الأول',
      birdCount: 500,
      cageArea: 50, // 50 متر مربع
    ),
    CageBattery(
      id: const Uuid().v4(),
      name: 'بطارية الدور الثاني',
      birdCount: 500,
      cageArea: 50,
    ),
  ];

  // تحقق من الكثافة
  for (var cage in cages) {
    print('${cage.name}: الكثافة = ${cage.stocking_density.toStringAsFixed(2)} طائر/م²');
    print('الكثافة آمنة؟ ${cage.isDensitySafe}');
  }

  // إنشاء الدورة
  final batch = BatchConfig(
    id: const Uuid().v4(),
    productionType: ProductionType.broiler,
    breedId: 'cobb', // كوب
    startDate: DateTime.now(),
    initialAge: 0, // عمر 0 يوم (كتاكيت)
    totalBirdCount: 1000,
    cages: cages,
    farmName: 'مزرعة الوادي',
    notes: 'دورة تجريبية - نوعية جيدة',
  );

  // حفظ
  await storage.saveBatchConfig(batch);
  print('\n✓ تم إنشاء دورة اللحم بنجاح');
  print('معرف الدورة: ${batch.id}');
  print('العمر الحالي: ${batch.currentAgeInDays} يوم');
  print('متوسط الكثافة: ${batch.averageStockingDensity.toStringAsFixed(2)} طائر/م²');
}

/// ============================================================
/// مثال 2: تسجيل بيانات يومية لدورة اللحم
/// ============================================================

Future<void> example2_RecordBroilerDailyData() async {
  final storage = LocalStorageService();
  
  // احصل على الدورة النشطة
  final batch = storage.getActiveBatch();
  if (batch == null) {
    print('لا توجد دورة نشطة');
    return;
  }

  // تسجيلات يومية على مدى 7 أيام
  final dailyWeights = [150, 320, 480, 720, 1050, 1380, 1750]; // بالجرام
  final feedConsumption = [15, 32, 48, 68, 85, 102, 120]; // بالكيلوجرام
  final deadBirds = [0, 2, 1, 0, 3, 2, 1];

  for (int day = 1; day <= 7; day++) {
    final record = DailyRecord(
      id: const Uuid().v4(),
      batchId: batch.id,
      date: DateTime.now().subtract(Duration(days: 8 - day)),
      averageWeight: dailyWeights[day - 1].toDouble(),
      feedConsumption: feedConsumption[day - 1].toDouble(),
      deadCount: deadBirds[day - 1],
      notes: 'تسجيل يومي عادي',
    );

    await storage.saveDailyRecord(record);
  }

  print('\n✓ تم تسجيل البيانات اليومية (7 أيام)');
  
  // احصل على الإحصائيات
  final totalFeed = storage.getTotalFeedConsumption(batch.id);
  final avgWeight = storage.getAverageWeight(batch.id);
  final mortality = storage.getMortalityRate(batch.id);

  print('إجمالي العلف: ${totalFeed.toStringAsFixed(1)} كيلوجرام');
  print('متوسط الوزن: ${avgWeight.toStringAsFixed(0)} جرام');
  print('معدل الوفيات: ${mortality.toStringAsFixed(2)}%');
}

/// ============================================================
/// مثال 3: إنشاء دورة بيض (Layer)
/// ============================================================

Future<void> example3_CreateLayerBatch() async {
  final storage = LocalStorageService();

  // سلالة البيض ذات إنتاجية عالية
  final breed = Breed.getBreedById('isa_brown');

  final batch = BatchConfig(
    id: const Uuid().v4(),
    productionType: ProductionType.layer,
    breedId: 'isa_brown', // إيزا براون
    startDate: DateTime.now().subtract(const Duration(days: 100)),
    initialAge: 16 * 7, // عمر 16 أسبوع (112 يوم)
    totalBirdCount: 2000,
    cages: [
      CageBattery(
        id: const Uuid().v4(),
        name: 'البطارية الأولى (1000 دجاجة)',
        birdCount: 1000,
        cageArea: 100,
      ),
      CageBattery(
        id: const Uuid().v4(),
        name: 'البطارية الثانية (1000 دجاجة)',
        birdCount: 1000,
        cageArea: 100,
      ),
    ],
    farmName: 'مزرعة الإنتاج',
  );

  await storage.saveBatchConfig(batch);
  
  print('\n✓ تم إنشاء دورة البيض بنجاح');
  print('السلالة: ${breed?.name}');
  print('ذروة الإنتاج المتوقعة: ${breed?.peakEggProduction}%');
  print('العمر الحالي: ${batch.currentAgeInDays} يوم');
}

/// ============================================================
/// مثال 4: تسجيل إنتاج البيض اليومي
/// ============================================================

Future<void> example4_RecordLayerDailyProduction() async {
  final storage = LocalStorageService();
  
  final batch = storage.getActiveBatch();
  if (batch == null || batch.productionType != ProductionType.layer) {
    print('يجب أن تكون هناك دورة بيض نشطة');
    return;
  }

  // تسجيلات يومية للبيض
  final eggCounts = [150, 320, 680, 1200, 1600, 1850, 1950];
  final eggPercentages = [7.5, 16.0, 34.0, 60.0, 80.0, 92.5, 97.5];

  for (int day = 1; day <= 7; day++) {
    final record = DailyRecord(
      id: const Uuid().v4(),
      batchId: batch.id,
      date: DateTime.now().subtract(Duration(days: 8 - day)),
      eggProduction: eggCounts[day - 1],
      eggProductionPercentage: eggPercentages[day - 1],
      deadCount: day == 3 ? 2 : 0, // وفاة طفيفة في اليوم الثالث
      notes: day == 1 ? 'بدء التسجيل' : 'إنتاج طبيعي',
    );

    await storage.saveDailyRecord(record);
  }

  print('\n✓ تم تسجيل إنتاج البيض (7 أيام)');
  
  // احصل على الإحصائيات
  final totalEggs = storage.getTotalEggProduction(batch.id);
  final avgProduction = storage.getDailyRecordsByBatch(batch.id)
      .fold<double>(0, (sum, r) => sum + (r.eggProductionPercentage ?? 0)) /
      storage.getDailyRecordsByBatch(batch.id).length;

  print('إجمالي البيض: $totalEggs');
  print('متوسط الإنتاج: ${avgProduction.toStringAsFixed(1)}%');
}

/// ============================================================
/// مثال 5: تحليل مقارن بين دورات
/// ============================================================

Future<void> example5_CompareBatches() async {
  final storage = LocalStorageService();
  
  // احصل على جميع الدورات
  final allBatches = storage.getAllBatchConfigs();
  
  print('\n📊 تحليل مقارن للدورات:');
  print('=' * 60);

  for (var batch in allBatches) {
    print('\n🐔 ${batch.breed?.name} (${batch.farmName})');
    print('───────────────────');
    
    final records = storage.getDailyRecordsByBatch(batch.id);
    final mortality = storage.getMortalityRate(batch.id);
    
    print('النوع: ${batch.productionType.displayName}');
    print('العمر: ${batch.currentAgeInDays} يوم');
    print('إجمالي الطيور: ${batch.totalBirdCount}');
    print('معدل الوفيات: ${mortality.toStringAsFixed(2)}%');
    print('السجلات المسجلة: ${records.length}');
    
    if (batch.productionType == ProductionType.broiler) {
      final avgWeight = storage.getAverageWeight(batch.id);
      final feedTotal = storage.getTotalFeedConsumption(batch.id);
      print('متوسط الوزن: ${avgWeight.toStringAsFixed(0)} جرام');
      print('استهلاك العلف: ${feedTotal.toStringAsFixed(1)} كيلوجرام');
    } else {
      final totalEggs = storage.getTotalEggProduction(batch.id);
      print('إجمالي البيض: $totalEggs');
    }
  }
}

/// ============================================================
/// مثال 6: حساب الاحتياجات الغذائية
/// ============================================================

Future<void> example6_NutritionCalculations() async {
  final storage = LocalStorageService();
  
  final batch = storage.getActiveBatch();
  if (batch == null) return;

  final breed = batch.breed;
  if (breed == null) return;

  print('\n🌾 الاحتياجات الغذائية:');
  print('=' * 60);
  print('السلالة: ${breed.name}');
  print('نوع الإنتاج: ${batch.productionType.displayName}');
  print('\nالاحتياجات اليومية:');
  
  breed.nutritionRequirements.forEach((key, value) {
    if (key == 'protein') {
      print('البروتين: $value% من العلف');
    } else if (key == 'energy') {
      print('الطاقة: $value كيلو سعرة/كيلوجرام');
    } else if (key == 'calcium') {
      print('الكالسيوم: $value% (مهم للبيض)');
    } else if (key == 'feedConversion') {
      print('نسبة التحويل الغذائي: $value');
    }
  });
  
  // حساب الكمية الكلية المطلوبة
  print('\nالكمية المطلوبة للدورة كاملة:');
  if (batch.productionType == ProductionType.broiler) {
    final feedPerBirdPerDay = 0.05; // كيلوجرام
    final totalDays = breed.productionCycleDays;
    final totalFeedNeeded = batch.totalBirdCount * feedPerBirdPerDay * totalDays;
    print('إجمالي العلف: ${totalFeedNeeded.toStringAsFixed(0)} كيلوجرام');
  }
}

/// ============================================================
/// مثال 7: تنبيهات تلقائية وتحذيرات
/// ============================================================

Future<void> example7_HealthWarnings() async {
  final storage = LocalStorageService();
  
  final batch = storage.getActiveBatch();
  if (batch == null) return;

  final records = storage.getDailyRecordsByBatch(batch.id);
  if (records.isEmpty) return;

  final latestRecord = records.last;
  final breed = batch.breed!;
  final mortality = storage.getMortalityRate(batch.id);
  
  print('\n⚠️ تحذيرات صحية:');
  print('=' * 60);

  var hasWarnings = false;

  // تحذيرات اللحم
  if (batch.productionType == ProductionType.broiler) {
    final currentWeight = latestRecord.averageWeight ?? 0;
    final expectedWeight = breed.avgDailyGain * batch.currentAgeInDays * 1000;
    final weightDifference = currentWeight - expectedWeight;
    
    if (weightDifference < -expectedWeight * 0.1) {
      print('🔴 تحذير: الوزن أقل من المتوقع بأكثر من 10%');
      print('   الوزن الحالي: ${currentWeight.toStringAsFixed(0)} جرام');
      print('   الوزن المتوقع: ${expectedWeight.toStringAsFixed(0)} جرام');
      hasWarnings = true;
    }

    if (latestRecord.feedConsumption! < 0) {
      print('🟡 تحذير: استهلاك العلف غير طبيعي');
      hasWarnings = true;
    }
  }

  // تحذيرات عامة
  if (mortality > 5) {
    print('🔴 تحذير: معدل الوفيات مرتفع (${mortality.toStringAsFixed(2)}%)');
    hasWarnings = true;
  }

  if (latestRecord.deadCount != null && latestRecord.deadCount! > 10) {
    print('🟡 تحذير: عدد الطيور النافقة اليوم مرتفع (${latestRecord.deadCount})');
    hasWarnings = true;
  }

  if (!hasWarnings) {
    print('✅ لا توجد تحذيرات - الحالة الصحية جيدة');
  }
}

/// ============================================================
/// مثال 8: تصدير البيانات
/// ============================================================

Future<void> example8_ExportData() async {
  final storage = LocalStorageService();
  
  final jsonData = await storage.exportAllDataAsJson();
  
  print('\n📄 تم تصدير البيانات:');
  print('=' * 60);
  print(jsonData);
  
  // يمكن حفظ هذا الـ JSON في ملف
  // أو إرساله عبر البريد الإلكتروني
}

/// ============================================================
/// دالة رئيسية لتشغيل جميع الأمثلة
/// ============================================================

Future<void> runAllExamples() async {
  print('🚀 بدء تشغيل الأمثلة...\n');
  
  try {
    // تهيئة الخدمة
    final storage = LocalStorageService();
    await storage.init();

    // تشغيل الأمثلة
    print('📝 مثال 1: إنشاء دورة لحم');
    await example1_CreateBroilerBatch();

    await Future.delayed(const Duration(seconds: 1));

    print('\n📝 مثال 2: تسجيل بيانات يومية');
    await example2_RecordBroilerDailyData();

    await Future.delayed(const Duration(seconds: 1));

    print('\n📝 مثال 3: إنشاء دورة بيض');
    await example3_CreateLayerBatch();

    await Future.delayed(const Duration(seconds: 1));

    print('\n📝 مثال 4: تسجيل إنتاج البيض');
    await example4_RecordLayerDailyProduction();

    await Future.delayed(const Duration(seconds: 1));

    print('\n📝 مثال 5: تحليل مقارن');
    await example5_CompareBatches();

    await Future.delayed(const Duration(seconds: 1));

    print('\n📝 مثال 6: الاحتياجات الغذائية');
    await example6_NutritionCalculations();

    await Future.delayed(const Duration(seconds: 1));

    print('\n📝 مثال 7: التحذيرات الصحية');
    await example7_HealthWarnings();

    await Future.delayed(const Duration(seconds: 1));

    print('\n📝 مثال 8: تصدير البيانات');
    await example8_ExportData();

    print('\n\n✅ انتهت جميع الأمثلة بنجاح!');
  } catch (e) {
    print('❌ خطأ: $e');
  }
}

// استدعاء من main.dart (في التطوير):
// runAllExamples();
