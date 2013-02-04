//
//  NSMutableArray+QueueAdditions.h
//  Baccarat
//
//  Created by Nader Rahimizad on 9/10/10.
//  Copyright 2010 GamesBox Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableArray (QueueAdditions)
- (id) dequeue;
- (id)pop ;
- (void) enqueue:(id)obj;
- (int)dequeueToBuffer: (void *)buffer;
@end
