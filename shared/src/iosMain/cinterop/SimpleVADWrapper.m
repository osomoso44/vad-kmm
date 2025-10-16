#import "SimpleVADWrapper.h"
#import "VADWrapper.h"

@interface SimpleVADWrapper()
@property (nonatomic, strong) VADWrapper* vadWrapper;
@property (nonatomic, assign) VoiceStartCallback startCallback;
@property (nonatomic, assign) VoiceEndCallback endCallback;
@property (nonatomic, assign) VoiceContinueCallback continueCallback;
@property (nonatomic, assign) void* context;
@end

@implementation SimpleVADWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        _vadWrapper = [[VADWrapper alloc] init];
        _vadWrapper.delegate = (id<VADDelegate>)self;
    }
    return self;
}

- (void)setSampleRate:(int)sampleRate {
    SL slEnum;
    switch (sampleRate) {
        case 8000:
            slEnum = SAMPLERATE_8;
            break;
        case 16000:
            slEnum = SAMPLERATE_16;
            break;
        case 24000:
            slEnum = SAMPLERATE_24;
            break;
        case 48000:
            slEnum = SAMPLERATE_48;
            break;
        default:
            slEnum = SAMPLERATE_16; // Default
            break;
    }
    [self.vadWrapper setSamplerate:slEnum];
}

- (void)setThresholds:(float)startProb endProb:(float)endProb startRatio:(float)startRatio endRatio:(float)endRatio startFrames:(int)startFrames endFrames:(int)endFrames {
    [self.vadWrapper setThresholdWithVadStartDetectionProbability:startProb 
                                    VadEndDetectionProbability:endProb 
                                    VoiceStartVadTrueRatio:startRatio 
                                    VoiceEndVadFalseRatio:endRatio 
                                    VoiceStartFrameCount:startFrames 
                                    VoiceEndFrameCount:endFrames];
}

- (void)setModelVersion:(int)modelVersion {
    SMVER modelEnum;
    switch (modelVersion) {
        case 4:
            modelEnum = v4;
            break;
        case 5:
            modelEnum = v5;
            break;
        default:
            modelEnum = v4; // Default
            break;
    }
    [self.vadWrapper setSileroModel:modelEnum];
}

- (void)processAudioData:(const float*)audioData count:(int)count {
    [self.vadWrapper processAudioDataWithBuffer:audioData count:count];
}

- (void)setCallbacks:(VoiceStartCallback)startCallback 
         endCallback:(VoiceEndCallback)endCallback 
      continueCallback:(VoiceContinueCallback)continueCallback 
              context:(void*)context {
    self.startCallback = startCallback;
    self.endCallback = endCallback;
    self.continueCallback = continueCallback;
    self.context = context;
}

- (void)cleanup {
    self.vadWrapper = nil;
    self.startCallback = nil;
    self.endCallback = nil;
    self.continueCallback = nil;
    self.context = nil;
}

#pragma mark - VADDelegate

- (void)voiceStarted {
    if (self.startCallback && self.context) {
        self.startCallback(self.context);
    }
}

- (void)voiceEndedWithWavData:(NSData *)wavData {
    if (self.endCallback && self.context && wavData) {
        self.endCallback(self.context, (const uint8_t*)wavData.bytes, wavData.length);
    }
}

- (void)voiceDidContinueWithPCMFloatData:(NSData *)pcmFloatData {
    if (self.continueCallback && self.context && pcmFloatData) {
        self.continueCallback(self.context, (const uint8_t*)pcmFloatData.bytes, pcmFloatData.length);
    }
}

@end
