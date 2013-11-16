//
//  LITabControl.h
//  LITabControl
//
//  Created by Mark Onyschuk on 11/12/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LITabControl;

@protocol LITabDataSource <NSObject>

- (NSUInteger)tabControlNumberOfTabs:(LITabControl *)tabControl;

- (id)tabControl:(LITabControl *)tabControl itemAtIndex:(NSUInteger)index;

- (NSString *)tabControl:(LITabControl *)tabControl titleForItem:(id)item;
- (void)tabControl:(LITabControl *)tabControl setTitle:(NSString *)title forItem:(id)item;

- (NSMenu *)tabControl:(LITabControl *)tabControl menuForItem:(id)item;
- (BOOL)tabControl:(LITabControl *)tabControl shouldShowMenuForItem:(id)item;

- (void)tabControlDidReorderItems:(LITabControl *)tabControl;
- (BOOL)tabControl:(LITabControl *)tabControl shouldReorderItem:(id)item;

- (void)tabControlDidChangeSelection:(NSNotification *)notification;

@end

extern NSString *LITabControlDidChangeSelectionNotification;

@interface LITabControl : NSControl

#pragma mark -
#pragma mark Display Properties

@property(nonatomic, copy) NSColor *borderColor;
@property(nonatomic, copy) NSColor *backgroundColor;

@property(nonatomic) CGFloat minTabWidth, maxTabWidth;

#pragma mark -
#pragma mark Data Source

@property(nonatomic, weak) id <LITabDataSource> dataSource;

- (void)reloadData;

#pragma mark -
#pragma mark Selection

@property(nonatomic, weak) id selectedItem;

#pragma mark -
#pragma mark Target/Action

@property(nonatomic) SEL addAction;
@property(nonatomic, weak) id addTarget;

@end

typedef enum {
    LIBorderMaskTop     = (1<<0),
    LIBorderMaskLeft    = (1<<1),
    LIBorderMaskRight   = (1<<2),
    LIBorderMaskBottom  = (1<<3)
} LIBorderMask;

@interface LITabButtonCell : NSButtonCell

@property(nonatomic) LIBorderMask borderMask;
@property(nonatomic, copy) NSColor *borderColor;
@property(nonatomic, copy) NSColor *backgroundColor;

@end

extern BOOL LIRectArrayWithBorderMask(NSRect sourceRect, LIBorderMask borderMask, NSRect **rectArray, NSInteger *rectCount);
