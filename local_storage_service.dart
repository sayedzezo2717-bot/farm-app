import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart';

// ============================================
// خدمة إدارة البيانات المحلية
// ============================================

class LocalStorageService {
  static const String _batchConfigBoxName = 'batch_config';
  static const String _dailyRecordsBoxName = 'daily_records';
  static const String _activeBatchKeyName = 'active_batch_id';

  late Box<BatchConfig> _batchConfigBox;
  late Box<DailyRecord> _dailyRecordsBox;
  late SharedPreferences _prefs;

  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  // ============================================
  // التهيئة والإعداد
  // ============================================

  /// تهيئة الخدمة (يجب استدعاؤها عند بدء التطبيق)
  Future<void> init() async {
    try {
      // تهيئة Hive
      _batchConfigBox = await Hive.openBox<BatchConfig>(_batchConfigBoxName);
      _dailyRecordsBox = await Hive.openBox<DailyRecord>(_dailyRecordsBoxName);

      // تهيئة SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      print('✓ تم تهيئة خدمة التخزين المحلي بنجاح');
    } catch (e) {
      print('✗ خطأ في تهيئة التخزين المحلي: $e');
      rethrow;
    }
  }

  // ============================================
  // عمليات إدارة الدورات (Batch Operations)
  // ============================================

  /// حفظ إعداد دورة جديدة
  Future<void> saveBatchConfig(BatchConfig config) async {
    try {
      await _batchConfigBox.put(config.id, config);
      await _setActiveBatchId(config.id);
      print('✓ تم حفظ إعداد الدورة: ${config.id}');
    } catch (e) {
      print('✗ خطأ في حفظ الدورة: $e');
      rethrow;
    }
  }

  /// الحصول على إعداد دورة معينة
  BatchConfig? getBatchConfig(String batchId) {
    try {
      return _batchConfigBox.get(batchId);
    } catch (e) {
      print('✗ خطأ في استرجاع الدورة: $e');
      return null;
    }
  }

  /// الحصول على جميع الدورات المحفوظة
  List<BatchConfig> getAllBatchConfigs() {
    try {
      return _batchConfigBox.values.toList();
    } catch (e) {
      print('✗ خطأ في استرجاع الدورات: $e');
      return [];
    }
  }

  /// حذف دورة معينة
  Future<void> deleteBatchConfig(String batchId) async {
    try {
      await _batchConfigBox.delete(batchId);
      
      // إذا كانت هذه الدورة النشطة، امسح معرف الدورة النشطة
      if (getActiveBatchId() == batchId) {
        await _prefs.remove(_activeBatchKeyName);
      }
      
      print('✓ تم حذف الدورة: $batchId');
    } catch (e) {
      print('✗ خطأ في حذف الدورة: $e');
      rethrow;
    }
  }

  /// تحديث إعداد دورة موجودة
  Future<void> updateBatchConfig(BatchConfig config) async {
    try {
      await _batchConfigBox.put(config.id, config);
      print('✓ تم تحديث الدورة: ${config.id}');
    } catch (e) {
      print('✗ خطأ في تحديث الدورة: $e');
      rethrow;
    }
  }

  // ============================================
  // عمليات إدارة الدورة النشطة
  // ============================================

  /// تعيين الدورة النشطة
  Future<void> _setActiveBatchId(String batchId) async {
    await _prefs.setString(_activeBatchKeyName, batchId);
    print('✓ تم تعيين الدورة النشطة: $batchId');
  }

  /// الحصول على معرف الدورة النشطة
  String? getActiveBatchId() {
    return _prefs.getString(_activeBatchKeyName);
  }

  /// الحصول على الدورة النشطة (كاملة)
  BatchConfig? getActiveBatch() {
    final batchId = getActiveBatchId();
    if (batchId == null) return null;
    return getBatchConfig(batchId);
  }

  /// التحقق من وجود دورة نشطة
  bool hasActiveBatch() {
    return getActiveBatchId() != null;
  }

  // ============================================
  // عمليات إدارة السجلات اليومية
  // ============================================

  /// حفظ سجل يومي جديد
  Future<void> saveDailyRecord(DailyRecord record) async {
    try {
      await _dailyRecordsBox.put(record.id, record);
      print('✓ تم حفظ السجل اليومي: ${record.id}');
    } catch (e) {
      print('✗ خطأ في حفظ السجل: $e');
      rethrow;
    }
  }

  /// الحصول على سجل يومي معين
  DailyRecord? getDailyRecord(String recordId) {
    try {
      return _dailyRecordsBox.get(recordId);
    } catch (e) {
      print('✗ خطأ في استرجاع السجل: $e');
      return null;
    }
  }

  /// الحصول على جميع السجلات اليومية لدورة معينة
  List<DailyRecord> getDailyRecordsByBatch(String batchId) {
    try {
      return _dailyRecordsBox.values
          .where((record) => record.batchId == batchId)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      print('✗ خطأ في استرجاع السجلات: $e');
      return [];
    }
  }

