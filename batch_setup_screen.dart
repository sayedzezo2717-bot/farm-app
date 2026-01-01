import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'local_storage_service.dart';

// ============================================
// شاشة إعداد الدورة الأولى
// ============================================

class BatchSetupScreen extends StatefulWidget {
  final LocalStorageService storageService;

  const BatchSetupScreen({
    Key? key,
    required this.storageService,
  }) : super(key: key);

  @override
  State<BatchSetupScreen> createState() => _BatchSetupScreenState();
}

class _BatchSetupScreenState extends State<BatchSetupScreen> {
  // متغيرات التحكم في النموذج
  ProductionType? _selectedProductionType;
  String? _selectedBreedId;
  List<Breed> _availableBreeds = [];
  
  int _selectedAge = 0;
  int _ageUnit = 0; // 0 = أيام، 1 = أسابيع
  
  int _totalBirdCount = 0;
  
  List<CageBattery> _cages = [];
  String _farmName = 'مزرعتي';
  String _notes = '';
  
  // متحكمات الإدخال
  late TextEditingController _ageController;
  late TextEditingController _totalBirdsController;
  late TextEditingController _farmNameController;
  late TextEditingController _notesController;
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController();
    _totalBirdsController = TextEditingController();
    _farmNameController = TextEditingController(text: _farmName);
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _totalBirdsController.dispose();
    _farmNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ============================================
  // معالجات التغييرات
  // ============================================

  /// عند اختيار نوع الإنتاج
  void _onProductionTypeChanged(ProductionType? type) {
    setState(() {
      _selectedProductionType = type;
      _selectedBreedId = null;
      _errorMessage = null;
      
      if (type != null) {
        _availableBreeds = Breed.getBreedsByType(type);
      } else {
        _availableBreeds = [];
      }
    });
  }

  /// عند اختيار السلالة
  void _onBreedChanged(String? breedId) {
    setState(() {
      _selectedBreedId = breedId;
      _errorMessage = null;
    });
  }

  /// عند تغيير العمر
  void _onAgeChanged(String value) {
    setState(() {
      _selectedAge = int.tryParse(value) ?? 0;
      _errorMessage = null;
    });
  }

  /// عند تغيير وحدة العمر
  void _onAgeUnitChanged(int? value) {
    setState(() {
      _ageUnit = value ?? 0;
      _errorMessage = null;
    });
  }

  /// عند تغيير العدد الكلي
  void _onTotalBirdsChanged(String value) {
    setState(() {
      _totalBirdCount = int.tryParse(value) ?? 0;
      _errorMessage = null;
    });
  }

  // ============================================
  // إدارة البطاريات/الأقفاص
  // ============================================

  void _addCageBattery() {
    showDialog(
      context: context,
      builder: (context) => _CageInputDialog(
        onCageAdded: (cage) {
          setState(() {
            _cages.add(cage);
            _errorMessage = null;
          });
        },
      ),
    );
  }

  void _removeCage(int index) {
    setState(() {
      _cages.removeAt(index);
    });
  }

  void _editCage(int index) {
    showDialog(
      context: context,
      builder: (context) => _CageInputDialog(
        initialCage: _cages[index],
        onCageAdded: (cage) {
          setState(() {
            _cages[index] = cage;
          });
        },
      ),
    );
  }

  // ============================================
  // التحقق من صحة المدخلات
  // ============================================

  String? _validateInputs() {
    // التحقق من اختيار نوع الإنتاج
    if (_selectedProductionType == null) {
      return 'يرجى اختيار نوع الإنتاج';
    }

    // التحقق من اختيار السلالة
    if (_selectedBreedId == null) {
      return 'يرجى اختيار السلالة';
    }

    // التحقق من العمر
    if (_selectedAge <= 0) {
      return 'يرجى إدخال عمر صحيح';
    }

    // التحقق من العدد الكلي
    if (_totalBirdCount <= 0) {
      return 'يرجى إدخال عدد الطيور';
    }

    // التحقق من عدم زيادة الأقفاص عن الإجمالي
    if (_cages.isNotEmpty) {
      final totalInCages = _cages.fold<int>(0, (sum, cage) => sum + cage.birdCount);
      if (totalInCages != _totalBirdCount) {
        return 'إجمالي الطيور في الأقفاص (${totalInCages}) يجب أن يساوي الإجمالي المدخل (${_totalBirdCount})';
      }

      // التحقق من الكثافة
      for (var cage in _cages) {
        if (!cage.isDensitySafe) {
          return 'كثافة ${cage.name} غير آمنة! المعدل الآمن: 8-15 طائر/متر مربع';
        }
      }
    }

    return null;
  }

