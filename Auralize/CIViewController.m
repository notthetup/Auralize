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

static const double preferredBufferSize = 0.0232;
static const double preferredSampleRate = 44100;


@synthesize sampleRate = _sampleRate;
@synthesize remoteIOUnit = remoteIOUnit;



- (id)init{
    self = [super init];
    if (self) {
        avAudioSessionInputChoice = [NSArray arrayWithObjects:AVAudioSessionPortUSBAudio, AVAudioSessionPortHeadsetMic, AVAudioSessionPortBluetoothHFP, AVAudioSessionPortLineIn, nil];
    }
    return self;
}

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
    
}

- (void) pauseAudioChain{
    
}

- (void) initAudioProcessing{
    
    [self setupAudioSession];
    [self hookUpAudioChain];
    
    NSError *err = nil;
    if (![session setActive:YES error:&err]){
        NSLog(@"Couldn't activate audio session: %@", err);
    }
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
    session = [AVAudioSession sharedInstance];
    
    
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&err]){
        NSLog(@"Couldn't set category audio session: %@", err);
    }
    
    if (![session setMode:AVAudioSessionModeMeasurement error:&err]){
        NSLog(@"Couldn't set mode audio session: %@", err);
    }
    //NSLog(@" %@", session.mode);
    
    AVAudioSessionPortDescription* preferedInput = NULL;
    
    for (AVAudioSessionPortDescription * inputChoice in avAudioSessionInputChoice){
        if (preferedInput == NULL)
            for (AVAudioSessionPortDescription *input in [[AVAudioSession sharedInstance] availableInputs]) {
                if ([input.portName isEqualToString:inputChoice.portName]){
                    preferedInput = input;
                    break;
                }
            }
    }
    
    if (![session setPreferredIOBufferDuration:preferredBufferSize error:&err]){
        NSLog(@"Couldn't set prefered io buffer size for session: %@", err);
    }
    NSLog(@"Buffer size is now %f", session.preferredIOBufferDuration);
    
    if (![session setPreferredSampleRate: preferredSampleRate error: &err])
        NSLog(@"Couldn't set prefered sample rate for session: %@", err);
    
    _sampleRate = session.sampleRate;
    
    [self logChoicesAndRoutesForSession];
    
    
}

- (void) hookUpAudioChain{
    
    
    OSStatus status;
    AudioUnitElement outputBus = 0;
    AudioUnitElement inputBus = 1;
    
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
    UInt32 flag = 1;
    status = AudioUnitSetProperty(remoteIOUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  inputBus,
                                  &flag,
                                  sizeof(flag));
    assert(status == noErr);
    
    // Describe format
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate         = 44100.00;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 1;
    audioFormat.mBitsPerChannel     = 16;
    audioFormat.mBytesPerPacket     = 2;
    audioFormat.mBytesPerFrame      = 2;
    
    
    // Apply format
    status = AudioUnitSetProperty(remoteIOUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  inputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    assert(status == noErr);
    
    status = AudioUnitSetProperty(remoteIOUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  outputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    assert(status == noErr);
    
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    
    // Set output callback
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(remoteIOUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  outputBus,
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
    
    CIViewController *this = (__bridge CIViewController *)inRefCon;
    UInt32 outBusNumber = 1;
    
    AudioUnitRender(this.remoteIOUnit,ioActionFlags,inTimeStamp,outBusNumber, inNumberFrames, ioData);
    
    return noErr;
    
}
@end
