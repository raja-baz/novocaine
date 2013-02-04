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

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>

#import "AudioFile.h"

@interface SoundEffectQueue : NSObject
{
	NSString *filename;
	AudioFile	*audioFile;

	int skipLoops;
}
@property (readwrite, nonatomic) BOOL isPlaying;
@property (nonatomic, strong)	NSMutableArray* soundList;


-(void) enqueue:(AudioFile*) sound;
-(void) enqueue:(AudioFile*)aFile sel:(SEL)s target:(id)tid;

-(UInt32) playQueuedSoundEffect:(float*)outData numFrames:(UInt32)numFrames channel:(int)channel numChannels:(int)numChannels;

@end
