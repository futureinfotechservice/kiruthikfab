import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../models/source_master_model.dart';

import '../../services/source_apiservice.dart';
import '../models/call_register_model.dart';
import '../services/call_register_service.dart';
import 'add_call_register_screen.dart';

class CallRegisterScreen extends StatefulWidget {
  const CallRegisterScreen({super.key});

  @override
  State<CallRegisterScreen> createState() => _CallRegisterScreenState();
}

class _CallRegisterScreenState extends State<CallRegisterScreen> {
  List<CallRegisterModel> records = [];
  List<CallRegisterModel> filtered = [];

  bool loading = true;

  final searchController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      int companyId = int.parse(prefs.getString('companyid')!);

      final data = await CallRegisterService().fetchRecords(companyId);

      if (!mounted) return;

      setState(() {
        records = data;
        filtered = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  void search(String value) {
    applyFilters();
  }

  Widget buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: search,
      decoration: InputDecoration(
        hintText: "Search",
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void applyFilters() {
    setState(() {
      filtered = records.where((record) {
        bool matchesSearch = true;
        bool matchesDate = true;

        if (searchController.text.isNotEmpty) {
          final query = searchController.text.toLowerCase();

          matchesSearch =
              record.entryNo.toLowerCase().contains(query) ||
              record.sourceName.toLowerCase().contains(query) ||
              record.callBy.toLowerCase().contains(query);
        }

        if (fromDate != null || toDate != null) {
          try {
            final recordDateParts = record.date.split('/');

            final recordDate = DateTime(
              int.parse(recordDateParts[2]),
              int.parse(recordDateParts[1]),
              int.parse(recordDateParts[0]),
            );

            if (fromDate != null) {
              matchesDate =
                  matchesDate &&
                  !recordDate.isBefore(
                    DateTime(fromDate!.year, fromDate!.month, fromDate!.day),
                  );
            }

            if (toDate != null) {
              matchesDate =
                  matchesDate &&
                  !recordDate.isAfter(
                    DateTime(
                      toDate!.year,
                      toDate!.month,
                      toDate!.day,
                      23,
                      59,
                      59,
                    ),
                  );
            }
          } catch (_) {
            matchesDate = false;
          }
        }

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  Widget buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime) onSelected,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );

        if (date != null) {
          onSelected(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(Icons.calendar_month),
        ),
        child: Text(
          value == null ? '' : '${value.day}/${value.month}/${value.year}',
        ),
      ),
    );
  }

  Future<void> showUpdateDialog(CallRegisterModel item) async {
    final SourceApiService apiService = SourceApiService();

    List<SourceMasterModel> sources = [];
    List<Map<String, dynamic>> agents = [];
    final sources1 = await apiService.fetchSources(context);
    final agent = await apiService.fetchEntryPersons(context);
    setState(() {
      sources = sources1;
      agents = agent;
    });
    final feedbackController = TextEditingController(text: item.feedback);

    final notesController = TextEditingController(text: item.notes);

    SourceMasterModel? selectedSource = sources.firstWhere(
      (e) => e.name == item.sourceName,
      orElse: () => sources.first,
    );

    Map<String, dynamic>? selectedAgent = agents.firstWhere(
      (e) => e['name'] == item.callBy,
      orElse: () => agents.first,
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${item.entryNo}'),

              content: SizedBox(
                width: 500,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<SourceMasterModel>(
                        value: selectedSource,
                        decoration: const InputDecoration(labelText: 'Source'),
                        items: sources.map((e) {
                          return DropdownMenuItem(
                            value: e,
                            child: Text(e.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedSource = value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: selectedAgent,
                        decoration: const InputDecoration(labelText: 'Call By'),
                        items: agents.map((e) {
                          return DropdownMenuItem(
                            value: e,
                            child: Text(e['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedAgent = value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: feedbackController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Feedback',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: notesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final res = await CallRegisterService().updateCallRegister(
                      id: item.id,
                      sourceId: int.parse(selectedSource!.id),
                      callById: int.parse(selectedAgent!['id'].toString()),

                      feedback: feedbackController.text,
                      notes: notesController.text,
                    );

                    if (res['status'] == true) {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(SnackBar(content: Text(res['message'])));

                      load();
                    } else {
                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(SnackBar(content: Text(res['message'])));
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 700;
    final medium =
        MediaQuery.of(context).size.width < 700 &&
        MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: const Color(0xff1E293B),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            mobile
                                ? const Text(
                                    'Entry Records Management',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const Text(
                                    'Entry Records Management',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            const SizedBox(height: 8),
                            mobile
                                ? const Text(
                                    'View, filter, add and manage\nall entry records',
                                    style: TextStyle(color: Colors.white70),
                                  )
                                : const Text(
                                    'View, filter, add and manage all entry records',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            load();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  mobile
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: buildDateField(
                                    label: 'From Date',
                                    value: fromDate,
                                    onSelected: (d) {
                                      setState(() {
                                        fromDate = d;
                                        applyFilters();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildDateField(
                                    label: 'To Date',
                                    value: toDate,
                                    onSelected: (d) {
                                      setState(() {
                                        toDate = d;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(child: buildSearchField()),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      fromDate = null;
                                      toDate = null;
                                      searchController.clear();
                                      filtered = records;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.black,
                                  ),
                                  label: const Text(
                                    "Clear",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                IconButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    fixedSize: Size(80, 55),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AddCallRegisterScreen(),
                                      ),
                                    ).then((_) => load());
                                  },

                                  icon: Icon(Icons.add, size: 40),
                                ),
                              ],
                            ),
                          ],
                        )
                      : mobile
                      ? Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: buildDateField(
                                    label: 'From Date',
                                    value: fromDate,
                                    onSelected: (d) {
                                      setState(() {
                                        fromDate = d;
                                        applyFilters();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 180,
                                  child: buildDateField(
                                    label: 'To Date',
                                    value: toDate,
                                    onSelected: (d) {
                                      setState(() {
                                        toDate = d;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: buildSearchField()),
                                const SizedBox(width: 20),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      fromDate = null;
                                      toDate = null;
                                      searchController.clear();
                                      filtered = records;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.black,
                                  ),
                                  label: const Text(
                                    "Clear",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 20),

                                SizedBox(
                                  width: 80,
                                  child: IconButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      fixedSize: Size(80, 55),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const AddCallRegisterScreen(),
                                        ),
                                      ).then((_) => load());
                                    },

                                    icon: Icon(Icons.add, size: 40),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            SizedBox(
                              width: 180,
                              child: buildDateField(
                                label: 'From Date',
                                value: fromDate,
                                onSelected: (d) {
                                  setState(() {
                                    fromDate = d;
                                    applyFilters();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 180,
                              child: buildDateField(
                                label: 'To Date',
                                value: toDate,
                                onSelected: (d) {
                                  setState(() {
                                    toDate = d;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(child: buildSearchField()),
                            const SizedBox(width: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  fromDate = null;
                                  toDate = null;
                                  searchController.clear();
                                  filtered = records;
                                });
                              },
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.black,
                              ),
                              label: const Text(
                                "Clear",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            const SizedBox(width: 20),

                            SizedBox(
                              width: 80,
                              child: IconButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  fixedSize: Size(80, 55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AddCallRegisterScreen(),
                                    ),
                                  ).then((_) => load());
                                },

                                icon: Icon(Icons.add, size: 40),
                              ),
                            ),
                          ],
                        ),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xff1E293B),
                    child: const Text(
                      "Entry Records List",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey.shade200,
                      ),
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('Entry No')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Source')),
                        DataColumn(label: Text('Call By')),
                        DataColumn(label: Text('From')),
                        DataColumn(label: Text('To')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: List.generate(filtered.length, (index) {
                        final item = filtered[index];

                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(item.entryNo),
                              ),
                            ),
                            DataCell(Text(item.date)),
                            DataCell(Text(item.sourceName)),
                            DataCell(Text(item.callBy)),
                            DataCell(Text(item.fromTime)),
                            DataCell(Text(item.toTime)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      showUpdateDialog(item);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text(
                                              "Are you sure you want to delete?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("No"),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  final res =
                                                      await CallRegisterService()
                                                          .deleteCallRegister(
                                                            item.id,
                                                          );
                                                  if (res['status'] == true) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          res['message'],
                                                        ),
                                                      ),
                                                    );
                                                    load();
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                child: const Text("Yes"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
