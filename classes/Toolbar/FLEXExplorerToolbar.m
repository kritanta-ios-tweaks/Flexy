//
//  FLEXExplorerToolbar.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXExplorerToolbar.h"
#import "FLEXToolbarItem.h"
#import "FLEXResources.h"
#import "FLEXUtility.h"

@interface FLEXExplorerToolbar ()

@property (nonatomic, strong, readwrite) FLEXToolbarItem *selectItem;
@property (nonatomic, strong, readwrite) FLEXToolbarItem *moveItem;
@property (nonatomic, strong, readwrite) FLEXToolbarItem *globalsItem;
@property (nonatomic, strong, readwrite) FLEXToolbarItem *closeItem;
@property (nonatomic, strong, readwrite) FLEXToolbarItem *hierarchyItem;
@property (nonatomic, strong, readwrite) UIView *dragHandle;

@property (nonatomic, strong) UIImageView *dragHandleImageView;

@property (nonatomic, strong) UIView *selectedViewDescriptionContainer;
@property (nonatomic, strong) UIView *selectedViewDescriptionSafeAreaContainer;
@property (nonatomic, strong) UIView *selectedViewColorIndicator;
@property (nonatomic, strong) UILabel *selectedViewDescriptionLabel;

@property (nonatomic, strong,readwrite) UIView *backgroundView;

@end

@implementation UIImage (NegativeImage)

- (UIImage *)negativeImage
{
    // get width and height as integers, since we'll be using them as
    // array subscripts, etc, and this'll save a whole lot of casting
    CGSize size = self.size;
    int width = size.width * self.scale;
    int height = size.height * self.scale;

    // Create a suitable RGB+alpha bitmap context in BGRA colour space
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *memoryPool = (unsigned char *)calloc(width*height*4, 1);
    CGContextRef context = CGBitmapContextCreate(memoryPool, width, height, 8, width * 4, colourSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colourSpace);

    // draw the current image to the newly created context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [self CGImage]);

    // run through every pixel, a scan line at a time...
    for(int y = 0; y < height; y++)
    {
        // get a pointer to the start of this scan line
        unsigned char *linePointer = &memoryPool[y * width * 4];

        // step through the pixels one by one...
        for(int x = 0; x < width; x++)
        {
            // get RGB values. We're dealing with premultiplied alpha
            // here, so we need to divide by the alpha channel (if it
            // isn't zero, of course) to get uninflected RGB. We
            // multiply by 255 to keep precision while still using
            // integers
            int r, g, b; 
            if(linePointer[3])
            {
                r = linePointer[0] * 255 / linePointer[3];
                g = linePointer[1] * 255 / linePointer[3];
                b = linePointer[2] * 255 / linePointer[3];
            }
            else
                r = g = b = 0;

            // perform the colour inversion
            r = 255 - r;
            g = 255 - g;
            b = 255 - b;

            // multiply by alpha again, divide by 255 to undo the
            // scaling before, store the new values and advance
            // the pointer we're reading pixel data from
            linePointer[0] = r * linePointer[3] / 255;
            linePointer[1] = g * linePointer[3] / 255;
            linePointer[2] = b * linePointer[3] / 255;
            linePointer += 4;
        }
    }

    // get a CG image from the context, wrap that into a
    // UIImage
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *returnImage = [UIImage imageWithCGImage:cgImage scale:self.scale orientation:UIImageOrientationUp];

    // clean up
    CGImageRelease(cgImage);
    CGContextRelease(context);
    free(memoryPool);

    // and return
    return returnImage;
}

@end

