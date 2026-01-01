import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'local_storage_service.dart';
import 'batch_setup_screen.dart';
import 'dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Hive
  await Hive.initFlutter();
  
  // تسجيل الأنواع المخصصة في Hive
  Hive.registerAdapter(ProductionTypeAdapter());
  Hive.registerAdapter(CageBatteryAdapter());
  Hive.registerAdapter(BatchConfigAdapter());
  Hive.registerAdapter(DailyRecordAdapter());

  // تهيئة خدمة التخزين المحلي
  final storageService = LocalStorageService();
  await storageService.init();

  runApp(MyApp(storageService: storageService));
}

// ============================================
// محول البيانات لـ Hive - ProductionType
// ============================================

class ProductionTypeAdapter extends TypeAdapter<ProductionType> {
  @override
  final int typeId = 3;

  @override
  ProductionType read(BinaryReader reader) {
    final value = reader.readByte();
    return ProductionType.values[value];
  }

  @override
  void write(BinaryWriter writer, ProductionType obj) {
    writer.writeByte(obj.index);
  }
}

// ============================================
// محول البيانات لـ Hive - CageBattery
// ============================================

class CageBatteryAdapter extends TypeAdapter<CageBattery> {
  @override
  final int typeId = 0;

  @override
  CageBattery read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final fieldKey = reader.readByte();
      fields[fieldKey] = reader.read();
    }
    return CageBattery(
      id: fields[0] as String,
      name: fields[1] as String,
      birdCount: fields[2] as int,
      cageArea: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CageBattery obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.birdCount)
      ..writeByte(3)
      ..write(obj.cageArea);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CageBatteryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ============================================
// محول البيانات لـ Hive - BatchConfig
// ============================================

class BatchConfigAdapter extends TypeAdapter<BatchConfig> {
  @override
  final int typeId = 1;

  @override
  BatchConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final fieldKey = reader.readByte();
      fields[fieldKey] = reader.read();
    }
    return BatchConfig(
      id: fields[0] as String,
      productionType: fields[1] as ProductionType,
      breedId: fields[2] as String,
      startDate: fields[3] as DateTime,
      initialAge: fields[4] as int,
      totalBirdCount: fields[5] as int,
      cages: (fields[6] as List).cast<CageBattery>(),
      createdAt: fields[7] as DateTime,
      farmName: fields[8] as String? ?? 'مزرعتي',
      notes: fields[9] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, BatchConfig obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productionType)
      ..writeByte(2)
      ..write(obj.breedId)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.initialAge)
      ..writeByte(5)
      ..write(obj.totalBirdCount)
      ..writeByte(6)
      ..write(obj.cages)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.farmName)
      ..writeByte(9)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ============================================
// محول البيانات لـ Hive - DailyRecord
// ============================================

class DailyRecordAdapter extends TypeAdapter<DailyRecord> {
  @override
  final int typeId = 2;

  @override
  DailyRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final fieldKey = reader.readByte();
      fields[fieldKey] = reader.read();
    }
    return DailyRecord(
      id: fields[0] as String,
      batchId: fields[1] as String,
      date: fields[2] as DateTime,
      averageWeight: fields[3] as double?,
      feedConsumption: fields[4] as double?,
      eggProduction: fields[5] as int?,
      eggProductionPercentage: fields[6] as double?,
      deadCount: fields[7] as int?,
      notes: fields[8] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, DailyRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.batchId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.averageWeight)
      ..writeByte(4)
      ..write(obj.feedConsumption)
      ..writeByte(5)
      ..write(obj.eggProduction)
      ..writeByte(6)
      ..write(obj.eggProductionPercentage)
      ..writeByte(7)
      ..write(obj.deadCount)
      ..writeByte(8)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ============================================
// التطبيق الرئيسي
// ============================================

class MyApp extends StatelessWidget {
  final LocalStorageService storageService;

  const MyApp({
    Key? key,
    required this.storageService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ======================== الإعدادات الأساسية ========================
      title: 'إدارة مزرعة الدواجن',
      debugShowCheckedModeBanner: false,
      
      // ======================== المظهر والألوان ========================
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.light,
        ),
        
        // ======================== أنماط النصوص ========================
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),

        // ======================== أنماط الأزرار ========================
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // ======================== أنماط المدخلات ========================
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),

        // ======================== أنماط البطاقات ========================
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // ======================== أنماط شريط التطبيق ========================
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
        ),
      },

      // ======================== الحالة الأولية ========================
      home: _buildHome(),

      // ======================== التوجيه (Navigation) ========================
      routes: {
        '/setup': (context) => BatchSetupScreen(
          storageService: storageService,
        ),
        '/dashboard': (context) => DashboardScreen(
          storageService: storageService,
        ),
        '/daily-record': (context) {
          final batchId = ModalRoute.of(context)?.settings.arguments as String?;
          return _DailyRecordPlaceholder(
            batchId: batchId,
            storageService: storageService,
          );
        },
      },

      // ======================== معالجة المسارات المجهولة ========================
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    // التحقق من وجود دورة نشطة
    final hasActiveBatch = storageService.hasActiveBatch();
    
    return hasActiveBatch
        ? DashboardScreen(storageService: storageService)
        : BatchSetupScreen(storageService: storageService);
  }
}

// ============================================
// عنصر مؤقت - لصفحة السجل اليومي
// ============================================

class _DailyRecordPlaceholder extends StatelessWidget {
  final String? batchId;
  final LocalStorageService storageService;

  const _DailyRecordPlaceholder({
    Key? key,
    this.batchId,
    required this.storageService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل البيانات اليومية'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('سيتم تطوير صفحة تسجيل البيانات اليومية'),
            const SizedBox(height: 16),
            Text('معرف الدورة: $batchId'),
          ],
        ),
      ),
    );
  }
}
