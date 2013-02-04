// Copyright (c) 2012 ezRover Inc.
// Author: Nader Rahimizad
// Site: http://ezRover.com
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


#import <CoreFoundation/CoreFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>

#import "Novocaine.h"

#if defined __MAC_OS_X_VERSION_MAX_ALLOWED
    #define USING_OSX 
    #include <CoreAudio/CoreAudio.h>
#else
    #define USING_IOS
#endif

@interface AudioFile : NSObject
{
	NSString			*fileName;
	AudioBufferList		incomingAudio;

	Novocaine			*audioManager;

	int framesSent;
}

//@property AudioStreamBasicDescription outputFormat;
@property (nonatomic, assign) AudioStreamBasicDescription     format;

@property (nonatomic, strong) NSURL	*fileURL;

@property (nonatomic, assign) SEL	onPlayFinished;
@property (nonatomic, assign) id	target;

@property (nonatomic, assign) UInt32 outputBufferSize;

-(id)initWithSoundNamed:(NSString *)file   novocaine:(Novocaine	*)audioManager;
-(UInt32)readData:(float*)outdata frames:(int)frames channel:(int)channel channels:(int)channels;

@end
