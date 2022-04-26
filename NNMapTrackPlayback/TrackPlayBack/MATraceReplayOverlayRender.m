//
//  MATraceReplayOverlayRender.m
//  MAMapKit
//
//  Created by shaobin on 2017/4/20.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "MATraceReplayOverlayRender.h"
#import "MATraceReplayOverlay.h"
#import "MATraceReplayOverlay+Addition.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>

typedef struct _MADrawPoint {
    float x;
    float y;
} MADrawPoint;

@interface MATraceReplayOverlayRenderer () {
    MAMultiColoredPolylineRenderer *_proxyRender;
    MAPolylineRenderer *_patchLineRender;
    
    NSTimeInterval _prevTime;

    CGPoint _imageMapPoints[4];
    GLuint _textureName;
    GLuint _programe;
    GLuint _uniform_viewMatrix_location;
    GLuint _uniform_projMatrix_location;
    GLuint _attribute_position_location;
    GLuint _attribute_texCoord_location;
}

@end

@implementation MATraceReplayOverlayRenderer

#pragma mark - Lifecycle <生命周期>
- (id)initWithOverlay:(id<MAOverlay>)overlay {
    if(![overlay isKindOfClass:[MATraceReplayOverlay class]]) {
        return nil;
    }
    self = [super initWithOverlay:overlay];
    if(self) {
        self.enableAutoCarDirection = YES;
        [self setDefaultConfiguration];
    }
    return self;
}

- (void)dealloc
{
    if(_textureName) {
        glDeleteTextures(1, &_textureName);
        _textureName = 0;
    }
}
#pragma mark - Custom Accessors <自定义访问器>
#pragma mark - IBActions <事件>
#pragma mark - set/get <属性监听>

/// 设置代理
- (void)setRendererDelegate:(id<MAOverlayRenderDelegate>)rendererDelegate {
    [super setRendererDelegate:rendererDelegate];
    _proxyRender.rendererDelegate = rendererDelegate;
    _patchLineRender.rendererDelegate = rendererDelegate;
}

/// 设置线宽
- (void)setLineWidth:(CGFloat)lineWidth {
    [super setLineWidth:lineWidth];
    _proxyRender.lineWidth = lineWidth;
    _patchLineRender.lineWidth = lineWidth;
}

/// 设置单线颜色
- (void)setStrokeColor:(UIColor *)strokeColor {
    [super setStrokeColor:strokeColor];
    
    NSMutableArray *colors = [NSMutableArray arrayWithObject:strokeColor];
    [colors addObject:[UIColor clearColor]];
    _proxyRender.strokeColors = colors;
    _patchLineRender.strokeColor = strokeColor;
}

/// 速度设置
- (void)setSpeed:(CGFloat)speed {
    _speed = speed;
    self.traceOverlay.speed = _speed;
}

/// 车辆角度是否跟随
- (void)setEnableAutoCarDirection:(BOOL)enableAutoCarDirection {
    _enableAutoCarDirection = enableAutoCarDirection;
    self.traceOverlay.enableAutoCarDirection = _enableAutoCarDirection;
}

/// 开始
- (void) start {
    self.traceOverlay.isPaused = NO;
    _prevTime = 0;
}

/// 暂停
- (void) pause {
    self.traceOverlay.isPaused = YES;
    _prevTime = 0;
}

/// 重置
- (void)reset {
    [self.traceOverlay reset];
    _prevTime = 0;
}

/// 转换一下overlay
- (MATraceReplayOverlay *) traceOverlay {
    return (MATraceReplayOverlay*)self.overlay;;
}

#pragma mark - Public <公有方法>

/**
 * @brief 绘制函数
 */
- (void)glRender
{
    CGFloat zoomLevel = [self getMapZoomLevel];
    if(_prevTime == 0) {
        _prevTime = CFAbsoluteTimeGetCurrent();
        [self.traceOverlay drawStepWithTime:0 zoomLevel:zoomLevel];
    } else {
        NSTimeInterval curTime = CFAbsoluteTimeGetCurrent();
        [self.traceOverlay drawStepWithTime:curTime - _prevTime zoomLevel:zoomLevel];
        _prevTime = curTime;
    }
    
    if(self.carImage && [self.traceOverlay getMultiPolyline].pointCount > 0) {
        [_proxyRender glRender];
        [_patchLineRender glRender];
        
        [self renderCarImage];
    } else {
        [_proxyRender glRender];
    }
}