  /// الحصول على أحدث سجل يومي لدورة معينة
  DailyRecord? getLatestDailyRecord(String batchId) {
    try {
      final records = getDailyRecordsByBatch(batchId);
      return records.isEmpty ? null : records.last;
    } catch (e) {
      print('✗ خطأ في استرجاع أحدث سجل: $e');
      return null;
    }
  }

  /// حذف سجل يومي
  Future<void> deleteDailyRecord(String recordId) async {
    try {
      await _dailyRecordsBox.delete(recordId);
      print('✓ تم حذف السجل: $recordId');
    } catch (e) {
      print('✗ خطأ في حذف السجل: $e');
      rethrow;
    }
  }

  /// تحديث سجل يومي
  Future<void> updateDailyRecord(DailyRecord record) async {
    try {
      await _dailyRecordsBox.put(record.id, record);
      print('✓ تم تحديث السجل: ${record.id}');
    } catch (e) {
      print('✗ خطأ في تحديث السجل: $e');
      rethrow;
    }
  }

  // ============================================
  // عمليات إحصائية
  // ============================================

  /// حساب إجمالي استهلاك العلف لدورة معينة
  double getTotalFeedConsumption(String batchId) {
    try {
      return getDailyRecordsByBatch(batchId)
          .fold<double>(0, (sum, record) => sum + (record.feedConsumption ?? 0));
    } catch (e) {
      print('✗ خطأ في حساب استهلاك العلف: $e');
      return 0;
    }
  }

  /// حساب إجمالي البيض المجمع
  int getTotalEggProduction(String batchId) {
    try {
      return getDailyRecordsByBatch(batchId)
          .fold<int>(0, (sum, record) => sum + (record.eggProduction ?? 0));
    } catch (e) {
      print('✗ خطأ في حساب إنتاج البيض: $e');
      return 0;
    }
  }

  /// حساب متوسط الوزن للدورة
  double getAverageWeight(String batchId) {
    try {
      final records = getDailyRecordsByBatch(batchId);
      if (records.isEmpty) return 0;
      
      final total = records.fold<double>(0, (sum, record) => sum + (record.averageWeight ?? 0));
      return total / records.length;
    } catch (e) {
      print('✗ خطأ في حساب متوسط الوزن: $e');
      return 0;
    }
  }

  /// حساب نسبة الوفيات
  double getMortalityRate(String batchId) {
    try {
      final config = getBatchConfig(batchId);
      if (config == null) return 0;

      final records = getDailyRecordsByBatch(batchId);
      final totalDeaths = records.fold<int>(0, (sum, record) => sum + (record.deadCount ?? 0));
      
      return (totalDeaths / config.totalBirdCount) * 100;
    } catch (e) {
      print('✗ خطأ في حساب نسبة الوفيات: $e');
      return 0;
    }
  }

  // ============================================
  // عمليات النسخ الاحتياطية والاستيراد/التصدير
  // ============================================

  /// تصدير جميع البيانات كـ JSON
  Future<String> exportAllDataAsJson() async {
    try {
      final batches = _batchConfigBox.values.toList();
      final records = _dailyRecordsBox.values.toList();

      final data = {
        'batches': batches.map((b) => _batchToJson(b)).toList(),
        'records': records.map((r) => _recordToJson(r)).toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };

      return jsonEncode(data);
    } catch (e) {
      print('✗ خطأ في التصدير: $e');
      rethrow;
    }
  }

  /// مسح جميع البيانات
  Future<void> clearAllData() async {
    try {
      await _batchConfigBox.clear();
      await _dailyRecordsBox.clear();
      await _prefs.clear();
      print('✓ تم مسح جميع البيانات');
    } catch (e) {
      print('✗ خطأ في مسح البيانات: $e');
      rethrow;
    }
  }

  // ============================================
  // دوال مساعدة خاصة
  // ============================================

  Map<String, dynamic> _batchToJson(BatchConfig batch) {
    return {
      'id': batch.id,
      'productionType': batch.productionType.toString(),
      'breedId': batch.breedId,
      'startDate': batch.startDate.toIso8601String(),
      'initialAge': batch.initialAge,
      'totalBirdCount': batch.totalBirdCount,
      'farmName': batch.farmName,
      'notes': batch.notes,
    };
  }

  Map<String, dynamic> _recordToJson(DailyRecord record) {
    return {
      'id': record.id,
      'batchId': record.batchId,
      'date': record.date.toIso8601String(),
      'averageWeight': record.averageWeight,
      'feedConsumption': record.feedConsumption,
      'eggProduction': record.eggProduction,
      'eggProductionPercentage': record.eggProductionPercentage,
      'deadCount': record.deadCount,
      'notes': record.notes,
    };
  }
}
