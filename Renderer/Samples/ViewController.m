//
//  ViewController.m
//
//
//  Created by  on 20/8/21.
//  Copyright © 2016年  All rights reserved.
//

#import "ViewController.h"
#define MainViewControllerTitle @"高德地图API-3D"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
{
    UITableView * _mainTableView;
    NSArray     * _titles;
    NSArray     * _className;
}

@end

@implementation ViewController


#pragma mark - tableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *rows = [[_titles objectAtIndex:indexPath.section] allValues].firstObject;
    NSString *className = [[rows objectAtIndex:indexPath.row] allValues].firstObject;
    NSString *title = [[rows objectAtIndex:indexPath.row] allKeys].firstObject;
    
    UIViewController *subViewController = [[NSClassFromString(className) alloc] init];
    subViewController.title = title;
    
    [self.navigationController pushViewController:subViewController animated:YES];
}

#pragma mark - tableView DataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_titles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[_titles objectAtIndex:section] allValues].firstObject count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *mainCellIdentifier = @"com.autonavi.mainCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:mainCellIdentifier];
    NSArray *rows = [[_titles objectAtIndex:indexPath.section] allValues].firstObject;
    NSString *className = [[rows objectAtIndex:indexPath.row] allValues].firstObject;
    NSString *title = [[rows objectAtIndex:indexPath.row] allKeys].firstObject;
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:mainCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByCharWrapping;
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.textLabel.font = [UIFont systemFontOfSize:13];
    }
    
    cell.detailTextLabel.text = className;
    cell.textLabel.text = title;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _mainTableView.bounds.size.width, 40)];
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:14];
    label.text = [[_titles objectAtIndex:section] allKeys].firstObject;
    label.numberOfLines = 1;
    [label sizeToFit];
    CGRect frame = label.frame;
    frame.origin.x = 15;
    frame.origin.y = header.bounds.size.height - frame.size.height;
    label.frame = frame;
    [header addSubview:label];
    return header;
}
#pragma mark - init
- (void)initTitles
{
    ///主页面标签title
    _titles = @[

                @{
                    @"围栏绘制":
                        @[
                            @{
                                @"围栏绘制":@"DrawRendererController"
                      
                            },
                        ]
                },
                
            ];
    
}

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = MainViewControllerTitle;
    
    [self initTitles];
    
    _mainTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _mainTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _mainTableView.sectionHeaderHeight = 10;
    _mainTableView.sectionFooterHeight = 0;
    _mainTableView.delegate = self;
    _mainTableView.dataSource = self;
    
    [self.view addSubview:_mainTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;
    
    [self.navigationController setToolbarHidden:YES animated:animated];
}

@end
