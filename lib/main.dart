import 'package:flutter/material.dart';

void main() {
  runApp(const StationeryApp());
}

class StationeryApp extends StatefulWidget {
  const StationeryApp({super.key});

  @override
  State<StationeryApp> createState() => _StationeryAppState();
}

class _StationeryAppState extends State<StationeryApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stationery Inventory',
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
  final String name;
  final int qty;
  final String unit;
  final String remarks;

  InventoryItem({
    required this.name,
    required this.qty,
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
  final List<String> _itemsList = [
    'Ballpen (Black)',
    'Ballpen (Blue)',
    'Ballpen (Red)',
    'Pencil HB',
    'Eraser',
    'Ruler (12 inch)',
    'Correction Tape',
    'A4 Bond Paper (Ream)',
    'Short Bond Paper (Ream)',
    'Long Bond Paper (Ream)',
    'Notebook (Spiral)',
    'Composition Notebook',
    'Sticky Notes 3x3',
    'Highlighter (Yellow)',
    'Paper Clip (Box)',
    'Binder Clip (Box)',
    'Stapler',
    'Scissors',
    'Clear Folder (A4)',
    'Brown Envelope (Long)',
    'OTHER (WALA SA LISTAHAN)'
  ];

  final List<String> _unitsList = [
    'pcs', 'box', 'pack', 'ream', 'pad', 'set', 'roll', 'bottle', 'pair', 'OTHER'
  ];

  String? _selectedItem;
  String _selectedUnit = 'pcs';
  
  final _customItemController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _customUnitController = TextEditingController();
  final _remarksController = TextEditingController();

  final List<InventoryItem> _inventoryData = [];

  void _addItem() {
    String finalItem = _selectedItem ?? '';
    if (finalItem == 'OTHER (WALA SA LISTAHAN)') {
      finalItem = _customItemController.text.trim();
    }

    if (finalItem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pumili o mag-type ng Item!')),
      );
      return;
    }

    int? qty = int.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maglagay ng tamang Qty!')),
      );
      return;
    }

    String finalUnit = _selectedUnit;
    if (finalUnit == 'OTHER') {
      finalUnit = _customUnitController.text.trim();
    }

    setState(() {
      _inventoryData.add(
        InventoryItem(
          name: finalItem,
          qty: qty,
          unit: finalUnit.isEmpty ? 'pcs' : finalUnit,
          remarks: _remarksController.text.isEmpty ? '-' : _remarksController.text,
        ),
      );

      // Reset form
      _selectedItem = null;
      _customItemController.clear();
      _qtyController.text = '1';
      _selectedUnit = 'pcs';
      _customUnitController.clear();
      _remarksController.clear();
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _inventoryData.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _inventoryData.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stationery Inventory'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeChanged,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FORM INPUTS
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Item Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Item ng Stationery'),
                      value: _selectedItem,
                      items: _itemsList.map((item) {
                        return DropdownMenuItem(value: item, child: Text(item));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedItem = val;
                        });
                      },
                    ),
                    if (_selectedItem == 'OTHER (WALA SA LISTAHAN)')
                      TextField(
                        controller: _customItemController,
                        decoration: const InputDecoration(labelText: 'I-type ang bagong Item Name'),
                      ),
                    const SizedBox(height: 10),
                    
                    // Qty and Unit
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Dami (Quantity)'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Unit'),
                            value: _selectedUnit,
                            items: _unitsList.map((unit) {
                              return DropdownMenuItem(value: unit, child: Text(unit));
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedUnit = val!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_selectedUnit == 'OTHER')
                      TextField(
                        controller: _customUnitController,
                        decoration: const InputDecoration(labelText: 'I-type ang Custom Unit'),
                      ),
                    const SizedBox(height: 10),

                    // Remarks
                    TextField(
                      controller: _remarksController,
                      decoration: const InputDecoration(labelText: 'Remarks / Puna'),
                    ),
                    const SizedBox(height: 15),

                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        onPressed: _addItem,
                        child: const Text('DAGDAG SA LISTAHAN'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TABLE HEADER & CLEAR ALL
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MGA NAITAALANG ITEM', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_inventoryData.isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: _clearAll,
                    child: const Text('BURAHIN LAHAT'),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // DATA TABLE
            _inventoryData.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Walang laman ang listahan')))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('No.')),
                        DataColumn(label: Text('Item Description')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Remarks')),
                        DataColumn(label: Text('Aksyon')),
                      ],
                      rows: List.generate(_inventoryData.length, (index) {
                        final item = _inventoryData[index];
                        return DataRow(cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(item.name)),
                          DataCell(Text('${item.qty}')),
                          DataCell(Text(item.unit)),
                          DataCell(Text(item.remarks)),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(index),
                            ),
                          ),
                        ]);
                      }),
                    ),
                  ),

            const SizedBox(height: 30),
            const Center(
              child: Text(
                'Developed by: Renante Fullo',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
