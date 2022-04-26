//
//  MATraceReplayOverlayRender.h
//  MAMapKit
//
//  Created by shaobin on 2017/4/20.
//  Copyright © 2017年 Amap. All rights reserved.
//

@import UIKit;
@import MAMapKit;

@class MATraceReplayOverlay;

@protocol MATraceReplayOverlayRendererDelegate <NSObject>

/**
 车辆点位和方向回调
 carPoint 车辆点位
 direction 方向0 - 360
 */
- (void) executionTraceReplayCarPoint: (MAMapPoint) carPoint runningDirection: (CGFloat) direction;

/**
 车辆所在的当前索引和点位回调
 cutIndex 车辆所在当前index
 cutIndexPoint index对应的point
 */
- (void) executionTraceReplayCutIndex: (NSInteger) cutIndex cutIndexPoint: (MAMapPoint) cutIndexPoint;

@end

///轨迹回放overlay渲染器（since 5.1.0）
@interface MATraceReplayOverlayRenderer : MAOverlayPathRenderer

///轨迹回放图标
@property (nonatomic, strong) UIImage *carImage;

///小汽车移动速度，默认80 km/h, 单位米每秒
@property (nonatomic, assign) CGFloat speed;

///是否自动调整车头方向，默认YES
@property (nonatomic, assign) BOOL enableAutoCarDirection;

/// 代理
@property (nonatomic, weak) id<MATraceReplayOverlayRendererDelegate> delegate;

/// 开始
- (void) start;

/// 暂停
- (void) pause;

/// 重置
- (void)reset;

@end
