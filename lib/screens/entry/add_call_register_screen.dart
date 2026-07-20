import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../indigator/main.dart';
import '../../models/call_register_model.dart';
import '../../models/customer_interest_model.dart';
import '../../models/source_call_history_model.dart';
import '../../models/source_master_model.dart';
import '../../services/call_register_service.dart';
import '../../services/customer_interest_apiservice.dart';
import '../../services/source_apiservice.dart';
import '../../widgets/custom_search_dropdown_source.dart';

class AddCallRegisterScreen extends StatefulWidget {
  final CallRegisterModel? existing;

  const AddCallRegisterScreen({super.key, this.existing});

  @override
  State<AddCallRegisterScreen> createState() => _AddCallRegisterScreenState();
}

class _AddCallRegisterScreenState extends State<AddCallRegisterScreen> {
  final SourceApiService _apiService = SourceApiService();
  final CustomerInterestApiservice _customerInterestService =
      CustomerInterestApiservice();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController feedbackController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final entryNoController = TextEditingController();

  // final _searchController = TextEditingController();
  final _searchController1 = TextEditingController();

  DateTime? selectedDate;
  DateTime? selectedFollowupDate;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  final TextEditingController fromTimeController = TextEditingController();
  final TextEditingController toTimeController = TextEditingController();
  SourceMasterModel? selectedSource;
  List<SourceMasterModel> sources = [];
  Map<String, dynamic>? selectedAgent;

  List<Map<String, dynamic>> agents = [];
  Map<String, dynamic> callRegisters = {};

  bool _initialized = false;
  List<CustomerInterestModel> _interests = [];
  CustomerInterestModel? _selectedInterest;
  String? userType;
  String? loginUsername;
  String? loginId;
  bool isEdit = false;
  List<SourceCallHistoryModel> sourceHistory = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;

