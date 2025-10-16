#ifndef SimpleVADWrapper_h
#define SimpleVADWrapper_h

#import <Foundation/Foundation.h>

// Callback types for C-style callbacks
typedef void (*VoiceStartCallback)(void* context);
typedef void (*VoiceEndCallback)(void* context, const uint8_t* wavData, size_t wavSize);
typedef void (*VoiceContinueCallback)(void* context, const uint8_t* pcmFloatData, size_t dataSize);

// Simple VAD wrapper interface
@interface SimpleVADWrapper : NSObject

// Initialize VAD
- (instancetype)init;

// Configure VAD
- (void)setSampleRate:(int)sampleRate;
- (void)setThresholds:(float)startProb endProb:(float)endProb startRatio:(float)startRatio endRatio:(float)endRatio startFrames:(int)startFrames endFrames:(int)endFrames;
- (void)setModelVersion:(int)modelVersion;

// Process audio
- (void)processAudioData:(const float*)audioData count:(int)count;

// Set callbacks
- (void)setCallbacks:(VoiceStartCallback)startCallback 
         endCallback:(VoiceEndCallback)endCallback 
      continueCallback:(VoiceContinueCallback)continueCallback 
              context:(void*)context;

// Cleanup
- (void)cleanup;

@end

#endif /* SimpleVADWrapper_h */
