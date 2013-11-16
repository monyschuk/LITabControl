//
//  LITabControl.m
//  LITabControl
//
//  Created by Mark Onyschuk on 11/12/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LITabControl.h"
#import "NSImage+LITabControl.h"

#import <QuartzCore/QuartzCore.h>

#define DF_MIN_TAB_WIDTH    (72.f * 2)
#define DF_MAX_TAB_WIDTH    (72.f * 2.5)

#define DF_BORDER_COLOR     [NSColor lightGrayColor]
#define DF_HIGHLIGHT_COLOR  [NSColor colorWithCalibratedRed:0.119 green:0.399 blue:0.964 alpha:1.000]
#define DF_BACKGROUND_COLOR [NSColor colorWithCalibratedRed:0.854 green:0.858 blue:0.873 alpha:1.000]

@interface LITabControl()

@property(nonatomic, strong) NSArray        *items;

@property(nonatomic, strong) NSScrollView   *scrollView;
@property(nonatomic, strong) NSButton       *addButton, *scrollLeftButton, *scrollRightButton;

@end

@implementation LITabControl

+ (Class)cellClass {
    return [LITabButtonCell class];
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
        [self.cell setBorderColor:DF_BORDER_COLOR];
        [self.cell setBackgroundColor:DF_BACKGROUND_COLOR];

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
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_addButton][_scrollView][_scrollLeftButton][_scrollRightButton]|" options:0 metrics:nil views:views]];
        
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

        [self updateButtons];
    }
}

- (void)updateButtons {
    [_addButton setEnabled:(self.addAction != NULL)];

    NSView *documentView = self.scrollView.documentView;
    NSClipView *contentView = self.scrollView.contentView;
    
    BOOL isDocumentClipped = documentView == nil || NSWidth(documentView.frame) > NSWidth(contentView.bounds);
    
    [_scrollLeftButton setHidden:isDocumentClipped];
    [_scrollRightButton setHidden:isDocumentClipped];
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
        
        [self updateButtons];
    }
}

- (IBAction)add:(id)sender {
    [[NSApplication sharedApplication] sendAction:self.addAction to:self.addTarget from:self];
}

- (IBAction)goLeft:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}
- (IBAction)goRight:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (IBAction)selectTab:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark -
#pragma mark Data Source

- (void)setDataSource:(id<LITabDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        
        [self reloadData];
    }
}

- (void)reloadData {
    NSView *tabView = [self viewWithClass:[NSView class]];
    NSMutableArray *newItems = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0, count = [self.dataSource tabControlNumberOfTabs:self]; i < count; i++) {
        [newItems addObject:[self.dataSource tabControl:self itemAtIndex:i]];
    }
    
    NSButton *prev = nil;
    for (id item in newItems) {
        NSButton *button = [self tabWithTitle:[self.dataSource tabControl:self titleForItem:item] view:tabView];
        
        [tabView addSubview:button];
        
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
}

- (NSButton *)tabWithTitle:(NSString *)title view:(NSView *)view {
    LITabButtonCell *tabCell = [[LITabButtonCell alloc] initTextCell:title];
    
    tabCell.target = self;
    tabCell.action = @selector(selectTab:);
    
    tabCell.borderMask = LIBorderMaskRight|LIBorderMaskBottom;
    
    tabCell.imagePosition = NSNoImage;
    tabCell.font = [NSFont fontWithName:@"HelveticaNeue-Medium" size:13];
    
    NSButton *tab = [self viewWithClass:[NSButton class]];

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
    
    [view addSubview:tab];
    [view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tab]|" options:0 metrics:nil views:@{@"tab": tab}]];
    
    return tab;
}

#pragma mark -
#pragma mark Layout

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, NSViewNoInstrinsicMetric);
}

#pragma mark -
#pragma mark Drawing

- (BOOL)isOpaque {
    return YES;
}
- (BOOL)isFlipped {
    return YES;
}


@end

@implementation LITabButtonCell

- (id)initTextCell:(NSString *)aString {
    if ((self = [super initTextCell:aString])) {
        [self setBordered:NO];
        
        [self setBorderColor:DF_BORDER_COLOR];
        [self setBackgroundColor:DF_BACKGROUND_COLOR];
        
        [self setHighlightsBy:NSNoCellMask];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LITabButtonCell *copy = [super copyWithZone:zone];
    
    copy->_borderMask = _borderMask;
    copy->_borderColor = [_borderColor copyWithZone:zone];
    copy->_backgroundColor = [_backgroundColor copyWithZone:zone];
    
    return copy;
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    if (_backgroundColor != backgroundColor) {
        _backgroundColor = backgroundColor.copy;
    
        [self.controlView setNeedsDisplay:YES];
    }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [self.backgroundColor set];
    NSRectFill(cellFrame);
    
    if (self.image && self.imagePosition != NSNoImage) {
        [self drawImage:[self.image imageWithTint:self.isHighlighted ? DF_HIGHLIGHT_COLOR : [NSColor darkGrayColor]] withFrame:cellFrame inView:controlView];
    }
    
    if (self.title.length && self.imagePosition != NSImageOnly) {
        NSMutableAttributedString *attributedTitle = self.attributedTitle.mutableCopy;
        [attributedTitle addAttributes:@{ NSForegroundColorAttributeName : (self.isHighlighted ? DF_HIGHLIGHT_COLOR : [NSColor darkGrayColor]) } range:NSMakeRange(0, attributedTitle.length)];
        [self drawTitle:attributedTitle withFrame:NSOffsetRect(cellFrame, 0, -2) inView:controlView];
    }

    NSRect *borderRects;
    NSInteger borderRectCount;
    if (LIRectArrayWithBorderMask(cellFrame, self.borderMask, &borderRects, &borderRectCount)) {
        [self.borderColor set];
        NSRectFillList(borderRects, borderRectCount);
    }
}

@end

BOOL LIRectArrayWithBorderMask(NSRect sourceRect, LIBorderMask borderMask, NSRect **rectArray, NSInteger *rectCount) {
    static NSRect outputArray[4];
    NSInteger outputCount = 0;
    
    NSRect remainderRect;
    if (borderMask & LIBorderMaskTop) {
        NSDivideRect(sourceRect, &outputArray[outputCount++], &remainderRect, 1, NSMinYEdge);
    }
    if (borderMask & LIBorderMaskLeft) {
        NSDivideRect(sourceRect, &outputArray[outputCount++], &remainderRect, 1, NSMinXEdge);
    }
    if (borderMask & LIBorderMaskRight) {
        NSDivideRect(sourceRect, &outputArray[outputCount++], &remainderRect, 1, NSMaxXEdge);
    }
    if (borderMask & LIBorderMaskBottom) {
        NSDivideRect(sourceRect, &outputArray[outputCount++], &remainderRect, 1, NSMaxYEdge);
    }
    
    if (rectCount) *rectCount = outputCount;
    if (rectArray) *rectArray = &outputArray[0];
    
    return (outputCount > 0);
}

NSString *LITabControlDidChangeSelectionNotification = @"LITabControlDidChangeSelectionNotification";
