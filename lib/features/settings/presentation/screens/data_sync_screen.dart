import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:howtocook/features/settings/presentation/widgets/modern_data_sync_widget.dart';

/// 数据同步页面
class DataSyncScreen extends ConsumerWidget {
  const DataSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据同步'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: ModernDataSyncWidget(),
      ),
    );
  }
}