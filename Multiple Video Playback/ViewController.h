//
//  ViewController.h
//  Multiple Video Playback
//
//  Created by Johnny Moralez on 2/15/13.
//  Copyright (c) 2013 Johnny Moralez. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoPlayerViewController.h"

@interface ViewController : UIViewController <VideoPlayerControlsDelegate>

@property (nonatomic, strong) IBOutlet UIView *topControlView;
@property (nonatomic, strong) IBOutlet UIView *bottomControlView;

@property (nonatomic, strong) IBOutlet UIView *leftPlayer;
@property (nonatomic, strong) IBOutlet UIView *rightPlayer;

@end
