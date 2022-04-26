//
//  ViewController.m
//  NNMapTrackPlayback
//
//  Created by 微克iOS on 2022/4/24.
//

#import "ViewController.h"
#import "MATraceReplayOverlay.h"
#import "MATraceReplayOverlayRender.h"

@import AMapFoundationKit;
@import MAMapKit;
@import AMapSearchKit;

@interface ViewController ()<MAMapViewDelegate, MATraceReplayOverlayRendererDelegate>

@property (nonatomic, strong) MATraceReplayOverlay *overlay;

@property (nonatomic, strong) MATraceReplayOverlayRenderer *overlayRenderer;

@property (nonatomic, strong) MAMapView *mapView;

@end

@implementation ViewController

#pragma mark - Lifecycle <生命周期>

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addsubviews];
}

#pragma mark - Custom Accessors <自定义访问器>
#pragma mark - IBActions <事件>
- (void)onAction:(UISegmentedControl *)control {
    
    switch (control.selectedSegmentIndex) {
        case 0:
            self.mapView.isAllowDecreaseFrame = YES;
            [self.overlayRenderer pause];
            break;
        case 1:
        {
            self.mapView.isAllowDecreaseFrame = NO;
            [self.overlayRenderer start];
        }
            break;
        case 2:
            [self.overlay reset];
            [self.overlayRenderer reset];
            break;
        default:
            break;
    }
}

#pragma mark - set/get <属性监听>
#pragma mark - Public <公有方法>
#pragma mark - Private <私有方法>
- (void) addsubviews {
    _mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
                                            [NSArray arrayWithObjects:
                                             @"暂停",
                                             @"开始",
                                             @"重置",
                                             nil]];
    segmentedControl.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    segmentedControl.tintColor = [UIColor blueColor];
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(onAction:) forControlEvents:UIControlEventValueChanged];
    [segmentedControl sizeToFit];
    segmentedControl.center = CGPointMake(self.view.bounds.size.width / 2, segmentedControl.bounds.size.height / 2 + 100);
    [self.view addSubview:segmentedControl];
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *mainBunldePath = [[NSBundle mainBundle] bundlePath];
        NSString *fileFullPath = [NSString stringWithFormat:@"%@/%@",mainBunldePath,@"TraceReplay.txt"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:fileFullPath]) {
            return;
        }
        
        NSData *data = [NSData dataWithContentsOfFile:fileFullPath];
        NSError *err = nil;
        NSArray *arr = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        if(!arr) {
            NSLog(@"[AMap]: %@", err);
            return;
        }
        
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[arr.firstObject objectForKey:@"lat"] doubleValue],
                                                                     [[arr.firstObject objectForKey:@"lon"] doubleValue]);
        NSMutableArray *locations = [NSMutableArray array];
        for(NSDictionary *dict in arr) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[[dict objectForKey:@"lat"] doubleValue]
                                                              longitude:[[dict objectForKey:@"lon"] doubleValue]];
            [locations addObject: location];
        }
        
        self.overlay = [[MATraceReplayOverlay alloc] initWithLocations:locations];
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.mapView addOverlay:weakSelf.overlay];
            weakSelf.mapView.zoomLevel = 10;
            [weakSelf.mapView setCenterCoordinate:location animated:NO];
        });
    });
}

#pragma mark - Protocol conformance <协议>

- (void)mapView:(MAMapView *)mapView didAddOverlayRenderers:(NSArray *)renderers
{
    NSLog(@"renderers :%@", renderers);
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MATraceReplayOverlay class]])
    {
        MATraceReplayOverlayRenderer *ret = [[MATraceReplayOverlayRenderer alloc] initWithOverlay:overlay];
        ret.carImage = [UIImage imageNamed:@"userPosition"];
        ret.lineWidth = 5;
        ret.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
        ret.delegate = self;
        ret.speed = 10000;
        self.overlayRenderer = ret;
        return ret;
    }
    return nil;
}

/**
 车辆点位和方向回调
 carPoint 车辆点位
 direction 方向0 - 360
 */
- (void) executionTraceReplayCarPoint: (MAMapPoint) carPoint runningDirection: (CGFloat) direction {
    [self.mapView setCenterCoordinate:MACoordinateForMapPoint(carPoint) animated:YES];
}

/**
 车辆所在的当前索引和点位回调
 cutIndex 车辆所在当前index
 cutIndexPoint index对应的point
 */
- (void) executionTraceReplayCutIndex: (NSInteger) cutIndex cutIndexPoint: (MAMapPoint) cutIndexPoint {
    
}


#pragma mark - Network request <网络请求>
#pragma mark - lazy <懒加载>


@end
