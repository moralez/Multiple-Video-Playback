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

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol VideoPlayerControlsDelegate <NSObject>
- (void)play:(id)sender shouldSeek:(BOOL)seekToZeroBeforePlay;
- (void)syncProgressBar;
- (void)syncPlayPauseButton;
- (void)disableButtonsAndScrubber;
- (void)enableButtonsAndScrubber;
@end

@interface VideoPlayerViewController : UIViewController

@property (nonatomic, weak)     id<VideoPlayerControlsDelegate> controlsDelegate;
@property (nonatomic, strong)   AVPlayer                        *player;
@property (nonatomic, strong)   AVPlayerItem                    *playerItem;
@property (nonatomic, copy)     NSURL                           *URL;
@property (nonatomic, strong)   id                              playerTimeObserver;
@property (nonatomic, assign)   BOOL                            seekToZeroBeforePlay;

- (void)addPlayerTimeObserver;

@end