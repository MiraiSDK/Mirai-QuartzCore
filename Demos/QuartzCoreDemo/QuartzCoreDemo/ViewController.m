//
//  ViewController.m
//  UIKitDemo
//
//  Created by Chen Yonghui on 1/24/15.
//  Copyright (c) 2015 Shanghai TinyNetwork Inc. All rights reserved.
//

#import "ViewController.h"
#import "TNTestViewController.h"

@interface ViewController () <UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) NSArray *tests;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Main";
    self.navigationItem.title = @"Tests";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tests = [[TNTestViewController tests] sortedArrayUsingComparator:^NSComparisonResult(Class c1, Class c2) {
        return [[c1 testName] compare:[c2 testName]];
    }];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;

#if __ANDROID__
    tableView.rowHeight = 100;
#endif
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tests.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Class class = self.tests[indexPath.row];
    cell.textLabel.text = [class testName];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Class class = self.tests[indexPath.row];
    UIViewController *vc = [[class alloc] init];
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end
