//
//  AppDelegate.m
//  QuartzCoreDemo
//
//  Created by Chen Yonghui on 1/24/15.
//  Copyright (c) 2015 Shanghai TinyNetwork Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"%s",__PRETTY_FUNCTION__);
    
    // Override point for customization after application launch.
    #if __ANDROID__
    	[[UIScreen mainScreen] setScreenMode:UIScreenSizeModePad scale:0];
    #endif
    						
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIViewController *vc = [[ViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    
    [self checkMainBundle];
    return YES;
}

- (void)checkMainBundle
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *bundlePath = [mainBundle bundlePath];
    
    NSLog(@"main bundle path:%@",bundlePath);
    NSLog(@"listing main bundle contents:");
    NSFileManager *fm =[NSFileManager defaultManager];
    NSArray *contents = [fm contentsOfDirectoryAtPath: bundlePath error:nil];
    NSLog(@"%@",contents);
    
    if (contents.count == 0) {
        NSLog(@"[Warning] empty main bundle contents?");
        return;
    }
    
    // check pathForResource:ofType:
    NSString *oneFile = contents[0];
    NSString *icon = [mainBundle pathForResource:oneFile ofType:nil];
    if (!icon) {
        NSLog(@"[Warning] main bundle has contents, but pathForResource:ofType: return nil. this happended if you init main bundle before expand contents to main bundle directory");
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"%s",__PRETTY_FUNCTION__);
    if (![NSThread isMainThread]) {
        NSLog(@"[ERROR] should called in mainthread");
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"%s",__PRETTY_FUNCTION__);
    if (![NSThread isMainThread]) {
        NSLog(@"[ERROR] should called in mainthread");
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"%s",__PRETTY_FUNCTION__);
    if (![NSThread isMainThread]) {
        NSLog(@"[ERROR] should called in mainthread");
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"%s",__PRETTY_FUNCTION__);
    if (![NSThread isMainThread]) {
        NSLog(@"[ERROR] should called in mainthread");
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"%s",__PRETTY_FUNCTION__);
    if (![NSThread isMainThread]) {
        NSLog(@"[ERROR] should called in mainthread");
    }
}

@end
