//
//  KMNetAPI.m
//  InstantCare
//
//  Created by bruce-zhu on 15/12/4.
//  Copyright © 2015年 omg. All rights reserved.
//

#import "KMNetAPI.h"
#import "KMUserRegisterModel.h"
#import "AFNetworking.h"
#import "KMDeviceSettingModel.h"

@interface KMNetAPI()

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) KMRequestResultBlock requestBlock;

@end

@implementation KMNetAPI

+ (instancetype)manager
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.data = [NSMutableData data];
    }

    return self;
}

- (void)postWithURL:(NSString *)url body:(NSString *)body block:(KMRequestResultBlock)block
{
    // debug
    DMLog(@"->SEND: %@  %@", url, body);

    NSData *httpBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.timeoutInterval = 60;
    [request setURL:[NSURL URLWithString:url]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPBody:httpBody];
    
    self.requestBlock = block;
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

// 用户登录接口
- (void )loginWithUserName:(NSString *)name
                  password:(NSString *)password
                       gid:(NSString *)gid
                     block:(KMRequestResultBlock)block
{
    NSString *url = [NSString stringWithFormat:@"http://%@/service/m/auth/login", kServerAddress];
    //NSString *body = [NSString stringWithFormat:@"{\"loginToken\":\"%@\",\"passwd\":\"%@\",\"gid\":\"%@\"}", name, password, gid];
    NSString *body = [NSString stringWithFormat:@"{\"loginToken\":\"%@\",\"passwd\":\"%@\"}", name, password];

    [self postWithURL:url body:body block:block];
}

#pragma mark - 用户注册
- (void)userRegisterWithModel:(KMUserRegisterModel *)model
                        block:(KMRequestResultBlock)block
{
    NSString *url = [NSString stringWithFormat:@"http://%@/omoud/webservice/APIService/register", kServerAddress];

    [self postWithURL:url body:[model mj_JSONString] block:block];
}

#pragma mark - 拥有装置
- (void)getDevicesWithid:(NSString *)userId
                     key:(NSString *)key
                   block:(KMRequestResultBlock)block
{
    self.requestBlock = block;
    NSString *url = [NSString stringWithFormat:@"http://%@/service/m/device/devices?id=%@&key=%@",
                     kServerAddress,
                     userId,
                     key];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 60;

    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *jsonString = [[NSString alloc] initWithData:responseObject
                                                     encoding:NSUTF8StringEncoding];
        if (self.requestBlock) {
            self.requestBlock(0, jsonString);
        }
        self.requestBlock = nil;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (self.requestBlock) {
            self.requestBlock((int)error.code, nil);
        }
        self.requestBlock = nil;
    }];
}

#pragma mark - 设置设备参数
- (void)updateDeviceSettingsWithModel:(KMDeviceSettingModel *)model
                                block:(KMRequestResultBlock)block
{
    NSString *url = [NSString stringWithFormat:@"http://%@/service/m/device/setting", kServerAddress];
    
    [self postWithURL:url body:[model mj_JSONString] block:block];
}

#pragma mark - 取得设备当前设定
/**
 *  取得设备当前设定
 *
 *  @param userId 成功登陆服务器返回的id
 *  @param key    成功登陆服务器返回的key
 *  @param imei   设备IMEI
 *  @param block  结果返回block
 */
- (void)getDevicesSettingsWithid:(NSString *)userId
                             key:(NSString *)key
                            IMEI:(NSString *)imei
                           block:(KMRequestResultBlock)block
{
    self.requestBlock = block;
    NSString *url = [NSString stringWithFormat:@"http://%@/service/m/device/setting?id=%@&key=%@&target=%@",
                     kServerAddress,
                     userId,
                     key,
                     imei];
    DMLog(@"-> getDevicesSettingsWithid: %@", url);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 60;
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *jsonString = [[NSString alloc] initWithData:responseObject
                                                     encoding:NSUTF8StringEncoding];
        DMLog(@"<- RECV: %@", jsonString);
        if (self.requestBlock) {
            self.requestBlock(0, jsonString);
        }
        self.requestBlock = nil;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (self.requestBlock) {
            self.requestBlock((int)error.code, nil);
        }
        self.requestBlock = nil;
    }];
}

/**
 *  取得设备当前设定
 *
 *  @param imei  设备IMEI
 *  @param block 结果返回block
 */
- (void)getDevicesSettingsWithIMEI:(NSString *)imei
                             block:(KMRequestResultBlock)block
{
    [self getDevicesSettingsWithid:member.userModel.id
                               key:member.userModel.key
                              IMEI:imei
                             block:block];
}

#pragma mark - 设备绑定和删除
- (void)bundleNewDeviceWithIMEI:(NSString *)imei
                          block:(KMRequestResultBlock)block
{
    NSString *url = [NSString stringWithFormat:@"http://%@/service/m/device/bundle", kServerAddress];
    NSString *body = [NSString stringWithFormat:@"{\"id\":\"%@\",\"key\":\"%@\",\"device_id\":\"%@\",\"verifyCode\":\"12345\"}",
                      member.userModel.id,
                      member.userModel.key,
                      imei];

    [self postWithURL:url body:body block:block];
}

- (void)unbundleDeviceWithIMEI:(NSString *)imei
                         block:(KMRequestResultBlock)block
{
    NSString *url = [NSString stringWithFormat:@"http://%@/service/m/device/unbundle", kServerAddress];
    NSString *body = [NSString stringWithFormat:@"{\"id\":\"%@\",\"key\":\"%@\",\"device_id\":\"%@\"}",
                      member.userModel.id,
                      member.userModel.key,
                      imei];
    
    [self postWithURL:url body:body block:block];
}

#pragma mark - 取得定位记录
- (void)requestLocationSetWithIMEI:(NSString *)imei
                             block:(KMRequestResultBlock)block
{
    self.requestBlock = block;
    NSString *url = [NSString stringWithFormat:@"http://%@/service/m/location/set?id=%@&key=%@&target=%@",
                     kServerAddress,
                     member.userModel.id,
                     member.userModel.key,
                     imei];
    DMLog(@"-> %@", url);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 60;

    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *jsonString = [[NSString alloc] initWithData:responseObject
                                                     encoding:NSUTF8StringEncoding];
        DMLog(@"<- RECV: %@", jsonString);
        if (self.requestBlock) {
            self.requestBlock(0, jsonString);
        }
        self.requestBlock = nil;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (self.requestBlock) {
            self.requestBlock((int)error.code, nil);
        }
        self.requestBlock = nil;
    }];
}

#pragma mark - 连接成功
- (void)connection: (NSURLConnection *)connection didReceiveResponse: (NSURLResponse *)aResponse
{
    self.data.length = 0;
}

#pragma mark 存储数据
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)incomingData
{
    [self.data appendData:incomingData];
}

#pragma mark 完成加载
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *jsonData = [[NSString alloc] initWithData:self.data
                                               encoding:NSUTF8StringEncoding];

    // debug
    DMLog(@"<- RECV: %@", jsonData);

    if (self.requestBlock) {
        self.requestBlock(0, jsonData);
    }

    self.requestBlock = nil;
}

#pragma mark 连接错误
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.requestBlock) {
        self.requestBlock((int)error.code, nil);
    }

    self.requestBlock = nil;
}

@end
