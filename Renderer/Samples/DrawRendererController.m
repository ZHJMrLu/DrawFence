//
//  DrawRendererController.m
//
//
//  Created by  on 20/8/21.
//  Copyright © 2016年  All rights reserved.
//

#import "DrawRendererController.h"

@interface DrawRendererController ()<MAMapViewDelegate>
{
    BOOL pointMove;// 大头针移动
    MAPointAnnotation * touchAnnotation;//点击的标注
    BOOL overlayMove;// 围栏移动
    CLLocationDistance _circleRadius; // 半径
    CLLocationCoordinate2D _circleCenter;// 圆心
}

@property (nonatomic, strong) MAMapView *mapView;

@property (nonatomic, strong) NSArray *lines;

@property (nonatomic, strong) MAPointAnnotation *pin1;
@property (nonatomic, strong) MAPointAnnotation *pin2;

/** 大头针数组 */
@property(nonatomic,strong)NSMutableArray * pointAnnotationArray;
/** 坐标数组 */
@property(nonatomic,strong)NSMutableArray * pointArray;
/** 左边间距数组 */
@property(nonatomic,strong)NSMutableArray * pointMarginArray;
/** 多边形数组 */
@property(nonatomic,strong)NSMutableArray * rectDataArray;
/** 正在操作的多边形围栏 */
@property(nonatomic,strong)MAPolygon * operationPolygon;
/** 正在操作的圆形围栏 */
@property(nonatomic,strong)MACircle * operationCircle;
/** 多变形视图数组 */
@property(nonatomic,strong)NSMutableArray * polygonRendererViewArray;
/** 圆形视图数组 */
@property(nonatomic,strong)NSMutableArray * circleRendererViewArray;


@end

@implementation DrawRendererController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(returnAction)];
    
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithTitle:@"AddRect" style:UIBarButtonItemStylePlain target:self action:@selector(addRectOverlayClick)],
        [[UIBarButtonItem alloc] initWithTitle:@"AddCircle" style:UIBarButtonItemStylePlain target:self action:@selector(addCircleOverlayClick)],
        [[UIBarButtonItem alloc] initWithTitle:@"Del" style:UIBarButtonItemStylePlain target:self action:@selector(deleteOverlayClick)]
    ];
    
    self.mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.rotateEnabled = NO;
    self.mapView.rotateCameraEnabled = NO;
    self.mapView.delegate = self;
    
    [self.view addSubview:self.mapView];
    
    _pointMarginArray = [NSMutableArray array];
    _rectDataArray = [NSMutableArray array];
    _polygonRendererViewArray = [NSMutableArray array];
    _circleRendererViewArray = [NSMutableArray array];
    
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
}

