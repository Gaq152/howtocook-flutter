import 'package:hive/hive.dart';
import '../../domain/entities/ai_model_config.dart';

/// Hive TypeAdapter for APICallRecord
/// TypeId: 2
class APICallRecordAdapter extends TypeAdapter<APICallRecord> {
  @override
  final int typeId = 2;

  @override
  APICallRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return APICallRecord(
      id: fields[0] as String,
      modelId: fields[1] as String,
      timestamp: fields[2] as DateTime,
      usedBuiltinKey: fields[3] as bool,
      provider: AIProvider.values[fields[4] as int],
    );
  }

  @override
  void write(BinaryWriter writer, APICallRecord obj) {
    writer
      ..writeByte(5)  // 5 个字段
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.modelId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.usedBuiltinKey)
      ..writeByte(4)
      ..write(obj.provider.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is APICallRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
