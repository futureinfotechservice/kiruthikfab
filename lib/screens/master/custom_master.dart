import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../models/area_master_model.dart';
import '../../models/productmaster_model.dart';

class CustomMasterScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback refresh;
  final bool isLoading;
  final bool isEditMode;
  final bool isListLoading;
  final List<dynamic> filteredDatas;
  final dynamic editingData;
  final TextEditingController nameController;
  final TextEditingController? descriptionController;
  final VoidCallback submitForm;
  final VoidCallback cancelEdit;
  final GlobalKey<FormState> formKey;
  final String searchQuery;
  final Function edit;
  final Function(String, int) delete;
  final String title;
  final ValueChanged<String> onSearchChanged;
  final IconData? icon;
  final String? subtitle;
  final Color? primaryColor;
  final List<Widget>? extraActions;
  final String? descriptionLabel;
  final bool showDescription;
  final String? idFieldName;

  const CustomMasterScreen({
    super.key,
    required this.onBack,
    required this.refresh,
    required this.isLoading,
    required this.isListLoading,
    required this.filteredDatas,
    required this.isEditMode,
    this.editingData,
    required this.formKey,
    required this.nameController,
    this.descriptionController,
    required this.submitForm,
    required this.cancelEdit,
    required this.searchQuery,
    required this.edit,
    required this.delete,
    required this.title,
    required this.onSearchChanged,
    this.icon,
    this.subtitle,
    this.primaryColor,
    this.extraActions,
    this.descriptionLabel = 'Description',
    this.showDescription = true,
    this.idFieldName = 'ID',
  });

  @override
  State<CustomMasterScreen> createState() => _CustomMasterScreenState();
}

