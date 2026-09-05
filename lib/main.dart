import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const StationeryApp());
}

class StationeryApp extends StatelessWidget {
  const StationeryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stationery Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const InventoryHomePage(),
    );
  }
}

class InventoryItem {
  String name;
  int quantity;
  double price;

  InventoryItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}

class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({super.key});

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final List<InventoryItem> _items = [
    InventoryItem(name: 'Notebook A5', quantity: 25, price: 45.00),
    InventoryItem(name: 'Ballpen Black', quantity: 100, price: 12.00),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void _addItem() {
    final String name = _nameController.text.trim();
    final int? qty = int.tryParse(_qtyController.text);
    final double? price = double.tryParse(_priceController.text);

    if (name.isNotEmpty && qty != null && price != null) {
      setState(() {
        _items.add(InventoryItem(name: name, quantity: qty, price: price));
      });
      _nameController.clear();
      _qtyController.clear();
      _priceController.clear();
      Navigator.pop(context);
    }
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (PHP)'),
            ),
          ],
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
      ),
    );
  }

  // 1. SAVE AS / EXPORT TO CSV FUNCTION WITH CUSTOM NAME & FOLDER SELECTION
  Future<void> _exportAndSaveCSV() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Walang items sa listahan para i-save.')),
      );
      return;
    }

    // A. Ask File Name Dialog
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

    // B. Build CSV Data
    List<List<dynamic>> rows = [
      ['Item Name', 'Quantity', 'Price'],
      ..._items.map((item) => [item.name, item.quantity, item.price]),
    ];
    String csvData = const ListToCsvConverter().convert(rows);

    // C. Pick Folder Location and Save
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

  // 2. LOAD CSV FILE TO APP
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
            if (row.length >= 3) {
              loadedItems.add(
                InventoryItem(
                  name: row[0].toString(),
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

  // 3. PRINT / GENERATE PDF REPORT
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
                headers: ['Item Name', 'Quantity', 'Price (PHP)'],
                data: _items
                    .map((item) => [
                          item.name,
                          item.quantity.toString(),
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
                  subtitle: Text('Qty: ${item.quantity}'),
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
