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


#include "RingBuffer.h"

RingBuffer::RingBuffer(SInt64 bufferLength, SInt64 numChannels) {

	mSizeOfBuffer=bufferLength;

	if (numChannels > kMaxNumChannels)
		mNumChannels = kMaxNumChannels;
	else if (numChannels <= 0)
		mNumChannels = 1;
	else
		mNumChannels = numChannels;
	
	mData = (float **)calloc(numChannels, sizeof(float *));

	for (int i=0; i < kMaxNumChannels; ++i) {
		mData[i] = nil;
		mNumOriginalFrames[i] = 0;
		mLastWrittenIndex[i] = 0;
		mLastReadIndex[i] = 0;
        mNumUnreadFrames[i] = 0;
	}
	
	for (int i=0; i < numChannels; ++i) {
		mData[i] = (float *)calloc(bufferLength, sizeof(float));
		mNumOriginalFrames[i] = bufferLength; // holds the initial buffer size
		mLastWrittenIndex[i] = 0;
		mLastReadIndex[i] = 0;
        mNumUnreadFrames[i] = 0;
	}
}

RingBuffer::~RingBuffer()  {
    for (int i=0; i<mNumChannels; i++) {
        free(mData[i]);
    }
}

void RingBuffer::AddNewSInt16AudioBuffer(const AudioBuffer aBuffer, int bytesPerFramesChannel) {
		
	int numChannelsHere = aBuffer.mNumberChannels;
	int numFrames = aBuffer.mDataByteSize/(numChannelsHere*bytesPerFramesChannel);//*sizeof(SInt16));
	
	SInt64 idx;

	NSLog(@"theFileLengthInFrames: %d, mChannelsPerFrame = %ld\ndataSize:%ld\nmBytesPerFrame:%d",
		  numFrames,
		  aBuffer.mNumberChannels,
		  aBuffer.mDataByteSize,
		  bytesPerFramesChannel);
	
	for (int iChannel = 0; iChannel < numChannelsHere; ++iChannel) { // In case the sound file is  mono single channel
		for (int i=0; i < numFrames; ++i) {
			idx = (i + mLastWrittenIndex[iChannel]) % (mSizeOfBuffer);
			if(bytesPerFramesChannel == 2)
			{
				UInt16 *dataPtr = (UInt16 *)aBuffer.mData;
				UInt16 data = dataPtr[i*numChannelsHere + iChannel];
				mData[iChannel][idx] = (float)data;
			}
			else
			{
				float *dataPtr = (float *)aBuffer.mData;
				float data = dataPtr[i*numChannelsHere + iChannel];
				mData[iChannel][idx] = data;
			}
		}
		
		mLastWrittenIndex[iChannel] = (mLastWrittenIndex[iChannel] + numFrames) % (mSizeOfBuffer);
        mNumUnreadFrames[iChannel] = mNumUnreadFrames[iChannel] + numFrames;
        if (mNumUnreadFrames[iChannel] >= mSizeOfBuffer)
			mNumUnreadFrames[iChannel] = mSizeOfBuffer;
	}
}

void RingBuffer::AddNewSInt16Data(const SInt16 *newData, const SInt64 numFrames, const SInt64 whichChannel) {
	SInt64 idx;
	for (int i=0; i < numFrames; ++i) {
		idx = (i + mLastWrittenIndex[whichChannel]) % (mSizeOfBuffer);
		mData[whichChannel][idx] = (float)newData[i];
	}
	
	mLastWrittenIndex[whichChannel] = (mLastWrittenIndex[whichChannel] + numFrames) % (mSizeOfBuffer);
    mNumUnreadFrames[whichChannel] = mNumUnreadFrames[whichChannel] + numFrames;
    if (mNumUnreadFrames[whichChannel] >= mSizeOfBuffer) mNumUnreadFrames[whichChannel] = mSizeOfBuffer;
}

void RingBuffer::AddNewFloatData(const float *newData, const SInt64 numFrames, const SInt64 whichChannel) {
	
	SInt64 idx;
	for (int i=0; i < numFrames; ++i) {
		idx = (i + mLastWrittenIndex[whichChannel]) % (mSizeOfBuffer);
		mData[whichChannel][idx] = newData[i];
	}
	
	mLastWrittenIndex[whichChannel] = (mLastWrittenIndex[whichChannel] + numFrames) % (mSizeOfBuffer);
    mNumUnreadFrames[whichChannel] = mNumUnreadFrames[whichChannel] + numFrames;
    if (mNumUnreadFrames[whichChannel] >= mSizeOfBuffer) mNumUnreadFrames[whichChannel] = mSizeOfBuffer;
}

