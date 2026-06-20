import 'package:flutter/material.dart';

class AdminReportsPanel extends StatefulWidget {
  const AdminReportsPanel({super.key});

  @override
  State<AdminReportsPanel> createState() => _AdminReportsPanelState();
}

class _AdminReportsPanelState extends State<AdminReportsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}