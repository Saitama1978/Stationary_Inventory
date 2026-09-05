import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const StationeryApp());
}

class StationeryApp extends StatefulWidget {
  const StationeryApp({super.key});

  @override
  State<StationeryApp> createState() => _StationeryAppState();
}

class _StationeryAppState extends State<StationeryApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stationery Inventory',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: InventoryHomePage(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class InventoryItem {
  String name;
  String category;
  String unit;
  int quantity;

  InventoryItem({
    required this.name,
    required this.category,
    required this.unit,
    required this.quantity,
  });
}

class InventoryHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const InventoryHomePage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final List<InventoryItem> _items = [
    InventoryItem(
      name: 'Notebook A5',
      category: 'Paper',
      unit: 'pcs',
      quantity: 25,
    ),
    InventoryItem(
      name: 'Ballpen Black',
      category: 'Writing',
      unit: 'box',
      quantity: 10,
    ),
  ];

  final List<String> _categories = [
    'General',
    'Writing',
    'Paper',
    'Art Supplies',
    'Office Equipment',
  ];

  final List<String> _units = [
    'pcs',
    'box',
    'pack',
    'set',
    'roll',
    'pad',
    'ream',
    'bottle',
    'can',
    'pair',
    'cartridge',
    'tube',
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  String _selectedCategory = 'General';
  String _selectedUnit = 'pcs';

  void _showItemDialog({InventoryItem? itemToEdit, int? editIndex}) {
    if (itemToEdit != null) {
      _nameController.text = itemToEdit.name;
      _qtyController.text = itemToEdit.quantity.toString();
      _selectedCategory = itemToEdit.category;
      _selectedUnit = itemToEdit.unit;
    } else {
      _nameController.clear();
      _qtyController.clear();
      _selectedCategory = _categories.first;
      _selectedUnit = _units.first;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(itemToEdit == null ? 'Add New Item' : 'Edit Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                          ),
                          items: _units.map((u) {
                            return DropdownMenuItem(value: u, child: Text(u));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => _selectedUnit = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final String name = _nameController.text.trim();
                  final int? qty = int.tryParse(_qtyController.text);

                  if (name.isNotEmpty && qty != null) {
                    setState(() {
                      if (itemToEdit != null && editIndex != null) {
                        _items[editIndex] = InventoryItem(
                          name: name,
                          category: _selectedCategory,
                          unit: _selectedUnit,
                          quantity: qty,
                        );
                      } else {
                        _items.add(
                          InventoryItem(
                            name: name,
                            category: _selectedCategory,
                            unit: _selectedUnit,
                            quantity: qty,
                          ),
                        );
                      }
                    });
                    _nameController.clear();
                    _qtyController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeveloperInfo() {
    showAboutDialog(
      context: context,
      applicationName: 'Stationery Inventory',
      applicationVersion: '1.3.1',
      applicationIcon: const Icon(Icons.inventory, size: 48),
      children: const [
        Text('Developer: 2/O Renante N. Fullo'),
        SizedBox(height: 8),
        Text('A mobile application designed for efficient inventory management.'),
      ],
    );
  }

  Future<void> _exportAndSaveCSV() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Walang items sa listahan para i-save.')),
      );
      return;
    }

    final TextEditingController fileNameController =
        TextEditingController(text: 'Stationery_Inventory');

    String? finalFileName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Inventory File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maglagay ng pangalan ng file:'),
            const SizedBox(height: 10),
            TextField(
              controller: fileNameController,
              decoration: const InputDecoration(
                labelText: 'File Name',
                border: OutlineInputBorder(),
                suffixText: '.csv',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              String name = fileNameController.text.trim();
              if (name.isEmpty) name = 'Stationery_Inventory';
              Navigator.pop(dialogContext, name);
            },
            child: const Text('Choose Folder'),
          ),
        ],
      ),
    );

    if (finalFileName == null) return;
    if (!finalFileName.endsWith('.csv')) finalFileName = '$finalFileName.csv';

    List<List<dynamic>> rows = [
      ['Item Name', 'Category', 'Quantity', 'Unit'],
      ..._items.map(
        (item) => [item.name, item.category, item.quantity, item.unit],
      ),
    ];
    String csvData = const ListToCsvConverter().convert(rows);

    try {
      final bytes = Uint8List.fromList(utf8.encode(csvData));

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Pumili ng Folder kung saan i-se-save:',
        fileName: finalFileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Matagumpay na na-save sa:\n$outputFile'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sa pag-save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCSVFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final input = await file.readAsString();
        final List<List<dynamic>> fields =
            const CsvToListConverter().convert(input);

        if (fields.length > 1) {
          List<InventoryItem> loadedItems = [];
          for (int i = 1; i < fields.length; i++) {
            final row = fields[i];
            if (row.length >= 4) {
              loadedItems.add(
                InventoryItem(
                  name: row[0].toString(),
                  category: row[1].toString(),
                  quantity: int.tryParse(row[2].toString()) ?? 0,
                  unit: row[3].toString(),
                ),
              );
            } else if (row.length >= 2) {
              loadedItems.add(
                InventoryItem(
                  name: row[0].toString(),
                  category: 'General',
                  quantity: int.tryParse(row[1].toString()) ?? 0,
                  unit: 'pcs',
                ),
              );
            }
          }

          setState(() {
            _items.clear();
            _items.addAll(loadedItems);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Matagumpay na na-load ang inventory!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sa pag-load ng file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Stationery Inventory Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Developer: 2/O Renante N. Fullo',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Item Name', 'Category', 'Qty', 'Unit'],
                data: _items
                    .map((item) => [
                          item.name,
                          item.category,
                          item.quantity.toString(),
                          item.unit,
                        ])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategoryFilter == 'All' ||
          item.category == _selectedCategoryFilter;

      return matchesSearch && matchesCategory;
    }).toList();

    int totalQuantity = _items.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    List<String> filterCategories = ['All', ..._categories];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stationery Inventory'),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: 'Toggle Dark Mode',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Load CSV File',
            onPressed: _loadCSVFile,
          ),
          IconButton(
            icon: const Icon(Icons.save_as),
            tooltip: 'Save As CSV File',
            onPressed: _exportAndSaveCSV,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print / Save PDF',
            onPressed: _generatePdfReport,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'developer') {
                _showDeveloperInfo();
              } else if (value == 'clear') {
                setState(() => _items.clear());
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'developer',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Developer Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear List'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Items: ${_items.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total Quantity: $totalQuantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterCategories.map((cat) {
                      final isSelected = _selectedCategoryFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryFilter = cat;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text('Walang nahanap na items.'))
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final bool isLowStock = item.quantity <= 5;
                      final originalIndex = _items.indexOf(item);

                      return ListTile(
                        onTap: () => _showItemDialog(
                          itemToEdit: item,
                          editIndex: originalIndex,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              isLowStock ? Colors.red.shade100 : null,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isLowStock ? Colors.red : null,
                            ),
                          ),
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.category}'
                          '${isLowStock ? ' • Low Stock Alert' : ''}',
                          style: TextStyle(
                            color: isLowStock ? Colors.red : null,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.quantity} ${item.unit}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isLowStock ? Colors.red : null,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showItemDialog(
                                itemToEdit: item,
                                editIndex: originalIndex,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _items.remove(item);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}
