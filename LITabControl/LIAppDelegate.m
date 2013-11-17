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
    NSMenu  *menu;
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.window setBackgroundColor:[NSColor whiteColor]];
    
    menu = [[NSMenu alloc] init];
    
    [menu addItem:[NSMenuItem separatorItem]];
    [[menu addItemWithTitle:NSLocalizedString(@"Delete Sheet...", nil) action:@selector(deleteSheet:) keyEquivalent:@""] setTarget:self];
    
    tabs = @[@"Sheet 1", @"Sheet 2", @"Sheet 3", @"Sheet 4", @"Sheet 5"];
    [self.tabControl setDataSource:self];
}

- (IBAction)deleteSheet:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark -
#pragma mark LITabControlDataSource

- (NSUInteger)tabControlNumberOfTabs:(LITabControl *)tabControl {
    return tabs.count;
}

- (id)tabControl:(LITabControl *)tabControl itemAtIndex:(NSUInteger)index {
    return tabs[index];
}

- (NSMenu *)tabControl:(LITabControl *)tabControl menuForItem:(id)item {
    return menu;
}

- (NSString *)tabControl:(LITabControl *)tabControl titleForItem:(id)item {
    return item;
}
- (void)tabControl:(LITabControl *)tabControl setTitle:(NSString *)title forItem:(id)item {
}

- (void)tabControlDidReorderItems:(LITabControl *)tabControl {
    
}
- (BOOL)tabControl:(LITabControl *)tabControl shouldReorderItem:(id)item {
    return YES;
}

- (void)tabControlDidChangeSelection:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

@end