#pragma mark - Private <私有方法>

/// 设置默认配置
- (void) setDefaultConfiguration {
    MATraceReplayOverlay *traceOverlay = (MATraceReplayOverlay*)self.overlay;
    /// 实际路线
    _proxyRender = [[MAMultiColoredPolylineRenderer alloc] initWithMultiPolyline:[traceOverlay getMultiPolyline]];
//    _proxyRender.gradient = YES;
    /// 动画路线
    _patchLineRender = [[MAPolylineRenderer alloc] initWithPolyline:[traceOverlay getPatchPolyline]];
    /// 设置默认颜色
    self.strokeColor = [UIColor redColor];
    __weak typeof(self) weakSelf = self;
    /// 监听回调
    traceOverlay.callBackDirection = ^() {
        
        if ([weakSelf.delegate respondsToSelector:@selector(executionTraceReplayCarPoint:runningDirection:)]) {
            [weakSelf.delegate executionTraceReplayCarPoint:[weakSelf.traceOverlay getCarPosition]
                                           runningDirection:[weakSelf.traceOverlay getRunningDirection]];
        }

        if ([weakSelf.delegate respondsToSelector:@selector(executionTraceReplayCutIndex:cutIndexPoint:)]) {
            [weakSelf.delegate executionTraceReplayCutIndex:[weakSelf.traceOverlay getOrigPointIndexOfCar]
                                              cutIndexPoint:[weakSelf.traceOverlay getMapPointOfIndex:[weakSelf.traceOverlay getOrigPointIndexOfCar]]];
        }
        
    };
}

/// 渲染车辆图标
- (void)renderCarImage {
    if(_textureName == 0) {
        NSError *error = nil;
        GLKTextureInfo *texInfo = [GLKTextureLoader textureWithCGImage:self.carImage.CGImage options:nil error:&error];
        _textureName = texInfo.name;
    }
    
    if(_programe == 0) {
        _programe = [self loadGLESPrograme];
    }
    
    if(_textureName == 0 || _programe == 0) {
        return;
    }
    
    MATraceReplayOverlay *traceOverlay = (MATraceReplayOverlay*)self.overlay;
    MAMapPoint carPoint = [traceOverlay getCarPosition];
    CLLocationDirection rotate = [traceOverlay getRunningDirection];
    
    double zoomLevel = [self getMapZoomLevel];
    double zoomScale = pow(2, zoomLevel);
    
    CGSize imageSize = self.carImage.size;
    
    double halfWidth  = imageSize.width  * (1 << 20) / zoomScale/2;
    double halfHeight = imageSize.height * (1 << 20) / zoomScale/2;
    
    _imageMapPoints[0].x = -halfWidth;
    _imageMapPoints[0].y = halfHeight;
    _imageMapPoints[1].x = halfWidth;
    _imageMapPoints[1].y = halfHeight;
    _imageMapPoints[2].x = halfWidth;
    _imageMapPoints[2].y = -halfHeight;
    _imageMapPoints[3].x = -halfWidth;
    _imageMapPoints[3].y = -halfHeight;
    
    MADrawPoint points[4] = { 0 };
    for(int i = 0; i < 4; ++i) {
        CGPoint tempPoint = _imageMapPoints[i];
        if(traceOverlay.enableAutoCarDirection) {
            tempPoint = CGPointApplyAffineTransform(_imageMapPoints[i], CGAffineTransformMakeRotation(rotate));
        }
        
        tempPoint.x += carPoint.x;
        tempPoint.y += carPoint.y;
        CGPoint p = [self glPointForMapPoint:MAMapPointMake(tempPoint.x, tempPoint.y)];
        points[i].x = p.x;
        points[i].y = p.y;
    }
    
    float *viewMatrix = [self getViewMatrix];
    float *projectionMatrix = [self getProjectionMatrix];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);//纹理和顶点皆已做过预乘alpha值处理
    
    
    glUseProgram(_programe);
    glBindTexture(GL_TEXTURE_2D, _textureName);
    
    //glUseProgram(shaderToUse.programName);
    glEnableVertexAttribArray(_attribute_position_location);
    glEnableVertexAttribArray(_attribute_texCoord_location);
    
    glUniformMatrix4fv(_uniform_viewMatrix_location, 1, false, viewMatrix);
    glUniformMatrix4fv(_uniform_projMatrix_location, 1, false, projectionMatrix);
            
    MADrawPoint textureCoords[4] = {
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
        0.0, 0.0
    };
    glVertexAttribPointer(_attribute_position_location, 2, GL_FLOAT, false, sizeof(MADrawPoint), &(points[0]));
    glVertexAttribPointer(_attribute_texCoord_location, 2, GL_FLOAT, false, sizeof(MADrawPoint), &(textureCoords[0]));
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glDisableVertexAttribArray(_attribute_position_location);
    glDisableVertexAttribArray(_attribute_texCoord_location);
    
    glDisable(GL_BLEND);
    glDepthMask(GL_TRUE);
    glUseProgram(0);
}

