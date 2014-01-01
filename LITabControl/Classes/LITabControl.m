//
//  LITabControl.m
//  LITabControl
//
//  Created by Mark Onyschuk on 11/12/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LITabControl.h"
#import "LITabCell.h"

#import <QuartzCore/QuartzCore.h>

#define DF_MIN_TAB_WIDTH    (72.f * 2.75)
#define DF_MAX_TAB_WIDTH    (72.f * 3.25)

@interface LITabControl() <NSTextFieldDelegate>

@property(nonatomic, strong) NSArray        *items;

@property(nonatomic, strong) NSScrollView   *scrollView;
@property(nonatomic, strong) NSButton       *addButton, *scrollLeftButton, *scrollRightButton, *draggingTab;

@property(nonatomic, strong) NSTextField    *editingField;

- (NSButton *)existingTabWithItem:(id)item;

@end

@implementation LITabControl

+ (Class)cellClass {
    return [LITabCell class];
}

#pragma mark -
#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self configureSubviews];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureSubviews];
}

- (void)configureSubviews {
    if (_scrollView == nil) {
        [self setWantsLayer:YES];

        _minTabWidth = DF_MIN_TAB_WIDTH;
        _maxTabWidth = DF_MAX_TAB_WIDTH;

        [self.cell setTitle:@""];
        [self.cell setBorderMask:LIBorderMaskBottom];
        [self.cell setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:13]];
        
        _scrollView         = [self viewWithClass:[NSScrollView class]];
        
        [_scrollView setDrawsBackground:NO];
        [_scrollView setBackgroundColor:[NSColor redColor]];
        
        _addButton          = [self buttonWithImageNamed:@"LITabPlusTemplate" target:self action:@selector(add:)];
        _scrollLeftButton   = [self buttonWithImageNamed:@"LITabLeftTemplate" target:self action:@selector(goLeft:)];
        _scrollRightButton  = [self buttonWithImageNamed:@"LITabRightTemplate" target:self action:@selector(goRight:)];
        
        [_scrollLeftButton setContinuous:YES];
        [_scrollRightButton setContinuous:YES];

        [_scrollLeftButton.cell sendActionOn:NSLeftMouseDownMask|NSPeriodicMask];
        [_scrollRightButton.cell sendActionOn:NSLeftMouseDownMask|NSPeriodicMask];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_scrollView, _addButton, _scrollLeftButton, _scrollRightButton);
        
        [self setSubviews:@[_scrollView, _addButton, _scrollLeftButton, _scrollRightButton]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_addButton][_scrollView]-(-1)-[_scrollLeftButton][_scrollRightButton]|" options:0 metrics:nil views:views]];
        
        for (NSView *view in views.allValues) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view": view}]];
        }
        
        [_addButton addConstraint:
         [NSLayoutConstraint constraintWithItem:_addButton attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1 constant:48]];
        [_scrollLeftButton addConstraint:
         [NSLayoutConstraint constraintWithItem:_scrollLeftButton attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1 constant:24]];

        [_scrollRightButton addConstraint:
         [NSLayoutConstraint constraintWithItem:_scrollRightButton attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1 constant:24]];
        
        [_addButton.cell setBorderMask:[_addButton.cell borderMask] | LIBorderMaskRight];
        [_scrollLeftButton.cell setBorderMask:[_scrollLeftButton.cell borderMask] | LIBorderMaskLeft];

        [self startObservingScrollView];
        [self updateButtons];
    }
}

- (void)dealloc {
    [self stopObservingScrollView];
}

- (void)updateButtons {
    [_addButton setEnabled:(self.addAction != NULL)];

    NSClipView *contentView = self.scrollView.contentView;

    BOOL isDocumentClipped = (contentView != nil) && (self.items.count * self.minTabWidth > NSWidth(contentView.bounds));
    
    if (isDocumentClipped) {
        [_scrollLeftButton  setHidden:NO];
        [_scrollRightButton setHidden:NO];
        
        [_scrollLeftButton setEnabled:([self firstTabLeftOutsideVisibleRect] != nil)];
        [_scrollRightButton setEnabled:([self firstTabRightOutsideVisibleRect] != nil)];
        
    } else {
        [_scrollLeftButton  setHidden:YES];
        [_scrollRightButton setHidden:YES];
    }
}

- (NSButton *)buttonWithImageNamed:(NSString *)name target:(id)target action:(SEL)action {
    NSButton *button = [self viewWithClass:[NSButton class]];

    [button setCell:[[self cell] copy]];

    [button setTarget:target];
    [button setAction:action];

    [button setEnabled:action != NULL];
    
    [button setImagePosition:NSImageOnly];
    [button setImage:[NSImage imageNamed:name]];
    
    return button;
}

