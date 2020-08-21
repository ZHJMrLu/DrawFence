//
//  DrawRendererController.h
//
//
//  Created by  on 20/8/21.
//  Copyright © 2016年  All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MAMapKit/MAMapKit.h>
@interface DrawRendererController : UIViewController

@end

@interface OverlayData : NSObject
/** 类型 r-方形 c-圆形 */
@property(nonatomic,copy)NSString * shapetype;
/** 标识 */
@property(nonatomic,copy)NSString * datestring;
/** 大头针数组 */
@property(nonatomic,strong)NSMutableArray * pointAnnotationArray;
/** 大头针对应的坐标数组 */
@property(nonatomic,strong)NSMutableArray * pointArray;
/** 多边形 */
@property(nonatomic,strong)MAPolygon *polygon;
/** 圆形 */
@property(nonatomic,strong)MACircle * circle;
/** 圆心 */
@property(nonatomic,assign)CLLocationCoordinate2D circlecenter;
/** 半径 */
@property(nonatomic,assign)CLLocationDistance circleradius;
@end
