import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/source_master_model.dart';

import '../../services/source_apiservice.dart';
import '../services/call_register_service.dart';

class AddCallRegisterScreen extends StatefulWidget {
  const AddCallRegisterScreen({super.key});

  @override
  State<AddCallRegisterScreen> createState() => _AddCallRegisterScreenState();
}

class _AddCallRegisterScreenState extends State<AddCallRegisterScreen> {
  final SourceApiService _apiService = SourceApiService();

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController feedbackController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final entryNoController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;

  SourceMasterModel? selectedSource;
  Map<String, dynamic>? selectedAgent;

  List<Map<String, dynamic>> agents = [];
  Map<String, dynamic> callRegisters = {};
  List<SourceMasterModel> sources = [];
  @override
  initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    setState(() {
      _isLoading = true;

      feedbackController.clear();
      notesController.clear();
      entryNoController.clear();
      selectedDate = null;
      fromTime = null;
      toTime = null;

      selectedSource = null;
      selectedAgent = null;
    });

    final res = await CallRegisterService().fetchCallRegister();

    final sources1 = await _apiService.fetchSources(context);
    final agent = await _apiService.fetchEntryPersons(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyName = prefs.getString('companyname') ?? '';

    if (res['call_register'] == null) {
      final lastEntry = res['other_entry_no']?['entry_no'];

      entryNoController.text = generateEntryNo(lastEntry, companyName);
    } else {
      entryNoController.text = generateEntryNo(
        res['call_register']['entry_no'],
        companyName,
      );
    }

    setState(() {
      callRegisters = res;
      sources = sources1;
      agents = agent;
      _isLoading = false;
    });
  }

  String getCompanyPrefix(String companyName) {
    final words = companyName.trim().split(RegExp(r'\s+'));

    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }

    return companyName.substring(0, 2).toUpperCase();
  }

  String generateEntryNo(String? lastEntryNo, String companyName) {
    final prefix = getCompanyPrefix(companyName);
    final year = DateTime.now().year;

    int nextSequence = 1;

    if (lastEntryNo != null && lastEntryNo.isNotEmpty) {
      final parts = lastEntryNo.split('-');

      if (parts.length == 3) {
        nextSequence = int.parse(parts[2]) + 1;
      }
    }

    return '$prefix-$year-${nextSequence.toString().padLeft(4, '0')}';
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: selectedDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> pickFromTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: fromTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        fromTime = time;
      });
    }
  }

  Future<void> pickToTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: toTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        toTime = time;
      });
    }
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    final now = DateTime.now();

    return DateFormat(
      "hh:mm a",
    ).format(DateTime(now.year, now.month, now.day, time.hour, time.minute));
  }

  Future<void> saveRecord() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyId = int.parse(prefs.getString('companyid').toString());

    final res = await CallRegisterService().insertCallRegister(
      companyId: companyId,
      entryNo: entryNoController.text,
      sourceId: int.parse(selectedSource!.id.toString()),
      callById: int.parse(selectedAgent!['id']),
      date: DateFormat('yyyy-MM-dd').format(selectedDate!),
      from: formatTime(fromTime),
      to: formatTime(toTime),
      feedback: feedbackController.text,
      notes: notesController.text,
    );

    if (res['status'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'])));

      feedbackController.clear();
      notesController.clear();

      setState(() {
        selectedDate = null;
        fromTime = null;
        toTime = null;

        selectedSource = null;
        selectedAgent = null;
      });

      await init(); // generates next entry number
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool mobile = width < 700;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios),
            color: Colors.white,
          ),
          actions: [
            IconButton(
              onPressed: () {
                init();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xff1E293B),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Call Register",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Log and manage incoming & outgoing call records",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          mobile
                              ? Column(
                                  children: [
                                    _entryField(),
                                    const SizedBox(height: 20),
                                    _dateField(),
                                    const SizedBox(height: 20),
                                    _sourceField(),
                                    const SizedBox(height: 20),
                                    _agentField(),
                                    const SizedBox(height: 20),
                                    _fromTimeField(),
                                    const SizedBox(height: 20),
                                    _toTimeField(),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _entryField()),
                                        const SizedBox(width: 24),
                                        Expanded(child: _dateField()),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(child: _sourceField()),
                                        const SizedBox(width: 24),
                                        Expanded(child: _agentField()),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(child: _fromTimeField()),
                                        const SizedBox(width: 24),
                                        Expanded(child: _toTimeField()),
                                      ],
                                    ),
                                  ],
                                ),

                          const SizedBox(height: 24),

                          _sectionLabel("Feedback *"),

                          const SizedBox(height: 8),

                          TextFormField(
                            controller: feedbackController,
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Feedback is required";
                              }
                              return null;
                            },
                            decoration: _inputDecoration(),
                          ),

                          const SizedBox(height: 20),

                          _sectionLabel("Notes"),

                          const SizedBox(height: 8),

                          TextFormField(
                            controller: notesController,
                            maxLines: 5,
                            decoration: _inputDecoration(),
                          ),

                          const SizedBox(height: 30),

                          const Divider(),

                          const SizedBox(height: 25),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 52,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      side: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Cancel"),
                                  ),
                                ),
                                SizedBox(
                                  width: 180,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: saveRecord,
                                    icon: const Icon(Icons.check),
                                    label: const Text("Save Record"),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xff4F1DDB),
                                      ),
                                      backgroundColor: const Color(0xff4F1DDB),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  Widget _entryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Entry No"),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: Colors.purple),
          initialValue: entryNoController.text,
          readOnly: true,
          decoration: _inputDecoration(
            prefixIcon: const Icon(Icons.receipt_long_outlined),
          ),
        ),
      ],
    );
  }

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Date *"),
        const SizedBox(height: 8),
        InkWell(
          onTap: pickDate,
          child: InputDecorator(
            decoration: _inputDecoration(
              prefixIcon: const Icon(Icons.calendar_month_outlined),
            ),
            child: Text(
              selectedDate == null
                  ? ""
                  : DateFormat("dd/MM/yyyy").format(selectedDate!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sourceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Source Name *"),
        const SizedBox(height: 8),
        DropdownButtonFormField<SourceMasterModel>(
          value: selectedSource,
          decoration: _inputDecoration(),
          items: sources.map((source) {
            return DropdownMenuItem<SourceMasterModel>(
              value: source,
              child: Text(source.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedSource = value;
            });
          },
        ),
      ],
    );
  }

  Widget _agentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Call By *"),
        const SizedBox(height: 8),
        if (agents.isNotEmpty)
          DropdownButtonFormField<Map<String, dynamic>>(
            value: selectedAgent,
            decoration: _inputDecoration(
              prefixIcon: const Icon(Icons.person_outline),
            ),
            hint: const Text("Select agent"),
            items: agents
                .map((e) => DropdownMenuItem(value: e, child: Text(e['name'])))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedAgent = value;
              });
            },
          ),
      ],
    );
  }

  Widget _fromTimeField() {
    return _timeField(
      title: "From Time *",
      value: formatTime(fromTime),
      onTap: pickFromTime,
    );
  }

  Widget _toTimeField() {
    return _timeField(
      title: "To Time *",
      value: formatTime(toTime),
      onTap: pickToTime,
    );
  }

  Widget _timeField({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(title),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: _inputDecoration(
              prefixIcon: const Icon(Icons.access_time),
              suffixIcon: const Icon(Icons.access_time),
            ),
            child: Text(value),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
