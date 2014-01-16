//
//  CIViewController.h
//  Auralize
//
//  Created by Chinmay Pendharkar on 14/1/14.
//  Copyright (c) 2014 CrayonIO Pte. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>
#include <AVFoundation/AVFoundation.h>

@interface CIViewController : UIViewController

@property (readonly) double sampleRate;
@property (readonly) AudioUnit remoteIOUnit;

@end
