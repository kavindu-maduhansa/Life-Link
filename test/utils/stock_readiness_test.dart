import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hci/models/blood_inventory.dart';
import 'package:hci/utils/stock_readiness.dart';

/// Tests for blood stock readiness: the parsing of a `bloodInventory`
/// document and the threshold policy that turns it into a warning.
///
/// A fixed `now` is passed everywhere freshness matters, so these tests
/// do not depend on the wall clock.
void main() {
  final now = DateTime(2026, 4, 10, 12, 0);

  BloodInventoryItem item({
    int available = 10,
    int reserved = 0,
    int minimum = 4,
    int expiryRisk = 0,
    DateTime? updatedAt,
    String group = 'O+',
    String component = BloodComponent.packedRedCells,
  }) {
    return BloodInventoryItem(
      id: 'inv-1',
      facilityId: 'GH-COL-01',
      bloodGroup: group,
      component: component,
      availableUnits: available,
      reservedUnits: reserved,
      minimumThreshold: minimum,
      expiryRiskUnits: expiryRisk,
      updatedAt: updatedAt ?? now.subtract(const Duration(hours: 1)),
      updatedBy: 'doctor-1',
    );
  }

  group('BloodInventoryItem.fromMap', () {
    test('reads a complete document', () {
      final parsed = BloodInventoryItem.fromMap('inv-9', {
        'facilityId': 'GH-COL-01',
        'bloodGroup': 'o-',
        'component': BloodComponent.platelets,
        'availableUnits': 6,
        'reservedUnits': 2,
        'minimumThreshold': 5,
        'expiryRiskUnits': 1,
        'updatedAt': Timestamp.fromDate(now),
        'updatedBy': 'doctor-2',
      });

      expect(parsed.id, 'inv-9');
      expect(parsed.bloodGroup, 'O-', reason: 'blood group is normalised to upper case');
      expect(parsed.component, BloodComponent.platelets);
      expect(parsed.usableUnits, 4);
      expect(parsed.updatedAt, now);
      expect(parsed.updatedBy, 'doctor-2');
    });

    test('an empty document parses with safe defaults instead of throwing', () {
      final parsed = BloodInventoryItem.fromMap('inv-empty', const <String, dynamic>{});

      expect(parsed.bloodGroup, '-');
      expect(parsed.component, BloodComponent.wholeBlood);
      expect(parsed.availableUnits, 0);
      expect(parsed.minimumThreshold, 0);
      expect(parsed.hasThreshold, isFalse);
      expect(parsed.updatedAt, isNull);
    });

    test('negative and wrong-typed counts resolve to zero', () {
      final parsed = BloodInventoryItem.fromMap('inv-bad', {'availableUnits': -5, 'reservedUnits': 'three', 'minimumThreshold': null});

      expect(parsed.availableUnits, 0);
      expect(parsed.reservedUnits, 0);
      expect(parsed.minimumThreshold, 0);
    });

    test('a null map does not throw', () {
      expect(() => BloodInventoryItem.fromMap('inv-null', null), returnsNormally);
    });
  });

  group('usableUnits', () {
    test('is available minus reserved', () {
      expect(item(available: 10, reserved: 3).usableUnits, 7);
    });

    test('never goes negative, and over-reservation is flagged', () {
      final over = item(available: 2, reserved: 5);
      expect(over.usableUnits, 0);
      expect(over.hasOverReservation, isTrue);
    });

    test('a normal line is not flagged as over-reserved', () {
      expect(item(available: 5, reserved: 5).hasOverReservation, isFalse);
    });
  });

  group('StockReadiness.levelFor', () {
    test('no usable units is out of stock', () {
      expect(StockReadiness.levelFor(item(available: 0)), StockLevel.outOfStock);
      expect(StockReadiness.levelFor(item(available: 4, reserved: 4)), StockLevel.outOfStock);
    });

    test('below half the minimum is a critical shortage', () {
      // minimum 10 -> critical under 5
      expect(StockReadiness.levelFor(item(available: 4, minimum: 10)), StockLevel.criticalShortage);
    });

    test('exactly half the minimum is low stock, not critical', () {
      expect(StockReadiness.levelFor(item(available: 5, minimum: 10)), StockLevel.lowStock);
    });

    test('below the minimum but at or above half is low stock', () {
      expect(StockReadiness.levelFor(item(available: 9, minimum: 10)), StockLevel.lowStock);
    });

    test('at the minimum is adequate', () {
      expect(StockReadiness.levelFor(item(available: 10, minimum: 10)), StockLevel.adequate);
    });

    test('above the minimum is adequate', () {
      expect(StockReadiness.levelFor(item(available: 40, minimum: 10)), StockLevel.adequate);
    });

    test('a line with no recorded minimum is not scored against an invented one', () {
      expect(StockReadiness.levelFor(item(available: 1, minimum: 0)), StockLevel.noThreshold);
    });

    test('out of stock wins even when no minimum is recorded', () {
      expect(StockReadiness.levelFor(item(available: 0, minimum: 0)), StockLevel.outOfStock);
    });
  });

  group('StockLevel semantics', () {
    test('out of stock and critical shortage are the critical levels', () {
      expect(StockLevel.outOfStock.isCritical, isTrue);
      expect(StockLevel.criticalShortage.isCritical, isTrue);
      expect(StockLevel.lowStock.isCritical, isFalse);
      expect(StockLevel.adequate.isCritical, isFalse);
      expect(StockLevel.noThreshold.isCritical, isFalse);
    });

    test('adequate and unscored lines need no attention', () {
      expect(StockLevel.adequate.needsAttention, isFalse);
      expect(StockLevel.noThreshold.needsAttention, isFalse);
      expect(StockLevel.lowStock.needsAttention, isTrue);
    });

    test('sort order is worst first, with unscored lines last', () {
      final ordered = StockLevel.values.toList()..sort((a, b) => a.sortWeight.compareTo(b.sortWeight));
      expect(ordered.first, StockLevel.outOfStock);
      expect(ordered.last, StockLevel.noThreshold);
    });
  });

  group('StockReadiness.freshnessFor', () {
    test('an update within 24 hours is current', () {
      expect(StockReadiness.freshnessFor(item(updatedAt: now.subtract(const Duration(hours: 23))), now: now), StockFreshness.current);
    });

    test('exactly 24 hours old is still current', () {
      expect(StockReadiness.freshnessFor(item(updatedAt: now.subtract(const Duration(hours: 24))), now: now), StockFreshness.current);
    });

    test('older than 24 hours is stale', () {
      expect(StockReadiness.freshnessFor(item(updatedAt: now.subtract(const Duration(hours: 25))), now: now), StockFreshness.stale);
    });

    test('a line with no timestamp is neverRecorded, not assumed current', () {
      final noStamp = BloodInventoryItem.fromMap('inv-x', {'availableUnits': 5});
      expect(StockReadiness.freshnessFor(noStamp, now: now), StockFreshness.neverRecorded);
      expect(StockReadiness.freshnessFor(noStamp, now: now).isTrustworthy, isFalse);
    });
  });

  group('StockReadiness.verdictFor', () {
    test('explains the free-unit arithmetic in plain language', () {
      final verdict = StockReadiness.verdictFor(item(available: 10, reserved: 3, minimum: 8), now: now);
      expect(verdict.usableUnits, 7);
      expect(verdict.reasons.any((r) => r.contains('7 unit(s) free')), isTrue);
      expect(verdict.reasons.any((r) => r.contains('minimum for this line is 8')), isTrue);
    });

    test('says so explicitly when no minimum is recorded', () {
      final verdict = StockReadiness.verdictFor(item(minimum: 0), now: now);
      expect(verdict.reasons.any((r) => r.contains('No minimum threshold is recorded')), isTrue);
    });

    test('surfaces expiry risk and marks the line as needing attention', () {
      final verdict = StockReadiness.verdictFor(item(available: 40, minimum: 5, expiryRisk: 3), now: now);
      expect(verdict.level, StockLevel.adequate);
      expect(verdict.hasExpiryRisk, isTrue);
      expect(verdict.needsAttention, isTrue, reason: 'expiry risk alone should draw the eye');
      expect(verdict.reasons.any((r) => r.contains('close to expiry')), isTrue);
    });

    test('surfaces an over-reservation as a data problem', () {
      final verdict = StockReadiness.verdictFor(item(available: 2, reserved: 6), now: now);
      expect(verdict.hasOverReservation, isTrue);
      expect(verdict.reasons.first, contains('Data problem'));
    });

    test('a stale line needs attention even when stock is adequate', () {
      final verdict = StockReadiness.verdictFor(
        item(available: 40, minimum: 5, updatedAt: now.subtract(const Duration(days: 4))),
        now: now,
      );
      expect(verdict.level, StockLevel.adequate);
      expect(verdict.freshness, StockFreshness.stale);
      expect(verdict.needsAttention, isTrue);
    });

    test('a healthy, current, fully-stocked line needs no attention', () {
      final verdict = StockReadiness.verdictFor(item(available: 40, reserved: 2, minimum: 5), now: now);
      expect(verdict.needsAttention, isFalse);
    });
  });

  group('StockReadiness.compare', () {
    test('sorts the worst level first', () {
      final items = [
        item(available: 40, minimum: 5, group: 'A+'),
        item(available: 0, minimum: 5, group: 'B+'),
        item(available: 4, minimum: 10, group: 'AB+'),
      ]..sort((a, b) => StockReadiness.compare(a, b));

      expect(StockReadiness.levelFor(items[0]), StockLevel.outOfStock);
      expect(StockReadiness.levelFor(items[1]), StockLevel.criticalShortage);
      expect(StockReadiness.levelFor(items[2]), StockLevel.adequate);
    });

    test('within the same level, sorts by the standard blood-group order', () {
      final items = [
        item(available: 40, minimum: 5, group: 'AB+'),
        item(available: 40, minimum: 5, group: 'O-'),
        item(available: 40, minimum: 5, group: 'A+'),
      ]..sort((a, b) => StockReadiness.compare(a, b));

      expect(items.map((i) => i.bloodGroup).toList(), ['O-', 'A+', 'AB+']);
    });
  });

  group('StockReadiness.summaryLine', () {
    test('is null for an empty inventory, so the header stays quiet', () {
      expect(StockReadiness.summaryLine(const [], now: now), isNull);
    });

    test('is null when every line is healthy', () {
      final healthy = [item(available: 40, minimum: 5), item(available: 30, minimum: 5)];
      expect(StockReadiness.summaryLine(healthy, now: now), isNull);
    });

    test('counts critical, low, expiring and stale lines', () {
      final mixed = [
        item(available: 0, minimum: 5, group: 'O-'),
        item(available: 4, minimum: 10, group: 'O+'),
        item(available: 9, minimum: 10, group: 'A+'),
        item(available: 40, minimum: 5, group: 'B+', expiryRisk: 2),
        item(available: 40, minimum: 5, group: 'AB+', updatedAt: now.subtract(const Duration(days: 3))),
      ];
      final summary = StockReadiness.summaryLine(mixed, now: now)!;

      expect(summary, contains('2 critical'));
      expect(summary, contains('1 low'));
      expect(summary, contains('1 expiring soon'));
      expect(summary, contains('1 needs a stock check'));
    });
  });

  group('BloodComponent', () {
    test('short labels are distinct for the known components', () {
      final shorts = BloodComponent.all.map(BloodComponent.shortLabel).toSet();
      expect(shorts.length, BloodComponent.all.length);
    });

    test('an unknown component is displayed as-is, never dropped', () {
      expect(BloodComponent.shortLabel('Granulocytes'), 'Granulocytes');
      expect(BloodComponent.isKnown('Granulocytes'), isFalse);
    });

    test('an empty component renders as a dash rather than nothing', () {
      expect(BloodComponent.shortLabel(''), '—');
    });
  });
}
