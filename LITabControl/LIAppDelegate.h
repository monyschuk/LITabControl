//
//  LIAppDelegate.h
//  LITabControl
//
//  Created by Mark Onyschuk on 11/12/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LITabControl.h"

@interface LIAppDelegate : NSObject <NSApplicationDelegate, LITabDataSource>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet LITabControl *tabControl;

@end
