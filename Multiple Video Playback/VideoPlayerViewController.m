//This file is part of MyVideoPlayer.
//
//MyVideoPlayer is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//MyVideoPlayer is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with MyVideoPlayer.  If not, see <http://www.gnu.org/licenses/>.

#import "VideoPlayerViewController.h"
#import "VideoPlayerView.h"

/* Asset keys */
NSString * const kTracksKey = @"tracks";
NSString * const kPlayableKey = @"playable";

/* PlayerItem keys */
NSString * const kStatusKey         = @"status";
NSString * const kCurrentItemKey	= @"currentItem";
NSString * const kDurationKey       = @"duration";
NSString * const kRateKey           = @"rate";

@interface VideoPlayerViewController ()

@property (nonatomic, strong) VideoPlayerView *playerView;

@end

static void *BRGCurrentItemObservationContext = &BRGCurrentItemObservationContext;
static void *BRGStatusObservationContext = &BRGStatusObservationContext;
static void *BRGDurationObservationContext = &BRGDurationObservationContext;
static void *BRGRateObservationContext = &BRGRateObservationContext;

@implementation VideoPlayerViewController

#pragma mark - UIView lifecycle

- (void)loadView {
    VideoPlayerView *playerView = [[VideoPlayerView alloc] init];
    self.view = playerView;
    
    self.playerView = playerView;
}

#pragma mark - Private methods

- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys {
    for (NSString *thisKey in requestedKeys) {
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if (keyStatus == AVKeyValueStatusFailed || keyStatus == AVKeyValueStatusCancelled) {
			return;
		}
	}
    
    if (!asset.playable) {
        return;
    }
	
	if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:kStatusKey];
		
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
	
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    [self.playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:BRGStatusObservationContext];
    
    // Durationchange
    [self.playerItem addObserver:self
                      forKeyPath:kDurationKey
                         options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                         context:BRGDurationObservationContext];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           [self setSeekToZeroBeforePlay:YES];
                                                       }];
    
    [self setSeekToZeroBeforePlay:YES];
    
    if (![self player]) {
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
        
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:BRGCurrentItemObservationContext];
        
        // Observe rate, play/pause-button?
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                         context:BRGRateObservationContext];
    }
    
    if (self.player.currentItem != self.playerItem) {
        [[self player] replaceCurrentItemWithPlayerItem:self.playerItem];
    }
}


#pragma mark - Key Valye Observing

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    
	if (context == BRGStatusObservationContext) {
        
        if (self.controlsDelegate && [self.controlsDelegate respondsToSelector:@selector(syncPlayPauseButton)]) {
            [self.controlsDelegate syncPlayPauseButton];
        }
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerStatusReadyToPlay) {
            
            if (self.controlsDelegate && [self.controlsDelegate respondsToSelector:@selector(play:shouldSeek:)]) {
                [self.controlsDelegate play:self shouldSeek:self.seekToZeroBeforePlay];
            }
        }
        
        switch (status) {
            
            case AVPlayerStatusReadyToPlay: {
                
                // Enable buttons & scrubber
                if (self.controlsDelegate && [self.controlsDelegate respondsToSelector:@selector(enableButtonsAndScrubber)]) {
                    [self.controlsDelegate enableButtonsAndScrubber];
                }
            }
                break;
                
            case AVPlayerStatusUnknown:
            case AVPlayerStatusFailed: {
                // Disable buttons & scrubber
                if (self.controlsDelegate && [self.controlsDelegate respondsToSelector:@selector(disableButtonsAndScrubber)]) {
                    [self.controlsDelegate disableButtonsAndScrubber];
                }
            }
                break;
        }
        
	} else if (context == BRGCurrentItemObservationContext) {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        if (newPlayerItem) {
            [self.playerView setPlayer:self.player];
            [self.playerView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            
            if (self.controlsDelegate && [self.controlsDelegate respondsToSelector:@selector(syncPlayPauseButton)]) {
                [self.controlsDelegate syncPlayPauseButton];
            }
            [self addPlayerTimeObserver];
        }
	} else if (context == BRGDurationObservationContext) {
        if (self.controlsDelegate && [self.controlsDelegate respondsToSelector:@selector(syncProgressBar)]) {
            [self.controlsDelegate syncProgressBar];
        }
    } else if (context == BRGRateObservationContext) {
            if (self.controlsDelegate && [self.controlsDelegate respondsToSelector:@selector(syncPlayPauseButton)]) {
                [self.controlsDelegate syncPlayPauseButton];
            }
	} else {
		[super observeValueForKeyPath:path ofObject:object change:change context:context];
	}
}


#pragma mark - Public methods

- (void)setURL:(NSURL*)URL {
    _URL = [URL copy];
    
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_URL options:nil];
    
    NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
    
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
     ^{
         dispatch_async( dispatch_get_main_queue(),
                        ^{
                            [self prepareToPlayAsset:asset withKeys:requestedKeys];
                        });
     }];
}


#pragma mark Rotation Methods

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        return YES;
    }
    
    return NO;
}

#pragma mark ???

- (CMTime)duration {
    // Pefered in HTTP Live Streaming.
    if ([self.playerItem respondsToSelector:@selector(duration)] && // 4.3
        self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        if (CMTIME_IS_VALID(self.playerItem.duration))
            return self.playerItem.duration;
    }
    
    else if (CMTIME_IS_VALID(self.player.currentItem.asset.duration))
        return self.player.currentItem.asset.duration;
    
    return kCMTimeInvalid;
}

- (void)addPlayerTimeObserver {
    if (!self.playerTimeObserver) {
        __unsafe_unretained VideoPlayerViewController *weakSelf = self;
        id observer = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(.5, NSEC_PER_SEC)
                                                                queue:dispatch_get_main_queue()
                                                           usingBlock:^(CMTime time) {
                                                               VideoPlayerViewController *strongSelf = weakSelf;
                                                               if (CMTIME_IS_VALID(strongSelf.player.currentTime) && CMTIME_IS_VALID(strongSelf.duration))
                                                                   if (strongSelf.controlsDelegate && [strongSelf.controlsDelegate respondsToSelector:@selector(syncProgressBar)]) {
                                                                       [strongSelf.controlsDelegate syncProgressBar];
                                                                   }
                                                           }];
        
        [self setPlayerTimeObserver:observer];
    }
}

@end