- (GLuint)loadGLESPrograme {
    NSString *vertexShaderSrc = @"precision highp float;\n\
    attribute vec2 attrVertex;\n\
    attribute vec2 attrTextureCoord;\n\
    uniform mat4 inViewMatrix;\n\
    uniform mat4 inProjMatrix;\n\
    varying vec2 textureCoord;\n\
    void main(){\n\
    gl_Position = inProjMatrix * inViewMatrix * (vec4(attrVertex, 1.0, 1.0));\n\
    textureCoord = attrTextureCoord;\n\
    }";
    
    NSString *fragShaderSrc = @"precision highp float;\n\
    varying vec2 textureCoord;\n\
    uniform sampler2D inTextureUnit;\n\
    void main(){\n\
    gl_FragColor = texture2D(inTextureUnit, textureCoord);\n\
    }";
    
    GLuint prgName = 0;
    prgName = glCreateProgram();
    
    if(prgName <= 0) {
        return 0;
    }
    
    GLint logLength = 0, status = 0;
    //////////////////////////////////////
    // Specify and compile VertexShader //
    //////////////////////////////////////
    const GLchar* vertexShaderSrcStr = (const GLchar*)[vertexShaderSrc UTF8String];
    
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, (const GLchar **)&(vertexShaderSrcStr), NULL);
    glCompileShader(vertexShader);
    glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);
    
    if (logLength > 0) {
        GLchar *log = (GLchar*) malloc(logLength);
        glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
        NSLog(@"Vtx Shader compile log:%s\n", log);
        free(log);
    }
    
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        NSLog(@"Failed to compile vtx shader:\n%s\n", vertexShaderSrcStr);
        return 0;
    }
    
    glAttachShader(prgName, vertexShader);
    glDeleteShader(vertexShader);
    
    
    /////////////////////////////////////////
    // Specify and compile Fragment Shader //
    /////////////////////////////////////////
    const GLchar* fragmentShaderSrcStr = (const GLchar*)[fragShaderSrc UTF8String];

    GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragShader, 1, (const GLchar **)&(fragmentShaderSrcStr), NULL);
    glCompileShader(fragShader);
    glGetShaderiv(fragShader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetShaderInfoLog(fragShader, logLength, &logLength, log);
        NSLog(@"Frag Shader compile log:\n%s\n", log);
        free(log);
    }
    
    glGetShaderiv(fragShader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        NSLog(@"Failed to compile frag shader:\n%s\n", fragmentShaderSrcStr);
        return 0;
    }
    
    glAttachShader(prgName, fragShader);
    glDeleteShader(fragShader);
    
    //////////////////////
    // Link the program //
    //////////////////////
    glLinkProgram(prgName);
    glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(prgName, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s\n", log);
        free(log);
    }
    
    glGetProgramiv(prgName, GL_LINK_STATUS, &status);
    if (status == 0) {
        NSLog(@"Failed to link program");
        return 0;
    }
    
    _uniform_viewMatrix_location = glGetUniformLocation(prgName, "inViewMatrix");
    _uniform_projMatrix_location = glGetUniformLocation(prgName, "inProjMatrix");
    
    _attribute_position_location = glGetAttribLocation(prgName, "attrVertex");
    _attribute_texCoord_location = glGetAttribLocation(prgName, "attrTextureCoord");
    
    return prgName;
}

#pragma mark - Protocol conformance <协议>
#pragma mark - Network request <网络请求>
#pragma mark - lazy <懒加载>

@end
