//
//  Connecter.h
//  GSDK
//

#import "Connecter.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BLEConnecter :Connecter

@property(nonatomic,strong)CBCharacteristic *airPatchChar;
@property(nonatomic,strong)CBCharacteristic *transparentDataWriteChar;
@property(nonatomic,strong)CBCharacteristic *transparentDataReadOrNotifyChar;
@property(nonatomic,strong)CBCharacteristic *connectionParameterChar;

@property(nonatomic,strong)CBUUID *transServiceUUID;
@property(nonatomic,strong)CBUUID *transTxUUID;
@property(nonatomic,strong)CBUUID *transRxUUID;
@property(nonatomic,strong)CBUUID *disUUID1;
@property(nonatomic,strong)CBUUID *disUUID2;
@property(nonatomic,strong)NSArray *serviceUUID;

@property(nonatomic,copy)DiscoverDevice discover;
@property(nonatomic,copy)UpdateState updateState;
@property(nonatomic,copy)WriteProgress writeProgress;

/**数据包大小，默认130个字节*/
@property(nonatomic,assign)NSUInteger datagramSize;

@property(nonatomic,strong)CBPeripheral *connPeripheral;

//+(instancetype)sharedInstance;

/**
 *  方法说明:设置特定的Service UUID，以及Service对应的具有读、写特征值
 *  @param serviceUUID 蓝牙模块的service uuid
 *  @param txUUID   具有写入权限特征值
 *  @param rxUUID   具有读取权限特征值
 */
- (void)configureTransparentServiceUUID: (NSString *)serviceUUID txUUID:(NSString *)txUUID rxUUID:(NSString *)rxUUID;

/**
 *  方法说明：扫描外设
 *  @param serviceUUIDs 需要连接的外设UUID
 *  @param options 其它可选操作
 *  @param discover 发现设备
 *         peripheral 发现的外设
 *         advertisementData
 *         RSSI 外设信号强度
 */
-(void)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options discover:(void(^_Nullable)(CBPeripheral *_Nullable peripheral,NSDictionary<NSString *, id> *_Nullable advertisementData,NSNumber *_Nullable RSSI))discover;

/**
 *  方法说明：停止扫描蓝牙外设
 */
-(void)stopScan;

/**
 *  方法说明：更新蓝牙状态
 *  @param state 更新蓝牙状态
 */
-(void)didUpdateState:(void(^_Nullable)(NSInteger state))state;

/**
 *  方法说明：连接外设
 *  @param peripheral 需要连接的外设
 *  @param options 其它可选操作
 *  @param timeout 连接超时
 *  @param connectState 连接状态
 */
-(void)connectPeripheral:(CBPeripheral *_Nullable)peripheral options:(nullable NSDictionary<NSString *,id> *)options timeout:(NSUInteger)timeout connectBlack:(void(^_Nullable)(ConnectState state)) connectState;

/**
 *  方法说明：连接外设
 *  @param peripheral 需要连接的外设
 *  @param options 其它可选操作
 */
-(void)connectPeripheral:(CBPeripheral * _Nullable)peripheral options:(nullable NSDictionary<NSString *,id> *)options;

/**
 *  方法说明：断开连接
 *  @param  peripheral 需要断开连接的外设
 */
-(void)closePeripheral:(nonnull CBPeripheral *)peripheral;

/**
 *  方法说明: 往蓝牙模块中写入数据 // Method description: write data to Bluetooth module
 *  @param  data 往蓝牙模块中写入的数据 // Data written to the Bluetooth module
 *  @param  progress 写入数据的进度 // Progress of writing data
 *  @param callBack 读取蓝牙模块返回数据 // Read Bluetooth module data
 */
-(void)write:(NSData *_Nullable)data progress:(void(^_Nullable)(NSUInteger total,NSUInteger progress))progress receCallBack:(void (^_Nullable)(NSData *_Nullable))callBack;

/**
 *  方法说明: 往蓝牙模块中写入数据 // Method description: write data to Bluetooth module
 *  @param characteristic   特征值
 *  @param data 往蓝牙模块中写入的数据 // Data written to the Bluetooth module
 *  @param type  写入方式<b>CBCharacteristicWriteWithResponse</b>写入方式是带流控写入方式。<b>CBCharacteristicWriteWithoutResponse</b>不带流控写入方式 <p><b>@see CBCharacteristicWriteType</b></p>
 * Writing method <b>CBCharacteristicWriteWithResponse</b> The writing method is a writing method with flow control. <b>CBCharacteristicWriteWithoutResponse</b>Without flow control write method <p><b>@see CBCharacteristicWriteType</b></p>
 */
-(void)writeValue:(NSData *)data forCharacteristic:(nonnull CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;
@end
