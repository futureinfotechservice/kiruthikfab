import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiruthikfab/services/delivery_partner_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/delivery_partner_master_model.dart';
import '../../services/delivery_management_apiservice.dart';
import 'custom_search_dropdown_salesperson.dart';

class DeliveryManagement extends StatefulWidget {
  const DeliveryManagement({super.key, required this.billNO});

  final String billNO;

  @override
  State<DeliveryManagement> createState() => _DeliveryManagementState();
}

class _DeliveryManagementState extends State<DeliveryManagement> {
  final entryNoController = TextEditingController();
  DeliveryPartnerMasterModel? selectedDeliveryPartner;
  List<DeliveryPartnerMasterModel> deliveryPartners = [];
  String? billNo;
  final searchController = TextEditingController();
  final _searchController = TextEditingController();
  final _delSearchController = TextEditingController();
  final GlobalKey<DropdownSearchState<String>> _internalDropdownKey =
      GlobalKey();
  final GlobalKey<DropdownSearchState<String>> _internalDropdownKey2 =
      GlobalKey();
  bool isLoading = true;
  bool isSaving = false;

  String companyid = "";
  String userType = "";
  List<dynamic> invoiceNo = [];
  List<dynamic> products = [];
  List<bool> productCheckedStatus = [];
  bool isUpdatingProducts = false;

  String? existingEntryNo;

  final List<String> checklists = [
    "Invoice No",
    "Payment Received",
    "Hand Stock to Delivery Area",
    "Package Complete",
    "Delivery Partner",
    "Customer Received",
  ];

  int? deliveryHeadId;
  bool isEditMode = false;
  List<dynamic> deliveryItems = [];
  late List<bool> checkedItems;
  List<bool> filteredCheckedItems = [];
  List<String> filteredChecklists = [];
  String searchQuery = "";
  String _companyName = "";
  List<dynamic> filteredProducts = [];
  bool isSearchingProducts = false;

  @override
  void initState() {
    super.initState();

    checkedItems = List.generate(checklists.length, (_) => false);
    filteredChecklists = List.from(checklists);
    filteredCheckedItems = List.from(checkedItems);
    filteredProducts = [];
    init();

    searchController.addListener(_filterChecklists);
  }

  Future<void> init() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      companyid = prefs.getString('companyid') ?? '';
      userType = prefs.getString('user_type')!.toUpperCase();
      if (companyid.isEmpty) {
        _showSnackBar("Company ID not found", isError: true);
        setState(() {
          isLoading = false;
        });
        return;
      }

      final companyName = prefs.getString('companyname') ?? '';
      final responses = await Future.wait([
        DeliveryManagementApiService.fetchProducts(companyId: companyid),
        DeliveryPartnerApiService().fetchDeliveryPartners(context),
      ]);
      final res = responses[0] as Map<String, dynamic>;
      deliveryPartners = responses[1] as List<DeliveryPartnerMasterModel>;

