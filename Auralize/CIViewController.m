//
//  CIViewController.m
//  Auralize
//
//  Created by Chinmay Pendharkar on 14/1/14.
//  Copyright (c) 2014 CrayonIO Pte. Ltd. All rights reserved.
//

#import "CIViewController.h"

@interface CIViewController ()

@end

@implementation CIViewController{
    NSArray* avAudioSessionInputChoice;
    AVAudioSession* session;
    AudioUnit remoteIOUnit;
}

static const double PREFERED_BUFFER_SIZE = 0.0232;
static const double PREFERED_SAMPLE_RATE = 44100;

static const int INPUT_NUM_CHANNELS = 1;
static const int OUTPUT_NUM_CHANNELS = 1;

static const int BYTES_PER_FLOAT = sizeof(float);
static const int BYTES_PER_SHORT = sizeof(short);
static const int BITS_PER_BYTE = 8;

static const AudioUnitElement INPUT_BUS = 1;
static const AudioUnitElement OUTPUT_BUS = 0;


@synthesize sampleRate = _sampleRate;
@synthesize remoteIOUnit = remoteIOUnit;

//@synthesize effectState = _effectState;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self initAudioProcessing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)switchValueChanged:(id)sender {
    UISwitch *thisSwitch = (UISwitch *) sender;
    
    if ([thisSwitch isOn])
        [self playAudioChain];
    else
        [self pauseAudioChain];
}


- (void) playAudioChain{
    OSStatus status = AudioOutputUnitStart(remoteIOUnit);
    assert(status == noErr);
    
    
}

- (void) pauseAudioChain{
    OSStatus status = AudioOutputUnitStop(remoteIOUnit);
    assert(status == noErr);
}

- (void) initAudioProcessing{
    
    [self setupAudioSession];
    [self hookUpAudioChain];
}

- (void) logChoicesAndRoutesForSession{
    NSLog(@"--------------------------------------------------");
    NSLog(@"Audio Inputs Avilable: %d", [[session availableInputs] count]);
    int counter = 0;
    for (AVAudioSessionPortDescription *input in [[AVAudioSession sharedInstance] availableInputs]) {
        NSLog(@"#%d Name :%@ - Type :%@ - Num Channels :%lu", counter++, input.portName, input.portType, (unsigned long)[input.channels count]);
        for (AVAudioSessionChannelDescription *channel in input.channels){
            NSLog(@"--#%lu Name :%@ - Label :%u", (unsigned long)channel.channelNumber, channel.channelName, (unsigned int)channel.channelLabel);
        }
    }
    
    AVAudioSessionRouteDescription* route = [session currentRoute];
    NSLog(@"Current Route has Inputs:");
    counter = 0;
    for (AVAudioSessionPortDescription *input in route.inputs) {
        NSLog(@"#%d Name :%@ - Type :%@ - Num Channels :%lu", counter++, input.portName, input.portType, (unsigned long)[input.channels count]);
        for (AVAudioSessionChannelDescription *channel in input.channels){
            NSLog(@"--#%lu Name :%@ - Label :%u", (unsigned long)channel.channelNumber, channel.channelName, (unsigned int)channel.channelLabel);
        }
    }
    
    
    NSLog(@"Current Route has Outputs:");
    counter = 0;
    for (AVAudioSessionPortDescription *input in route.outputs) {
        NSLog(@"#%d Name :%@ - Type :%@ - Num Channels :%lu", counter++, input.portName, input.portType, (unsigned long)[input.channels count]);
        for (AVAudioSessionChannelDescription *channel in input.channels){
            NSLog(@"--#%lu Name :%@ - Label :%u", (unsigned long)channel.channelNumber, channel.channelName, (unsigned int)channel.channelLabel);
        }
    }
    NSLog(@"--------------------------------------------------");
    
}
- (void) setupAudioSession{
    
    NSError *err = nil;
    avAudioSessionInputChoice = [NSArray arrayWithObjects:AVAudioSessionPortUSBAudio, AVAudioSessionPortHeadsetMic, AVAudioSessionPortBluetoothHFP, AVAudioSessionPortLineIn, nil];
    
    session = [AVAudioSession sharedInstance];
    
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&err]){
        NSLog(@"Couldn't set category audio session: %@", err);
    }
    
    if (![session setMode:AVAudioSessionModeMeasurement error:&err]){
        NSLog(@"Couldn't set mode audio session: %@", err);
    }
    //NSLog(@" %@", session.mode);
    
    if (![session setActive:YES error:&err]){
        NSLog(@"Couldn't activate audio session: %@", err);
    }
    
    AVAudioSessionPortDescription* preferedInput = NULL;
    
    for (NSString * inputChoice in avAudioSessionInputChoice){
        if (preferedInput == NULL)
            for (AVAudioSessionPortDescription *input in [[AVAudioSession sharedInstance] availableInputs]) {
                if ([input.portType isEqualToString:inputChoice]){
                    preferedInput = input;
                    NSLog(@"Preferred Input is %@", preferedInput);
                    break;
                }
            }
    }
    
    if (![session setPreferredInput:preferedInput error:&err]){
        NSLog(@"Couldn't set prefered input for session: %@", err);
    }
    
    if (![session setPreferredIOBufferDuration:PREFERED_BUFFER_SIZE error:&err]){
        NSLog(@"Couldn't set prefered io buffer size for session: %@", err);
    }
    NSLog(@"Buffer size is now %f", session.preferredIOBufferDuration);
    
    if (![session setPreferredSampleRate: PREFERED_SAMPLE_RATE error: &err])
        NSLog(@"Couldn't set prefered sample rate for session: %@", err);
    
    _sampleRate = session.sampleRate;
    
    //[self logChoicesAndRoutesForSession];
    
    
}

