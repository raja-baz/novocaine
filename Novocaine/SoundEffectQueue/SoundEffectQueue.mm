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

#import "SoundEffectQueue.h"
#import "NSMutableArray+QueueAdditions.h"

#import <AudioToolbox/AudioToolbox.h>

#import "RingBuffer.h"
#import "Novocaine.h"

@implementation SoundEffectQueue

-(void) dealloc {
	[_soundList removeAllObjects];
	_soundList = nil;
	
	filename = nil;
}

-(void) enqueue:(AudioFile*)aFile {

	aFile.target=nil;
	aFile.onPlayFinished = nil;
	
	[self.soundList enqueue:aFile];
#ifdef DEBUG
	NSLog(@"enqueu: %@  soundList: %@",aFile,self.soundList);
#endif
}
-(void) enqueue:(AudioFile*)aFile sel:(SEL)s target:(id)tid {
	
	aFile.target=tid;
	aFile.onPlayFinished = s;
	
	[self.soundList enqueue:aFile];
#ifdef DEBUG
	NSLog(@"enqueu: %@  soundList: %@",aFile,self.soundList);
#endif
}

-(UInt32) playQueuedSoundEffect:(float*)outdata numFrames:(UInt32)frames channel:(int)channel numChannels:(int)channels {

	if(skipLoops < 10)
	{
		// leave some time delay between playing sounds once one ends
		skipLoops ++;
	}
	else{

		if(audioFile)
		{
			@autoreleasepool {
				UInt32 framesRead = [audioFile readData:outdata frames:frames channel:channel channels:channels];
				if(framesRead == 0)
				{
					if(audioFile.target)
						[audioFile.target performSelector:audioFile.onPlayFinished withObject:audioFile];
					audioFile=nil;
					skipLoops = 0;
				}
			}
		}
		else if([self.soundList count])
		{
			@autoreleasepool {
#ifdef DEBUG
				NSLog(@"playQueuedSoundEffect: %@  soundList: %@",self,self.soundList);
#endif
				audioFile = (AudioFile*)[self.soundList dequeue];
				if(audioFile)
				{
#ifdef DEBUG
					NSLog(@"playAudioFile: %@",audioFile.fileURL);
#endif
					self.isPlaying = NO;
					/*

					UInt32 framesRead = [audioFile readData:outdata frames:frames channel:channel channels:channels];
					if(framesRead == 0)
					{
						if(audioFile.target)
							[audioFile.target performSelector:audioFile.onPlayFinished withObject:audioFile];
						audioFile=nil;
					}
					 */
				}
			}
		}
	}
}

-(id) init {
	self = [super init];
    if (self)
    {
		self.soundList = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

@end