      if (mounted) {
        _companyName = companyName;

        await _generateInitialEntryNumber(res);

        final data = await DeliveryManagementApiService.fetchAllInvoiceNo(
          companyId: companyid,
        );

        if (widget.billNO != '0') {
          setState(() {
            billNo = widget.billNO;
          });
          await fetchDelivery();
        }

        setState(() {
          invoiceNo = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error initializing data", isError: true);
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    entryNoController.dispose();
    searchController.dispose();
    searchController.removeListener(_filterChecklists);
    super.dispose();
  }

  void _filterChecklists() {
    setState(() {
      searchQuery = searchController.text.toLowerCase();
      _updateFilteredLists();
    });
  }

  void _updateFilteredLists() {
    if (searchQuery.isEmpty) {
      filteredChecklists = List.from(checklists);
      filteredCheckedItems = List.from(checkedItems);
      filteredProducts = List.from(products);
      isSearchingProducts = false;
    } else {
      filteredChecklists = [];
      filteredCheckedItems = [];
      filteredProducts = [];
      isSearchingProducts = true;

      for (int i = 0; i < checklists.length; i++) {
        if (checklists[i].toLowerCase().contains(searchQuery)) {
          filteredChecklists.add(checklists[i]);
          filteredCheckedItems.add(checkedItems[i]);
        }
      }

      for (int i = 0; i < products.length; i++) {
        final productName =
            products[i]['checklist']?.toString().toLowerCase() ?? '';
        if (productName.contains(searchQuery)) {
          filteredProducts.add(products[i]);
        }
      }
    }
  }

  void updateCheckedItem(int filteredIndex, bool? value) {
    if (value != null && filteredIndex < filteredChecklists.length) {
      String checklistItem = filteredChecklists[filteredIndex];
      int originalIndex = checklists.indexOf(checklistItem);

      if (originalIndex != -1) {
        setState(() {
          checkedItems[originalIndex] = value;
          filteredCheckedItems[filteredIndex] = value;
        });
      }
    }
  }

  void initializeProductCheckboxes() {
    if (products.isNotEmpty && productCheckedStatus.isEmpty) {
      setState(() {
        productCheckedStatus = List.generate(products.length, (index) {
          if (isEditMode &&
              deliveryItems.isNotEmpty &&
              index < deliveryItems.length) {
            return deliveryItems[index]["product_checked"]?.toString() == "1";
          }
          return false;
        });
      });
    }
  }

  Future<void> updatePartner() async {
    await DeliveryManagementApiService()
        .updatePartner(
          invoiceNo: billNo!,
          partnerName: selectedDeliveryPartner!.name,
        )
        .timeout(const Duration(seconds: 30));
  }

  Future<void> updateProductStatus(int index, bool value) async {
    if (!isEditMode) return;

    setState(() {
      productCheckedStatus[index] = value;
    });

    try {
      await DeliveryManagementApiService()
          .updateChecklist(
            detailId: deliveryItems[index]["detailid"].toString(),
            isChecked: value ? "1" : "0",
          )
          .timeout(const Duration(seconds: 30));

      await fetchDelivery();
    } catch (e) {
      setState(() {
        productCheckedStatus[index] = !value;
      });
      _showSnackBar("Failed to update product status", isError: true);
    }
  }

  Future<void> saveDelivery() async {
    if (billNo == null || billNo!.isEmpty) {
      _showSnackBar("Please Select Invoice", isError: true);
      return;
    }

    if (entryNoController.text.isEmpty) {
      _showSnackBar("Entry Number is required", isError: true);
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      if (isEditMode) {
        await updateDelivery();
      } else {
        await createDelivery();
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> updateDelivery() async {
    setState(() {
      isUpdatingProducts = true;
    });

    try {
      for (
        int i = 0;
        i < deliveryItems.length && i < checkedItems.length;
        i++
      ) {
        await DeliveryManagementApiService()
            .updateChecklist(
              detailId: deliveryItems[i]["detailid"].toString(),
              isChecked: checkedItems[i] ? "1" : "0",
            )
            .timeout(const Duration(seconds: 30));
      }

      // if (mounted) {
      //   // _showSnackBar("Delivery Updated Successfully");
      // }
    } catch (e) {
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingProducts = false;
        });
      }
    }
  }

  Future<void> createDelivery() async {
    setState(() {
      isUpdatingProducts = true;
    });

    try {
      final data = await DeliveryManagementApiService.completeDelivery(
        companyId: companyid,
        billNo: billNo!,
        entryNoController: entryNoController.text,
        deliveryPartnerController: selectedDeliveryPartner!.name,
      );

      if (data["status"] == "success") {
        deliveryHeadId = data["head_id"];
        final fetchResponse = await DeliveryManagementApiService()
            .fetchDeliveryDetails(
              companyid: companyid,
              headId: deliveryHeadId.toString(),
            );

        final fetchData = jsonDecode(fetchResponse);

        if (fetchData["status"] == "success" && fetchData["details"] != null) {
          List<dynamic> details = fetchData["details"];

          for (int i = 0; i < details.length && i < checkedItems.length; i++) {
            int detailId = int.parse(details[i]["id"].toString());
            await DeliveryManagementApiService()
                .updateChecklist(
                  detailId: detailId.toString(),
                  isChecked: checkedItems[i] ? "1" : "0",
                )
                .timeout(const Duration(seconds: 30));
          }
        }

        if (mounted) {
          await fetchDelivery();

          setState(() {
            isEditMode = true;
            existingEntryNo = entryNoController.text;
          });

          // _showSnackBar("Delivery Created Successfully");
        }
      } else {
        throw Exception(data["message"] ?? "Failed to create delivery");
      }
    } catch (e) {
      _showSnackBar(
        "Failed to create delivery: ${e.toString()}",
        isError: true,
      );
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingProducts = false;
        });
      }
    }
  }

  Future<void> _generateInitialEntryNumber(Map<String, dynamic> res) async {
    if (res['delivery_head'] == null) {
      final lastEntry = null; //res['other_entry_no']?['entry_no'];

      entryNoController.text = generateEntryNo(lastEntry, _companyName);
    } else {
      entryNoController.text = generateEntryNo(
        res['delivery_head']['entry_no'],
        _companyName,
      );
    }
  }

  Future<void> resetEntryNumberForNewDelivery() async {
    if (!isEditMode) {
      final res = await DeliveryManagementApiService.fetchProducts(
        companyId: companyid,
      );

      if (mounted) {
        if (res['delivery_head'] == null) {
          final lastEntry = null; //res['other_entry_no']?['entry_no'];
          entryNoController.text = generateEntryNo(lastEntry, _companyName);
        } else {
          entryNoController.text = generateEntryNo(
            res['delivery_head']['entry_no'],
            _companyName,
          );
        }
      }
    }
  }

  Future<void> fetchDelivery() async {
    try {
      setState(() {
        selectedDeliveryPartner = null;
      });
      final res = await DeliveryManagementApiService().fetchAllProducts(
        companyId: companyid,
        billNo: billNo!,
      );

      final data = res;

      if (data["delivery_items"] != null && data["delivery_items"].isNotEmpty) {
        final res = data["delivery_items"];

        products = res;
        filteredProducts = List.from(res);
        productCheckedStatus = List.generate(res.length, (_) => false);

        entryNoController.text = data["delivery_items"][0]['entry_no'];
        deliveryItems = data["delivery_items"];
        deliveryHeadId = int.parse(deliveryItems.first["headid"].toString());
        isEditMode = true;

        if (data["delivery_items"][0]['delivery_partner'] != null &&
            data["delivery_items"][0]['delivery_partner'] != '') {
          try {
            selectedDeliveryPartner = deliveryPartners
                .where(
                  (element) =>
                      element.name.toLowerCase() ==
                      data["delivery_items"][0]['delivery_partner']
                          .toString()
                          .toLowerCase(),
                )
                .first;
          } catch (e) {
            selectedDeliveryPartner = null;
          }
        }

        existingEntryNo = data["entry_no"]?.toString();
        if (existingEntryNo != null && existingEntryNo!.isNotEmpty) {
          entryNoController.text = existingEntryNo!;
        }

        setState(() {
          checkedItems = List.generate(checklists.length, (index) {
            if (index < deliveryItems.length) {
              return deliveryItems[index]["isChecked"].toString() == "1";
            }
            return false;
          });

          if (products.isNotEmpty) {
            productCheckedStatus = List.generate(products.length, (index) {
              if (index < deliveryItems.length) {
                return deliveryItems[index]["product_checked"]?.toString() ==
                    "1";
              }
              return false;
            });
          }

          _updateFilteredLists();
        });
      } else {
        if (data["delivery_items1"][0]['invoice_delivery_partner'] != null &&
            data["delivery_items1"][0]['invoice_delivery_partner'] != '') {
          selectedDeliveryPartner = deliveryPartners
              .where(
                (element) =>
                    element.id ==
                    data["delivery_items1"][0]['invoice_delivery_partner'],
              )
              .first;
        }

        // deliveryPartnerController.text = '';
        // await generateNewEntryNumber();
        isEditMode = false;
        existingEntryNo = null;
        setState(() {
          deliveryItems.clear();
          existingEntryNo = null;
          checkedItems = List.generate(checklists.length, (_) => false);
          productCheckedStatus = List.generate(products.length, (_) => false);
          filteredProducts = List.from(products);
          _updateFilteredLists();
        });

        await generateNewEntryNumber();
      }
    } catch (e) {
      _showSnackBar("Error fetching delivery data", isError: true);
    }
  }

  Future<void> generateNewEntryNumber() async {
    if (isEditMode || companyid.isEmpty) {
      return;
    }

    final res = await DeliveryManagementApiService.fetchProducts(
      companyId: companyid,
    );

    if (mounted) {
      String newEntryNo;
      if (res['delivery_head'] == null) {
        final lastEntry = null; // res['other_entry_no']?['entry_no'];
        newEntryNo = generateEntryNo(lastEntry, _companyName);
      } else {
        newEntryNo = generateEntryNo(
          res['delivery_head']['entry_no'],
          _companyName,
        );
      }

      setState(() {
        entryNoController.text = newEntryNo;
      });
    }
  }

  void refreshEntryNumber() async {
    if (!isEditMode) {
      await generateNewEntryNumber();
      _showSnackBar("Entry number refreshed");
    }
  }

  String getCompanyPrefix(String companyName) {
    if (companyName.isEmpty) return "DF";

    final words = companyName.trim().split(RegExp(r'\s+'));

    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (companyName.length >= 2) {
      return companyName.substring(0, 2).toUpperCase();
    }

    return "DF";
  }

  String generateEntryNo(String? lastEntryNo, String companyName) {
    final prefix = getCompanyPrefix(companyName);
    final year = DateTime.now().year;
    int nextSequence = 1;

    if (lastEntryNo != null && lastEntryNo.isNotEmpty) {
      final parts = lastEntryNo.split('-');
      if (parts.length == 3) {
        try {
          nextSequence = int.parse(parts[2]) + 1;
        } catch (e) {
          nextSequence = 1;
        }
      }
    }

    return '$prefix-$year-${nextSequence.toString().padLeft(4, '0')}';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 700;
    final completed = checkedItems.where((e) => e).length;
    final progressValue = checklists.isNotEmpty
        ? double.parse((completed / checklists.length).toString())
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 25),
                  mobile ? _buildMobileLayout() : _buildDesktopLayout(),
                  const SizedBox(height: 25),
                  _buildChecklistTable(completed, progressValue),
                  const SizedBox(height: 25),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final width = MediaQuery.of(context).size.width;

    final bool mobile = width < 700;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(color: Color(0xff1E293B)),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Delivery Management",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              mobile
                  ? Text(
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      "Verify and dispatch delivery\nitems with checklist confirmation",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    )
                  : const Text(
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      "Verify and dispatch delivery items with checklist confirmation",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        buildEntryCard(),
        const SizedBox(height: 15),
        buildBillCard(),
        const SizedBox(height: 15),
        buildDeliveryPartner(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: buildEntryCard()),
            const SizedBox(width: 20),
            Expanded(child: buildBillCard()),
          ],
        ),
        const SizedBox(height: 15),
        buildDeliveryPartner(),
      ],
    );
  }

  Widget buildDeliveryPartner() {
    return buildPartnerCard();
  }

  Widget buildEntryCard() {
    return buildLookupCard(
      title: "ENTRY NO.",
      controller: entryNoController,
      hint: "Entry Number",
      iconColor: Colors.blue,
      readOnly: true,
    );
  }

  Widget _buildChecklistTable(int completed, double progressValue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildChecklistHeader(completed, progressValue),
          if (products.isEmpty) _buildChecklistList() else _buildProductsList(),
        ],
      ),
    );
  }

  Widget _buildChecklistHeader(int completed, double progressValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xff1E293B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                "Checklist & Products",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$completed / ${checklists.length} Completed",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 250,
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xff0F172A),
                    hintText: "Search Checklists...",
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistList() {
    if (filteredChecklists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            "No matching checklists found",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: const Row(
            children: [
              Expanded(
                flex: 1,
                child: Text("#", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  "Checklist Item",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "Status",
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredChecklists.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: filteredCheckedItems[index]
                          ? Colors.green
                          : Colors.grey.shade200,
                      child: Text(
                        "${checklists.indexOf(filteredChecklists[index]) + 1}",
                        style: TextStyle(
                          color: filteredCheckedItems[index]
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        filteredChecklists[index],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          decoration: filteredCheckedItems[index]
                              ? TextDecoration.lineThrough
                              : null,
                          color: filteredCheckedItems[index]
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Checkbox(
                      value: filteredCheckedItems[index],
                      onChanged: (value) => updateCheckedItem(index, value),
                      activeColor: Colors.green,
                      checkColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    // Use filtered products if searching, otherwise use all products
    final displayProducts = searchQuery.isNotEmpty
        ? filteredProducts
        : products;

    if (displayProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            searchQuery.isNotEmpty
                ? "No checklists found matching '$searchQuery'"
                : "No checklists found for this invoice",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Initialize product checkboxes for displayed products
    if (productCheckedStatus.isEmpty ||
        productCheckedStatus.length != products.length) {
      initializeProductCheckboxes();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              const Expanded(
                flex: 1,
                child: Text("#", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Expanded(
                flex: 3,
                child: Text(
                  "Checklists Item",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Expanded(
                flex: 1,
                child: Text(
                  "Date",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (isEditMode)
                const Expanded(
                  flex: 1,
                  child: Text(
                    "Verified",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayProducts.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            final product = displayProducts[index];

            // Find the original index for this product
            int originalIndex = products.indexOf(product);
            if (originalIndex == -1) originalIndex = index;

            final date = DateTime.parse(product['date']!.toString());
            final formatedDate = DateFormat('dd-MM-yyyy').format(date);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          isEditMode && productCheckedStatus[originalIndex]
                          ? Colors.green
                          : Colors.blue.shade100,
                      child: Text(
                        "${originalIndex + 1}",
                        style: TextStyle(
                          color:
                              isEditMode && productCheckedStatus[originalIndex]
                              ? Colors.white
                              : Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checklists[originalIndex],
                            // product['checklist']?.toString() ??
                            //     'Unknown checklist',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              decoration:
                                  isEditMode &&
                                      productCheckedStatus[originalIndex]
                                  ? TextDecoration.lineThrough
                                  : null,
                              color:
                                  isEditMode &&
                                      productCheckedStatus[originalIndex]
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      formatedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  if (isEditMode)
                    Expanded(
                      flex: 1,
                      child: Checkbox(
                        value: product['isChecked'].toString() == '1'
                            ? true
                            : false,
                        onChanged: isUpdatingProducts
                            ? null
                            : (value) => updateProductStatus(
                                originalIndex,
                                value ?? false,
                              ),
                        activeColor: Colors.green,
                        checkColor: Colors.white,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    // Calculate total items and checked items
    final totalChecklists = checklists.length;

    // final totalProducts = products.isNotEmpty ? products.length : 0;
    final totalItems = totalChecklists;

    final checkedChecklists = checkedItems.where((e) => e).length;
    final checkedProducts = productCheckedStatus.isNotEmpty
        ? productCheckedStatus.where((e) => e).length
        : 0;
    final totalChecked = checkedChecklists + checkedProducts;

    final bool allItemsChecked = totalItems > 0 && totalChecked == totalItems;

    String buttonText = "";
    bool buttonEnabled = false;
    Color buttonColor = Colors.blue;

    if (isEditMode) {
      if (allItemsChecked) {
        buttonText = "Finish Delivery";
        buttonEnabled = true;
        buttonColor = Colors.green;
      } else {
        buttonText = "Finish Delivery ($totalChecked/$totalItems completed)";
        buttonEnabled = false;
        buttonColor = Colors.grey;
      }
    } else {
      buttonText = "Create Delivery";
      buttonEnabled = true;
      buttonColor = Colors.blue;
    }
    if (products.isNotEmpty &&
        allItemsChecked &&
        products[0]['invoice_status'] == 'Delivered') {
      buttonText = "Delivery Already Finished";
      buttonEnabled = false;
      buttonColor = Colors.green;
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: buttonEnabled
                ? (isEditMode ? finishDelivery : saveDelivery)
                : null,
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isEditMode ? Icons.check_circle : Icons.save),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> finishDelivery() async {
    if (billNo == null || billNo!.isEmpty) {
      _showSnackBar("Please Select Invoice", isError: true);
      return;
    }

    if (entryNoController.text.isEmpty) {
      _showSnackBar("Entry Number is required", isError: true);
      return;
    }

    final totalChecklists = checklists.length;

    final checkedChecklists = checkedItems.where((e) => e).length;

    if (checkedChecklists != totalChecklists) {
      _showSnackBar(
        "Please complete all checklist items before finishing",
        isError: true,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await updateDelivery();

      final data = await DeliveryManagementApiService.updateDelivery(
        companyId: companyid,
        headId: billNo.toString(),
        status: "Delivered",
      );

      if (data["status"] == "success") {
        // _showSnackBar("Delivery Finished Successfully!");

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        throw Exception(data["message"] ?? "Failed to finish delivery");
      }
    } catch (e) {
      _showSnackBar("Error finishing delivery: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget buildBillCard() {
    OutlineInputBorder border({Color color = const Color(0xFFD1D5DB)}) {
      return OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(6),
      );
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("BILL NO.", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          DropdownSearch<String>(
            key: _internalDropdownKey,
            selectedItem: billNo,
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
            items: (filter, loadProps) => invoiceNo.map<String>((invoice) {
              return invoice['invoiceno'];
            }).toList(),
            onSelected: (value) async {
              if (value == null) return;

              setState(() {
                billNo = value;
              });

              await Future.delayed(const Duration(milliseconds: 200));

              await fetchDelivery();
            },
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                controller: _searchController,

                decoration: InputDecoration(
                  hintText: 'Search...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
                ),
                onSubmitted: (value) {
                  setState(() {
                    billNo = value;
                  });

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!mounted) return;

                    setState(() => isLoading = true);

                    await fetchDelivery();

                    if (mounted) {
                      setState(() => isLoading = false);
                    }
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
        ],
      ),
    );
  }

  Widget buildPartnerCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Partner.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          DropdownSearch<DeliveryPartnerMasterModel>(
            compareFn: (item1, item2) {
              return item1.id == item2.id;
            },
            key: _internalDropdownKey2,
            selectedItem: selectedDeliveryPartner,
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
            items: (filter, loadProps) =>
                deliveryPartners.map<DeliveryPartnerMasterModel>((invoice) {
                  return invoice;
                }).toList(),
            itemAsString: (item) {
              return item.name;
            },
            onSelected: (value) async {
              if (value == null) return;

              setState(() {
                selectedDeliveryPartner = value;
              });
              updatePartner();
            },
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                controller: _delSearchController,

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
                      _delSearchController.clear();
                    },
                  ),
                ),
                onSubmitted: (value) async {
                  final partner = deliveryPartners.firstWhere(
                    (element) => element.name == value,
                  );

                  setState(() {
                    selectedDeliveryPartner = partner;
                  });
                  updatePartner();
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
        ],
      ),
    );
  }

  Widget buildLookupCard({
    required String title,
    required TextEditingController controller,
    required String hint,
    required Color iconColor,
    required bool readOnly,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (isEditMode && existingEntryNo != null)
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Existing",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (!isEditMode)
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Auto-generated",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: readOnly,
            controller: controller,
            style: TextStyle(
              color: readOnly ? Colors.grey.shade700 : Colors.blue,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                Icons.badge,
                color: readOnly ? Colors.grey : Colors.blue,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
              suffixIcon: !isEditMode && !readOnly
                  ? IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: refreshEntryNumber,
                      tooltip: "Generate New Entry Number",
                    )
                  : null,
            ),
          ),
          if (!isEditMode)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "New entry number will be auto-generated based on last entry",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
