//
//  ViewController.m
//  TestHealthy
//
//  Created by 古玉彬 on 16/2/17.
//  Copyright © 2016年 ms. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>

@interface ViewController ()
/**
 *  进入步数
 */
@property (weak, nonatomic) IBOutlet UILabel *todayStep;

/**
 *  健康
 */
@property (nonatomic, strong) HKHealthStore * healthStore;

/**
 *  读取查询
 */
@property (nonatomic, strong) HKSampleQuery * readDataQuery;
/**
 *  插入数据
 */
@property (nonatomic, strong) HKSampleQuery * writeDataQuery;

//写数据
@property (nonatomic, strong) HKSampleType * stepType;

//读数据
@property (nonatomic, strong) HKObjectType * readType;

/**
 *  时间区间
 */
@property (nonatomic, strong) NSPredicate * timePredicate;

//统计
@property (nonatomic, assign) NSInteger numberCount;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getStepCountFromHealthKit];
    
}


- (void)getStepCountFromHealthKit {
    
    
    //判断健康是否可用
    if ([HKHealthStore isHealthDataAvailable]) {
        
         self.healthStore = [[HKHealthStore alloc] init];
        
        self.stepType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        
        self.readType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        //申请访问步数权限
        [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithObject:self.stepType] readTypes:[NSSet setWithObject:self.readType] completion:^(BOOL success, NSError * _Nullable error) {
            
            if (error) {
                
                NSLog(@"%@",error);
            }else{
                
                
                //观察数据变化
                [self obHealthChanged];
            }
            
        }];
    }else{
        NSLog(@"健康功能不可用");
    }
    
    
}

//更新数据
- (IBAction)updateStep {
    
    [self.healthStore executeQuery:self.readDataQuery];
    
}


- (HKSampleQuery *)readDataQuery {
    
    if (_readDataQuery) {
        _readDataQuery = nil;
    }
    
    
    _readDataQuery = [[HKSampleQuery alloc] initWithSampleType:self.stepType predicate:self.timePredicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        
        if (error) {
            
            NSLog(@"%@",error);
        }
        
        NSInteger currentStep = 0;
        
        for (HKQuantitySample * sample in results) {
            
            currentStep += [sample.quantity doubleValueForUnit:[HKUnit countUnit]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.todayStep setText:[NSString stringWithFormat:@"%d",currentStep]];
            
        });
    }];
    
    return _readDataQuery;
}

//长时间监听数据变化
- (void)obHealthChanged{
    
    HKObserverQuery * query = [[HKObserverQuery alloc] initWithSampleType:self.stepType predicate:self.timePredicate updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@",error);
        }
        else{
            [self updateStep];
        }
    }];
    
    [self.healthStore executeQuery:query];
    
}
- (HKSampleQuery *)writeDataQuery {
    
    if (_writeDataQuery) {
        
        _writeDataQuery = nil;
    }
    
    return _writeDataQuery;
}


- (NSPredicate *)timePredicate {
    
    if (!_timePredicate) {
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        NSDate * now = [NSDate date];
        
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
        
        NSDate *startDate = [calendar dateFromComponents:components];
        
        NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
        
         _timePredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    }
    
    return _timePredicate;
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
