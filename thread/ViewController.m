//
//  ViewController.m
//  thread
//
//  Created by xunming Tan on 2020/7/21.
//  Copyright © 2020 xmt. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    dispatch_semaphore_t _semaphoreLocks;
}
@property(assign,nonatomic)NSInteger tickets;
@property(assign,nonatomic)NSInteger ticketSurplusCount;




@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    //串行队列
//    dispatch_queue_t queue = dispatch_queue_create("xmt", DISPATCH_QUEUE_SERIAL);
//
//    //并发队列
//    dispatch_queue_t queues = dispatch_queue_create("xmt", DISPATCH_QUEUE_CONCURRENT);
//
//    //主队列
//    dispatch_queue_t main = dispatch_get_main_queue();
//
//    //全局并发队列
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//
//    //同步创建方法
//    dispatch_sync(queue, ^{
//       //同步方法
//    });
//
//    //异步创建方法
//    dispatch_sync(queue, ^{
//       //异步方法
//    });
    
    /**   GCD组合方法
     *  同步执行 + 并发队列
     *  异步执行 + 并发队列
     *  同步执行 + 串行队列
     *  异步执行 + 串行队列
     
     *  同步执行 + 主队列
     *  异步执行 + 主队列
     */
    
/**
      区别              并发队列                  串行队列                    主队列
    同步（sync）  没有开启新线程，串行执行任务  没有开启新线程，串行执行任务       死锁卡住不执行
    异步（async） 有开启新线程，并发执行任务    有开启新线程（1条），串行执行任务  没有开启新线程，串行执行任务
*/
    
//    『主队列』+『同步执行』   串行队列所在的线程（子线程）死锁
//    dispatch_queue_t queue = dispatch_get_main_queue();
//    dispatch_sync(queue, ^{  // 异步执行 + 串行队列
//        dispatch_sync(queue, ^{  // 同步执行 + 当前串行队列
//            //任务 1
//            [NSThread sleepForTimeInterval:2];
//            NSLog(@"1---%@",[NSThread currentThread]);
//        });
//    });
 
        
//    // 使用 NSThread 的 detachNewThreadSelector 方法会创建线程，并自动启动线程执行 selector 任务
//    [NSThread detachNewThreadSelector:@selector(syncMain) toTarget:self withObject:nil];
     
    
//    [self semaphoreSync];

    [self initTicketStatusSave];
    
    
}

 
/**
 * 线程安全：使用 semaphore 加锁
 * 初始化火车票数量、卖票窗口（线程安全）、并开始卖票
 */
- (void)initTicketStatusSave {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"semaphore---begin");
    
    _semaphoreLocks = dispatch_semaphore_create(1);
    
    self.ticketSurplusCount = 50;
    
    // queue1 代表北京火车票售卖窗口
    dispatch_queue_t queue1 = dispatch_queue_create("net.xmt.test1", DISPATCH_QUEUE_SERIAL);
    // queue2 代表上海火车票售卖窗口
    dispatch_queue_t queue2 = dispatch_queue_create("net.xmt.test2", DISPATCH_QUEUE_SERIAL);
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue1, ^{
        [weakSelf saleTicketSafe];
    });
    
    dispatch_async(queue2, ^{
        [weakSelf saleTicketSafe];
    });
}

/**
 * 售卖火车票（线程安全）
 */
- (void)saleTicketSafe {
    while (1) {
        // 相当于加锁
        dispatch_semaphore_wait(_semaphoreLocks, DISPATCH_TIME_FOREVER);
        
        if (self.ticketSurplusCount > 0) {  // 如果还有票，继续售卖
            self.ticketSurplusCount--;
            NSLog(@"%@", [NSString stringWithFormat:@"剩余票数：%ld 窗口：%@", (long)self.ticketSurplusCount, [NSThread currentThread]]);
            [NSThread sleepForTimeInterval:0.2];
        } else { // 如果已卖完，关闭售票窗口
            NSLog(@"所有火车票均已售完");
            
            // 相当于解锁
            dispatch_semaphore_signal(_semaphoreLocks);
            break;
        }
        
        // 相当于解锁
        dispatch_semaphore_signal(_semaphoreLocks);
    }
}