class _CustomMasterScreenState extends State<CustomMasterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
    final primaryColor = widget.primaryColor ?? const Color(0xFF1E293B);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(primaryColor, isWeb),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.3],
                ),
              ),
            ),
          ),
          widget.isLoading
              ? _buildLoadingState(primaryColor)
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: isWeb ? 1400 : 1200,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderCard(primaryColor, isWeb),
                              const SizedBox(height: 24),
                              _buildFormCard(primaryColor, isWeb),
                              const SizedBox(height: 32),
                              _buildListHeader(
                                primaryColor,
                                isWeb,
                                isSmallScreen,
                              ),
                              _buildSearchBar(
                                isWeb: false,
                                primaryColor: primaryColor,
                              ),
                              const SizedBox(height: 16),
                              if (widget.isListLoading)
                                _buildListLoadingState()
                              else if (widget.filteredDatas.isEmpty)
                                _buildEmptyState(primaryColor, isWeb)
                              else
                                isWeb
                                    ? _buildWebTable(primaryColor)
                                    : _buildMobileList(primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor, bool isWeb) {
    return AppBar(
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back',
        ),
      ),
      title: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.title} Master',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.extraActions != null) ...widget.extraActions!,
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: widget.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            splashRadius: 20,
          ),
        ),
        const SizedBox(width: 8),
      ],
      // bottom: isWeb
      //     ? null
      //     : PreferredSize(
      //         preferredSize: const Size.fromHeight(60),
      //         child:,
      //       ),
    );
  }

  Widget _buildSearchBar({required bool isWeb, required Color primaryColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withValues(alpha: 0.05),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onTap: () => setState(() => _isSearchFocused = true),
          onSubmitted: (_) => setState(() => _isSearchFocused = false),
          decoration: InputDecoration(
            hintText: 'Search ${widget.title.toLowerCase()}s...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(
              Icons.search,
              color: _isSearchFocused ? primaryColor : Colors.grey[400],
              size: 22,
            ),
            suffixIcon: widget.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      widget.onSearchChanged('');
                      setState(() => _isSearchFocused = false);
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: widget.onSearchChanged,
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading ${widget.title}s...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch the data',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildListLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.grey[100]!,
                    Colors.grey[50]!,
                    Colors.grey[100]!,
                  ],
                  stops: const [0, 0.5, 1],
                ).createShader(bounds),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment(-1, 0),
                      end: Alignment(1, 0),
                      colors: [
                        Colors.grey[100]!,
                        Colors.grey[200]!,
                        Colors.grey[100]!,
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor, bool isWeb) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.isEditMode ? Icons.edit_note : Icons.add_circle_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEditMode
                        ? 'Edit ${widget.title}'
                        : 'Add New ${widget.title}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isEditMode && widget.editingData != null
                        ? 'Updating: ${_getDisplayName(widget.editingData)}'
                        : 'Create a new ${widget.title.toLowerCase()} record',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (isWeb && widget.isEditMode)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: Colors.amber[200], size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Editing Mode',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDisplayName(dynamic data) {
    if (data == null) return '';
    // Handle different data models
    if (data is AreaMasterModel) {
      return data.areaname;
    }
    if (data is ProductMasterModel) {
      return data.productname;
    }
    // Fallback to trying to access 'name' or 'title' properties
    try {
      return data.name ?? data.title ?? data.toString();
    } catch (_) {
      return data.toString();
    }
  }

  String _getId(dynamic data) {
    if (data == null) return '';
    if (data is AreaMasterModel) {
      return data.id;
    }
    if (data is ProductMasterModel) {
      return data.id;
    }

    try {
      return data.id?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _getDescription(dynamic data) {
    if (data == null) return '';
    if (data is AreaMasterModel) {
      return '';
    }
    try {
      return data.description ?? data.desc ?? '';
    } catch (_) {
      return '';
    }
  }

  Widget _buildFormCard(Color primaryColor, bool isWeb) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.isEditMode ? Icons.edit : Icons.add,
                      color: primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.isEditMode
                        ? 'Update ${widget.title} Details'
                        : 'Enter ${widget.title} Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  if (widget.isEditMode && widget.editingData != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.idFieldName}: ${_getId(widget.editingData)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Name Field
              _buildFormField(
                label: '${widget.title} Name',
                icon: Icons.title,
                controller: widget.nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '${widget.title} name is required';
                  }
                  if (value.length < 2) {
                    return '${widget.title} name must be at least 2 characters';
                  }
                  return null;
                },
                isWeb: isWeb,
              ),

              // Optional Description Field
              if (widget.showDescription &&
                  widget.descriptionController != null) ...[
                const SizedBox(height: 16),
                _buildFormField(
                  label: '',
                  icon: Icons.description,
                  controller: widget.descriptionController!,
                  validator: null,
                  isWeb: isWeb,
                  maxLines: 3,
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              _buildFormActions(primaryColor, isWeb, isSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isWeb,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            textInputAction: maxLines == 1
                ? TextInputAction.done
                : TextInputAction.newline,
            onFieldSubmitted: (_) {
              if (maxLines == 1) widget.submitForm();
            },
            decoration: InputDecoration(
              hintText: 'Enter $label...',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildFormActions(Color primaryColor, bool isWeb, bool isSmall) {
    return isWeb
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.isEditMode) ...[
                _buildActionButton(
                  label: 'Cancel',
                  icon: Icons.close,
                  onPressed: widget.cancelEdit,
                  isPrimary: false,
                  primaryColor: primaryColor,
                ),
                const SizedBox(width: 12),
              ],
              _buildActionButton(
                label: widget.isEditMode ? 'Update' : 'Create',
                icon: widget.isEditMode ? Icons.save : Icons.add,
                onPressed: widget.submitForm,
                isPrimary: true,
                primaryColor: primaryColor,
              ),
            ],
          )
        : Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(
                  label: widget.isEditMode
                      ? 'Update ${widget.title}'
                      : 'Create ${widget.title}',
                  icon: widget.isEditMode ? Icons.save : Icons.add,
                  onPressed: widget.submitForm,
                  isPrimary: true,
                  primaryColor: primaryColor,
                ),
              ),
              if (widget.isEditMode) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    label: 'Cancel',
                    icon: Icons.close,
                    onPressed: widget.cancelEdit,
                    isPrimary: false,
                    primaryColor: primaryColor,
                  ),
                ),
              ],
            ],
          );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
    required Color primaryColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 50,
      constraints: isPrimary ? null : const BoxConstraints(minWidth: 120),
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
              ),
            ),
    );
  }

  Widget _buildListHeader(Color primaryColor, bool isWeb, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 0 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '${widget.title} List',
                style: TextStyle(
                  fontSize: isWeb ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.filteredDatas.length}',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (isWeb)
            _buildSearchBar(isWeb: true, primaryColor: primaryColor)
          else
            const SizedBox(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, bool isWeb) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.searchQuery.isNotEmpty
                ? 'No matching ${widget.title.toLowerCase()}s found'
                : 'No ${widget.title.toLowerCase()}s yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Start by creating your first ${widget.title.toLowerCase()}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          if (!widget.searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                widget.nameController.clear();
                if (widget.descriptionController != null) {
                  widget.descriptionController?.clear();
                }
                // Focus on name field
                FocusScope.of(context).requestFocus(FocusNode());
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWebTable(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 1,
                  child: Text(
                    'S.No',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    '${widget.title} Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                if (widget.showDescription &&
                    widget.descriptionController != null)
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF475569),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.filteredDatas.length,
            itemBuilder: (context, index) {
              final item = widget.filteredDatas[index];
              final bool isEditing = _getId(widget.editingData) == _getId(item);

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isEditing
                        ? primaryColor.withValues(alpha: 0.05)
                        : index % 2 == 0
                        ? Colors.white
                        : const Color(0xFFFAFAFA),
                    border: Border(
                      bottom: index < widget.filteredDatas.length - 1
                          ? const BorderSide(color: Color(0xFFF1F5F9))
                          : BorderSide.none,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isEditing ? primaryColor : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isEditing
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          _getDisplayName(item),
                          style: TextStyle(
                            fontWeight: isEditing
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isEditing
                                ? primaryColor
                                : const Color(0xFF1E293B),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (widget.showDescription &&
                          widget.descriptionController != null)
                        Expanded(
                          flex: 3,
                          child: Text(
                            _getDescription(item),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionIcon(
                              icon: Icons.edit,
                              color: isEditing ? Colors.grey : primaryColor,
                              onPressed: isEditing
                                  ? null
                                  : () => widget.edit(item),
                              tooltip: 'Edit ${widget.title}',
                            ),
                            const SizedBox(width: 4),
                            _buildActionIcon(
                              icon: Icons.delete_outline,
                              color: Colors.red[400]!,
                              onPressed: () =>
                                  widget.delete(_getId(item), index),
                              tooltip: 'Delete ${widget.title}',
                            ),
                            const SizedBox(width: 4),
                            _buildActionIcon(
                              icon: Icons.info_outline,
                              color: Colors.blue[400]!,
                              onPressed: () =>
                                  _showDetailsDialog(item, primaryColor),
                              tooltip: 'View Details',
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
      ),
    );
  }

  Widget _buildMobileList(Color primaryColor) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.filteredDatas.length,
      itemBuilder: (context, index) {
        final item = widget.filteredDatas[index];
        final bool isEditing = _getId(widget.editingData) == _getId(item);

        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isEditing
                ? primaryColor.withValues(alpha: 0.05)
                : Colors.white,
            elevation: isEditing ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isEditing
                  ? BorderSide(color: primaryColor, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () => _showDetailsDialog(item, primaryColor),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isEditing
                            ? primaryColor
                            : primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isEditing ? Colors.white : primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDisplayName(item),
                            style: TextStyle(
                              fontWeight: isEditing
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isEditing
                                  ? primaryColor
                                  : const Color(0xFF1E293B),
                              fontSize: 16,
                            ),
                          ),
                          if (widget.showDescription &&
                              _getDescription(item).isNotEmpty)
                            Text(
                              _getDescription(item),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (isEditing)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Editing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionIcon(
                          icon: Icons.edit,
                          color: isEditing ? Colors.grey : primaryColor,
                          onPressed: isEditing ? null : () => widget.edit(item),
                          tooltip: 'Edit ${widget.title}',
                          size: 22,
                        ),
                        _buildActionIcon(
                          icon: Icons.delete_outline,
                          color: Colors.red[400]!,
                          onPressed: () => widget.delete(_getId(item), index),
                          tooltip: 'Delete ${widget.title}',
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    String? tooltip,
    double size = 20,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: size),
      tooltip: tooltip,
      splashRadius: 20,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        backgroundColor: onPressed != null
            ? color.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
    );
  }

  void _showDetailsDialog(dynamic item, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon ?? Icons.info,
                  color: primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getDisplayName(item),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              if (_getDescription(item).isNotEmpty)
                Text(
                  _getDescription(item),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              const SizedBox(height: 8),
              if (item.createdAt != null)
                Text(
                  'Created: ${_formatDate(item.createdAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.edit(item);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.delete(
                        _getId(item),
                        widget.filteredDatas.indexOf(item),
                      );
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
