//
//  NSImage+LITabControl.m
//  LITabControl
//
//  Created by Mark Onyschuk on 11/13/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "NSImage+LITabControl.h"

@implementation NSImage (LITabControl)

- (NSImage *)imageWithTint:(NSColor *)color {
    NSRect imageRect = NSZeroRect; imageRect.size = self.size;
    NSImage *highlightImage = [[NSImage alloc] initWithSize:imageRect.size];
    
    [highlightImage lockFocus];
    
    [self drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    [color set];
    NSRectFillUsingOperation(imageRect, NSCompositeSourceAtop);
    
    [highlightImage unlockFocus];

    return highlightImage;
}

@end
