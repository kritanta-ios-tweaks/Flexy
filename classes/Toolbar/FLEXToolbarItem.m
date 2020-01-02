

//
//  FLEXToolbarItem.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXToolbarItem.h"
#import "FLEXUtility.h"

@interface FLEXToolbarItem ()

@property (nonatomic, copy) NSMutableAttributedString *attributedTitle;
@property (nonatomic, strong) UIImage *image;

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

@implementation FLEXToolbarItem

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[self class] defaultBackgroundColor];
        [self setTitleColor:[[self class] defaultTitleColor] forState:UIControlStateNormal];
        [self setTitleColor:[[self class] disabledTitleColor] forState:UIControlStateDisabled];
    }
    return self;
}

+ (instancetype)toolbarItemWithTitle:(NSString *)title image:(UIImage *)image
{
    FLEXToolbarItem *toolbarItem = [self buttonWithType:UIButtonTypeCustom];
    NSMutableAttributedString *normalTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:[self titleAttributes]];
    [normalTitle addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, [title length])];
    NSMutableAttributedString *highlightedTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:[self titleAttributes]];
    [highlightedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [title length])];
    NSMutableAttributedString *selectedTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:[self titleAttributes]];
    [selectedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [title length])];
    toolbarItem.attributedTitle = normalTitle;
    toolbarItem.image = image;
    UIImage *invertedImage = [image negativeImage];
    [toolbarItem setAttributedTitle:normalTitle forState:UIControlStateNormal];
    [toolbarItem setAttributedTitle:highlightedTitle forState:UIControlStateHighlighted];
    [toolbarItem setAttributedTitle:selectedTitle forState:UIControlStateSelected];
    [toolbarItem setImage:image forState:UIControlStateNormal];
    [toolbarItem setImage:invertedImage forState:UIControlStateHighlighted];
    [toolbarItem setImage:invertedImage forState:UIControlStateSelected];
    return toolbarItem;
}


#pragma mark - Display Defaults

+ (NSDictionary<NSString *, id> *)titleAttributes
{
    return @{NSFontAttributeName : [FLEXUtility defaultFontOfSize:12.0]};
}

+ (UIColor *)defaultTitleColor
{
    return [UIColor colorWithWhite:1 alpha:1.0];
}

+ (UIColor *)highlightedTitleColor
{
    return [UIColor colorWithWhite:0.0 alpha:1.0];
}

+ (UIColor *)disabledTitleColor
{
    return [UIColor colorWithWhite:121.0/255.0 alpha:1.0];
}

+ (UIColor *)highlightedBackgroundColor
{
    return [UIColor colorWithWhite:0.3 alpha:1.0];
}

+ (UIColor *)selectedBackgroundColor
{
    return [UIColor colorWithWhite:0.7 alpha:1.0];
}

+ (UIColor *)defaultBackgroundColor
{
    return [UIColor clearColor];
}

+ (CGFloat)topMargin
{
    return -3.0;
}


#pragma mark - State Changes

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self updateBackgroundColor];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self updateBackgroundColor];
}

- (void)updateBackgroundColor
{
    if (self.highlighted) {
        self.backgroundColor = [[self class] highlightedBackgroundColor];
    } else if (self.selected) {
        self.backgroundColor = [[self class] selectedBackgroundColor];
    } else {
        self.backgroundColor = [[self class] defaultBackgroundColor];
    }
}


#pragma mark - UIButton Layout Overrides

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    // Bottom aligned and centered.
    CGRect titleRect = CGRectZero;
    CGSize titleSize = [self.attributedTitle boundingRectWithSize:contentRect.size options:0 context:nil].size;
    titleSize = CGSizeMake(ceil(titleSize.width), ceil(titleSize.height));
    titleRect.size = titleSize;
    titleRect.origin.y = contentRect.origin.y + CGRectGetMaxY(contentRect) - titleSize.height - 3;
    titleRect.origin.x = contentRect.origin.x + FLEXFloor((contentRect.size.width - titleSize.width) / 2.0);
    return titleRect;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGSize imageSize = self.image.size;
    CGRect titleRect = [self titleRectForContentRect:contentRect];
    CGFloat availableHeight = contentRect.size.height - titleRect.size.height - [[self class] topMargin];
    CGFloat originY = [[self class] topMargin] + FLEXFloor((availableHeight - imageSize.height) / 2.0);
    CGFloat originX = FLEXFloor((contentRect.size.width - imageSize.width) / 2.0);
    CGRect imageRect = CGRectMake(originX, originY, imageSize.width, imageSize.height);
    return imageRect;
}

@end