- (void) hookUpAudioChain{
    
    OSStatus status;
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &remoteIOUnit);
    assert(status == noErr);
    
    // Enable IO for recording
    UInt32 one = 1;
    status = AudioUnitSetProperty(remoteIOUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  INPUT_BUS,
                                  &one,
                                  sizeof(one));
    assert(status == noErr);
    
    status = AudioUnitSetProperty(remoteIOUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  OUTPUT_BUS,
                                  &one,
                                  sizeof(one));
    assert(status == noErr);
    
    // Describe format
    AudioStreamBasicDescription inputAudioFormat;
    inputAudioFormat.mSampleRate         = _sampleRate;
    inputAudioFormat.mFormatID           = kAudioFormatLinearPCM;
    inputAudioFormat.mFormatFlags        = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    inputAudioFormat.mBytesPerPacket     = BYTES_PER_FLOAT;
	inputAudioFormat.mFramesPerPacket    = 1;
	inputAudioFormat.mBytesPerFrame      = BYTES_PER_FLOAT;
	inputAudioFormat.mChannelsPerFrame   = INPUT_NUM_CHANNELS;
	inputAudioFormat.mBitsPerChannel     = BYTES_PER_FLOAT * BITS_PER_BYTE;
    
    // Describe format
    AudioStreamBasicDescription outputAudioFormat;
    outputAudioFormat.mSampleRate         = _sampleRate;
    outputAudioFormat.mFormatID           = kAudioFormatLinearPCM;
    outputAudioFormat.mFormatFlags        = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    outputAudioFormat.mBytesPerPacket     = BYTES_PER_FLOAT;
	outputAudioFormat.mFramesPerPacket    = 1;
	outputAudioFormat.mBytesPerFrame      = BYTES_PER_FLOAT;
	outputAudioFormat.mChannelsPerFrame   = OUTPUT_NUM_CHANNELS;
	inputAudioFormat.mBitsPerChannel     = BYTES_PER_FLOAT * BITS_PER_BYTE;
    
    
    // Apply format
    status = AudioUnitSetProperty(remoteIOUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  INPUT_BUS,
                                  &inputAudioFormat,
                                  sizeof(inputAudioFormat));
    assert(status == noErr);
    
    status = AudioUnitSetProperty(remoteIOUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  OUTPUT_BUS,
                                  &inputAudioFormat,
                                  sizeof(inputAudioFormat));
    assert(status == noErr);
    
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    
    // Set output callback
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(remoteIOUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  OUTPUT_BUS,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    assert(status == noErr);
    
    // Initialise
    status = AudioUnitInitialize(remoteIOUnit);
    assert(status == noErr);

}

OSStatus playbackCallback ( void                        *inRefCon,
                           AudioUnitRenderActionFlags  *ioActionFlags,
                           const AudioTimeStamp        *inTimeStamp,
                           UInt32                      inBusNumber,
                           UInt32                      inNumberFrames,
                           AudioBufferList             *ioData
                           ){
    
    @autoreleasepool {
        
        CIViewController *this = (__bridge CIViewController *)inRefCon;
        //EffectState *effectState = (EffectState*) inRefCon;
        
        /*CheckError(AudioUnitRender(this.remoteIOUnit,
                                   ioActionFlags,
                                   inTimeStamp,
                                   INPUT_BUS,
                                   inNumberFrames,
                                   ioData),
                   "Couldn't render from RemoteIO unit");*/
        
        AudioUnitRender(this.remoteIOUnit,ioActionFlags,inTimeStamp,INPUT_BUS, inNumberFrames, ioData);
        
        return noErr;
        
    }
    
}
@end
