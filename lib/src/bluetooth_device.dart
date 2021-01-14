class BluetoothDevice {
  String name;
  String address;
  int type;
  bool connected;

  BluetoothDevice({this.name, this.address, this.type, this.connected});

  BluetoothDevice.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    address = json['address'];
    type = json['type'];
    connected = json['connected'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['address'] = this.address;
    data['type'] = this.type;
    data['connected'] = this.connected;
    return data;
  }
}