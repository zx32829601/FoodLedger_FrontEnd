import 'package:flutter/material.dart';

/// FoodLedger 應用程式的根元件。
class FoodLedgerApp extends StatelessWidget {
  const FoodLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodLedger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: const _ProjectReadyPage(),
    );
  }
}

class _ProjectReadyPage extends StatelessWidget {
  const _ProjectReadyPage();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('FoodLedger')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text('專案初始化完成', style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '下一步將建立設計系統與響應式導覽架構。',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