      init();
    }
  }

  DateTime? _parseDate(String dateString) {
    try {
      if (dateString.isEmpty) return null;

      // If date is already in yyyy-MM-dd format, use DateTime.parse
      if (dateString.contains('-') && dateString.split('-')[0].length == 4) {
        return DateTime.parse(dateString);
      }

      // Parse dd/MM/yyyy format
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      if (timeString.isEmpty) return null;

      // If time is in HH:MM format (24-hour)
      if (timeString.contains(':') &&
          !timeString.contains('AM') &&
          !timeString.contains('PM')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          return TimeOfDay(hour: hour, minute: minute);
        }
      }

      // Handle HH:MM AM/PM format
      if (timeString.contains('AM') || timeString.contains('PM')) {
        String cleanTime = timeString
            .replaceAll('AM', '')
            .replaceAll('PM', '')
            .trim();
        final parts = cleanTime.split(':');

        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);

          // Convert to 24-hour format
          if (timeString.contains('PM') && hour != 12) {
            hour += 12;
          } else if (timeString.contains('AM') && hour == 12) {
            hour = 0;
          }

          return TimeOfDay(hour: hour, minute: minute);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id');
    final username = prefs.getString('username');
    final userTypes = prefs.getString('user_type');
    final isUser = userType == "USER";
    if (widget.existing != null) {
      setState(() {
        isEdit = true;
        feedbackController.text = widget.existing!.feedback;
        notesController.text = widget.existing!.notes;
        entryNoController.text = widget.existing!.entryNo;
        selectedDate = _parseDate(widget.existing!.date.toString());
        selectedFollowupDate = _parseDate(
          widget.existing!.followupDate.toString(),
        );

        // Parse and set the time values
        fromTime = _parseTime(widget.existing!.fromTime);
        toTime = _parseTime(widget.existing!.toTime);

        // IMPORTANT: Set the controller text values with formatted time
        if (fromTime != null) {
          fromTimeController.text = fromTime!.format(context);
        }
        if (toTime != null) {
          toTimeController.text = toTime!.format(context);
        }

        selectedSource = sources.firstWhere(
          (element) => element.name == widget.existing!.sourceName,
        );

        selectedAgent = agents.firstWhere(
          (element) => element['name'] == widget.existing!.callBy,
        );
        _selectedInterest = widget.existing!.interest;
      });
    }

    setState(() {
      loginId = id;
      loginUsername = username;
      userType = userTypes;
      if (!isUser && !isEdit) {
        selectedAgent = {'id': loginId, 'name': loginUsername};
      }
      _isLoading = false;
    });
  }

  Future<void> init() async {
    setState(() {
      _isLoading = true;

      feedbackController.clear();
      notesController.clear();
      entryNoController.clear();

      fromTime = null;
      toTime = TimeOfDay.now();
      selectedDate = DateTime.now();
      fromTimeController.clear();
      toTimeController.text = toTime!.format(context);
      selectedSource = null;
      selectedAgent = null;
    });
    final responses = await Future.wait([
      CallRegisterService().fetchCallRegister(),
      _apiService.fetchSources(context),
      _apiService.fetchEntryPersons(context),
      _customerInterestService.fetchInterests(context),
    ]);

    final res = responses[0] as Map<String, dynamic>;

    final List<SourceMasterModel> sources1 =
        responses[1] as List<SourceMasterModel>;

    final agent = responses[2] as List<Map<String, dynamic>>;

    final interests = responses[3] as List<CustomerInterestModel>;

    SharedPreferences prefs = await SharedPreferences.getInstance();

    final companyName = prefs.getString('companyname') ?? '';

    if (res['call_register'] == null) {
      // final lastEntry = res['other_entry_no']?['entry_no'].toString();

      // entryNoController.text = generateEntryNo(lastEntry, companyName);
      entryNoController.text = generateEntryNo(null, companyName);
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

      _interests = interests;
    });
    await loadData();
  }

  Future<void> fetchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('companyid');
    sourceHistory = await CallRegisterService().fetchCallHistory(
      companyId!,
      selectedSource!.id,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isUser = userType == "USER";
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
          ? Center(child: CircularWaveProgress())
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
                                    if (!isUser) _agentField(),
                                    if (!isUser) const SizedBox(height: 20),
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
                                        if (!isUser) const SizedBox(width: 24),
                                        if (!isUser)
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
                          _dateField1(),
                          const SizedBox(height: 24),

                          customerInterest(),
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
                                    onPressed: isEdit ? update : saveRecord,
                                    icon: const Icon(Icons.check),
                                    label: Text(
                                      isEdit ? "update" : "Save Record",
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      side: BorderSide(
                                        color: isEdit
                                            ? Colors.blue
                                            : Color(0xff4F1DDB),
                                      ),
                                      backgroundColor: isEdit
                                          ? Colors.blue
                                          : Color(0xff4F1DDB),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          buildHistory(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget buildHistory() {
    if (sourceHistory.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "No History Available",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            "History",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sourceHistory.length,
          itemBuilder: (context, index) {
            final item = sourceHistory[index];

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(
                            Icons.history,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Entry #${item.entryNo}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  "dd MMM yyyy",
                                ).format(DateTime.parse(item.date)),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.interest,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Info Grid
                    Row(
                      children: [
                        Expanded(
                          child: _infoTile(
                            Icons.person_outline,
                            "From",
                            item.from,
                          ),
                        ),
                        Expanded(child: _infoTile(Icons.person, "To", item.to)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _infoTile(Icons.call, "Call By", item.callBy),
                        ),
                        Expanded(
                          child: _infoTile(
                            Icons.event_available,
                            "Follow-up",
                            item.followupDate.isNotEmpty
                                ? DateFormat(
                                    'dd MMM yyyy',
                                  ).format(DateTime.parse(item.followupDate))
                                : "-",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoTile(
                      Icons.timer_outlined,
                      "Total Time",
                      '${item.totalTime} Minutes',
                    ),

                    const SizedBox(height: 16),

                    // Feedback
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Feedback",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.feedback,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Notes
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Notes",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.notes,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value.isEmpty ? "-" : value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
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
      initialDate: selectedDate,
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> pickFollowupDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: selectedFollowupDate,
    );

    if (date != null) {
      setState(() {
        selectedFollowupDate = date;
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
        fromTimeController.text = time.format(context);
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
        toTimeController.text = time.format(context);
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

  Future<void> update() async {
    final follow = selectedFollowupDate == null
        ? ''
        : DateFormat('yyyy-MM-dd').format(selectedFollowupDate!);
    final isUser = userType == "USER";
    final res = await CallRegisterService().updateCallRegister(
      id: widget.existing!.id,
      sourceId: int.parse(selectedSource!.id),
      callById: !isUser ? int.parse(selectedAgent!['id'].toString()) : 0,
      from: fromTimeController.text,
      to: toTimeController.text,
      date: DateFormat('yyyy-MM-dd').format(selectedDate!),
      feedback: feedbackController.text,
      notes: notesController.text,
      followupDate: follow,
      interest: _selectedInterest!.id.toString(),
    );

    if (res['status'] == true) {
      if (context.mounted && mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  Future<void> saveRecord() async {
    final follow = selectedFollowupDate == null
        ? ''
        : DateFormat('yyyy-MM-dd').format(selectedFollowupDate!);

    if (fromTime != null && toTime != null) {
      final fromMinutes = fromTime!.hour * 60 + fromTime!.minute;
      final toMinutes = toTime!.hour * 60 + toTime!.minute;

      if (fromMinutes >= toMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("From time should be less than To time"),
          ),
        );
        return;
      }
    }

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
      followupDate: follow,
      interest: _selectedInterest?.id ?? "",
    );

    if (res['status'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['message'])));
      }

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
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

  Widget customerInterest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Customer Interest *"),
        const SizedBox(height: 8),

        DropdownSearch<CustomerInterestModel>(
          selectedItem: _selectedInterest,

          compareFn: (item, selectedItem) => item.id == selectedItem.id,

          items: (filter, loadProps) => _interests,

          itemAsString: (CustomerInterestModel item) => item.interest,

          decoratorProps: DropDownDecoratorProps(
            baseStyle: const TextStyle(fontSize: 14, color: Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: border(),
              enabledBorder: border(),
              focusedBorder: border(),
              disabledBorder: border(color: const Color(0xFFD1D5DB)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              hintText: "Select Interest",
              hintStyle: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),

          onSelected: (CustomerInterestModel? value) {
            setState(() {
              _selectedInterest = value;
            });
          },

          popupProps: PopupProps.menu(
            showSearchBox: true,

            searchFieldProps: TextFieldProps(
              controller: _searchController1,
              decoration: InputDecoration(
                hintText: 'Search...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  // borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController1.clear();
                  },
                ),
              ),
            ),

            menuProps: MenuProps(
              // borderRadius: BorderRadius.circular(12),
              elevation: 6,
              color: Colors.white,
              backgroundColor: Colors.white,
            ),

            itemBuilder:
                (
                  context,
                  CustomerInterestModel item,
                  bool isDisabled,
                  bool isSelected,
                ) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      item.interest,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black,
                      ),
                    ),
                  );
                },
          ),
        ),
      ],
    );
  }

  Widget _dateField1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Followup Date *"),
        const SizedBox(height: 8),
        InkWell(
          onTap: pickFollowupDate,
          child: InputDecorator(
            decoration: _inputDecoration(
              prefixIcon: const Icon(Icons.calendar_month_outlined),
            ),
            child: Text(
              selectedFollowupDate == null
                  ? ""
                  : DateFormat("dd/MM/yyyy").format(selectedFollowupDate!),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder border({Color color = const Color(0xFFD1D5DB)}) {
    return OutlineInputBorder(
      borderSide: BorderSide(color: color, width: 1.4),
      borderRadius: BorderRadius.circular(6),
    );
  }

  Widget _sourceField() {
    final customerNames = sources
        .map((e) => {'name': e.name, 'mobile': e.mobileNo})
        .take(100)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 5),
        CustomDropdownSearchSource(
          label: "Source Name *",
          isRequired: true,
          items: customerNames,
          selectedItem: selectedSource?.name ?? '',
          onChanged: (value) async {
            if (value == null) return;
            setState(() {
              selectedSource = sources.firstWhere(
                (element) => element.name == value,
              );
            });
            fetchHistory();
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
          DropdownSearch<String>(
            compareFn: (item, selectedItem) => item == selectedItem,
            selectedItem: selectedAgent?['name'],
            decoratorProps: DropDownDecoratorProps(
              baseStyle: TextStyle(fontSize: 14, color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: border(),
                enabledBorder: border(),
                focusedBorder: border(),
                disabledBorder: border(color: const Color(0xFFD1D5DB)),

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                hintStyle: TextStyle(color: const Color(0xFF6B7280)),
              ),
            ),
            items: (filter, loadProps) => agents.map((e) {
              return e['name'].toString();
            }).toList(),
            onSelected: (value) {
              setState(() {
                selectedAgent = agents.firstWhere(
                  (element) => element['name'] == value,
                );
              });
            },
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                controller: _searchController1,

                decoration: InputDecoration(
                  hintText: 'Search...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    // borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController1.clear();
                    },
                  ),
                ),
                onSubmitted: (value) async {
                  setState(() {
                    selectedAgent = agents.firstWhere(
                      (element) => element['name'] == value,
                    );
                  });
                },
              ),
              menuProps: MenuProps(
                // borderRadius: BorderRadius.circular(12),
                elevation: 6,
                color: Colors.white,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        // DropdownButtonFormField<Map<String, dynamic>>(
        //   initialValue: selectedAgent,
        //   decoration: _inputDecoration(
        //     prefixIcon: const Icon(Icons.person_outline),
        //   ),
        //   hint: const Text("Select agent"),
        //   items: agents
        //       .map((e) => DropdownMenuItem(value: e, child: Text(e['name'])))
        //       .toList(),
        //   onChanged: (value) {
        //     setState(() {
        //       selectedAgent = value;
        //     });
        //   },
        // ),
      ],
    );
  }

  Widget _fromTimeField() {
    return _timeField(
      title: "From Time *",
      // value: formatTime(fromTime),
      controller: fromTimeController,
      onTap: pickFromTime,
    );
  }

  Widget _toTimeField() {
    return _timeField(
      title: "To Time *",
      // value: formatTime(toTime),
      controller: toTimeController,
      onTap: pickToTime,
    );
  }

  Widget _timeField({
    required String title,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(title),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,

                decoration: _inputDecoration(
                  prefixIcon: const Icon(Icons.access_time),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.access_time),
              ),
            ),
          ],
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
