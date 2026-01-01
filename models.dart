import 'package:hive/hive.dart';

// ============================================
// تعريف أنواع الإنتاج
// ============================================

enum ProductionType {
  broiler,  // لحم
  layer,    // بيض
}

extension ProductionTypeDisplay on ProductionType {
  String get displayName {
    return this == ProductionType.broiler ? 'إنتاج لحم' : 'إنتاج بيض';
  }
}

// ============================================
// نموذج السلالة (Breed)
// ============================================

class Breed {
  final String id;
  final String name;        // اسم السلالة (مثل: Ross, Cobb, بلدي محسن)
  final ProductionType type; // النوع الذي تنتمي له
  final double avgDailyGain; // متوسط الوزن اليومي (للحم)
  final double peakEggProduction; // نسبة إنتاج البيض الذروة (للبيض)
  final int productionCycleDays; // مدة الدورة بالأيام
  final Map<String, dynamic> nutritionRequirements; // احتياجات التغذية

  Breed({
    required this.id,
    required this.name,
    required this.type,
    this.avgDailyGain = 0.0,
    this.peakEggProduction = 0.0,
    this.productionCycleDays = 42, // 42 يوم للحم، 500+ يوم للبيض
    this.nutritionRequirements = const {},
  });

  // قائمة السلالات المعرفة مسبقاً
  static final List<Breed> predefinedBreeds = [
    // سلالات اللحم (Broilers)
    Breed(
      id: 'cobb',
      name: 'كوب أبيض (Cobb)',
      type: ProductionType.broiler,
      avgDailyGain: 2.15,
      productionCycleDays: 42,
      nutritionRequirements: {
        'protein': 23.0, // %
        'energy': 3200, // kcal/kg
        'feedConversion': 1.45,
      },
    ),
    Breed(
      id: 'ross',
      name: 'روس أبيض (Ross)',
      type: ProductionType.broiler,
      avgDailyGain: 2.10,
      productionCycleDays: 42,
      nutritionRequirements: {
        'protein': 23.0,
        'energy': 3200,
        'feedConversion': 1.47,
      },
    ),
    Breed(
      id: 'sasso',
      name: 'ساسو (Sasso)',
      type: ProductionType.broiler,
      avgDailyGain: 1.65,
      productionCycleDays: 56,
      nutritionRequirements: {
        'protein': 21.0,
        'energy': 3000,
        'feedConversion': 2.1,
      },
    ),

    // سلالات البيض (Layers)
    Breed(
      id: 'local_improved',
      name: 'بلدي محسن (Local Improved)',
      type: ProductionType.layer,
      peakEggProduction: 85.0, // %
      productionCycleDays: 500,
      nutritionRequirements: {
        'protein': 16.0,
        'energy': 2800,
        'calcium': 3.5,
      },
    ),
    Breed(
      id: 'lohmann',
      name: 'لوهمن براون (Lohmann Brown)',
      type: ProductionType.layer,
      peakEggProduction: 95.0,
      productionCycleDays: 500,
      nutritionRequirements: {
        'protein': 16.5,
        'energy': 2850,
        'calcium': 3.8,
      },
    ),
    Breed(
      id: 'isa_brown',
      name: 'إيزا براون (ISA Brown)',
      type: ProductionType.layer,
      peakEggProduction: 98.0,
      productionCycleDays: 500,
      nutritionRequirements: {
        'protein': 17.0,
        'energy': 2900,
        'calcium': 4.0,
      },
    ),
  ];

  // الحصول على السلالات حسب النوع
  static List<Breed> getBreedsByType(ProductionType type) {
    return predefinedBreeds.where((breed) => breed.type == type).toList();
  }

  // الحصول على سلالة معينة من خلال الـ ID
  static Breed? getBreedById(String id) {
    try {
      return predefinedBreeds.firstWhere((breed) => breed.id == id);
    } catch (e) {
      return null;
    }
  }
}

// ============================================
// نموذج بطارية / قفص الدواجن
// ============================================

@HiveType(typeId: 0)
class CageBattery {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name; // مثل: بطارية 1، قفص الدور الأول
  
  @HiveField(2)
  final int birdCount; // عدد الطيور في هذه البطارية
  
  @HiveField(3)
  final double cageArea; // مساحة القفص بالمتر المربع
  
