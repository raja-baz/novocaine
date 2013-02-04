// Copyright (c) 2012 Alex Wiltschko
// 
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// TODO:
// Switching mic and speaker on/off
//
// HOUSEKEEPING AND NICE FEATURES:
// Disambiguate outputFormat (the AUHAL's stream format)
// More nuanced input detection on the Mac
// Route switching should work, check with iPhone
// Device switching should work, check with laptop. Read that damn book.
// Wrap logging with debug macros.
// Think about what should be public, what private.
// Ability to select non-default devices.


#import "AudioManager.h"
#import "Novocaine.h"

@implementation AudioManager

static AudioManager *sharedAudioManager = nil;

void sessionInterruptionListener(void *inClientData, UInt32 inInterruption) {

	if (inInterruption == kAudioSessionBeginInterruption) {
		NSLog(@"Begin interuption");
		[[NSNotificationCenter defaultCenter] postNotificationName:kAudioSessionBeginInterruptionName object:nil];
	}
	else if (inInterruption == kAudioSessionEndInterruption) {
		NSLog(@"End interuption");
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kAudioSessionEndInterruptionName object:nil];
	}
}

#pragma mark - Singleton Methods
+(AudioManager*) sharedAudioManager {
	@synchronized(self)
	{
		if(sharedAudioManager == nil)
		{
			sharedAudioManager = [[self alloc] init];
		}
	}
	return sharedAudioManager;
}

-(id)init {
	if (self = [super init])
	{		
#if defined USING_IOS
		CheckError( AudioSessionInitialize(NULL, NULL, sessionInterruptionListener, (__bridge void *)(self)), "Couldn't initialize audio session");
#elif defined USING_OSX
#endif
		return self;
	}
	return nil;
}

@end