  // ============================================
  // حفظ الإعدادات
  // ============================================

  Future<void> _saveBatchConfig() async {
    // التحقق من الصحة
    final error = _validateInputs();
    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // تحويل الأسابيع إلى أيام إذا لزم الأمر
      final ageInDays = _ageUnit == 0 ? _selectedAge : _selectedAge * 7;

      // إنشاء كائن BatchConfig
      final batchConfig = BatchConfig(
        id: const Uuid().v4(),
        productionType: _selectedProductionType!,
        breedId: _selectedBreedId!,
        startDate: DateTime.now(),
        initialAge: ageInDays,
        totalBirdCount: _totalBirdCount,
        cages: _cages,
        farmName: _farmNameController.text.isNotEmpty
            ? _farmNameController.text
            : 'مزرعتي',
        notes: _notesController.text,
      );

      // حفظ في قاعدة البيانات المحلية
      await widget.storageService.saveBatchConfig(batchConfig);

      // عرض رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ تم إنشاء الدورة بنجاح!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // الانتقال إلى لوحة التحكم
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في حفظ الإعدادات: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================
  // بناء واجهة المستخدم
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد دورة جديدة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.amber.shade700,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // رسالة الخطأ
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // =============== 1. نوع الإنتاج ===============
                  _buildSectionTitle('1️⃣ نوع الإنتاج'),
                  _buildProductionTypeSelector(),
                  const SizedBox(height: 24),

                  // =============== 2. اختيار السلالة ===============
                  _buildSectionTitle('2️⃣ اختيار السلالة'),
                  _buildBreedSelector(),
                  const SizedBox(height: 24),

                  // =============== 3. العمر ===============
                  _buildSectionTitle('3️⃣ عمر الطائر'),
                  _buildAgeInput(),
                  const SizedBox(height: 24),

                  // =============== 4. عدد الطيور ===============
                  _buildSectionTitle('4️⃣ عدد الطيور'),
                  _buildBirdCountInput(),
                  const SizedBox(height: 24),

                  // =============== 5. البطاريات/الأقفاص ===============
                  _buildSectionTitle('5️⃣ توزيع البطاريات/الأقفاص'),
                  _buildCagesManager(),
                  const SizedBox(height: 24),

                  // =============== 6. معلومات إضافية ===============
                  _buildSectionTitle('6️⃣ معلومات إضافية'),
                  _buildAdditionalInfo(),
                  const SizedBox(height: 32),

                  // =============== زر الحفظ ===============
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveBatchConfig,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('بدء الدورة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // شريط التحميل
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================
  // مكونات الواجهة
  // ============================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProductionTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildProductionTypeOption(
            ProductionType.layer,
            '🐓 إنتاج البيض',
            'الدجاج البلدي، اللوهمن، إيزا براون',
          ),
          Divider(height: 0, color: Colors.grey.shade300),
          _buildProductionTypeOption(
            ProductionType.broiler,
            '🍗 إنتاج اللحم',
            'كوب، روس، ساسو',
          ),
        ],
      ),
    );
  }

  Widget _buildProductionTypeOption(
    ProductionType type,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedProductionType == type;
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.amber.shade100,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Radio<ProductionType>(
        value: type,
        groupValue: _selectedProductionType,
        onChanged: _onProductionTypeChanged,
      ),
      onTap: () => _onProductionTypeChanged(type),
    );
  }

  Widget _buildBreedSelector() {
    if (_selectedProductionType == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'اختر نوع الإنتاج أولاً',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: const Text('اختر السلالة'),
        value: _selectedBreedId,
        onChanged: _onBreedChanged,
        items: _availableBreeds.map((breed) {
          return DropdownMenuItem<String>(
            value: breed.id,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breed.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (_selectedBreedId == breed.id)
                  Text(
                    _getBreedDescription(breed),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getBreedDescription(Breed breed) {
    if (breed.type == ProductionType.broiler) {
      return 'متوسط الوزن اليومي: ${breed.avgDailyGain} جرام | الدورة: ${breed.productionCycleDays} يوم';
    } else {
      return 'ذروة الإنتاج: ${breed.peakEggProduction.toStringAsFixed(1)}% | مدة الإنتاج: ${breed.productionCycleDays} يوم';
    }
  }

  Widget _buildAgeInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            onChanged: _onAgeChanged,
            decoration: InputDecoration(
              hintText: 'العمر',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.calendar_today),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            underline: const SizedBox.shrink(),
            value: _ageUnit,
            onChanged: _onAgeUnitChanged,
            items: const [
              DropdownMenuItem(value: 0, child: Text('أيام')),
              DropdownMenuItem(value: 1, child: Text('أسابيع')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBirdCountInput() {
    return TextField(
      controller: _totalBirdsController,
      keyboardType: TextInputType.number,
      onChanged: _onTotalBirdsChanged,
      decoration: InputDecoration(
        hintText: 'إدخل عدد الطيور الكلي',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.pets),
      ),
    );
  }

  Widget _buildCagesManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_cages.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 يمكنك إضافة بطاريات/أقفاص لتوزيع الطيور (اختياري)',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 13,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cages.length,
              separatorBuilder: (_, __) => Divider(height: 0),
              itemBuilder: (context, index) {
                final cage = _cages[index];
                return ListTile(
                  title: Text(cage.name),
                  subtitle: Text(
                    '${cage.birdCount} طائر | ${cage.cageArea.toStringAsFixed(1)} م² | الكثافة: ${cage.stocking_density.toStringAsFixed(2)} طائر/م²',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editCage(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeCage(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addCageBattery,
          icon: const Icon(Icons.add),
          label: const Text('إضافة بطارية/قفص'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _farmNameController,
          decoration: InputDecoration(
            labelText: 'اسم المزرعة',
            hintText: 'مثل: مزرعتي، مزرعة الوادي',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'ملاحظات إضافية',
            hintText: 'أي معلومات إضافية عن الدورة',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.notes),
          ),
        ),
      ],
    );
  }
}

// ============================================
// حوار إضافة/تعديل البطارية
// ============================================

class _CageInputDialog extends StatefulWidget {
  final CageBattery? initialCage;
  final Function(CageBattery) onCageAdded;

  const _CageInputDialog({
    Key? key,
    this.initialCage,
    required this.onCageAdded,
  }) : super(key: key);

  @override
  State<_CageInputDialog> createState() => _CageInputDialogState();
}

class _CageInputDialogState extends State<_CageInputDialog> {
  late TextEditingController _nameController;
  late TextEditingController _birdCountController;
  late TextEditingController _areaController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCage?.name ?? '',
    );
    _birdCountController = TextEditingController(
      text: widget.initialCage?.birdCount.toString() ?? '',
    );
    _areaController = TextEditingController(
      text: widget.initialCage?.cageArea.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birdCountController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _onAddCage() {
    final name = _nameController.text.trim();
    final birdCount = int.tryParse(_birdCountController.text) ?? 0;
    final area = double.tryParse(_areaController.text) ?? 0;

    if (name.isEmpty || birdCount <= 0 || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول بشكل صحيح'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cage = CageBattery(
      id: widget.initialCage?.id ?? const Uuid().v4(),
      name: name,
      birdCount: birdCount,
      cageArea: area,
    );

    widget.onCageAdded(cage);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialCage == null ? 'إضافة بطارية' : 'تعديل البطارية',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم البطارية/القفص',
                hintText: 'مثل: بطارية 1، الدور الأول',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _birdCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'عدد الطيور',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _areaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'مساحة البطارية (متر مربع)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _onAddCage,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