#pragma mark - Action Handlers
- (void)returnAction
{
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - 添加多边形
-(void)addRectOverlayClick{
    [self addNewRectOverLay];
}
#pragma mark - 添加一个多边形围栏
-(void)addNewRectOverLay{
    CGPoint center = [self.mapView convertCoordinate:self.mapView.centerCoordinate toPointToView:self.view];
    CGFloat width = 50;
    // 时间字符串 用作唯一标识
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyMMddHHmmss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    dateString = [NSString stringWithFormat:@"%@rect",dateString];
    NSMutableArray * pointAnnotationArray = [NSMutableArray array];
    NSMutableArray * pointArray = [NSMutableArray array];
    for (NSInteger i = 0 ; i < 8;  i++) {
        
        NSInteger x = (i == 1 || i == 5) ? 0 : (i == 2 || i == 3 || i == 4) ? 1 : -1;
        NSInteger y = (i == 3 || i == 7) ? 0 : (i == 4 || i == 5 || i == 6) ? 1 : -1;
        
        
        CGPoint pointCenter = CGPointMake(center.x+ x * width, center.y+ y *  width);
        CLLocationCoordinate2D coordinate2D = [self.mapView convertPoint:pointCenter toCoordinateFromView:self.view];
        MAPointAnnotation * pointAnnotation = [[MAPointAnnotation alloc] init];
        pointAnnotation.coordinate =  coordinate2D;
        pointAnnotation.title = [NSString stringWithFormat:@"%ld",i + 100];
        pointAnnotation.subtitle = dateString;
        [self.mapView addAnnotation:pointAnnotation];
        [pointAnnotationArray addObject:pointAnnotation];
        [pointArray addObject:[NSValue valueWithCGPoint:pointCenter]];
    }
    NSInteger count = pointAnnotationArray.count;
    CLLocationCoordinate2D coordinates[count];
    for (NSInteger i = 0 ; i < count ; i ++) {
        MAPointAnnotation * subPoint = pointAnnotationArray[i];
        coordinates[i] = subPoint.coordinate;
    }
    
    MAPolygon *polygon = [MAPolygon polygonWithCoordinates:coordinates count:count];
    polygon.title = dateString;
    _operationPolygon = polygon;
    [self.mapView addOverlay:polygon];
    
    OverlayData * data = [[OverlayData alloc]init];
    data.pointAnnotationArray = pointAnnotationArray;
    data.pointArray = pointArray;
    data.shapetype = @"r";
    data.polygon = polygon;
    data.datestring = dateString;
    [_rectDataArray insertObject:data atIndex:0];
    [self updateMAPolygonRendererViewColor];
    [self setMACircleRendererViewColorDisable];
}
#pragma mark - 添加圆形
-(void)addCircleOverlayClick{
    CLLocationCoordinate2D circleCenter = self.mapView.centerCoordinate;
    CGPoint center = [self.mapView convertCoordinate:circleCenter toPointToView:self.view];
    CGFloat width = 50;
    
    // 时间字符串 用作唯一标识
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyMMddHHmmss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    dateString = [NSString stringWithFormat:@"%@circle",dateString];
    
    CGPoint radiusPoint = CGPointMake(center.x + width, center.y);
    CLLocationCoordinate2D radiusCoordinate2D = [self.mapView convertPoint:radiusPoint toCoordinateFromView:self.view];
    
    MAMapPoint p1 = MAMapPointForCoordinate(circleCenter);
    MAMapPoint p2 = MAMapPointForCoordinate(radiusCoordinate2D);
    
    CLLocationDistance circleRadius =  MAMetersBetweenMapPoints(p1, p2);
    
    NSMutableArray * pointAnnotationArray = [NSMutableArray array];
    NSMutableArray * pointArray = [NSMutableArray array];
    
    CGPoint pointCenter = CGPointMake(center.x, center.y - width);
    CLLocationCoordinate2D coordinate2D = [self.mapView convertPoint:pointCenter toCoordinateFromView:self.view];
    MAPointAnnotation * pointAnnotation = [[MAPointAnnotation alloc] init];
    pointAnnotation.coordinate =  coordinate2D;
    pointAnnotation.title = [NSString stringWithFormat:@"%ld",100];
    pointAnnotation.subtitle = dateString;
    [self.mapView addAnnotation:pointAnnotation];
    [pointAnnotationArray addObject:pointAnnotation];
    [pointArray addObject:[NSValue valueWithCGPoint:pointCenter]];
    
    MACircle * circle = [MACircle circleWithCenterCoordinate:circleCenter radius:circleRadius];
    circle.title = dateString;
    _operationCircle = circle;
    [self.mapView addOverlay:circle];
    
    _circleCenter = circleCenter;
    _circleRadius = circleRadius;
    
    OverlayData * data = [[OverlayData alloc]init];
    data.pointAnnotationArray = pointAnnotationArray;
    data.pointArray = pointArray;
    data.shapetype = @"c";
    data.circle = circle;
    data.datestring = dateString;
    data.circlecenter = circleCenter;
    data.circleradius = circleRadius;
    [_rectDataArray insertObject:data atIndex:0];
    [self updateMACircleRendererViewColor];
    [self setMAPolygonRendererViewColorDisable];
}
#pragma mark - 删除围栏
-(void)deleteOverlayClick{
    NSInteger selectIndex = -1;
    for (NSInteger index = 0 ; index < _rectDataArray.count; index ++) {
        OverlayData * data = _rectDataArray[index];
        if ([data.datestring isEqualToString:_operationPolygon.title] ||[data.datestring isEqualToString:_operationCircle.title] ) {
            [self.mapView removeAnnotations:data.pointAnnotationArray];
            selectIndex = index;
            break;
        }
    }
    if (selectIndex != -1) {
        [_rectDataArray removeObjectAtIndex:selectIndex];
    }
    if (_operationPolygon) {
        [self.mapView removeOverlay:_operationPolygon];
    }
    
    if (_operationCircle) {
        [self.mapView removeOverlay:_operationCircle];
    }
    // 如果只是点击了一下围栏，只会触发touchesBegan，这时地图设置为滚动了，因此需要重置一下
    self.mapView.scrollEnabled = YES;
    // 移除多边形视图
    if (_rectDataArray.count == 0) {
        [_polygonRendererViewArray removeAllObjects];
        [_circleRendererViewArray removeAllObjects];
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    UITouch * touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    CLLocationCoordinate2D coor = [self.mapView convertPoint:point toCoordinateFromView:self.view];
    // 判断是不是标注
    UIView * touchView = touch.view;
    
    // 清空计算距离的点数组
    [_pointMarginArray removeAllObjects];
    
    self.mapView.scrollEnabled = YES;
    _operationCircle = nil;
    _operationPolygon = nil;
    pointMove = overlayMove = NO;
    if ([touchView isKindOfClass:MAPinAnnotationView.class]) {
        MAPinAnnotationView *  annotationView = (MAPinAnnotationView *)touchView;
        self.mapView.scrollEnabled = NO;
        pointMove = YES;
        MAPointAnnotation * pointAnnotation = annotationView.annotation;
        pointAnnotation.coordinate = coor;
        touchAnnotation = pointAnnotation;
        for (OverlayData * data in _rectDataArray) {
            if ([data.datestring isEqualToString:pointAnnotation.subtitle]) {
                _pointAnnotationArray = data.pointAnnotationArray;
                _pointArray = data.pointArray;
                if ([pointAnnotation.subtitle rangeOfString:@"rect"].location != NSNotFound) {

                    _operationPolygon = data.polygon;
                    _operationCircle = nil;
                }else{
                    
                    _operationCircle = data.circle;
                    _operationPolygon = nil;
                    _circleRadius = data.circleradius;
                    _circleCenter = data.circlecenter;
                }
                break;
            }
        }
        [self rendererOverlay];
    }else{
        // 判断点在不在区域内
        for (OverlayData * data in _rectDataArray) {
            // 判断点在不在区域内
            NSInteger count = data.pointAnnotationArray.count;
            CLLocationCoordinate2D coordinates[count];
            for (NSInteger i = 0 ; i < count ; i ++) {
                MAPointAnnotation * subPoint = data.pointAnnotationArray[i];
                coordinates[i] = subPoint.coordinate;
            }
            if ([data.shapetype isEqualToString:@"r"]) {
                
                overlayMove = MAPolygonContainsCoordinate(coor,coordinates,count);
                if (overlayMove) {
                    _pointAnnotationArray = data.pointAnnotationArray;
                    _pointArray = data.pointArray;
                    _operationPolygon = data.polygon;
                    _operationCircle = nil;
                    break;
                }
            }else{
                
                overlayMove = MACircleContainsCoordinate(coor,data.circlecenter,data.circleradius);
                if (overlayMove) {
                    _pointAnnotationArray = data.pointAnnotationArray;
                    _pointArray = data.pointArray;
                    _operationCircle = data.circle;
                    _operationPolygon = nil;
                    _circleRadius = data.circleradius;
                    _circleCenter = data.circlecenter;
                    break;
                }
            }
            
            
        }
        if (overlayMove) {
            NSLog(@"InSide");
            self.mapView.scrollEnabled = NO;
            if (_operationPolygon) {
                for (NSValue * pointValue in _pointArray) {
                    CGPoint anniontPoint = [pointValue CGPointValue];
                    CGPoint marginPoint = CGPointMake(anniontPoint.x - point.x, anniontPoint.y - point.y);
                    [_pointMarginArray addObject:[NSValue valueWithCGPoint:marginPoint]];
                }
            }
            if (_operationCircle) {
                
                // 大头针与点击点的偏移量
                NSValue * pointValue = [_pointArray firstObject];
                CGPoint  anniontPoint = [pointValue CGPointValue];
                CGPoint  marginPoint = CGPointMake(anniontPoint.x - point.x, anniontPoint.y - point.y);
                [_pointMarginArray addObject:[NSValue valueWithCGPoint:marginPoint]];
                // 圆心与点击点的偏移量
                anniontPoint = [self.mapView convertCoordinate:_circleCenter toPointToView:self.view];
                marginPoint = CGPointMake(anniontPoint.x - point.x, anniontPoint.y - point.y);
                [_pointMarginArray addObject:[NSValue valueWithCGPoint:marginPoint]];
                
            }
            
        }else{
            NSLog(@"OutSide");
        }
    }
    if (_operationPolygon) {

        NSLog(@"选了多边形");
    }
    if (_operationCircle) {
        
        NSLog(@"选了圆形");
        
    }
    NSLog(@"touchesBegan");
}
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch * touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    if (pointMove) {
        
        [self pointMoveOperation:point];
    }
    if (overlayMove) {
        
        [self overlayMoveOperation:point];
    }
}
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch * touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    if (pointMove) {
        NSInteger index = [touchAnnotation.title integerValue] - 100;
        
        [_pointArray replaceObjectAtIndex:index withObject:[NSValue valueWithCGPoint:point]];
        
        [self pointMoveOperation:point];
        
    }
    if (overlayMove) {
        
        [self overlayMoveOperation:point];
    }
    pointMove = NO;
    [_pointMarginArray removeAllObjects];
    self.mapView.scrollEnabled = YES;
    NSLog(@"touchesEnded");
}
#pragma mark 大头针移动
-(void)pointMoveOperation:(CGPoint)point{
    CLLocationCoordinate2D coor = [self.mapView convertPoint:point toCoordinateFromView:self.view];
    touchAnnotation.coordinate = coor;
    NSInteger index = [touchAnnotation.title integerValue] - 100;
    [_pointArray replaceObjectAtIndex:index withObject:[NSValue valueWithCGPoint:point]];
    if (_operationCircle) {
        MAMapPoint p1 = MAMapPointForCoordinate(_circleCenter);
        MAMapPoint p2 = MAMapPointForCoordinate(coor);
        _circleRadius =  MAMetersBetweenMapPoints(p1, p2);
        for (OverlayData * data in _rectDataArray) {
            if ([data.datestring isEqualToString:_operationCircle.title]) {
                data.circleradius = _circleRadius;
                
                break;
            }
        }
    }
    [self rendererOverlay];
}
#pragma mark 围栏移动
-(void)overlayMoveOperation:(CGPoint)point{
    if (_operationPolygon) {
        for (NSInteger i = 0 ; i < _pointMarginArray.count; i ++) {
            NSValue * pointValue = _pointMarginArray[i];
            CGPoint marginPoint = [pointValue CGPointValue];
            CGPoint movePoint = CGPointMake(marginPoint.x + point.x, marginPoint.y + point.y);
            MAPointAnnotation * pointAnnotation = _pointAnnotationArray[i];
            CLLocationCoordinate2D coor = [self.mapView convertPoint:movePoint toCoordinateFromView:self.view];
            pointAnnotation.coordinate = coor;
            [_pointArray replaceObjectAtIndex:i withObject:[NSValue valueWithCGPoint:movePoint]];
        }
    }
    if (_operationCircle) {
        // 大头针移动
        NSValue * pointValue = [_pointMarginArray firstObject];
        CGPoint marginPoint = [pointValue CGPointValue];
        CGPoint movePoint = CGPointMake(marginPoint.x + point.x, marginPoint.y + point.y);
        CLLocationCoordinate2D coor = [self.mapView convertPoint:movePoint toCoordinateFromView:self.view];
        MAPointAnnotation * pointAnnotation = [_pointAnnotationArray firstObject];
        pointAnnotation.coordinate = coor;
        [_pointArray replaceObjectAtIndex:0 withObject:[NSValue valueWithCGPoint:movePoint]];
        // 圆心移动
        pointValue = [_pointMarginArray lastObject];
        marginPoint = [pointValue CGPointValue];
        movePoint = CGPointMake(marginPoint.x + point.x, marginPoint.y + point.y);
        coor = [self.mapView convertPoint:movePoint toCoordinateFromView:self.view];
        _circleCenter = coor;
        for (OverlayData * data in _rectDataArray) {
            if ([data.datestring isEqualToString:_operationCircle.title]) {
                data.circlecenter = _circleCenter;
                break;
            }
        }
    }
    [self rendererOverlay];
}
#pragma mark 绘制围栏
-(void)rendererOverlay{
    if (_operationPolygon) {
        NSInteger count = _pointAnnotationArray.count;
        CLLocationCoordinate2D coordinates[count];
        for (NSInteger i = 0 ; i < count ; i ++) {
            MAPointAnnotation * subPoint = _pointAnnotationArray[i];
            coordinates[i] = subPoint.coordinate;
        }
        [_operationPolygon setPolygonWithCoordinates:coordinates count:count];
        [self updateMAPolygonRendererViewColor];
        [self setMACircleRendererViewColorDisable];
    }
    if (_operationCircle) {
        [_operationCircle setCircleWithCenterCoordinate:_circleCenter radius:_circleRadius];
        [self updateMACircleRendererViewColor];
        [self setMAPolygonRendererViewColorDisable];
    }
}
#pragma mark - 设置选中多边形颜色
-(void)updateMAPolygonRendererViewColor{
    for (MAPolygonRenderer *polygonRenderer in _polygonRendererViewArray) {
        MAPolygon * polygon = polygonRenderer.polygon;
        UIColor * fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        if ([polygon.title isEqualToString:_operationPolygon.title]) {
            fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.2];
        }
        polygonRenderer.fillColor = fillColor;
    }
}
#pragma mark - 多边形围栏颜色置灰
-(void)setMAPolygonRendererViewColorDisable{
    for (MAPolygonRenderer *polygonRenderer in _polygonRendererViewArray) {
        polygonRenderer.fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    }
}
#pragma mark - 设置选中圆形颜色
-(void)updateMACircleRendererViewColor{
    for (MACircleRenderer *circleRenderer in _circleRendererViewArray) {
        MACircle * circle = circleRenderer.circle;
        UIColor * fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        if ([circle.title isEqualToString:_operationCircle.title]) {
            fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.2];
        }
        circleRenderer.fillColor = fillColor;
    }
}
#pragma mark - 圆形围栏颜色置灰
-(void)setMACircleRendererViewColorDisable{
    for (MACircleRenderer *circleRenderer in _circleRendererViewArray) {
        circleRenderer.fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    }
}
#pragma mark - MAMapViewDelegate
- (void)mapView:(MAMapView *)mapView mapDidZoomByUser:(BOOL)wasUserAction{
    if (wasUserAction) {
        for (OverlayData * data in _rectDataArray) {
            for (NSInteger i = 0 ; i < data.pointAnnotationArray.count; i ++) {
                
                MAPointAnnotation * pointAnnotation = data.pointAnnotationArray[i];
                CGPoint point = [mapView convertCoordinate:pointAnnotation.coordinate toPointToView:self.view];
                [data.pointArray replaceObjectAtIndex:i withObject:[NSValue valueWithCGPoint:point]];
            }
        }
    }
}
- (void)mapView:(MAMapView *)mapView mapDidMoveByUser:(BOOL)wasUserAction{
    if (wasUserAction) {
        for (OverlayData * data in _rectDataArray) {
            for (NSInteger i = 0 ; i < data.pointAnnotationArray.count; i ++) {
                
                MAPointAnnotation * pointAnnotation = data.pointAnnotationArray[i];
                CGPoint point = [mapView convertCoordinate:pointAnnotation.coordinate toPointToView:self.view];
                [data.pointArray replaceObjectAtIndex:i withObject:[NSValue valueWithCGPoint:point]];
            }
        }
    }
}
- (MAAnnotationView*)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation {
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *pointReuseIndetifier = @"pointReuseIndetifier";
        MAPinAnnotationView *annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndetifier];
        }
        
        annotationView.canShowCallout               = NO;
        annotationView.animatesDrop                 = NO;
        annotationView.draggable                    = NO;
        annotationView.pinColor                     = MAPinAnnotationColorRed;
        return annotationView;
    }
    
    return nil;
}
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolygon class]])
    {
        MAPolygon * polygon = (MAPolygon *)overlay;
        UIColor * fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        if ([polygon.title isEqualToString:_operationPolygon.title]) {
            fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.2];
        }
        MAPolygonRenderer *polygonRenderer = [[MAPolygonRenderer alloc] initWithPolygon:overlay];
        polygonRenderer.fillColor = fillColor;
        [_polygonRendererViewArray addObject:polygonRenderer];
        
        return polygonRenderer;
    }
    if ([overlay isKindOfClass:[MACircle class]]){
        MACircle * circle = (MACircle *)overlay;
        UIColor * fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        if ([circle.title isEqualToString:_operationCircle.title]) {
            fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.2];
        }
        MACircleRenderer *circleRenderer = [[MACircleRenderer alloc] initWithCircle:overlay];
        circleRenderer.fillColor   = fillColor;
        [_circleRendererViewArray addObject:circleRenderer];
        return circleRenderer;
    }
    
    return nil;
}
@end

@implementation OverlayData

@end
