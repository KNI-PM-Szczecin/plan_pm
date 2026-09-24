// Stronicowanie zapytań do Supabase (fetchAllPages).
//
// PostgREST ucina odpowiedź do `max-rows` po cichu, więc błąd tutaj nie
// rzuca wyjątku — onboarding po prostu gubi kierunki z końca listy. Każdy
// test sprawdza, że wraca KOMPLET wierszy, i to w kolejności z bazy.
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/service/backend_service.dart';

/// Udaje PostgREST: `range(from, to)` na tabeli [total] wierszy, przycięte do
/// [serverMaxRows]. Liczy zapytania, żeby było widać koszt.
class FakeTable {
  FakeTable(this.total, {this.serverMaxRows = 1000});

  final int total;
  final int serverMaxRows;
  int requests = 0;

  Future<List<Map<String, dynamic>>> range(int from, int to) async {
    requests++;
    final end = [to + 1, from + serverMaxRows, total].reduce((a, b) => a < b ? a : b);
    return [for (var i = from; i < end; i++) {'id': i}];
  }
}

List<int> ids(List<Map<String, dynamic>> rows) => rows.map((r) => r['id'] as int).toList();

void main() {
  test('więcej wierszy niż limit — wracają wszystkie, po kolei', () async {
    final table = FakeTable(2500);
    final rows = await fetchAllPages(table.range);
    expect(ids(rows), List.generate(2500, (i) => i));
  });

  test('serwer ma limit niższy niż strona — nic nie ginie', () async {
    // Ktoś ustawi max-rows=500 w projekcie Supabase: strona 0–999 przyjdzie
    // z 500 wierszami. Zatrzymanie na „niepełnej stronie” ucięłoby resztę.
    final table = FakeTable(1700, serverMaxRows: 500);
    final rows = await fetchAllPages(table.range);
    expect(ids(rows), List.generate(1700, (i) => i));
  });

  test('liczba wierszy równa wielokrotności strony', () async {
    final table = FakeTable(2000);
    final rows = await fetchAllPages(table.range);
    expect(rows, hasLength(2000));
    expect(table.requests, 3, reason: 'dwie pełne strony + jedna pusta na koniec');
  });

  test('dzisiejszy rozmiar widoku mieści się w jednym zapytaniu + pustym', () async {
    final table = FakeTable(516);
    final rows = await fetchAllPages(table.range);
    expect(rows, hasLength(516));
    expect(table.requests, 2);
  });

  test('pusty widok daje pustą listę', () async {
    final table = FakeTable(0);
    expect(await fetchAllPages(table.range), isEmpty);
    expect(table.requests, 1);
  });
}
