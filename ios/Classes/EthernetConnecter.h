//
//  EthernetConnecter.h
//  GSDK
//

#import "Connecter.h"

@interface EthernetConnecter :Connecter
/**连接设备的ip地址*/
@property(nonatomic,strong)NSString *ip;
/**连接设备的端口号*/
@property(nonatomic,assign)int port;

//+(instancetype)sharedInstance;

/**
 *  方法说明: 连接设备
 *  @param ip 连接设备的ip地址
 *  @param port 连接设备的端口号
 *  @param connectState 连接状态    @see ConnectState
 *  @param callback 输入流数据回调
 */
-(void)connectIP:(NSString *)ip port:(int)port connectState:(void (^)(ConnectState state))connectState callback:(void(^)(NSData *data))callback;

-(void)connectIP:(NSString *)ip port:(int)port connectState:(void (^)(ConnectState))connectState;

@end
