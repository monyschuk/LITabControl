//
//  LIAppDelegate.m
//  LITabControl
//
//  Created by Mark Onyschuk on 11/12/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIAppDelegate.h"

@implementation LIAppDelegate {
    NSArray *tabs;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.window setBackgroundColor:[NSColor whiteColor]];
    
    tabs = @[@"Sheet 1", @"Sheet 2", @"Sheet 3", @"Sheet 4", @"Sheet 5"];
    [self.tabControl setDataSource:self];
}

#pragma mark -
#pragma mark LITabControlDataSource

- (NSUInteger)tabControlNumberOfTabs:(LITabControl *)tabControl {
    return tabs.count;
}

- (id)tabControl:(LITabControl *)tabControl itemAtIndex:(NSUInteger)index {
    return tabs[index];
}

- (NSString *)tabControl:(LITabControl *)tabControl titleForItem:(id)item {
    return item;
}
- (void)tabControl:(LITabControl *)tabControl setTitle:(NSString *)title forItem:(id)item {
}

- (NSMenu *)tabControl:(LITabControl *)tabControl menuForItem:(id)item {
    return nil;
}
- (BOOL)tabControl:(LITabControl *)tabControl shouldShowMenuForItem:(id)item {
    return NO;
}

- (void)tabControlDidReorderItems:(LITabControl *)tabControl {
    
}
- (BOOL)tabControl:(LITabControl *)tabControl shouldReorderItem:(id)item {
    return YES;
}

- (void)tabControlDidChangeSelection:(NSNotification *)notification {
}

@end