//self.tickets = 20;
//NSThread *t1 = [[NSThread alloc]initWithTarget:self selector:@selector(saleTickets) object:nil];
//t1.name = @"售票员A";
//[t1 start];
//
//NSThread *t2 = [[NSThread alloc]initWithTarget:self selector:@selector(saleTickets) object:nil];
//t2.name = @"售票员B";
//[t2 start];

////@synchronized
//- (void)saleTickets{
//    while (YES) {
//        [NSThread sleepForTimeInterval:1.0];
//        //互斥锁 -- 保证锁内的代码在同一时间内只有一个线程在执行
//        @synchronized (self){
//            //1.判断是否有票
//            if (self.tickets > 0) {
//                //2.如果有就卖一张
//                self.tickets --;
//                NSLog(@"还剩%ld张票  %@",(long)self.tickets,[NSThread currentThread]);
//            }else{
//                //3.没有票了提示
//                NSLog(@"卖完了 %@",[NSThread currentThread]);
//                break;
//            }
//        }
//    }
//
//}




/**
 * semaphore 线程同步
 */
- (void)semaphoreSync {
    
    NSLog(@"currentThread---%@",[NSThread currentThread]);
    NSLog(@"开始");
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block int number = 0;
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 1---%@",[NSThread currentThread]);
        
        number = 100;
        
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
        NSLog(@"任务 2---%@",[NSThread currentThread]);      // 打印当前线程
        
        number = 100;
        
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

}

/**
 * 队列组 dispatch_group_enter、dispatch_group_leave
 *
 * 6.5.3 dispatch_group_enter、dispatch_group_leave

 dispatch_group_enter 标志着一个任务追加到 group，执行一次，相当于 group 中未执行完毕任务数 +1
 dispatch_group_leave 标志着一个任务离开了 group，执行一次，相当于 group 中未执行完毕任务数 -1。
 当 group 中未执行完毕任务数为0的时候，才会使 dispatch_group_wait 解除阻塞，以及执行追加到 dispatch_group_notify 中的任务。
 */
- (void)groupEnterAndLeave {
    NSLog(@"currentThread---%@",[NSThread currentThread]);
    NSLog(@"开始");
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 1---%@",[NSThread currentThread]);

        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 2---%@",[NSThread currentThread]);
        
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"3---%@",[NSThread currentThread]);
    
        NSLog(@"结束");
    });
}

/**
 * 队列组 dispatch_group_wait
 */
- (void)groupWait {
    NSLog(@"currentThread---%@",[NSThread currentThread]);
    NSLog(@"开始");
    
    dispatch_group_t group =  dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 1---%@",[NSThread currentThread]);
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 2---%@",[NSThread currentThread]);
    });
    
    // 等待上面的任务全部完成后，会往下继续执行（会阻塞当前线程）
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    NSLog(@"结束");
    
}

/**
 * 队列组 dispatch_group_notify
 */
- (void)groupNotify {
    NSLog(@"currentThread---%@",[NSThread currentThread]);
    NSLog(@"开始");
    
    dispatch_group_t group =  dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 1--%@",[NSThread currentThread]);
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 2---%@",[NSThread currentThread]);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 等前面的异步任务 1、任务 2 都执行完毕后，回到主线程执行下边任务
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 3--%@",[NSThread currentThread]);

        NSLog(@"结束");
    });
}

/**
 * 快速迭代方法 dispatch_apply
 */
- (void)apply {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    NSLog(@"apply---begin");
    dispatch_apply(6, queue, ^(size_t index) {
        NSLog(@"%zd---%@",index, [NSThread currentThread]);
    });
    NSLog(@"apply---end");
}

/**
 * 一次性代码（只执行一次）dispatch_once
 */
- (void)once {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 只执行 1 次的代码（这里面默认是线程安全的）
    });
}


/**
 * 延时执行方法 dispatch_after
 */
- (void)after {
    NSLog(@"currentThread---%@",[NSThread currentThread]);
    NSLog(@"开始");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 2.0 秒后异步追加任务代码到主队列，并开始执行
        NSLog(@"after---%@",[NSThread currentThread]);
    });
}

/**
 * 栅栏方法 dispatch_barrier_async
 */
- (void)barrier {
    dispatch_queue_t queue = dispatch_queue_create("xmt", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 1---%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 2---%@",[NSThread currentThread]);
    });
    
    dispatch_barrier_async(queue, ^{
        // 任务 barrier
        [NSThread sleepForTimeInterval:2];
        NSLog(@"barrier---%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 3---%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 4---%@",[NSThread currentThread]);
    });
}


