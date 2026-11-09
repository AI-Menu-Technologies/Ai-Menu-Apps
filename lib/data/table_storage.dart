import 'package:shared_preferences/shared_preferences.dart';

class TableStorage {
  static const String _floorKey = 'selected_floor';
  static const String _tableIdKey = 'selected_table_id';
  static const String _tableNameKey = 'selected_table_name';

  /// Сохраняет выбранный этаж и стол.
  static Future<void> saveTable({
    required int floor,
    required String tableId,
    required String tableName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_floorKey, floor);
    await prefs.setString(_tableIdKey, tableId);
    await prefs.setString(_tableNameKey, tableName);
  }

  /// Возвращает выбранный этаж.
  static Future<int?> getFloor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_floorKey);
  }

  /// Возвращает ID выбранного стола.
  static Future<String?> getTableId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tableIdKey);
  }

  /// Возвращает название выбранного стола.
  static Future<String?> getTableName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tableNameKey);
  }

  /// Возвращает всю информацию о выбранном столе.
  static Future<SelectedTable?> getSelectedTable() async {
    final prefs = await SharedPreferences.getInstance();

    final floor = prefs.getInt(_floorKey);
    final tableId = prefs.getString(_tableIdKey);
    final tableName = prefs.getString(_tableNameKey);

    if (floor == null || tableId == null || tableName == null) {
      return null;
    }

    return SelectedTable(
      floor: floor,
      tableId: tableId,
      tableName: tableName,
    );
  }

  /// Удаляет выбранный стол.
  static Future<void> clearTable() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_floorKey);
    await prefs.remove(_tableIdKey);
    await prefs.remove(_tableNameKey);
  }
}

class SelectedTable {
  final int floor;
  final String tableId;
  final String tableName;

  const SelectedTable({
    required this.floor,
    required this.tableId,
    required this.tableName,
  });
}