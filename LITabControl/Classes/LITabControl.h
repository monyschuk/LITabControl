//
//  LITabControl.h
//  LITabControl
//
//  Created by Mark Onyschuk on 11/12/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LITabCell.h"

@class LITabControl;

@protocol LITabDataSource <NSObject>

- (NSUInteger)tabControlNumberOfTabs:(LITabControl *)tabControl;

- (id)tabControl:(LITabControl *)tabControl itemAtIndex:(NSUInteger)index;

- (NSMenu *)tabControl:(LITabControl *)tabControl menuForItem:(id)item;

- (NSString *)tabControl:(LITabControl *)tabControl titleForItem:(id)item;
- (void)tabControl:(LITabControl *)tabControl setTitle:(NSString *)title forItem:(id)item;

- (BOOL)tabControl:(LITabControl *)tabControl canReorderItem:(id)item;
- (void)tabControlDidReorderItems:(LITabControl *)tabControl orderedItems:(NSArray *)itemArray;

@optional
- (void)tabControlDidChangeSelection:(NSNotification *)notification;

- (BOOL)tabControl:(LITabControl *)tabControl canEditItem:(id)item;
- (BOOL)tabControl:(LITabControl *)tabControl canSelectItem:(id)item;

- (void)tabControl:(LITabControl *)tabControl willDisplayButton:(LITabButton *)button forItem:(id)item;

@end

@protocol LITabDelegate <NSControlTextEditingDelegate>
@end

extern NSString *LITabControlSelectionDidChangeNotification;

@interface LITabControl : NSControl

#pragma mark -
#pragma mark Display Properties

@property(nonatomic, copy) NSColor *borderColor;
@property(nonatomic, copy) NSColor *backgroundColor;

@property(nonatomic) CGFloat minTabWidth, maxTabWidth;

#pragma mark -
#pragma mark Delegate & Data Source

@property(nonatomic, weak) id <LITabDelegate> delegate;
@property(nonatomic, weak) id <LITabDataSource> dataSource;

- (void)reloadData;

#pragma mark -
#pragma mark Selection

@property(nonatomic, weak) id selectedItem;

#pragma mark -
#pragma mark Target/Action

@property(nonatomic) SEL addAction;
@property(nonatomic, weak) id addTarget;

#pragma mark -
#pragma mark Editing

- (void)editItem:(id)item;

#pragma mark -
#pragma mark Tab Buttons

+ (Class)tabButtonClass;

- (NSArray *)tabButtons;
- (NSButton *)tabButtonWithItem:(id)item;

@end
