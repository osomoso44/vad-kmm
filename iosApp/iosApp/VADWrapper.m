#import "VADWrapper.h"
#import <RealTimeCutVADCXXLibrary/RealTimeCutVADCXXLibrary.h>

@interface VADWrapper()

@property (nonatomic, assign) VADInstanceHandle vadInstance;

- (void)voiceStartCallback;
- (void)voiceEndCallbackWithData:(NSData *)wavData;
- (void)voiceDidContinueWithPCMFloatData:(NSData *)pcmFloatData;

@end

void voiceStartCallbackBridge(void* context) {
    VADWrapper *wrapper = (__bridge VADWrapper *)context;
    if (wrapper != nil) {
        [wrapper voiceStartCallback];
    }
}

void voiceEndCallbackBridge(void* context, const uint8_t* wavData, size_t wavSize) {
    VADWrapper *wrapper = (__bridge VADWrapper *)context;
    if (wrapper != nil) {
        NSData *data = [NSData dataWithBytes:wavData length:wavSize];
        [wrapper voiceEndCallbackWithData:data];
    }
}

void voiceDidContinueCallbackBridge(void* context, const uint8_t* pcmFloatData, size_t dataSize) {
    VADWrapper *wrapper = (__bridge VADWrapper *)context;
    if (wrapper != nil) {
        NSData *data = [NSData dataWithBytes:pcmFloatData length:dataSize];
        [wrapper voiceDidContinueWithPCMFloatData:data];
    }
}

@implementation VADWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        _vadInstance = create_vad_instance();
        set_vad_callback(_vadInstance, (__bridge void *)(self), &voiceStartCallbackBridge, &voiceEndCallbackBridge, &voiceDidContinueCallbackBridge);
    }
    return self;
}

- (void)dealloc {
    destroy_vad_instance(_vadInstance);
    _vadInstance = NULL;
}

- (void)setSamplerate:(SL)sl {
    set_vad_sample_rate(_vadInstance, (int)sl);
}

- (void)setThresholdWithVadStartDetectionProbability:(float)a
                          VadEndDetectionProbability:(float)b
                              VoiceStartVadTrueRatio:(float)c
                              VoiceEndVadFalseRatio:(float)d
                                VoiceStartFrameCount:(int)e
                                VoiceEndFrameCount:(int)f {
    set_vad_threshold(_vadInstance, a, b, c, d, e, f);
}

- (void)setSileroModel:(SMVER)modelVersion {
    // Try main bundle first (for Xcode projects)
    NSBundle *resourceBundle = [NSBundle mainBundle];
    
    NSString *modelName = (modelVersion == v4 ? @"silero_vad" : @"silero_vad_v5");
    NSURL *modelURL = [resourceBundle URLForResource:modelName withExtension:@"onnx"];
    
    if (!modelURL) {
        // Try bundle for class if not found in main bundle
        resourceBundle = [NSBundle bundleForClass:[self class]];
        modelURL = [resourceBundle URLForResource:modelName withExtension:@"onnx"];
    }
    
    if (!modelURL) {
        NSLog(@"ERROR: Could not find model file %@.onnx in bundle", modelName);
        NSLog(@"Available resources in main bundle: %@", [[NSBundle mainBundle] pathsForResourcesOfType:@"onnx" inDirectory:nil]);
        return;
    }
    
    NSString *modelPath = [modelURL path];
    NSLog(@"Loading VAD model: %@", modelPath);
    
    if (!modelPath || [modelPath length] == 0) {
        NSLog(@"ERROR: Model path is nil or empty");
        return;
    }
    
    set_vad_model(_vadInstance, (int)modelVersion, [modelPath UTF8String]);
}

- (void)processAudioData:(NSArray<NSNumber *> *)audioData {
    float buffer[audioData.count];
    for (NSUInteger i = 0; i < audioData.count; i++) {
        buffer[i] = [audioData[i] floatValue];
    }
    process_vad_audio(_vadInstance, buffer, audioData.count);
}

- (void)processAudioDataWithBuffer:(const float *)audioData count:(NSUInteger)count {
    process_vad_audio(_vadInstance, audioData, count);
}

- (void)voiceStartCallback {
    if ([self.delegate respondsToSelector:@selector(voiceStarted)]) {
        [self.delegate voiceStarted];
    }
}

- (void)voiceEndCallbackWithData:(NSData *)wavData {
    if ([self.delegate respondsToSelector:@selector(voiceEndedWithWavData:)]) {
        [self.delegate voiceEndedWithWavData:wavData];
    }
}

- (void)voiceDidContinueWithPCMFloatData:(NSData *)pcmFloatData {
    if ([self.delegate respondsToSelector:@selector(voiceDidContinueWithPCMFloatData:)]) {
        [self.delegate voiceDidContinueWithPCMFloatData:pcmFloatData];
    }
}

// Additional configuration methods - placeholder implementations
- (void)setFrameSize:(int)frameSize {
    // TODO: Implementar si el framework nativo lo soporta
    NSLog(@"setFrameSize: %d", frameSize);
}

- (void)setMode:(int)mode {
    // TODO: Implementar si el framework nativo lo soporta
    NSLog(@"setMode: %d", mode);
}

- (void)setMinimumSilenceDurationMs:(int)duration {
    // TODO: Implementar si el framework nativo lo soporta
    NSLog(@"setMinimumSilenceDurationMs: %d", duration);
}

- (void)setMinimumSpeechDurationMs:(int)duration {
    // TODO: Implementar si el framework nativo lo soporta
    NSLog(@"setMinimumSpeechDurationMs: %d", duration);
}

- (void)setSilenceDurationMs:(int)duration {
    // TODO: Implementar si el framework nativo lo soporta
    NSLog(@"setSilenceDurationMs: %d", duration);
}

- (void)setMaxRecordingDurationMs:(int)duration {
    // TODO: Implementar si el framework nativo lo soporta
    NSLog(@"setMaxRecordingDurationMs: %d", duration);
}

- (void)setRecordSpeechOnly:(BOOL)recordSpeechOnly {
    // TODO: Implementar si el framework nativo lo soporta
    NSLog(@"setRecordSpeechOnly: %@", recordSpeechOnly ? @"YES" : @"NO");
}

- (void)stopRecording {
    // TODO: Implementar si el framework nativo lo soporta
    NSLog(@"stopRecording called");
}

@end
