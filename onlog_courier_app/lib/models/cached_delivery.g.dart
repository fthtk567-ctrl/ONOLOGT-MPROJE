// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_delivery.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedDeliveryAdapter extends TypeAdapter<CachedDelivery> {
  @override
  final int typeId = 0;

  @override
  CachedDelivery read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedDelivery(
      id: fields[0] as String,
      merchantId: fields[1] as String,
      merchantName: fields[2] as String,
      merchantAddress: fields[3] as String,
      pickupLat: fields[4] as double?,
      pickupLng: fields[5] as double?,
      deliveryAddress: fields[6] as String,
      deliveryLat: fields[7] as double?,
      deliveryLng: fields[8] as double?,
      declaredAmount: fields[9] as double,
      packageCount: fields[10] as int,
      status: fields[11] as String,
      assignedCourierId: fields[12] as String?,
      courierType: fields[13] as String?,
      createdAt: fields[14] as DateTime,
      assignedAt: fields[15] as DateTime?,
      pickedUpAt: fields[16] as DateTime?,
      deliveredAt: fields[17] as DateTime?,
      notes: fields[18] as String?,
      customerPhone: fields[19] as String?,
      customerName: fields[20] as String?,
      isSynced: fields[21] as bool,
      lastUpdated: fields[22] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedDelivery obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.merchantId)
      ..writeByte(2)
      ..write(obj.merchantName)
      ..writeByte(3)
      ..write(obj.merchantAddress)
      ..writeByte(4)
      ..write(obj.pickupLat)
      ..writeByte(5)
      ..write(obj.pickupLng)
      ..writeByte(6)
      ..write(obj.deliveryAddress)
      ..writeByte(7)
      ..write(obj.deliveryLat)
      ..writeByte(8)
      ..write(obj.deliveryLng)
      ..writeByte(9)
      ..write(obj.declaredAmount)
      ..writeByte(10)
      ..write(obj.packageCount)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.assignedCourierId)
      ..writeByte(13)
      ..write(obj.courierType)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.assignedAt)
      ..writeByte(16)
      ..write(obj.pickedUpAt)
      ..writeByte(17)
      ..write(obj.deliveredAt)
      ..writeByte(18)
      ..write(obj.notes)
      ..writeByte(19)
      ..write(obj.customerPhone)
      ..writeByte(20)
      ..write(obj.customerName)
      ..writeByte(21)
      ..write(obj.isSynced)
      ..writeByte(22)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedDeliveryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
