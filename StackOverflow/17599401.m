#import <Foundation/Foundation.h>

@interface Sync:NSObject
@property(nonatomic, retain) NSMutableArray *a;
@property(nonatomic, retain) dispatch_queue_t q;
@property(nonatomic) NSUInteger c;
@end
@implementation Sync
- (id)init
{
	self = [super init];
	if (self) {
		_a = [[NSMutableArray alloc] init];
		_q = dispatch_queue_create("array q", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (void) synchronizedAdd:(NSObject*)anObject
{
	@synchronized(self) {
		[_a addObject:anObject];
		[_a removeLastObject];
		_c++;
	}
}

- (void) dispatchSyncAdd:(NSObject*)anObject
{
	dispatch_sync(_q, ^{
		[_a addObject:anObject];
		[_a removeLastObject];
		_c++;
	});
}

- (void) dispatchASyncAdd:(NSObject*)anObject
{
	dispatch_async(_q, ^{
		[_a addObject:anObject];
		[_a removeLastObject];
		_c++;
	});
}

- (void) test
{
#define TESTCASES 1000000
	NSObject *o = [NSObject new];
	NSTimeInterval start;
	NSTimeInterval end;
	
	start = [NSDate timeIntervalSinceReferenceDate];
	_c = 0;
	for(int i = 0; i < TESTCASES; i++ ) {
		[self synchronizedAdd:o];
	}
	end = [NSDate timeIntervalSinceReferenceDate];
	assert(_c == TESTCASES);
	NSLog(@"@synchronized uncontended add: %2.5f seconds", end - start);

	start = [NSDate timeIntervalSinceReferenceDate];
	_c = 0;
	for(int i = 0; i < TESTCASES; i++ ) {
		[self dispatchSyncAdd:o];
	}
	end = [NSDate timeIntervalSinceReferenceDate];
	assert(_c == TESTCASES);
	NSLog(@"Dispatch sync uncontended add: %2.5f seconds", end - start);

	start = [NSDate timeIntervalSinceReferenceDate];
	_c = 0;
	for(int i = 0; i < TESTCASES; i++ ) {
		[self dispatchASyncAdd:o];
	}
	end = [NSDate timeIntervalSinceReferenceDate];
	NSLog(@"Dispatch async uncontended add: %2.5f seconds", end - start);
	
	dispatch_sync(_q, ^{;}); // wait for async stuff to complete
	end = [NSDate timeIntervalSinceReferenceDate];
	assert(_c == TESTCASES);
	NSLog(@"Dispatch async uncontended add completion: %2.5f seconds", end - start);


	dispatch_queue_t serial1 = dispatch_queue_create("serial 1", DISPATCH_QUEUE_SERIAL);
	dispatch_queue_t serial2 = dispatch_queue_create("serial 2", DISPATCH_QUEUE_SERIAL);
	
	dispatch_group_t group = dispatch_group_create();
	
#define TESTCASE_SPLIT_IN_2 (TESTCASES/2)
	start = [NSDate timeIntervalSinceReferenceDate];
	_c = 0;
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_2, serial1, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_2, serial2, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	end = [NSDate timeIntervalSinceReferenceDate];
	assert(_c == TESTCASES);
	NSLog(@"Synchronized, 2 queue: %2.5f seconds", end - start);
	
	start = [NSDate timeIntervalSinceReferenceDate];
	_c = 0;
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_2, serial1, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_2, serial2, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	end = [NSDate timeIntervalSinceReferenceDate];
	assert(_c == TESTCASES);
	NSLog(@"Dispatch sync, 2 queue: %2.5f seconds", end - start);
	
	start = [NSDate timeIntervalSinceReferenceDate];
	_c = 0;
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_2, serial1, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_2, serial2, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	end = [NSDate timeIntervalSinceReferenceDate];
	NSLog(@"Dispatch async, 2 queue: %2.5f seconds", end - start);
	dispatch_sync(_q, ^{;}); // wait for async stuff to complete
	end = [NSDate timeIntervalSinceReferenceDate];
	assert(_c == TESTCASES);
	NSLog(@"Dispatch async 2 queue add completion: %2.5f seconds", end - start);

#define TESTCASE_SPLIT_IN_10 (TESTCASES/10)
	dispatch_queue_t serial3 = dispatch_queue_create("serial 3", DISPATCH_QUEUE_SERIAL);
	dispatch_queue_t serial4 = dispatch_queue_create("serial 4", DISPATCH_QUEUE_SERIAL);
	dispatch_queue_t serial5 = dispatch_queue_create("serial 5", DISPATCH_QUEUE_SERIAL);
	dispatch_queue_t serial6 = dispatch_queue_create("serial 6", DISPATCH_QUEUE_SERIAL);
	dispatch_queue_t serial7 = dispatch_queue_create("serial 7", DISPATCH_QUEUE_SERIAL);
	dispatch_queue_t serial8 = dispatch_queue_create("serial 8", DISPATCH_QUEUE_SERIAL);
	dispatch_queue_t serial9 = dispatch_queue_create("serial 9", DISPATCH_QUEUE_SERIAL);
	dispatch_queue_t serial10 = dispatch_queue_create("serial 10", DISPATCH_QUEUE_SERIAL);
	start = [NSDate timeIntervalSinceReferenceDate];
	_c = 0;
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial1, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial2, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial3, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial4, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial5, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial6, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial7, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial8, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial8, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial10, ^(size_t i){
			[self synchronizedAdd:o];
		});
	});
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	end = [NSDate timeIntervalSinceReferenceDate];
	assert(_c == TESTCASES);
	NSLog(@"Synchronized, 10 queue: %2.5f seconds", end - start);
	
	start = [NSDate timeIntervalSinceReferenceDate];
	_c = 0;
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial1, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial2, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial3, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial4, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial5, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial6, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial7, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial8, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial9, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial10, ^(size_t i){
			[self dispatchSyncAdd:o];
		});
	});
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	end = [NSDate timeIntervalSinceReferenceDate];
	assert(_c == TESTCASES);
	NSLog(@"Dispatch sync, 10 queue: %2.5f seconds", end - start);
	
	start = [NSDate timeIntervalSinceReferenceDate];
	_c = 0;
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial1, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial2, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial3, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial4, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial5, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial6, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial7, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial8, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial9, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		dispatch_apply(TESTCASE_SPLIT_IN_10, serial10, ^(size_t i){
			[self dispatchASyncAdd:o];
		});
	});
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	end = [NSDate timeIntervalSinceReferenceDate];
	NSLog(@"Dispatch async, 10 queue: %2.5f seconds", end - start);
	dispatch_sync(_q, ^{;}); // wait for async stuff to complete
	end = [NSDate timeIntervalSinceReferenceDate];
	assert(_c == TESTCASES);
	NSLog(@"Dispatch async 10 queue add completion: %2.5f seconds", end - start);

	exit(0);
}
@end

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		Sync *s = [[Sync alloc] init];
		[s performSelector:@selector(test) withObject:nil afterDelay:0.0];
		[[NSRunLoop currentRunLoop] run];
	}
    return 0;
}
