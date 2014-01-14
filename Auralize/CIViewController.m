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

@implementation CIViewController

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
    
    NSError *err = nil;
    if (![[AVAudioSession sharedInstance] setActive:YES error:&err]){
        NSLog(@"Couldn't activate audio session: %@", err);
    }
    
    
    NSLog(@"Audio Inputs Avilable: ");
    int counter = 0;
    for (AVAudioSessionPortDescription *input in [[AVAudioSession sharedInstance] availableInputs]) {
        NSLog(@"#%d Name :%@ - Type :%@ - Num Channels :%lu", counter++, input.portName, input.portType, (unsigned long)[input.channels count]);
        for (AVAudioSessionChannelDescription *channel in input.channels){
            NSLog(@"--#%lu Name :%@ - Label :%u", (unsigned long)channel.channelNumber, channel.channelName, (unsigned int)channel.channelLabel);
        }
    }
    
    [self setupMicrophoneInput];
    [self setupOutput];
    [self hookUpAudioChain];
}

- (void) setupMicrophoneInput{
    //kAudioSessionMode_Measurement

}

- (void) setupOutput{
    
}

- (void) hookUpAudioChain{
    
    
}

@end