void RingBuffer::AddNewDoubleData(const double *newData, const SInt64 numFrames, const SInt64 whichChannel) {
	
	SInt64 idx;
	for (int i=0; i < numFrames; ++i) {
		idx = (i + mLastWrittenIndex[whichChannel]) % (mSizeOfBuffer);
		mData[whichChannel][idx] = (float)newData[i];
	}
	
	mLastWrittenIndex[whichChannel] = (mLastWrittenIndex[whichChannel] + numFrames) % (mSizeOfBuffer);
    mNumUnreadFrames[whichChannel] = mNumUnreadFrames[whichChannel] + numFrames;
    if (mNumUnreadFrames[whichChannel] >= mSizeOfBuffer) mNumUnreadFrames[whichChannel] = mSizeOfBuffer;
}

void RingBuffer::AddNewInterleavedFloatData(const float *newData, const SInt64 numFrames, const SInt64 numChannelsHere) {
	
	int numChannelsToCopy = (numChannelsHere <= mNumChannels) ? numChannelsHere : mNumChannels;
	float zero = 0.0f;
	
	for (int iChannel = 0; iChannel < numChannelsToCopy; ++iChannel) {
		
		if (numFrames + mLastWrittenIndex[iChannel] < mSizeOfBuffer) { // if our new set of samples won't overrun the edge of the buffer
			vDSP_vsadd((float *)&newData[iChannel], 
					   numChannelsHere, 
					   &zero, 
					   &mData[iChannel][mLastWrittenIndex[iChannel]], 
					   1, 
					   numFrames);
		}
			
		else {															// if we will overrun, then we need to do two separate copies.
			int numSamplesInFirstCopy = mSizeOfBuffer - mLastWrittenIndex[iChannel];
			int numSamplesInSecondCopy = numFrames - numSamplesInFirstCopy;
			
			vDSP_vsadd((float *)&newData[iChannel], 
					   numChannelsHere, 
					   &zero, 
					   &mData[iChannel][mLastWrittenIndex[iChannel]], 
					   1, 
					   numSamplesInFirstCopy);
			
			vDSP_vsadd((float *)&newData[numSamplesInFirstCopy*numChannelsHere + iChannel], 
					   numChannelsHere, 
					   &zero, 
					   &mData[iChannel][0], 
					   1, 
					   numSamplesInSecondCopy);
		}
	
		mLastWrittenIndex[iChannel] = (mLastWrittenIndex[iChannel] + numFrames) % (mSizeOfBuffer);
        mNumUnreadFrames[iChannel] = (mNumUnreadFrames[iChannel] + numFrames);
        if (mNumUnreadFrames[iChannel] >= mSizeOfBuffer) mNumUnreadFrames[iChannel] = mSizeOfBuffer;
	}	
}

void RingBuffer::FetchFreshData2(float *outData, SInt64 numFrames, SInt64 whichChannel, SInt64 stride) {

	if(stride > mNumChannels)
		stride = mNumChannels;

    if (mLastWrittenIndex[whichChannel] - numFrames >= 0) { // if we're requesting samples that won't go off the left end of the ring buffer, then go ahead and copy them all out.
        
        UInt32 idx = mLastWrittenIndex[whichChannel] - numFrames;
        float zero = 0.0f;
        vDSP_vsadd(&mData[whichChannel][idx], 
                   1, 
                   &zero, 
                   outData, 
                   stride, 
                   numFrames);
    }
    
    else { // if we will overrun, then we need to do two separate copies.
        
        // The copy that bleeds off the left, and cycles back to the right of the ring buffer
        int numSamplesInFirstCopy = numFrames - mLastWrittenIndex[whichChannel];
        // The copy that starts at the beginning, and proceeds to the end.
        int numSamplesInSecondCopy = mLastWrittenIndex[whichChannel];
        
        float zero = 0.0f;
        UInt32 firstIndex = mSizeOfBuffer - numSamplesInFirstCopy;
        vDSP_vsadd(&mData[whichChannel][firstIndex],
                   1, 
                   &zero, 
                   &outData[0], 
                   stride, 
                   numSamplesInFirstCopy);

        vDSP_vsadd(&mData[whichChannel][0],
                   1, 
                   &zero, 
                   &outData[numSamplesInFirstCopy*stride],
                   stride, 
                   numSamplesInSecondCopy);
        
    }

}

