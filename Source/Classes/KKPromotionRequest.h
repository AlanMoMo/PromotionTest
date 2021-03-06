//
//  KKPromotionRequest.h
//  KKPromotion
//
//  Created by aby.wang on 2019/12/19.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    PromotionRequestPost,
    PromotionRequestGet,
    PromotionRequestDelete,
} PromotionRequestMethod;

typedef void(^RequestCallBack)( NSError * _Nullable error,  id _Nullable responseObject);

NS_ASSUME_NONNULL_BEGIN

@interface KKPromotionRequest : NSObject

-(void)requestWithPath:(NSString*)path method:(PromotionRequestMethod)method parameters:(NSDictionary *)params completion:(RequestCallBack)callback;
-(void)requestWithPath:(NSString*)path method:(PromotionRequestMethod)method urlParams:(NSDictionary * _Nullable)urlParams parameters:(NSDictionary *)params completion:(RequestCallBack)callback;
@end

NS_ASSUME_NONNULL_END
