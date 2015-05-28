/* CATextLayer.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>

   This file is part of QuartzCore.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/



/* Demo/TextLayer.m
 
 Copyright (C) 2012 Free Software Foundation, Inc.
 
 Author: Ivan Vucica <ivan@vucica.net>
 Date: August 2012
 
 This file is part of QuartzCore.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; see the file COPYING.LIB.
 If not, see <http://www.gnu.org/licenses/> or write to the
 Free Software Foundation, 51 Franklin Street, Fifth Floor,
 Boston, MA 02110-1301, USA.
 */

#import "CATextLayer.h"

@implementation CATextLayer
@synthesize string = _string;
@synthesize font = _font;
@synthesize fontSize = _fontSize;
@synthesize foregroundColor = _foregroundColor;
@synthesize wrapped = _wrapped;
@synthesize truncationMode = _truncationMode;
@synthesize alignmentMode = _alignmentMode;

- (void) dealloc
{
    [_string release];
    CGColorRelease(_foregroundColor);
    [_truncationMode release];
    [_alignmentMode release];
    [super dealloc];
}

- (void)setForegroundColor: (CGColorRef)foregroundColor
{
    if (foregroundColor == _foregroundColor)
        return;
    
    CGColorRetain(foregroundColor);
    CGColorRelease(_foregroundColor);
    _foregroundColor = foregroundColor;
}


- (void) drawInContext: (CGContextRef)context
{
#if !(GNUSTEP)
    // Cocoa-provided Core Graphics
    [self drawInContextCoreText: context];
#else
    // Opal doesn't work with -drawInContextCoreText:.
    [self drawInContextElementary: context];
#endif
}

- (void) drawInContextCoreText: (CGContextRef)context
{
    /* Requires CoreText */
    
    if (!_string)
        return;
    
    CTLineRef line;
    
    if ([_string isKindOfClass:[NSString class]]) {
        
        if (!_foregroundColor)
            return;
        
        CFTypeRef fontUsing;
        if (!_font) {
            
            fontUsing = CTFontCreateWithName((CFStringRef)@"Helvetica", _fontSize ?: 36, NULL);
        } else if (CFGetTypeID(_font)==CTFontGetTypeID()){
            
            fontUsing = _font;
        } else if(CFGetTypeID(_font)==(CGFontGetTypeID())) {
            
            fontUsing = CTFontCreateWithGraphicsFont((CGFontRef)_font, _fontSize ?: 36, NULL, NULL );
        }
        else {
        
            fontUsing = CTFontCreateWithName((CFStringRef)@"Helvetica", _fontSize ?: 36, NULL);
        }
        
        NSMutableDictionary * attributesDict;
        attributesDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          (id)fontUsing, (id)kCTFontAttributeName,
                          (id)_foregroundColor, (id)kCTForegroundColorAttributeName,
                          nil];
        
        if (_wrapped) {
            
            CTTextAlignment theAlignment = kCTCenterTextAlignment;
            
            CFIndex theNumberOfSettings = 1;
            CTParagraphStyleSetting theSettings[1] =
            {
                { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment),
                    &theAlignment }
            };

            CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(theSettings, theNumberOfSettings);
            [attributesDict setObject:(id)paragraphStyle forKey:(id)kCTParagraphStyleAttributeName];
        }
        
        NSAttributedString * stringToDraw;
        stringToDraw = [[NSAttributedString alloc] initWithString: _string
                                                       attributes: attributesDict];
        line = CTLineCreateWithAttributedString((CFAttributedStringRef)stringToDraw);
        [stringToDraw release];
        [(id)fontUsing release];
    } else if([_string isKindOfClass:[NSAttributedString class]]){
    
        line = CTLineCreateWithAttributedString((CFAttributedStringRef)_string);
    } else {
        
        return;
    }
    
    /* Drawing */
    CGContextSetTextPosition(context, 5, 15);
    CTLineDraw(line, context);
    
    /* Cleanup */
    [(id)line release];
//    CGColorRelease(_foregroundColor);
}

- (void) drawInContextElementary: (CGContextRef)ctx
{
    /* Lacks support for UTF-8 */
    
    CGContextSaveGState(ctx);
    
    //CGContextSetGrayFillColor(ctx, 0, 1);
    CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
    if (_foregroundColor)
        CGContextSetFillColorWithColor(ctx, _foregroundColor);
    else
        NSLog(@"Nil color");
    CGContextSelectFont(ctx, "Helvetica-Bold", _fontSize, kCGEncodingMacRoman);
    CGContextShowTextAtPoint(ctx, 5, 15, [_string UTF8String], [_string length]);
    
    CGContextRestoreGState(ctx);
}

/*
 // create system font
 CTFontRef sysUIFont = CTFontCreateUIFontForLanguage(kCTFontSystemFontType, 24.0, NULL);
 
 // create from the postscript name
 CTFontRef helveticaBold = CTFontCreateWithName(CFSTR("Helvetica-Bold"), 24.0, NULL);
 
 // create it by replacing traits of existing font, this replaces bold with italic
 CTFontRef helveticaItalic = CTFontCreateCopyWithSymbolicTraits(helveticaBold, 24.0, NULL,
 kCTFontItalicTrait, kCTFontBoldTrait | kCTFontItalicTrait);
 */

@end


NSString * const kCATruncationNone = @"none";
NSString * const kCATruncationStart = @"start";
NSString * const kCATruncationEnd = @"middle";
NSString * const kCATruncationMiddle = @"end";

/* Alignment modes. */

NSString * const kCAAlignmentNatural = @"natural";
NSString * const kCAAlignmentLeft = @"left";
NSString * const kCAAlignmentRight = @"right";
NSString * const kCAAlignmentCenter = @"center";
NSString * const kCAAlignmentJustified = @"justified";

