import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Request Cancellation & Spam Abort Tests', () {
    test('CancelToken aborts request and is recognized by isCancel', () async {
      final cancelToken = CancelToken();

      expect(cancelToken.isCancelled, isFalse);

      cancelToken.cancel('User navigated away / switched month');

      expect(cancelToken.isCancelled, isTrue);
      expect(cancelToken.cancelError, isNotNull);

      // Verify DioException cancel detection
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/transactions'),
        type: DioExceptionType.cancel,
        error: cancelToken.cancelError,
      );
      expect(CancelToken.isCancel(dioException), isTrue);
    });

    test('Rapid navigation spam cancels prior token and keeps latest active', () async {
      CancelToken? activeToken;
      final cancelledTokens = <CancelToken>[];

      void onMonthChanged(int month) {
        if (activeToken != null && !activeToken!.isCancelled) {
          activeToken!.cancel('Superseded by month $month');
          cancelledTokens.add(activeToken!);
        }
        activeToken = CancelToken();
      }

      // Simulate rapid user tapping (January -> February -> March -> April)
      onMonthChanged(1);
      final tokenJan = activeToken!;

      onMonthChanged(2);
      final tokenFeb = activeToken!;

      onMonthChanged(3);
      final tokenMar = activeToken!;

      onMonthChanged(4);
      final tokenApr = activeToken!;

      // Prior 3 tokens must be cancelled
      expect(tokenJan.isCancelled, isTrue);
      expect(tokenFeb.isCancelled, isTrue);
      expect(tokenMar.isCancelled, isTrue);
      expect(cancelledTokens.length, 3);

      // Latest token remains active
      expect(tokenApr.isCancelled, isFalse);
      expect(activeToken, equals(tokenApr));
    });
  });
}
