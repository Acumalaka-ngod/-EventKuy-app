import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventkuy/core/responsive.dart';
import 'package:eventkuy/models/event.dart';
import 'package:eventkuy/providers/favorite_provider.dart';
import 'package:eventkuy/services/mock_api_service.dart';
import 'package:eventkuy/widgets/event_card.dart';

final _event = Event(
  id: '11111111-1111-4111-8111-000000000001',
  title: 'Sound of Tomorrow',
  description: 'Festival musik terbesar tahun ini.',
  date: DateTime(2025, 7, 12),
  location: 'Istora Senayan, Jakarta',
  price: 750000,
  quota: 3000,
  imageUrl: 'assets/images/event_sound.jpg',
  category: 'Konser',
  tags: const ['Musik', 'Festival'],
  timeRange: '15:00 - 23:00',
);

void main() {
  for (final size in const [
    Size(390, 844), // HP
    Size(768, 1024), // Tablet
    Size(1080, 800), // Laptop kecil (kasus overflow 32px sebelumnya)
    Size(1400, 900), // Desktop (kasus overflow 6.6px sebelumnya)
  ]) {
    testWidgets(
      'EventGridCard tidak overflow pada ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final w = size.width;
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => FavoriteProvider(api: MockApiService()),
            child: MaterialApp(
              home: Scaffold(
                body: ConstrainedContent(
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: contentPadding(w)),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: eventGridColumns(w),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: eventGridAspect(w),
                    ),
                    itemCount: 4,
                    itemBuilder: (_, i) =>
                        EventGridCard(event: _event, onTap: () {}),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
