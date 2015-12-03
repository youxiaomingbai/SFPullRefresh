//
//  TopRefreshViewController.m
//  SFPullRefreshDemo
//
//  Created by shaohua.chen on 10/16/14.
//  Copyright (c) 2014 shaohua.chen. All rights reserved.
//

#import "TableTestViewController.h"
#import "UIScrollView+SFPullRefresh.h"
#import "TestTableCell.h"
#import "TableTestViewController.h"
#import "CustomRefreshControl.h"

@interface TableTestViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray *items;

@property (assign, nonatomic) NSInteger page;

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) UILabel *hintsLabel;
@end

@implementation TableTestViewController

static NSString *cellId = @"cellId";

- (UILabel *)hintsLabel {
    if (!_hintsLabel) {
        _hintsLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
        _hintsLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _hintsLabel;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _items = [NSMutableArray array];
    _page = 0;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.tableView registerNib:[UINib nibWithNibName:@"TestTableCell" bundle:nil] forCellReuseIdentifier:cellId];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];


    __weak TableTestViewController *wkself = self; //you must use wkself to break the retain cycle
    [self.tableView sf_addRefreshHandler:^{
        wkself.page=0;
        [wkself loadStrings];
    } customRefreshControl:[[CustomRefreshControl alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 64)]];
    
    [self.tableView sf_addLoadMoreHandler:^{
        NSLog(@"load more");
        [wkself loadStrings];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    NSLog(@"TableTestViewController dealloced");
}



- (void)loadStrings
{
    [self requestDataAtPage:self.page success:^(NSArray *strings) {
        if (self.tableView.sf_isRefreshing) {
            [self.items removeAllObjects];
        }
        for (NSString *str in strings) {
//            [self.items insertObject:str atIndex:0]; //如果顶部加载，数据从头插入体验更好
            [self.items addObject:str];
        }
        self.page++;
        if (strings.count<10) {
            [self.tableView sf_reachEndWithText:@"加载完毕"];
        }
        [self.tableView sf_finishLoading];
        if (self.items.count<=0) {
            self.hintsLabel.text = @"没有数据";
            [self.tableView sf_showHintsView:self.hintsLabel];
        }
    } failure:^(NSString *msg) {
        [self.items removeAllObjects];
        [self.tableView sf_finishLoading];
        //可以使用自定义的提示界面
        self.hintsLabel.text = msg;
        [self.tableView sf_showHintsView:self.hintsLabel];
    }];
}



#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 85;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TestTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    [cell setIcon:[NSString stringWithFormat:@"%li", indexPath.row%10] string:_items[indexPath.row]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    TableTestViewController *tableTestVC = [[TableTestViewController alloc] initWithNibName:nil bundle:nil];
    tableTestVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:tableTestVC animated:YES];
}

- (void)requestDataAtPage:(NSInteger)page success:(void(^)(NSArray *))success failure:(void(^)(NSString *))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1.5);
        NSMutableArray *arr = [NSMutableArray array];
        if (page<5) {
            for (int i=0; i<10; i++) {
                [arr addObject:[NSString stringWithFormat:@"this is row%ld", i+page*10]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    success(arr);
                }
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
//                if (failure) {
//                    failure(@"服务器错误！");
//                }
                if (success) {
                    success(arr);
                }
            });
        }
        
    });
}


@end