- (id)viewWithClass:(Class)clss {
    id view = [[clss alloc] initWithFrame:NSZeroRect];
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];

    return view;
}

#pragma mark -
#pragma mark ScrollView Observation

static char LIScrollViewObservationContext;

- (void)startObservingScrollView {
    [self.scrollView addObserver:self forKeyPath:@"frame" options:0 context:&LIScrollViewObservationContext];
    [self.scrollView addObserver:self forKeyPath:@"documentView.frame" options:0 context:&LIScrollViewObservationContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewDidScroll:) name:NSViewBoundsDidChangeNotification object:self.scrollView.contentView];
}
- (void)stopObservingScrollView {
    [self.scrollView removeObserver:self forKeyPath:@"frame" context:&LIScrollViewObservationContext];
    [self.scrollView removeObserver:self forKeyPath:@"documentView.frame" context:&LIScrollViewObservationContext];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:self.scrollView.contentView];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &LIScrollViewObservationContext) {
        [self updateButtons];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)scrollViewDidScroll:(NSNotification *)notification {
    [self updateButtons];
    [self invalidateRestorableState];
}

#pragma mark -
#pragma mark Properties

- (void)setBorderColor:(NSColor *)borderColor {
    [self.cell setBorderColor:borderColor];
    
}
- (void)setBackgroundColor:(NSColor *)backgroundColor {
    [self.cell setBackgroundColor:backgroundColor];
}

#pragma mark -
#pragma mark Actions

- (void)setAddAction:(SEL)addAction {
    if (_addAction != addAction) {
        _addAction = addAction;
    }
}

- (void)add:(id)sender {
    [[NSApplication sharedApplication] sendAction:self.addAction to:self.addTarget from:self];
    
    [self invalidateRestorableState];
}

- (void)goLeft:(id)sender {
    NSButton *tab = [self firstTabLeftOutsideVisibleRect];
    
    if (tab != nil) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setAllowsImplicitAnimation:YES];
            [tab scrollRectToVisible:[tab bounds]];
        } completionHandler:nil];
    }
}

- (NSButton *)firstTabLeftOutsideVisibleRect {
    NSView *tabView = self.scrollView.documentView;
    NSRect  visibleRect = tabView.visibleRect;
    
    for (NSButton *button in [[tabView subviews] reverseObjectEnumerator]) {
        if (NSMinX(button.frame) < NSMinX(visibleRect)) {
            return button;
        }
    }
    return nil;
}

- (void)goRight:(id)sender {
    NSButton *tab = [self firstTabRightOutsideVisibleRect];

    if (tab != nil) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setAllowsImplicitAnimation:YES];
            [tab scrollRectToVisible:[tab bounds]];
        } completionHandler:nil];
    }
}

- (NSButton *)firstTabRightOutsideVisibleRect {
    NSView *tabView = self.scrollView.documentView;
    NSRect  visibleRect = tabView.visibleRect;
    
    for (NSButton *button in [tabView subviews]) {
        if (NSMaxX(button.frame) > NSMaxX(visibleRect)) {
            return button;
        }
    }
    return nil;
}

- (void)selectTab:(id)sender {
    NSButton *selectedButton = sender;

    for (NSButton *button in [self.scrollView.documentView subviews]) {
        [button setState:(button == selectedButton) ? 1 : 0];
    }

    [[NSApplication sharedApplication] sendAction:self.action to:self.target from:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:LITabControlSelectionDidChangeNotification object:self];

    NSEvent *currentEvent = [NSApp currentEvent];
    
    if (currentEvent.clickCount > 1) {
        [self editItem:[[sender cell] representedObject]];
        
    } else if ([self.dataSource tabControl:self canReorderItem:[[sender cell] representedObject]]) {
        [self reorderTab:sender withEvent:currentEvent];
    }

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setAllowsImplicitAnimation:YES];
        [selectedButton scrollRectToVisible:[selectedButton bounds]];
    } completionHandler:nil];
    
    [self invalidateRestorableState];
}

#pragma mark -
#pragma mark Reordering

