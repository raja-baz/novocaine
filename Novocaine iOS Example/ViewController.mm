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


#import "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
    [audioManager pause];
    audioManager = nil;
    
    delete ringBuffer;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    BOOL testAudioFileReader = YES;
    BOOL testAudio = YES;
    BOOL testPlayNoise = NO;
    BOOL testMeasureDecibles = YES;
    BOOL testPlayDalekVoice = NO;

    ringBuffer = new RingBuffer(32768, 2); 
    audioManager = [Novocaine audioManager];

    RingBuffer *bRingBuffer=ringBuffer;
    
    // AUDIO FILE READING OHHH YEAHHHH
    // ========================================
    if (testAudioFileReader) {
        NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:@"TLC" withExtension:@"mp3"];
        
        fileReader = [[AudioFileReader alloc]
                      initWithAudioFileURL:inputFileURL
                      samplingRate:audioManager.samplingRate
                      numChannels:audioManager.numOutputChannels];
        
        [fileReader play];
        fileReader.currentTime = 30.0;
    }
    
    __block AudioFileReader *bFileReader = fileReader;
    
    if(testAudio) {
        
        // Basic playthru example
        __block float dbVal = 0.0;
        __block float frequency = 100.0;
        __block float phase = 0.0;
        
        [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
            
            float volume = 0.5;
            vDSP_vsmul(data, 1, &volume, data, 1, numFrames*numChannels);
            
            bRingBuffer->AddNewInterleavedFloatData(data, numFrames, numChannels);
            
            // MEASURE SOME DECIBELS!
            // ==================================================
            if(testMeasureDecibles) {
                vDSP_vsq(data, 1, data, 1, numFrames*numChannels);
                float meanVal = 0.0;
                vDSP_meanv(data, 1, &meanVal, numFrames*numChannels);
                
                float one = 1.0;
                vDSP_vdbcon(&meanVal, 1, &one, &meanVal, 1, 1, 0);
                dbVal = dbVal + 0.2 * (meanVal - dbVal);
                
                if(dbVal > -30)
                    printf("Decibel level: %f\n", dbVal);
            }

        }];
        
        [audioManager setOutputBlock:^(float *outData, UInt32 numFrames, UInt32 numChannels) {
            
            bRingBuffer->FetchInterleavedData(outData, numFrames, numChannels);

            if(testPlayNoise) {
                
                // MAKE SOME NOOOOO OIIIISSSEEE
                // ==================================================
                for (int i = 0; i < numFrames * numChannels; i++) {
                    outData[i] = (rand() % 100) / 100.0f / 2;
                }
                
            } else if(testPlayDalekVoice){
                
                // DALEK VOICE!
                float samplingRate = audioManager.samplingRate;
                for (int i=0; i < numFrames; ++i) {
                    for (int iChannel = 0; iChannel < numChannels; ++iChannel)
                    {
                        float theta = phase * M_PI * 2;
                        outData[i*numChannels + iChannel] *= sin(theta);
                    }
                    phase += 1.0 / (samplingRate / frequency);
                    if (phase > 1.0) phase = -1;
                }

            } else {
                
                // AUDIO FILE READING OHHH YEAHHHH
                // ========================================
                if (testAudioFileReader) {
                    [bFileReader retrieveFreshAudio:outData numFrames:numFrames numChannels:numChannels];
                }
            }
    
        }];
        
    }
    
    // SIGNAL GENERATOR!
    {
//    __block float frequency = 40.0;
//    __block float phase = 0.0;
//    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//
//         float samplingRate = audioManager.samplingRate;
//         for (int i=0; i < numFrames; ++i)
//         {
//             for (int iChannel = 0; iChannel < numChannels; ++iChannel) 
//             {
//                 float theta = phase * M_PI * 2;
//                 data[i*numChannels + iChannel] = sin(theta);
//             }
//             phase += 1.0 / (samplingRate / frequency);
//             if (phase > 1.0) phase = -1;
//         }
//     }];
    }
    
    // DALEK VOICE!
    {
    // (aka Ring Modulator)
    
//    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         ringBuffer->AddNewInterleavedFloatData(data, numFrames, numChannels);
//     }];
//    
//    __block float frequency = 100.0;
//    __block float phase = 0.0;
//    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         ringBuffer->FetchInterleavedData(data, numFrames, numChannels);
//         
//         float samplingRate = audioManager.samplingRate;
//         for (int i=0; i < numFrames; ++i)
//         {
//             for (int iChannel = 0; iChannel < numChannels; ++iChannel) 
//             {
//                 float theta = phase * M_PI * 2;
//                 data[i*numChannels + iChannel] *= sin(theta);
//             }
//             phase += 1.0 / (samplingRate / frequency);
//             if (phase > 1.0) phase = -1;
//         }
//     }];
    }
    
    // VOICE-MODULATED OSCILLATOR
    {
//    __block float magnitude = 0.0;
//    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         vDSP_rmsqv(data, 1, &magnitude, numFrames*numChannels);
//     }];
//    
//    __block float frequency = 100.0;
//    __block float phase = 0.0;
//    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//
//         printf("Magnitude: %f\n", magnitude);
//         float samplingRate = audioManager.samplingRate;
//         for (int i=0; i < numFrames; ++i)
//         {
//             for (int iChannel = 0; iChannel < numChannels; ++iChannel) 
//             {
//                 float theta = phase * M_PI * 2;
//                 data[i*numChannels + iChannel] = magnitude*sin(theta);
//             }
//             phase += 1.0 / (samplingRate / (frequency));
//             if (phase > 1.0) phase = -1;
//         }
//     }];
    }

    // AUDIO FILE WRITING YEAH!
    {
    // ========================================    
//    NSArray *pathComponents = [NSArray arrayWithObjects:
//                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], 
//                               @"My Recording.m4a", 
//                               nil];
//    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
//    NSLog(@"URL: %@", outputFileURL);
//    
//    fileWriter = [[AudioFileWriter alloc] 
//                  initWithAudioFileURL:outputFileURL 
//                  samplingRate:audioManager.samplingRate 
//                  numChannels:audioManager.numInputChannels];
//    
//    
//    __block int counter = 0;
//    audioManager.inputBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
//        [fileWriter writeNewAudio:data numFrames:numFrames numChannels:numChannels];
//        counter += 1;
//        if (counter > 400) { // roughly 5 seconds of audio
//            audioManager.inputBlock = nil;
//            [fileWriter release];
//        }
//    };
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
