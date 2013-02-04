//
//  NSMutableArray+QueueAdditions.m
//  Baccarat
//
//  Created by Nader Rahimizad on 9/10/10.
//  Copyright 2010 GamesBox Co., Ltd. All rights reserved.
//

#import "NSMutableArray+QueueAdditions.h"


@implementation NSMutableArray (QueueAdditions)
// Queues are first-in-first-out, so we remove objects from the head
- (id)dequeue {
    if ([self count] == 0) {
        return nil;
    }
    id queueObject = self[0];
    [self removeObjectAtIndex:0];
    return queueObject;
}

- (id)pop {
    if ([self count] == 0) {
        return nil;
    }
	id obj = self[([self count]-1)];
    [self removeObjectAtIndex:([self count]-1)];
    return obj;
}

- (int)dequeueToBuffer: (void *)buffer {
    if ([self count] == 0) {
        return 0;
    }

	int len=0;
    NSData *queueObject = self[0];
	len = [queueObject length];
	if(queueObject != nil && len > 0)
		memcpy(buffer, (void *)[queueObject bytes], len); // in bytes
	[self removeObjectAtIndex:0];
    return len;
}

// Add to the tail of the queue (no one likes it when people cut in line!)
- (void) enqueue:(id)anObject {
	//[anObject retain];
    [self addObject:anObject];
	
	//int count = [self count];
	//NSLog(@"Sound queue %p added. count %d",self, count);
			
    //this method automatically adds to the end of the array
}
@end