- (void)reorderTab:(NSButton *)tab withEvent:(NSEvent *)event {
    // note existing tabs which will be reordered over
    // the course of our drag; while the dragging tab maintains
    // its position over the course of the dragging operation
    
    NSView          *tabView        = self.scrollView.documentView;
    NSMutableArray  *orderedTabs    = [[NSMutableArray alloc] initWithArray:tabView.subviews];
    
    // create a dragging tab used to represent our drag,
    // and constraint its position and its size; the first
    // constraint sets position - we'll be varying this one
    // during our drag...
    
    CGFloat   tabX                  = NSMinX(tab.frame);
    NSPoint   dragPoint             = [tabView convertPoint:event.locationInWindow fromView:nil];
    
    
    NSButton *draggingTab           = [self tabWithTitle:tab.title];
    
    NSArray  *draggingConstraints   = @[[NSLayoutConstraint constraintWithItem:draggingTab attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:tabView attribute:NSLayoutAttributeLeading
                                                                    multiplier:1 constant:tabX],                                // VARIABLE
                                        
                                        [NSLayoutConstraint constraintWithItem:draggingTab attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:tabView attribute:NSLayoutAttributeTop
                                                                    multiplier:1 constant:0],                                   // CONSTANT
                                        [NSLayoutConstraint constraintWithItem:draggingTab attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:tabView attribute:NSLayoutAttributeBottom
                                                                    multiplier:1 constant:0]];                                  // CONSTANT
    
    
    draggingTab.cell = [tab.cell copy];
    
    // the presence of a menu affects the vertical offset of our title
    if ([tab.cell menu] != nil) [draggingTab.cell setMenu:[[NSMenu alloc] init]];


    [tabView addSubview:draggingTab];
    [tabView addConstraints:draggingConstraints];
    
    [tab setHidden:YES];
    
    BOOL dragged = NO, reordered = NO;
    
    while (1) {
        event = [self.window nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask];
        
        if (event.type == NSLeftMouseUp) break;
        
        // ensure the dragged tab shows borders on both of its sides when dragging
        if (dragged == NO && event.type == NSLeftMouseDragged) {
            dragged = YES;
            
            LITabCell *cell = draggingTab.cell;
            cell.borderMask = cell.borderMask | LIBorderMaskLeft | LIBorderMaskRight;
        }

        // move the dragged tab
        NSPoint nextPoint = [tabView convertPoint:event.locationInWindow fromView:nil];
        
        CGFloat nextX = tabX + (nextPoint.x - dragPoint.x);
        
        [draggingConstraints[0] setConstant:nextX];

        // test for reordering...
        if (NSMidX(draggingTab.frame) < NSMinX(tab.frame) && tab != orderedTabs.firstObject) {
            // shift left
            NSUInteger index = [orderedTabs indexOfObject:tab];
            [orderedTabs exchangeObjectAtIndex:index withObjectAtIndex:index - 1];
            
            [self layoutTabs:orderedTabs inView:tabView];
            [tabView addConstraints:draggingConstraints];

            reordered = YES;
            
        } else if (NSMidX(draggingTab.frame) > NSMaxX(tab.frame) && tab != orderedTabs.lastObject) {
            // shift right
            NSUInteger index = [orderedTabs indexOfObject:tab];
            [orderedTabs exchangeObjectAtIndex:index+1 withObjectAtIndex:index];
            
            [self layoutTabs:orderedTabs inView:tabView];
            [tabView addConstraints:draggingConstraints];

            reordered = YES;
        }
        
        [tabView layoutSubtreeIfNeeded];
    }

    [draggingTab removeFromSuperview];
    draggingTab = nil;
    
    [tabView removeConstraints:draggingConstraints];

    [tab setHidden:NO];
    [tab.cell setControlView:tab];
    
    if (reordered) {
        NSArray *orderedItems = [orderedTabs valueForKeyPath:@"cell.representedObject"];
        [self.dataSource tabControlDidReorderItems:self orderedItems:orderedItems];
        [self reloadData]; // mildly expensive but ensures state...
        
        
        [self setSelectedItem:[tab.cell representedObject]];
    }
}

#pragma mark -
#pragma mark Selection

- (id)selectedItem {
    for (NSButton *button in [self.scrollView.documentView subviews]) {
        if ([button state] == 1) {
            return [[button cell] representedObject];
        }
    }
    return nil;
}
- (void)setSelectedItem:(id)selectedItem {
    for (NSButton *button in [self.scrollView.documentView subviews]) {
        if ([[[button cell] representedObject] isEqual:selectedItem]) {
            [button setState:1];
            
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [context setAllowsImplicitAnimation:YES];
                [button scrollRectToVisible:[button bounds]];
            } completionHandler:nil];
            
        } else {
            [button setState:0];
        }
    }
    
    [self invalidateRestorableState];
}

#pragma mark -
#pragma mark Data Source