// Return the number of frames fetched
SInt64 RingBuffer::FetchData(float *outData, SInt64 numFrames, SInt64 whichOfChannels, SInt64 numChannels) {
    int idx;
	int channel = whichOfChannels;	// numChannels refers to how many channels outData hosts (not related to the ringbuffer or it's data's channels

	if(mNumChannels == 1 && whichOfChannels == 1)
	{
		channel = 0; // Since the RingBuffer may have been created to only host a single channel
	}

	if(numFrames > mNumUnreadFrames[channel])
		numFrames = mNumUnreadFrames[channel]; // Read a  maximum of available data to read
	
	if(mNumUnreadFrames[channel] > 0)
	{
		 NSLog(@"frames: %lld mNumUnreadFrames:%lld mLastReadIndex:%lld\nmNumOriginalFrames:%lld\nmSizeOfBuffer:%lld",
			  numFrames,
			  mNumUnreadFrames[channel],
			  mLastReadIndex[channel],
			  mNumOriginalFrames[channel],
			  mSizeOfBuffer);

		for (int frame=0; frame < numFrames; ++frame) {
			idx = (mLastReadIndex[channel] + frame) % (mSizeOfBuffer);
			outData[frame*numChannels+channel] = mData[channel][idx];
		}
	
		mLastReadIndex[channel] = (mLastReadIndex[channel] + numFrames) % (mSizeOfBuffer);
		mNumUnreadFrames[channel] -= numFrames;
    }
	else
	{
		numFrames = 0;
	}
	
    if (mNumUnreadFrames[channel] <= 0)
		mNumUnreadFrames[channel] = 0;
	
	return numFrames;
}

void RingBuffer::FetchInterleavedData(float *outData, SInt64 numFrames, SInt64 numChannels) {
    for (int iChannel=0; iChannel < numChannels; ++iChannel) {
        FetchData(outData, numFrames, iChannel, numChannels);
    }
}

void RingBuffer::FetchFreshData(float *outData, SInt64 numFrames, SInt64 whichChannel, SInt64 stride) {

	int idx;
	for (int i=0; i < numFrames; ++i) {
		idx = (mLastWrittenIndex[whichChannel] - numFrames + i) % (mSizeOfBuffer);
		outData[i*stride] = mData[whichChannel][idx];
	}
	
	mLastReadIndex[whichChannel] = mLastWrittenIndex[whichChannel];
    mNumUnreadFrames[whichChannel] = 0; // Reading at the front of the buffer resets old data
}

void RingBuffer::SeekWriteHeadPosition(SInt64 offset, int iChannel) {
    mLastWrittenIndex[iChannel] = (mLastWrittenIndex[iChannel] + offset) % (mSizeOfBuffer);
}

void RingBuffer::SeekReadHeadPosition(SInt64 offset, int iChannel) {
    mLastReadIndex[iChannel] = (mLastReadIndex[iChannel] + offset) % (mSizeOfBuffer);
}

SInt64 RingBuffer::NumNewFrames(SInt64 lastReadFrame, int iChannel) {
	int numNewFrames = mLastWrittenIndex[iChannel] - lastReadFrame;
	if (numNewFrames < 0) numNewFrames += mSizeOfBuffer;
	
	return (SInt64)numNewFrames;
}

#pragma mark - Analytics
float RingBuffer::Mean(const SInt64 whichChannel) {
	float mean;
	vDSP_meanv(mData[whichChannel],1,&mean,mSizeOfBuffer);
	return mean;
}

float RingBuffer::Max(const SInt64 whichChannel) {
	float max;
	vDSP_maxv(mData[whichChannel],1,&max,mSizeOfBuffer);
	return max;
}

float RingBuffer::Min(const SInt64 whichChannel) {
	float min;
	vDSP_minv(mData[whichChannel],1,&min,mSizeOfBuffer);
	return min;	
}

void RingBuffer::Clear() {
	for (int i=0; i < mNumChannels; ++i) {
		memset(mData[i], 0, sizeof(float)*mSizeOfBuffer);
		mLastWrittenIndex[i] = 0;
		mLastReadIndex[i] = 0;
		mNumUnreadFrames[i] = 0;
	}
}

void RingBuffer::Reset() {
	for (int i=0; i < mNumChannels; ++i) {
		// memset(mData[i], 0, sizeof(float)*mSizeOfBuffer); // Do not erase the original content written for soundeffects
		// mLastWrittenIndex[i] = 0; // Do not erase the original content written for soundeffects
		mLastReadIndex[i] = 0;
		mNumUnreadFrames[i] = mNumOriginalFrames[i];
	}
}
