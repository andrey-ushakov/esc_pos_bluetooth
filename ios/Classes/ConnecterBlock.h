//
//  ConnecterBlock.h
//  GSDK
//

#ifndef ConnecterBlock_h
#define ConnecterBlock_h
#import <CoreBluetooth/CBPeripheral.h>

/**
 *  @enum ConnectState
 *  @discussion 连接状态
 *  @constant CONNECT_STATE_DISCONNECT ConnectDeviceState返回state为该状态是表示已断开连接
 *  @constant CONNECT_STATE_CONNECTING ConnectDeviceState返回state为该状态是表示正在连接中
 *  @constant CONNECT_STATE_CONNECTED  ConnectDeviceState返回state为该状态是表示连接成功
 *  @constant CONNECT_STATE_TIMEOUT    ConnectDeviceState返回state为该状态是表示连接超时
 *  @constant CONNECT_STATE_FAILT      ConnectDeviceState返回state为该状态是表示连接失败
 */
typedef enum : NSUInteger {
    NOT_FOUND_DEVICE,//未找到设备
    CONNECT_STATE_DISCONNECT,//断开连接
    CONNECT_STATE_CONNECTING,//连接中
    CONNECT_STATE_CONNECTED,//连接上
    CONNECT_STATE_TIMEOUT,//连接超时
    CONNECT_STATE_FAILT//连接失败
}ConnectState;

/**发现设备 Discover devices*/
typedef void(^DiscoverDevice)(CBPeripheral *_Nullable peripheral,NSDictionary<NSString *, id> * _Nullable advertisementData,NSNumber * _Nullable RSSI);
/**蓝牙状态更新 Bluetooth status update*/
typedef void(^UpdateState)(NSInteger state);
/**连接状态 Connection Status*/
typedef void(^ConnectDeviceState)(ConnectState state);
/**读取数据 Read data*/
typedef void(^ReadData)(NSData * _Nullable data);
/**发送数据进度  只适用于蓝牙发送数据 Sending data progress ** Only for Bluetooth sending data*/
typedef void(^WriteProgress)(NSUInteger total,NSUInteger progress);
typedef void (^Error)(id error);

#endif /* ConnecterBlock_h */
