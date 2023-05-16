part 'bluetooth_device.g.dart';

class BluetoothDevice {
  BluetoothDevice();

  String? name;
  String? address;
  int? type = 0;
  bool? connected = false;

  factory BluetoothDevice.fromJson(Map<String, dynamic> json) => _$BluetoothDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$BluetoothDeviceToJson(this);
}
