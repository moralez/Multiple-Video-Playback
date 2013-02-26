//
//  ViewController.m
//  Multiple Video Playback
//
//  Created by Johnny Moralez on 2/15/13.
//  Copyright (c) 2013 Johnny Moralez. All rights reserved.
//

#import "ViewController.h"
#import "VideoPlayerViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "HSSlider.h"

@interface ViewController ()

@property (nonatomic, strong) VideoPlayerViewController *leftVideoPlayerViewController;
@property (nonatomic, strong) VideoPlayerViewController *rightVideoPlayerViewController;

@property (nonatomic, weak)   VideoPlayerViewController *masterVideoPlayerViewController; // The shorter video

// Scrubbing
@property (nonatomic, assign, getter = isScrubbing) BOOL scrubbing;
@property (nonatomic, assign) float restoreAfterScrubbingRate;
- (void)beginScrubbing:(id)sender;
- (void)scrub:(id)sender;
- (void)endScrubbing:(id)sender;

// Array of UIView-subclasses
@property (nonatomic, strong) NSArray *controls;

// Controls
@property (nonatomic, strong) UIButton *closeControlButton;
@property (nonatomic, strong) HSSlider *scrubberControlSlider;
@property (nonatomic, strong) UILabel *currentPlayerTimeLabel;
@property (nonatomic, strong) UILabel *remainingPlayerTimeLabel;

@property (nonatomic, strong) UIButton *playPauseControlButton;

@end

@implementation ViewController

#pragma mark View Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_1" withExtension:@"mp4"];
    [self setupLeftPlayerWithURL:url];
    
    NSURL *url2 = [[NSBundle mainBundle] URLForResource:@"sample_iPod" withExtension:@"m4v"];
    [self setupRightPlayerWithURL:url2];
    
    self.masterVideoPlayerViewController = self.leftVideoPlayerViewController;
    
    [self setupControls];
}

#pragma mark Player Control Setup Methods

- (void)setupScrubber {
    self.scrubberControlSlider = [[HSSlider alloc] initWithFrame:CGRectZero];
    [self.scrubberControlSlider setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.scrubberControlSlider setFrame:CGRectMake(70., 3., self.view.bounds.size.width-140., 14.)];
    
    [self.scrubberControlSlider addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [self.scrubberControlSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [self.scrubberControlSlider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrubberControlSlider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.topControlView addSubview:self.scrubberControlSlider];
}

- (void)setupTopControls {
    [self setupScrubber];
}

- (void)setupControls {
    [self setupTopControls];
}

#pragma mark Player View Setup Methods

- (void)setupLeftPlayerWithURL:(NSURL*)url {
    VideoPlayerViewController *player = [[VideoPlayerViewController alloc] init];
    player.URL = url;
    player.controlsDelegate = self;
    
    CGRect playerFrame = self.leftPlayer.frame;
    playerFrame.origin.x = 0;
    playerFrame.origin.y = 0;
    player.view.frame = playerFrame;
    self.leftVideoPlayerViewController = player;
    [self.leftPlayer addSubview:self.leftVideoPlayerViewController.view];

}

- (void)setupRightPlayerWithURL:(NSURL*)url {
    VideoPlayerViewController *player = [[VideoPlayerViewController alloc] init];
    player.URL = url;
    player.controlsDelegate = self;
    
    CGRect playerFrame = self.rightPlayer.frame;
    playerFrame.origin.x = 0;
    playerFrame.origin.y = 0;
    player.view.frame = playerFrame;
    self.rightVideoPlayerViewController = player;
    [self.rightPlayer addSubview:self.rightVideoPlayerViewController.view];
}

#pragma mark Scrubber Handling

- (void)beginScrubbing:(id)sender {
    [self removePlayerTimeObserver];
    [self setScrubbing:YES];
    [self setRestoreAfterScrubbingRate:self.masterVideoPlayerViewController.player.rate];
    
    [self.leftVideoPlayerViewController.player setRate:0.];
    [self.rightVideoPlayerViewController.player setRate:0.];
}

- (void)scrub:(id)sender {
    [self.leftVideoPlayerViewController.player seekToTime:CMTimeMakeWithSeconds(self.scrubberControlSlider.value, NSEC_PER_SEC)];
    [self.rightVideoPlayerViewController.player seekToTime:CMTimeMakeWithSeconds(self.scrubberControlSlider.value, NSEC_PER_SEC)];
}

- (void)endScrubbing:(id)sender {
    [self.leftVideoPlayerViewController.player setRate:self.restoreAfterScrubbingRate];
    [self.rightVideoPlayerViewController.player setRate:self.restoreAfterScrubbingRate];
    [self setScrubbing:NO];
    [self.masterVideoPlayerViewController addPlayerTimeObserver];
}

#pragma mark ???

- (void)removePlayerTimeObserver {
    if ([self.masterVideoPlayerViewController playerTimeObserver]) {
        [[self.masterVideoPlayerViewController player] removeTimeObserver:[self.masterVideoPlayerViewController playerTimeObserver]];
        [self.masterVideoPlayerViewController setPlayerTimeObserver:nil];
    }
}

- (CMTime)duration {
    // Pefered in HTTP Live Streaming.
    if ([self.masterVideoPlayerViewController.playerItem respondsToSelector:@selector(duration)] && // 4.3
        self.masterVideoPlayerViewController.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        if (CMTIME_IS_VALID(self.masterVideoPlayerViewController.playerItem.duration))
            return self.masterVideoPlayerViewController.playerItem.duration;
    }
    
    else if (CMTIME_IS_VALID(self.masterVideoPlayerViewController.player.currentItem.asset.duration))
        return self.masterVideoPlayerViewController.player.currentItem.asset.duration;
    
    return kCMTimeInvalid;
}

#pragma mark Video Player Controls Delegate Methods

- (void)play:(id)sender shouldSeek:(BOOL)seekToZeroBeforePlay {
    
    if ([sender isKindOfClass:[VideoPlayerViewController class]]) {
        VideoPlayerViewController *playerVC = (VideoPlayerViewController*)sender;
        if (seekToZeroBeforePlay)  {
            [playerVC.player seekToTime:kCMTimeZero];
        }
        
        [playerVC.player play];
    }
}

- (void)syncProgressBar {
    NSInteger currentSeconds = ceilf(CMTimeGetSeconds(self.masterVideoPlayerViewController.player.currentTime));
    NSInteger seconds = currentSeconds % 60;
    NSInteger minutes = currentSeconds / 60;
    NSInteger hours = minutes / 60;
    
    NSInteger duration = ceilf(CMTimeGetSeconds(self.duration));
    NSInteger currentDurationSeconds = duration-currentSeconds;
    NSInteger durationSeconds = currentDurationSeconds % 60;
    NSInteger durationMinutes = currentDurationSeconds / 60;
    NSInteger durationHours = durationMinutes / 60;
    
    [self.currentPlayerTimeLabel setText:[NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds]];
    [self.remainingPlayerTimeLabel setText:[NSString stringWithFormat:@"-%02d:%02d:%02d", durationHours, durationMinutes, durationSeconds]];
    
    [self.scrubberControlSlider setMinimumValue:0.];
    [self.scrubberControlSlider setMaximumValue:duration];
    [self.scrubberControlSlider setValue:currentSeconds];
    
    NSLog(@"%@", self.masterVideoPlayerViewController.player.currentItem.seekableTimeRanges);
}

@end
