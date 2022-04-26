//
//  MATraceReplayOverlay.h
//  MAMapKit
//
//  Created by shaobin on 2017/4/20.
//  Copyright © 2017年 Amap. All rights reserved.
//

@import Foundation;
@import MAMapKit;
@import UIKit;

typedef void(^MACallBackDirection)(void);

///轨迹回放overlay（since 5.1.0）
@interface MATraceReplayOverlay : MABaseOverlay

///是否启动点抽稀，默认YES
@property (nonatomic, assign) BOOL enablePointsReduce;

///各个点权重设置，取值1-5，5最大。权重为5则不对此点做抽稀。格式为：{weight:indices}
@property (nonatomic, strong) NSDictionary<NSNumber*, NSArray*> *pointsWeight;

///小汽车移动速度，默认80 km/h, 单位米每秒  默认 1000米
@property (nonatomic, assign) CGFloat speed;

///是否自动调整车头方向，默认NO
@property (nonatomic, assign) BOOL enableAutoCarDirection;

///是否暂停, 初始为YES
@property (nonatomic, assign) BOOL isPaused;

/// 方向改变回调
@property (nonatomic, copy) MACallBackDirection callBackDirection;

/**
 根据经纬度数组初始化轨迹
 locations 经纬度数组
 */
- (instancetype) initWithLocations: (NSArray <CLLocation *>*) locations;

/**
 * @brief 重置为初始状态
 */
- (void)reset;

/**
 * @brief 获取行进方向,in radian
 */
- (CGFloat)getRunningDirection;

/**
 * @brief 获取小车位置
 */
- (MAMapPoint)getCarPosition;

/**
 * @brief 获取当前car所在位置点索引
 */
- (NSInteger)getOrigPointIndexOfCar;

/**
 * @brief 获取抽稀后当前car所在位置点索引
 */
- (NSInteger)getReducedPointIndexOfCar;

/**
 * @brief 获取索引index对应的mapPoint
 */
- (MAMapPoint)getMapPointOfIndex:(NSInteger)origIndex;

/**
 * @brief 预处理，加快后面的操作流畅度. 调用前不要把overlay加到mapview，在callback中再把overlay加到mapview
 */
- (void)prepareAsync:(void(^)(void))callback;

@end