- (void)setDataSource:(id<LITabDataSource>)dataSource {
    if (_dataSource != dataSource) {
        
        if (_dataSource && [_dataSource respondsToSelector:@selector(tabControlDidChangeSelection:)])
            [[NSNotificationCenter defaultCenter] removeObserver:_dataSource name:LITabControlSelectionDidChangeNotification object:self];
        
        _dataSource = dataSource;
        
        if (_dataSource && [_dataSource respondsToSelector:@selector(tabControlDidChangeSelection:)])
            [[NSNotificationCenter defaultCenter] addObserver:_dataSource selector:@selector(tabControlDidChangeSelection:) name:LITabControlSelectionDidChangeNotification object:self];
        
        [self reloadData];
    }
}

- (void)reloadData {
    NSView *tabView = [self viewWithClass:[NSView class]];
    NSMutableArray *newItems = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0, count = [self.dataSource tabControlNumberOfTabs:self]; i < count; i++) {
        [newItems addObject:[self.dataSource tabControl:self itemAtIndex:i]];
    }
    
    NSMutableArray *newTabs = [[NSMutableArray alloc] init];
    
    for (id item in newItems) {
        NSButton *button = [self tabWithTitle:[self.dataSource tabControl:self titleForItem:item]];
        LITabCell *buttonCell = [button cell];
        
        [buttonCell setRepresentedObject:item];
        
        // NOTE: menus are dynamic, but we indicate their presence by associating a menu
        // with the button cell...
        
        NSMenu *menu = [self.dataSource tabControl:self menuForItem:item];
        if (menu != nil) {
            [buttonCell setMenu:[[NSMenu alloc] init]];
            [button addTrackingArea:[[NSTrackingArea alloc] initWithRect:_scrollView.bounds
                                                                 options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp|NSTrackingInVisibleRect
                                                                   owner:self
                                                                userInfo:@{@"item" : item}]];
        }

        [newTabs addObject:button];
    }

    [tabView setSubviews:newTabs];
    [self layoutTabs:newTabs inView:tabView];
    
    self.items = newItems;
    self.scrollView.documentView = (self.items.count) ? tabView : nil;
    
    if (self.scrollView.documentView) {
        NSClipView *clipView = self.scrollView.contentView;
        NSView *documentView = self.scrollView.documentView;
        
        [clipView addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[documentView]" options:0 metrics:nil views:@{@"documentView": documentView}]];
        [clipView addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[documentView]|" options:0 metrics:nil views:@{@"documentView": documentView}]];
    }
    
    [self updateButtons];
    
    [self invalidateRestorableState];
}

- (void)layoutTabs:(NSArray *)tabs inView:(NSView *)tabView {
    // remove old constraints, if any...
    [tabView removeConstraints:tabView.constraints];
    
    // constrain passed tabs into a horizontal list...
    NSButton *prev = nil;
    for (NSButton *button in tabs) {
        [tabView addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|" options:0 metrics:nil views:@{@"button":button}]];
        
        [tabView addConstraint:
         [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeading
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:(prev != nil ? prev : tabView)
                                      attribute:(prev != nil ? NSLayoutAttributeTrailing : NSLayoutAttributeLeading)
                                     multiplier:1 constant:0]];
        prev = button;
    }
    
    if (prev) {
        [tabView addConstraint:
         [NSLayoutConstraint constraintWithItem:prev attribute:NSLayoutAttributeTrailing
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:tabView attribute:NSLayoutAttributeTrailing
                                     multiplier:1 constant:0]];
    }
    
    [tabView layoutSubtreeIfNeeded];
}

- (NSButton *)tabWithTitle:(NSString *)title {
    LITabCell   *tabCell    = [[LITabCell alloc] initTextCell:title];
    
    tabCell.target          = self;
    tabCell.action          = @selector(selectTab:);
    
    [tabCell sendActionOn:NSLeftMouseDownMask];

    tabCell.imagePosition   = NSNoImage;
    tabCell.borderMask      = LIBorderMaskRight|LIBorderMaskBottom;
    tabCell.font            = [NSFont fontWithName:@"HelveticaNeue-Medium" size:13];
    
    NSButton    *tab        = [self viewWithClass:[NSButton class]];

    [tab setCell:tabCell];
    
    [tab addConstraints:
     @[[NSLayoutConstraint constraintWithItem:tab attribute:NSLayoutAttributeWidth
                                    relatedBy:NSLayoutRelationGreaterThanOrEqual
                                       toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                   multiplier:1.0 constant:self.minTabWidth],
       
       [NSLayoutConstraint constraintWithItem:tab attribute:NSLayoutAttributeWidth
                                    relatedBy:NSLayoutRelationLessThanOrEqual
                                       toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                   multiplier:1.0 constant:self.maxTabWidth]]];
    
    return tab;
}

- (NSButton *)existingTabWithItem:(id)item {
    for (NSButton *button in [self.scrollView.documentView subviews]) {
        if (button != self.draggingTab) {
            if ([[[button cell] representedObject] isEqual:item]) {
                return button;
            }
        }
    }
    return nil;
}

#pragma mark -
#pragma mark ScrollView Tracking

- (NSButton *)trackedButtonWithEvent:(NSEvent *)theEvent {
    id item = theEvent.trackingArea.userInfo[@"item"];
    return (item != nil) ? [self existingTabWithItem:item] : nil;
}

- (void)mouseEntered:(NSEvent *)theEvent {
    [[[self trackedButtonWithEvent:theEvent] cell] setShowsMenu:YES];
}
- (void)mouseExited:(NSEvent *)theEvent {
    [[[self trackedButtonWithEvent:theEvent] cell] setShowsMenu:NO];
}

#pragma mark -
#pragma mark Editing

- (void)editItem:(id)item {
    NSButton *button = [self existingTabWithItem:item];
    
    // end existing editing, if any...
    if (self.editingField != nil) {
        [self.window makeFirstResponder:self];
    }
    
    // layout items if necessary
    [self layoutSubtreeIfNeeded];
    
    if (button != nil) {
        LITabCell *cell = button.cell;
        NSRect titleRect = [cell titleRectForBounds:button.bounds];
        
        self.editingField = [[NSTextField alloc] initWithFrame:titleRect];

        self.editingField.editable = YES;
        self.editingField.font = cell.font;
        self.editingField.alignment = NSCenterTextAlignment;
        self.editingField.backgroundColor = cell.backgroundColor;
        self.editingField.focusRingType = NSFocusRingTypeNone;

        self.editingField.textColor = [[NSColor darkGrayColor] blendedColorWithFraction:0.5 ofColor:[NSColor blackColor]];

        NSTextFieldCell *textFieldCell = self.editingField.cell;
        
        [textFieldCell setBordered:NO];
        [textFieldCell setScrollable:YES];
        
        self.editingField.stringValue = button.title;
        
        [button addSubview:self.editingField];
        
        self.editingField.delegate = self;
        [self.editingField selectText:self];
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    NSString *title = self.editingField.stringValue;
    NSButton *button = (id)[self.editingField superview];

    self.editingField.delegate = nil;
    [self.editingField removeFromSuperview];
    self.editingField = nil;

    if (title.length > 0) {
        [button setTitle:title];
        
        [self.dataSource tabControl:self setTitle:title forItem:[button.cell representedObject]];
    }
}

#pragma mark -
#pragma mark Drawing

- (BOOL)isOpaque {
    return YES;
}
- (BOOL)isFlipped {
    return YES;
}

#pragma mark -
#pragma mark State Restoration

// NOTE: to enable state restoration, be sure to either assign an identifier to
// the LITabControl instance within IB or, if the control is created programmatically,
// prior to adding it to your window's view hierarchy.

#define kScrollXOffsetKey @"scrollOrigin"
#define kSelectedButtonIndexKey @"selectedButtonIndex"

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    CGFloat scrollXOffset = 0;
    NSUInteger selectedButtonIndex = NSNotFound;
    
    scrollXOffset = self.scrollView.contentView.bounds.origin.x;
    
    NSUInteger index = 0;
    for (NSButton *button in [self.scrollView.documentView subviews]) {
        if (button.state == 1) {
            selectedButtonIndex = index;
            break;
        }
        index += 1;
    }
    
    [coder encodeDouble:scrollXOffset forKey:kScrollXOffsetKey];
    [coder encodeInteger:selectedButtonIndex forKey:kSelectedButtonIndexKey];
}

- (void)restoreStateWithCoder:(NSCoder *)coder {
    [super restoreStateWithCoder:coder];

    CGFloat scrollXOffset = [coder decodeDoubleForKey:kScrollXOffsetKey];
    NSUInteger selectedButtonIndex = [coder decodeIntegerForKey:kSelectedButtonIndexKey];

    NSRect bounds = self.scrollView.contentView.bounds; bounds.origin.x = scrollXOffset;
    self.scrollView.contentView.bounds = bounds;
    
    NSUInteger index = 0;
    for (NSButton *button in [self.scrollView.documentView subviews]) {
        if (index == selectedButtonIndex) {
            [button setState:1];
        } else {
            [button setState:0];
        }
        index += 1;
    }
}

@end

NSString *LITabControlSelectionDidChangeNotification = @"LITabControlSelectionDidChangeNotification";
