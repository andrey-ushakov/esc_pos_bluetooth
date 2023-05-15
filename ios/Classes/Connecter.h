//
//  Connecter.h
//  GSDK
//
#import <Foundation/Foundation.h>
#import "ConnecterBlock.h"

@interface Connecter:NSObject

//读取数据
@property(nonatomic,copy)ReadData readData;
//连接状态
@property(nonatomic,copy)ConnectDeviceState state;

/**
 * 方法说明: 连接 // Method description: connect
 */
-(void)connect;

/**
 *  方法说明: 连接到指定设备 // Method description: connect to the specified device
 *  @param connectState 连接状态
 */
-(void)connect:(void(^)(ConnectState state))connectState;

/**
 * 方法说明: 关闭连接
 */
-(void)close;

/**
 *  发送数据 // send data
 *  向输出流中写入数据 // Write data to the output stream
 */
-(void)write:(NSData *)data receCallBack:(void(^)(NSData *data))callBack;
-(void)write:(NSData *)data;

/**
 *  读取数据
 *  @parma data 读取到的数据
 */
-(void)read:(void(^)(NSData *data))data;

@end