/**
 * 线程间通信
 */
- (void)communication {
    // 获取全局并发队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // 获取主队列
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        // 异步任务 1
        [NSThread sleepForTimeInterval:2];
        NSLog(@"1---%@",[NSThread currentThread]);
        
        // 回到主线程
        dispatch_async(mainQueue, ^{
            // 追加在主线程中执行的任务
            [NSThread sleepForTimeInterval:2];
            NSLog(@"2---%@",[NSThread currentThread]);
        });
    });
}


/**
 * 异步执行 + 主队列
 * 特点：只在主线程中执行任务，执行完一个任务，再执行下一个任务
 */
- (void)asyncMain {
    NSLog(@"currentThread---%@",[NSThread currentThread]);
    NSLog(@"开始");
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 1---%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 2--%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 3---%@",[NSThread currentThread]);
    });
    
    NSLog(@"结束");
}

/**
 * 同步执行 + 主队列
 * 特点(主线程调用)：互等卡主不执行。
 * 特点(其他线程调用)：不会开启新线程，执行完一个任务，再执行下一个任务。
 */
- (void)syncMain {
    
    NSLog(@"currentThread---%@",[NSThread currentThread]);
    NSLog(@"syncMain---begin");
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    dispatch_sync(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 1---%@",[NSThread currentThread]);
    });
    
    dispatch_sync(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 2---%@",[NSThread currentThread]);
    });
    
    dispatch_sync(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 3---%@",[NSThread currentThread]);
    });
    
    NSLog(@"syncMain---end");
}


/**
 * 异步执行 + 串行队列
 * 特点：会开启新线程，但是因为任务是串行的，执行完一个任务，再执行下一个任务。
 */
- (void)asyncSerial {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"开始");
    
    dispatch_queue_t queue = dispatch_queue_create("net.xmt.asyncSerial", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 1---%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{

        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 2---%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{

        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务 3---%@",[NSThread currentThread]);
    });
    
    NSLog(@"结束");
}


/**
 * 同步执行 + 串行队列
 * 特点：不会开启新线程，在当前线程执行任务。任务是串行的，执行完一个任务，再执行下一个任务。
 */
- (void)syncSerial {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"syncSerial---begin");
    
    dispatch_queue_t queue = dispatch_queue_create("com.xmt.syncSerial", DISPATCH_QUEUE_SERIAL);
    
    dispatch_sync(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];
        NSLog(@"1---%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];
        NSLog(@"2---%@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];
        NSLog(@"3---%@",[NSThread currentThread]);
    });
    
    NSLog(@"syncSerial---end");
}

/**
 * 异步执行 + 并发队列
 * 特点：可以开启多个线程，任务交替（同时）执行。
 */
- (void)asyncConcurrent {
    NSLog(@"currentThread---%@",[NSThread currentThread]);
    NSLog(@"asyncConcurrent---begin");
    
    dispatch_queue_t queue = dispatch_queue_create("com.xmt.asyncConcurrent", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];
        NSLog(@"1---%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];
        NSLog(@"2---%@",[NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];
        NSLog(@"3---%@",[NSThread currentThread]);
    });
    
    NSLog(@"asyncConcurrent---end");
}

/**
 * 同步执行 + 并发队列
 * 特点：在当前线程中执行任务，不会开启新线程，执行完一个任务，再执行下一个任务。
 */
- (void)syncConcurrent {
    NSLog(@"currentThread---%@",[NSThread currentThread]);  // 打印当前线程
    NSLog(@"syncConcurrent---begin");
    
    dispatch_queue_t queue = dispatch_queue_create("com.xmt.text", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_sync(queue, ^{
        // 追加任务 1
        [NSThread sleepForTimeInterval:2];
        NSLog(@"1---%@",[NSThread currentThread]);
    });
    
    dispatch_sync(queue, ^{
        // 追加任务 2
        [NSThread sleepForTimeInterval:2];
        NSLog(@"2---%@",[NSThread currentThread]);
    });
    
    dispatch_sync(queue, ^{
        // 追加任务 3
        [NSThread sleepForTimeInterval:2];
        NSLog(@"3---%@",[NSThread currentThread]);
    });
    
    NSLog(@"syncConcurrent---end");
}


@end
