背景

今天在开发过程中遇到需要进行循环网络请求，大体需求如下：
网络请求A返回成功后，继续调用网络请求A（即：A—>A—>A……）。虽然不难，但还是记录下
- 先来看看直接循环请求
```
- (void)viewDidLoad {
    for (NSInteger i = 0; i < 3; i ++) {
          NSLog(@"第%ld个任务开始",i);
          [self createNomalRequest:i];
      }
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
```
控制台结果打印
```
2022-10-19 11:33:16.977936+0800 SemaphoreDemo[5449:133236] 第0个任务开始
2022-10-19 11:33:16.980112+0800 SemaphoreDemo[5449:133236] 第1个任务开始
2022-10-19 11:33:16.998561+0800 SemaphoreDemo[5449:133236] 第2个任务开始
2022-10-19 11:33:17.192302+0800 SemaphoreDemo[5449:133154] 第1个任务结束
2022-10-19 11:33:17.203401+0800 SemaphoreDemo[5449:133154] 第0个任务结束
2022-10-19 11:33:17.219418+0800 SemaphoreDemo[5449:133154] 第2个任务结束
```
这显然不符合我们预期，使用信号量来处理
```
- (void)viewDidLoad {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
      for (NSInteger i = 0; i < 3; i ++) {
          NSLog(@"第%ld个任务开始",i);
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
```
因为AFNetworking回调默认是主线程，这样dispatch_semaphore_wait和dispatch_semaphore_signal在同一个线程，会产生死锁，所以我们需要放在异步线程执行
控制台结果打印
```
2022-10-19 11:38:14.440358+0800 SemaphoreDemo[5499:137809] 第0个任务开始
2022-10-19 11:38:14.642872+0800 SemaphoreDemo[5499:137663] 第0个任务结束
2022-10-19 11:38:14.642924+0800 SemaphoreDemo[5499:137809] 第1个任务开始
2022-10-19 11:38:14.746131+0800 SemaphoreDemo[5499:137663] 第1个任务结束
2022-10-19 11:38:14.746160+0800 SemaphoreDemo[5499:137809] 第2个任务开始
2022-10-19 11:38:14.812154+0800 SemaphoreDemo[5499:137663] 第2个任务结束
```
当然还有其他方法可以实现这个需求，这里仅举例一个。