@implementation FLEXExplorerToolbar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundView = [[UIView alloc] init];
        self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1.0];
        [self addSubview:self.backgroundView];

        self.dragHandle = [[UIView alloc] init];
        self.dragHandle.backgroundColor = [UIColor clearColor];
        [self addSubview:self.dragHandle];
        
        UIImage *dragHandle = [FLEXResources dragHandle];
        dragHandle = [dragHandle negativeImage];
        self.dragHandleImageView = [[UIImageView alloc] initWithImage:dragHandle];
        [self.dragHandle addSubview:self.dragHandleImageView];
        
        UIImage *globalsIcon = [FLEXResources globeIcon];
        globalsIcon = [globalsIcon negativeImage];
        self.globalsItem = [FLEXToolbarItem toolbarItemWithTitle:@"Menu" image:globalsIcon];
        [self.globalsItem setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];

        UIImage *listIcon = [FLEXResources listIcon];
        listIcon = [listIcon negativeImage];
        self.hierarchyItem = [FLEXToolbarItem toolbarItemWithTitle:@"Views" image:listIcon];
        [self.hierarchyItem setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
        
        UIImage *selectIcon = [FLEXResources selectIcon];
        selectIcon = [selectIcon negativeImage];
        self.selectItem = [FLEXToolbarItem toolbarItemWithTitle:@"Select" image:selectIcon];
        [self.selectItem setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
        
        UIImage *moveIcon = [FLEXResources moveIcon];
        moveIcon = [moveIcon negativeImage];
        self.moveItem = [FLEXToolbarItem toolbarItemWithTitle:@"Move" image:moveIcon];
        [self.moveItem setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
        
        UIImage *closeIcon = [FLEXResources closeIcon];
        closeIcon = [closeIcon negativeImage];
        self.closeItem = [FLEXToolbarItem toolbarItemWithTitle:@"Close" image:closeIcon];
        [self.closeItem setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];

        self.selectedViewDescriptionContainer = [[UIView alloc] init];
        self.selectedViewDescriptionContainer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1];
        self.selectedViewDescriptionContainer.hidden = YES;
        [self addSubview:self.selectedViewDescriptionContainer];

        self.selectedViewDescriptionSafeAreaContainer = [[UIView alloc] init];
        self.selectedViewDescriptionSafeAreaContainer.backgroundColor = [UIColor clearColor];
        [self.selectedViewDescriptionContainer addSubview:self.selectedViewDescriptionSafeAreaContainer];
        
        self.selectedViewColorIndicator = [[UIView alloc] init];
        self.selectedViewColorIndicator.backgroundColor = [UIColor redColor];
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewColorIndicator];
        
        self.selectedViewDescriptionLabel = [[UILabel alloc] init];
        self.selectedViewDescriptionLabel.backgroundColor = [UIColor clearColor];
        self.selectedViewDescriptionLabel.textColor = [UIColor whiteColor];
        self.selectedViewDescriptionLabel.font = [[self class] descriptionLabelFont];
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewDescriptionLabel];
        
        self.toolbarItems = @[_globalsItem, _hierarchyItem, _selectItem, _moveItem, _closeItem];
    }
        
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];


    CGRect safeArea = [self safeArea];
    // Drag Handle
    const CGFloat kToolbarItemHeight = [[self class] toolbarItemHeight];
    self.dragHandle.frame = CGRectMake(CGRectGetMinX(safeArea), CGRectGetMinY(safeArea), [[self class] dragHandleWidth], kToolbarItemHeight);
    CGRect dragHandleImageFrame = self.dragHandleImageView.frame;
    dragHandleImageFrame.origin.x = FLEXFloor((self.dragHandle.frame.size.width - dragHandleImageFrame.size.width) / 2.0);
    dragHandleImageFrame.origin.y = FLEXFloor((self.dragHandle.frame.size.height - dragHandleImageFrame.size.height) / 2.0);
    self.dragHandleImageView.frame = dragHandleImageFrame;
    
    
    // Toolbar Items
    CGFloat originX = CGRectGetMaxX(self.dragHandle.frame);
    CGFloat originY = CGRectGetMinY(safeArea)-0.0;
    CGFloat height = kToolbarItemHeight;
    CGFloat width = FLEXFloor((CGRectGetWidth(safeArea) - CGRectGetWidth(self.dragHandle.frame)) / [self.toolbarItems count]);
    for (UIView *toolbarItem in self.toolbarItems) {
        toolbarItem.frame = CGRectMake(originX, originY, width, height);
        originX = CGRectGetMaxX(toolbarItem.frame);
    }
    
    // Make sure the last toolbar item goes to the edge to account for any accumulated rounding effects.
    UIView *lastToolbarItem = [self.toolbarItems lastObject];
    CGRect lastToolbarItemFrame = lastToolbarItem.frame;
    lastToolbarItemFrame.size.width = CGRectGetMaxX(safeArea) - lastToolbarItemFrame.origin.x;
    lastToolbarItem.frame = lastToolbarItemFrame;

    self.backgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), kToolbarItemHeight);
    
    const CGFloat kSelectedViewColorDiameter = [[self class] selectedViewColorIndicatorDiameter];
    const CGFloat kDescriptionLabelHeight = [[self class] descriptionLabelHeight];
    const CGFloat kHorizontalPadding = [[self class] horizontalPadding];
    const CGFloat kDescriptionVerticalPadding = [[self class] descriptionVerticalPadding];
    const CGFloat kDescriptionContainerHeight = [[self class] descriptionContainerHeight];
    
    CGRect descriptionContainerFrame = CGRectZero;
    descriptionContainerFrame.size.width = CGRectGetWidth(self.bounds);
    descriptionContainerFrame.size.height = kDescriptionContainerHeight;
    descriptionContainerFrame.origin.x = CGRectGetMinX(self.bounds);
    descriptionContainerFrame.origin.y = CGRectGetMaxY(self.bounds) - kDescriptionContainerHeight;
    self.selectedViewDescriptionContainer.frame = descriptionContainerFrame;

    CGRect descriptionSafeAreaContainerFrame = CGRectZero;
    descriptionSafeAreaContainerFrame.size.width = CGRectGetWidth(safeArea);
    descriptionSafeAreaContainerFrame.size.height = kDescriptionContainerHeight;
    descriptionSafeAreaContainerFrame.origin.x = CGRectGetMinX(safeArea);
    descriptionSafeAreaContainerFrame.origin.y = CGRectGetMinY(safeArea);
    self.selectedViewDescriptionSafeAreaContainer.frame = descriptionSafeAreaContainerFrame;

    // Selected View Color
    CGRect selectedViewColorFrame = CGRectZero;
    selectedViewColorFrame.size.width = kSelectedViewColorDiameter;
    selectedViewColorFrame.size.height = kSelectedViewColorDiameter;
    selectedViewColorFrame.origin.x = kHorizontalPadding;
    selectedViewColorFrame.origin.y = FLEXFloor((kDescriptionContainerHeight - kSelectedViewColorDiameter) / 2.0);
    self.selectedViewColorIndicator.frame = selectedViewColorFrame;
    self.selectedViewColorIndicator.layer.cornerRadius = ceil(selectedViewColorFrame.size.height / 2.0);
    
    // Selected View Description
    CGRect descriptionLabelFrame = CGRectZero;
    CGFloat descriptionOriginX = CGRectGetMaxX(selectedViewColorFrame) + kHorizontalPadding;
    descriptionLabelFrame.size.height = kDescriptionLabelHeight;
    descriptionLabelFrame.origin.x = descriptionOriginX;
    descriptionLabelFrame.origin.y = kDescriptionVerticalPadding;
    descriptionLabelFrame.size.width = CGRectGetMaxX(self.selectedViewDescriptionContainer.bounds) - kHorizontalPadding - descriptionOriginX;
    self.selectedViewDescriptionLabel.frame = descriptionLabelFrame;
}
    
    
#pragma mark - Setter Overrides

