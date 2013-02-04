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


#import "AudioFile.h"
#import "RingBuffer.h"

@implementation AudioFile {
    RingBuffer *ringBuffer;
}

-(void) dealloc {
	_fileURL = nil;
	// _fileID  = nil;

	_onPlayFinished = nil;
	_target = nil;
}

-(id)initWithSoundNamed:(NSString *)file  novocaine:(Novocaine	*)novacaine{
	
	if (self = [super init])
	{
		fileName = file;
		
		// Open a reference to the audio file
		self.fileURL = [[NSBundle mainBundle] URLForResource:file withExtension:@"wav"];
		audioManager = novacaine;
		[self readFile];
		
		return self;
	}
	return nil;
}

-(BOOL) readFile {

	OSStatus						err = noErr;
	SInt64							theFileLengthInFrames = 0;
	AudioStreamBasicDescription		theFileFormat;
	UInt32							thePropertySize = sizeof(theFileFormat);
	ExtAudioFileRef					extRef = NULL;
	void*							theData = NULL;

	// Open a file with ExtAudioFileOpen()
	err = ExtAudioFileOpenURL((__bridge CFURLRef)self.fileURL, &extRef);	
	if(err) {
		NSLog(@"MyGetOpenALAudioData: ExtAudioFileOpenURL FAILED, Error = %ld\n", err);
		if (extRef) ExtAudioFileDispose(extRef);
		return NO;
	}

	// Get the audio data format
	err = ExtAudioFileGetProperty(extRef,
								  kExtAudioFileProperty_FileDataFormat,
								  &thePropertySize,
								  &theFileFormat);
	if(err) {
		NSLog(@"MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileDataFormat) FAILED, Error = %ld\n", err);
		if (extRef) ExtAudioFileDispose(extRef);
		return NO;

	}
	if (theFileFormat.mChannelsPerFrame > kMaxNumChannels)  {
		NSLog(@"MyGetOpenALAudioData - Unsupported Format, channel count is greater than stereo\n");
		if (extRef) ExtAudioFileDispose(extRef);
		return NO;

	}

	// self.latency = .011609977; // 512 samples / ( 44100 samples / sec ) default
	// We're going to impose a format upon the input file. Single-channel float does the trick.
	
	theFileFormat.mSampleRate = audioManager.outputFormat.mSampleRate; // 44100;
	theFileFormat.mFormatID = audioManager.outputFormat.mFormatID; // kAudioFormatLinearPCM;
	theFileFormat.mFormatFlags = audioManager.outputFormat.mFormatFlags; // kAudioFormatFlagIsFloat;
	theFileFormat.mBytesPerPacket = audioManager.outputFormat.mBytesPerPacket; // 4*theFileFormat.mChannelsPerFrame;
	theFileFormat.mFramesPerPacket = audioManager.outputFormat.mFramesPerPacket; // 1;
	theFileFormat.mBytesPerFrame = audioManager.outputFormat.mBytesPerFrame; // 4*theFileFormat.mChannelsPerFrame;
	theFileFormat.mChannelsPerFrame = 1; // theFileFormat.mChannelsPerFrame;
	theFileFormat.mBitsPerChannel = audioManager.outputFormat.mBitsPerChannel; // 32;

	// Apply the format to our file
	ExtAudioFileSetProperty(extRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &theFileFormat);

	// Get the total frame count
	thePropertySize = sizeof(theFileLengthInFrames);
	err = ExtAudioFileGetProperty(extRef,
								  kExtAudioFileProperty_FileLengthFrames,
								  &thePropertySize,
								  &theFileLengthInFrames);
	if(err) {
		NSLog(@"MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileLengthFrames) FAILED, Error = %ld\n", err);
		if (extRef) ExtAudioFileDispose(extRef);
		return NO;

	}

	// Read all the data into memory
	SInt64		dataSize = theFileLengthInFrames * (theFileFormat.mChannelsPerFrame *theFileFormat.mBytesPerFrame); // we will always have two channels minimum even if a channel is blank data
#ifdef DEBUG
	NSLog(@"fileURL: %@ \ntheFileLengthInFrames: %lld, mChannelsPerFrame = %ld\ndataSize:%lld\nmSampleRate:%f\nmBytesPerFrame:%ld mSampleRate:%f",
		  self.fileURL,
		  theFileLengthInFrames,
		  theFileFormat.mChannelsPerFrame,
		  dataSize,
		  theFileFormat.mSampleRate,
		  theFileFormat.mBytesPerFrame,
		  theFileFormat.mSampleRate);
#endif
	incomingAudio.mNumberBuffers = 1;
	incomingAudio.mBuffers[0].mDataByteSize		= dataSize;
	incomingAudio.mBuffers[0].mNumberChannels	= theFileFormat.mChannelsPerFrame;
	incomingAudio.mBuffers[0].mData				= malloc(dataSize);

	// Read the data into an AudioBufferList
	err = ExtAudioFileRead(extRef, (UInt32*)&theFileLengthInFrames, &incomingAudio);
	if(err == noErr)
	{
		// success
		framesSent = 0;
		ringBuffer = new RingBuffer(theFileLengthInFrames, theFileFormat.mChannelsPerFrame);
		ringBuffer->AddNewSInt16AudioBuffer(incomingAudio.mBuffers[0],theFileFormat.mBytesPerFrame/theFileFormat.mChannelsPerFrame);
	}
	else
	{
		// failure
		free (theData);
		theData = NULL; // make sure to return NULL
		NSLog(@"MyGetOpenALAudioData: ExtAudioFileRead FAILED, Error = %ld\n", err);
		if (extRef) ExtAudioFileDispose(extRef);
		return NO;
	}

	if (extRef) ExtAudioFileDispose(extRef);
	free (theData);
	return YES;
}


-(UInt32)readData:(float*)outdata frames:(int)frames channel:(int)channel channels:(int)channels{

	SInt64 fetchedFrames[2];
	fetchedFrames[0]=0;
	fetchedFrames[1]=0;
	if(ringBuffer)
	{
		// we set channel to 0, 1 or -1 so that we can set which of the two channels we fill with data -1 means both
		if(channel == -1)
		{
			for (int iChannel=0; iChannel < channels; ++iChannel) {
				fetchedFrames[iChannel] = ringBuffer->FetchData(outdata, frames, iChannel,channels);
			}
			if(fetchedFrames[0] == 0)
				ringBuffer->Reset();
			return fetchedFrames[0] > fetchedFrames[1] ? fetchedFrames[0] : fetchedFrames[1];
		}
		else{
			//fetchedFrames[channel] = 1;
			//ringBuffer->AddNewInterleavedFloatData(outdata, frames, channels);
			fetchedFrames[channel] = ringBuffer->FetchData(outdata, frames, channel, channels);
			if(fetchedFrames[channel] == 0)
				ringBuffer->Reset();
			return fetchedFrames[channel];
		}
#ifdef DEBUG
		NSLog(@"frames: %d fetchedFrames:%lld fetchedFrames:%lld",frames,fetchedFrames[0],fetchedFrames[1]);
#endif
	}
	return 0;
}
@end








