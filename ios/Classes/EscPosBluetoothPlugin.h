#import <Flutter/Flutter.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ConnecterManager.h"

@interface EscPosBluetoothPlugin : NSObject<FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate>
@property(nonatomic,copy)ConnectDeviceState state;
@end

@interface EscPosBluetoothStreamHandler : NSObject<FlutterStreamHandler>
@property FlutterEventSink sink;
@end
