import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
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
  bool isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stationery Inventory',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: InventoryScreen(
        isDarkMode: isDarkMode,
        onThemeChanged: () {
          setState(() {
            isDarkMode = !isDarkMode;
          });
        },
      ),
    );
  }
}

class InventoryItem {
  String name;
  int quantity;
  String unit;
  String remarks;

  InventoryItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.remarks,
  });
}

class InventoryScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;

  const InventoryScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<String> presetItems = [
    'A4 Paper',
    'Ballpen (Blue)',
    'Ballpen (Black)',
    'Ballpen (Red)',
    'Pencil',
    'Eraser',
    'Stapler',
    'Staple Wire',
    'Paper Clip',
    'Folder',
    'Envelope',
    'Correction Tape',
    'OTHER'
  ];

  final List<String> presetUnits = [
    'pcs',
    'box',
    'pack',
    'ream',
    'roll',
    'set',
    'OTHER'
  ];

  String? selectedItem = 'A4 Paper';
  String customItem = '';
  int quantity = 1;
  String? selectedUnit = 'pcs';
  String customUnit = '';
  String remarks = '';

  List<InventoryItem> inventoryList = [];

  void _addItem() {
    String finalItem = (selectedItem == 'OTHER') ? customItem.trim() : (selectedItem ?? '');
    String finalUnit = (selectedUnit == 'OTHER') ? customUnit.trim() : (selectedUnit ?? '');

    if (finalItem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paki-pili o paki-type ang item!')),
      );
      return;
    }

    setState(() {
      inventoryList.add(InventoryItem(
        name: finalItem,
        quantity: quantity,
        unit: finalUnit.isEmpty ? 'pcs' : finalUnit,
        remarks: remarks,
      ));
      remarks = '';
    });
  }

  void _clearAll() {
    setState(() {
      inventoryList.clear();
    });
  }

  // SAVE TO EXCEL (.CSV)
  Future<void> _exportToExcel() async {
    if (inventoryList.isEmpty) return;

    List<List<dynamic>> rows = [
      ["Item Name", "Quantity", "Unit", "Remarks"],
      ...inventoryList.map((item) => [item.name, item.quantity, item.unit, item.remarks])
    ];

    String csvData = const ListToCsvConverter().convert(rows);

    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Inventory Excel (.csv)',
      fileName: 'stationery_inventory.csv',
    );

    if (outputPath != null) {
      final file = File(outputPath);
      await file.writeAsString(csvData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Na-save sa: $outputPath')),
        );
      }
    }
  }

  // LOAD DATA FROM EXCEL (.CSV)
  Future<void> _loadFromExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final input = await file.readAsString();
      List<List<dynamic>> fields = const CsvToListConverter().convert(input);

      if (fields.length > 1) {
        setState(() {
          inventoryList.clear();
          for (var i = 1; i < fields.length; i++) {
            var row = fields[i];
            if (row.length >= 3) {
              inventoryList.add(InventoryItem(
                name: row[0].toString(),
                quantity: int.tryParse(row[1].toString()) ?? 1,
                unit: row[2].toString(),
                remarks: row.length > 3 ? row[3].toString() : '',
              ));
            }
          }
        });
      }
    }
  }

  // PRINT / SAVE AS PDF
  Future<void> _printOrPdf() async {
    if (inventoryList.isEmpty) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Stationery Inventory Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Developed by: Renante Fullo'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Item Name', 'Quantity', 'Unit', 'Remarks'],
                data: inventoryList.map((i) => [i.name, i.quantity.toString(), i.unit, i.remarks]).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stationery Inventory'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.onThemeChanged,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedItem,
                      decoration: const InputDecoration(labelText: 'Item ng Stationery'),
                      items: presetItems.map((item) {
                        return DropdownMenuItem(value: item, child: Text(item));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedItem = val),
                    ),
                    if (selectedItem == 'OTHER')
                      TextField(
                        decoration: const InputDecoration(labelText: 'I-type ang pangalan ng Item'),
                        onChanged: (val) => customItem = val,
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: '1',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Dami (Quantity)'),
                            onChanged: (val) => quantity = int.tryParse(val) ?? 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: presetUnits.map((u) {
                              return DropdownMenuItem(value: u, child: Text(u));
                            }).toList(),
                            onChanged: (val) => setState(() => selectedUnit = val),
                          ),
                        ),
                      ],
                    ),
                    if (selectedUnit == 'OTHER')
                      TextField(
                        decoration: const InputDecoration(labelText: 'I-type ang Unit'),
                        onChanged: (val) => customUnit = val,
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Remarks / Puna'),
                      onChanged: (val) => remarks = val,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(45),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _addItem,
                      child: const Text('DAGDAG SA LISTAHAN'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Save Excel'),
                ),
                ElevatedButton.icon(
                  onPressed: _printOrPdf,
                  icon: const Icon(Icons.print),
                  label: const Text('Print / PDF'),
                ),
                ElevatedButton.icon(
                  onPressed: _loadFromExcel,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Load File'),
                ),
                OutlinedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete),
                  label: const Text('Burahin Lahat'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text('MGA NAITAALANG ITEM', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            inventoryList.isEmpty
                ? const Text('Walang laman ang listahan')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inventoryList.length,
                    itemBuilder: (ctx, idx) {
                      final item = inventoryList[idx];
                      return Card(
                        child: ListTile(
                          title: Text('${item.name} - ${item.quantity} ${item.unit}'),
                          subtitle: item.remarks.isNotEmpty ? Text(item.remarks) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => inventoryList.removeAt(idx)),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
            const Text('Developed by: Renante Fullo', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
// ==========================================
// PASTE THIS AT THE VERY BOTTOM OF YOUR FILE
// ==========================================
Future<void> exportAndSaveExcel({
  required BuildContext context,
  required List<int> excelBytes,
  String defaultFileName = "Inventory_Report",
}) async {
  TextEditingController fileNameController =
      TextEditingController(text: defaultFileName);

  String? finalFileName = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text("Export Excel File"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAlignment.start,
          children: [
            const Text("Pumili ng pangalan para sa iyong file:"),
            const SizedBox(height: 10),
            TextField(
              controller: fileNameController,
              decoration: const InputDecoration(
                labelText: "File Name",
                border: OutlineInputBorder(),
                suffixText: ".xlsx",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              String name = fileNameController.text.trim();
              if (name.isEmpty) name = defaultFileName;
              Navigator.pop(dialogContext, name);
            },
            child: const Text("Next (Select Folder)"),
          ),
        ],
      );
    },
  );

  if (finalFileName == null) return;

  if (!finalFileName.endsWith('.xlsx')) {
    finalFileName = '$finalFileName.xlsx';
  }

  try {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Pumili ng Folder kung saan i-se-save:',
      fileName: finalFileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsBytes(excelBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Matagumpay na na-save sa:\n$outputFile"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error sa pag-save ng file: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
