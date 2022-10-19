//
//  ViewController.m
//  SemaphoreDemo
//
//  Created by Mac on 2022/10/19.
//

#import "ViewController.h"
#import "AFNetworking.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
      for (NSInteger i = 0; i < 3; i ++) {
          NSLog(@"第%ld个任务开始",i);
//          [self createNomalRequest:i];
          [self createSemaRequest:i];
      }
    });
}

- (void)createSemaRequest:(NSInteger)index{
    // 创建信号量
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    NSString *urlString = @"http://www.baidu.com";
    [[AFHTTPSessionManager manager] GET:urlString parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 发送信号 （信号量+1）
        dispatch_semaphore_signal(sema);
        NSLog(@"第%ld个任务结束",(long)index);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_semaphore_signal(sema);
        NSLog(@"第%ld个任务结束", (long)index);
    }];
    // 等待signal执行+1后（>0），才执行wait后的业务
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

- (void)createNomalRequest:(NSInteger)index{
  
    NSString *urlString = @"http://www.baidu.com";
    [[AFHTTPSessionManager manager] GET:urlString parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"第%ld个任务结束",(long)index);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"第%ld个任务结束", (long)index);
    }];
}

@end