- (void)setToolbarItems:(NSArray<FLEXToolbarItem *> *)toolbarItems {
    if (_toolbarItems == toolbarItems) {
        return;
    }
    
    // Remove old toolbar items, if any
    for (FLEXToolbarItem *item in _toolbarItems) {
        [item removeFromSuperview];
    }
    
    // Trim to 5 items if necessary
    if (toolbarItems.count > 5) {
        toolbarItems = [toolbarItems subarrayWithRange:NSMakeRange(0, 5)];
    }

    for (FLEXToolbarItem *item in toolbarItems) {
        [self addSubview:item];
        [item setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
    }

    _toolbarItems = toolbarItems.copy;

    // Lay out new items
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setSelectedViewOverlayColor:(UIColor *)selectedViewOverlayColor
{
    if (![_selectedViewOverlayColor isEqual:selectedViewOverlayColor]) {
        _selectedViewOverlayColor = selectedViewOverlayColor;
        self.selectedViewColorIndicator.backgroundColor = selectedViewOverlayColor;
    }
}

- (void)setSelectedViewDescription:(NSString *)selectedViewDescription
{
    if (![_selectedViewDescription isEqual:selectedViewDescription]) {
        _selectedViewDescription = selectedViewDescription;
        self.selectedViewDescriptionLabel.text = selectedViewDescription;
        BOOL showDescription = [selectedViewDescription length] > 0;
        self.selectedViewDescriptionContainer.hidden = !showDescription;
    }
}


#pragma mark - Sizing Convenience Methods

+ (UIFont *)descriptionLabelFont
{
    return [UIFont systemFontOfSize:12.0];
}

+ (CGFloat)toolbarItemHeight
{
    return 50.0;
}

+ (CGFloat)dragHandleWidth
{
    return 30.0;
}

+ (CGFloat)descriptionLabelHeight
{
    return ceil([[self descriptionLabelFont] lineHeight]);
}

+ (CGFloat)descriptionVerticalPadding
{
    return 2.0;
}

+ (CGFloat)descriptionContainerHeight
{
    return [self descriptionVerticalPadding] * 2.0 + [self descriptionLabelHeight];
}

+ (CGFloat)selectedViewColorIndicatorDiameter
{
    return ceil([self descriptionLabelHeight] / 2.0);
}

+ (CGFloat)horizontalPadding
{
    return 11.0;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat height = 0.0;
    height += [[self class] toolbarItemHeight];
    height += [[self class] descriptionContainerHeight];
    return CGSizeMake(size.width, height);
}

- (CGRect)safeArea
{
  CGRect safeArea = self.bounds;
#if FLEX_AT_LEAST_IOS11_SDK
  if (@available(iOS 11, *)) {
    safeArea = UIEdgeInsetsInsetRect(self.bounds, self.safeAreaInsets);
  }
#endif
  return safeArea;
}

@end