  CageBattery({
    required this.id,
    required this.name,
    required this.birdCount,
    required this.cageArea,
  });

  // حساب الكثافة (عدد الطيور / المساحة)
  double get stocking_density => birdCount / cageArea;

  // التحقق من مناسبة الكثافة (للدواجن عادة 10-12 طائر/متر مربع)
  bool get isDensitySafe {
    return stocking_density >= 8 && stocking_density <= 15;
  }
}

// ============================================
// الإعدادات الأولية للدورة (BatchConfig)
// ============================================

@HiveType(typeId: 1)
class BatchConfig {
  @HiveField(0)
  final String id; // معرف فريد للدورة
  
  @HiveField(1)
  final ProductionType productionType; // نوع الإنتاج
  
  @HiveField(2)
  final String breedId; // معرف السلالة
  
  @HiveField(3)
  final DateTime startDate; // تاريخ بدء الدورة
  
  @HiveField(4)
  final int initialAge; // العمر الأولي بالأيام
  
  @HiveField(5)
  final int totalBirdCount; // إجمالي عدد الطيور
  
  @HiveField(6)
  final List<CageBattery> cages; // قائمة الأقفاص/البطاريات
  
  @HiveField(7)
  final DateTime createdAt; // وقت إنشاء الإعداد
  
  @HiveField(8)
  final String farmName; // اسم المزرعة (اختياري)
  
  @HiveField(9)
  final String notes; // ملاحظات إضافية

  BatchConfig({
    required this.id,
    required this.productionType,
    required this.breedId,
    required this.startDate,
    required this.initialAge,
    required this.totalBirdCount,
    required this.cages,
    DateTime? createdAt,
    this.farmName = 'مزرعتي',
    this.notes = '',
  }) : createdAt = createdAt ?? DateTime.now();

  // الحصول على بيانات السلالة
  Breed? get breed => Breed.getBreedById(breedId);

  // حساب العمر الحالي بالأيام
  int get currentAgeInDays {
    return initialAge + DateTime.now().difference(startDate).inDays;
  }

  // التحقق مما إذا انتهت الدورة
  bool get isCycleComplete {
    final cycleDays = breed?.productionCycleDays ?? 0;
    return currentAgeInDays >= cycleDays;
  }

  // نسبة تقدم الدورة (0.0 - 1.0)
  double get cycleProgress {
    final cycleDays = breed?.productionCycleDays ?? 1;
    return (currentAgeInDays / cycleDays).clamp(0.0, 1.0);
  }

  // إجمالي الكثافة في جميع الأقفاص
  double get averageStockingDensity {
    if (cages.isEmpty) return 0;
    final totalArea = cages.fold<double>(0, (sum, cage) => sum + cage.cageArea);
    return totalBirdCount / totalArea;
  }

  @override
  String toString() {
    return 'BatchConfig('
        'id: $id, '
        'type: ${productionType.displayName}, '
        'breed: ${breed?.name ?? "غير معروف"}, '
        'age: $currentAgeInDays days)';
  }
}

// ============================================
// نموذج السجلات اليومية (Daily Records)
// ============================================

@HiveType(typeId: 2)
class DailyRecord {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String batchId; // معرف الدورة
  
  @HiveField(2)
  final DateTime date; // تاريخ التسجيل
  
  @HiveField(3)
  final double? averageWeight; // متوسط الوزن بالجرام (للحم)
  
  @HiveField(4)
  final double? feedConsumption; // استهلاك العلف بالكيلوجرام
  
  @HiveField(5)
  final int? eggProduction; // عدد البيض المجمع (للبيض)
  
  @HiveField(6)
  final double? eggProductionPercentage; // نسبة الإنتاج %
  
  @HiveField(7)
  final int? deadCount; // عدد الطيور النافقة
  
  @HiveField(8)
  final String notes; // ملاحظات

  DailyRecord({
    required this.id,
    required this.batchId,
    required this.date,
    this.averageWeight,
    this.feedConsumption,
    this.eggProduction,
    this.eggProductionPercentage,
    this.deadCount,
    this.notes = '',
  });

  // حساب التحويل الغذائي (Feed Conversion Ratio) للحم
  double? get feedConversionRatio {
    if (averageWeight == null || feedConsumption == null || feedConsumption == 0) {
      return null;
    }
    return feedConsumption! / (averageWeight! / 1000); // kg feed / kg meat
  }
}
