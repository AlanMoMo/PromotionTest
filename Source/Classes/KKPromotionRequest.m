//
//  KKPromotionRequest.m
//  KKPromotion
//
//  Created by aby.wang on 2019/12/19.
//

#import "KKPromotionRequest.h"
#import "KKPromotion.h"
#import "PromotionTool.h"
#import "CommonCode.h"
#if COCOPODS
#import <AFNetworking.h>
#else
#import <AFNetworking/AFNetworking.h>
#endif

#define PROMOTION_BASE_URL @"http://39.105.245.41:8080"

@interface KKPromotionRequest ()

@property(nonatomic, strong)AFURLSessionManager* session;
@property(nonatomic, strong, readonly)NSSet<NSString *> *HTTPMethodsEncodingParametersInURI;

@end


@implementation KKPromotionRequest

-(NSSet<NSString *> *)HTTPMethodsEncodingParametersInURI{
    return [[NSSet alloc] initWithArray:@[@"GET"]];
}

- (AFURLSessionManager *)session {
    if (!_session) {
        NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
    }
    return _session;
}

-(void)requestWithPath:(NSString*)path method:(PromotionRequestMethod)method urlParams:(NSDictionary * _Nullable)urlParams parameters:(NSDictionary *)params completion:(RequestCallBack)callback{
    dispatch_queue_t global = dispatch_get_global_queue(0, 0);
    dispatch_async(global, ^{
        NSString *urlString = [NSString stringWithFormat:@"%@%@", PROMOTION_BASE_URL, path];
        NSURL *url = [NSURL URLWithString:urlString];
        if (!url) {
            return;
        }
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
        request.HTTPMethod = [self methodString:method];
        NSString *token = [[KKPromotion sharedInstance] currentToken];
        if (token) {
            [request setValue:token forHTTPHeaderField:@"Authorization"];
        }
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        request = [self requestBySerializingRequest:request urlParams:urlParams params:params needConstants:![path isEqualToString:PROMOTION_LOGIN]];
        NSURLSessionDataTask* task = [self.session dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            callback(error, responseObject);
        }];
        [task resume];
    });
}

-(void)requestWithPath:(NSString*)path method:(PromotionRequestMethod)method parameters:(NSDictionary *)params completion:(RequestCallBack)callback{
    [self requestWithPath:path method:method urlParams:nil parameters:params completion:callback];
}

- (NSMutableURLRequest *)requestBySerializingRequest:(NSMutableURLRequest *)request urlParams:(NSDictionary*)urlParams params:(NSDictionary *)params needConstants:(BOOL)isNeed{
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    NSMutableDictionary* targetUrlParams = [self urlConstantsParams];
    if (urlParams) {
        [targetUrlParams addEntriesFromDictionary:urlParams];
    }
    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[request.HTTPMethod uppercaseString]]) {
        NSString *query = nil;
        [targetUrlParams addEntriesFromDictionary:params];
        query = AFQueryStringFromParameters(params);
        if (query && query.length > 0) {
            mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString] stringByAppendingFormat:mutableRequest.URL.query ? @"&%@" : @"?%@", query]];
        }
    } else {
        if (targetUrlParams) {
            NSString* query = nil;
            query = AFQueryStringFromParameters(targetUrlParams);
            if (query && query.length > 0) {
                mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString] stringByAppendingFormat:mutableRequest.URL.query ? @"&%@" : @"?%@", query]];
            }
        }
        if (params) {
            NSError* serializationError = nil;
            if ([NSJSONSerialization isValidJSONObject:params]) {
                mutableRequest = [[[AFJSONRequestSerializer serializer] requestBySerializingRequest:mutableRequest withParameters:params error:&serializationError] mutableCopy];
                if (serializationError) {
                    NSLog(@"参数数据转化有误：%@",serializationError.localizedFailureReason);
                }
            } else {
                NSLog(@"参数有误");
            }
        }
    }
    return mutableRequest;
}

#pragma mark - 私有方法
- (NSString *)methodString:(PromotionRequestMethod)method{
    NSString *result = @"get";
    switch (method) {
        case PromotionRequestPost:
            result = @"post";
            break;
        case PromotionRequestGet:
            result = @"get";
            break;
        case PromotionRequestDelete:
            result = @"put";
            break;
        default:
            break;
    }
    return result;
}

#pragma mark - 固定URL参数
- (NSMutableDictionary *)urlConstantsParams{
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    // 当前国家
    NSString* country = [PromotionTool getCountryName];
    [params setObject:country forKey:@"country"];
    // 当前语言
    NSString* language = [PromotionTool getPreferredLanguage];
    [params setObject:language forKey:@"language"];
    return params;
}

@end
