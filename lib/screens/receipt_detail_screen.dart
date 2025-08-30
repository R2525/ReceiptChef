// lib/screens/receipt_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_item.dart';
import '../providers/auth_provider.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final Receipt receipt;

  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    // 품목을 카테고리별로 그룹화
    final Map<String, List<PaymentItem>> groupedItems = {};
    for (var item in receipt.items) {
      (groupedItems[item.category] ??= []).add(item);
    }

    // 카테고리 순서 정의
    final categoryOrder = ['식자재', '가공품', '기타'];
    final sortedCategories = groupedItems.keys.toList()
      ..sort((a, b) => categoryOrder.indexOf(a).compareTo(categoryOrder.indexOf(b)));

    return Scaffold(
      appBar: AppBar(
        title: Text(receipt.store),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 영수증 이미지 표시
            Image.file(
              receipt.imageFile,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),

            // 2. 구매 목록 표시
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '구매 목록',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  // 3. 카테고리별로 품목 리스트 출력
                  ...sortedCategories.map((category) {
                    final items = groupedItems[category]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            category,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        ...items.map((item) => ListTile(
                          title: Text(item.name),
                          trailing: Text('${NumberFormat('#,###').format(item.amount)}원'),
                        )),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
