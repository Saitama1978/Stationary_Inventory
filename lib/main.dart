import 'dart:io';
import 'dart:convert';
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
  double price;

  InventoryItem({
    required this.name,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.price,
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
      price: 45.00,
    ),
    InventoryItem(
      name: 'Ballpen Black',
      category: 'Writing',
      unit: 'pcs',
      quantity: 100,
      price: 12.00,
    ),
  ];

  final List<String> _categories = [
    'General',
    'Writing',
    'Paper',
    'Art Supplies',
    'Office Equipment',
  ];

  final List<String> _units = ['pcs', 'box', 'pack', 'set', 'roll'];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedCategory = 'General';
  String _selectedUnit = 'pcs';

  void _addItem() {
    final String name = _nameController.text.trim();
    final int? qty = int.tryParse(_qtyController.text);
    final double? price = double.tryParse(_priceController.text);

    if (name.isNotEmpty && qty != null && price != null) {
      setState(() {
        _items.add(
          InventoryItem(
            name: name,
            category: _selectedCategory,
            unit: _selectedUnit,
            quantity: qty,
            price: price,
          ),
        );
      });
      _nameController.clear();
      _qtyController.clear();
      _priceController.clear();
      _selectedCategory = 'General';
      _selectedUnit = 'pcs';
      Navigator.pop(context);
    }
  }

  void _showAddItemDialog() {
    _selectedCategory = _categories.first;
    _selectedUnit = _units.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Item'),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price (PHP)',
                      border: OutlineInputBorder(),
                    ),
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
                onPressed: _addItem,
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
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.inventory, size: 48),
      children: const [
        Text('Developer: Kenneth Quintero'),
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
      ['Item Name', 'Category', 'Unit', 'Quantity', 'Price'],
      ..._items.map(
        (item) =>
            [item.name, item.category, item.unit, item.quantity, item.price],
      ),
    ];
    String csvData = const ListToCsvConverter().convert(rows);

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Pumili ng Folder kung saan i-se-save:',
        fileName: finalFileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csvData);

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
            if (row.length >= 5) {
              loadedItems.add(
                InventoryItem(
                  name: row[0].toString(),
                  category: row[1].toString(),
                  unit: row[2].toString(),
                  quantity: int.tryParse(row[3].toString()) ?? 0,
                  price: double.tryParse(row[4].toString()) ?? 0.0,
                ),
              );
            } else if (row.length >= 3) {
              loadedItems.add(
                InventoryItem(
                  name: row[0].toString(),
                  category: 'General',
                  unit: 'pcs',
                  quantity: int.tryParse(row[1].toString()) ?? 0,
                  price: double.tryParse(row[2].toString()) ?? 0.0,
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
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Item Name', 'Category', 'Qty', 'Unit', 'Price (PHP)'],
                data: _items
                    .map((item) => [
                          item.name,
                          item.category,
                          item.quantity.toString(),
                          item.unit,
                          item.price.toStringAsFixed(2)
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
      body: _items.isEmpty
          ? const Center(child: Text('Walang laman ang inventory.'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.category} • Qty: ${item.quantity} ${item.unit}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₱${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _items.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}
