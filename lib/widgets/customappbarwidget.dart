import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitleDate;
  final String? initials;
  final bool showBackButton;
  final List<Widget>? actions; // Add actions parameter

  const CustomAppBarWidget({
    Key? key,
    required this.title,
    this.subtitleDate,
    this.initials,
    this.showBackButton = false,
    this.actions, // Add this
  }) : super(key: key);

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final bool displayBackButton = showBackButton || _isMobile(context);

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      leading: displayBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        onPressed: () => context.pop(),
        tooltip: 'Back',
      )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (subtitleDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Today', style: TextStyle(color: Colors.grey)),
                Text(
                  subtitleDate!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        if (actions != null) ...actions!, // Add custom actions
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}