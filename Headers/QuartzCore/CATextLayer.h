/* CATextLayer.h

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

#import "QuartzCore/CABase.h"
#import "QuartzCore/CAMediaTiming.h"
#import "QuartzCore/CATransform3D.h"
#import "QuartzCore/CALayer.h"
#if GNUSTEP
#import <CoreText/CoreText.h>
#import <CoreText/CTFont.h>
#import <CoreGraphics/CoreGraphics.h>
#endif


/* The text layer provides simple text layout and rendering of plain
 * or attributed strings. The first line is aligned to the top of the
 * layer. */

@interface CATextLayer : CALayer
{
@private
    struct CATextLayerPrivate *_state;
}

/* The text to be rendered, should be either an NSString or an
 * NSAttributedString. Defaults to nil. */

@property(copy) id string;

/* The font to use, currently may be either a CTFontRef, a CGFontRef,
 * or a string naming the font. Defaults to the Helvetica font. Only
 * used when the `string' property is not an NSAttributedString. */

@property CFTypeRef font;

/* The font size. Defaults to 36. Only used when the `string' property
 * is not an NSAttributedString. Animatable (Mac OS X 10.6 and later.) */

@property CGFloat fontSize;

/* The color object used to draw the text. Defaults to opaque white.
 * Only used when the `string' property is not an NSAttributedString.
 * Animatable (Mac OS X 10.6 and later.) */

@property CGColorRef foregroundColor;

/* When true the string is wrapped to fit within the layer bounds.
 * Defaults to NO.*/

@property(getter=isWrapped) BOOL wrapped;

/* Describes how the string is truncated to fit within the layer
 * bounds. The possible options are `none', `start', `middle' and
 * `end'. Defaults to `none'. */

@property(copy) NSString *truncationMode;

/* Describes how individual lines of text are aligned within the layer
 * bounds. The possible options are `natural', `left', `right',
 * `center' and `justified'. Defaults to `natural'. */

@property(copy) NSString *alignmentMode;

@end

/* Truncation modes. */

CA_EXTERN NSString * const kCATruncationNone;
CA_EXTERN NSString * const kCATruncationStart;
CA_EXTERN NSString * const kCATruncationEnd;
CA_EXTERN NSString * const kCATruncationMiddle;

/* Alignment modes. */

CA_EXTERN NSString * const kCAAlignmentNatural;
CA_EXTERN NSString * const kCAAlignmentLeft;
CA_EXTERN NSString * const kCAAlignmentRight;
CA_EXTERN NSString * const kCAAlignmentCenter;
CA_EXTERN NSString * const kCAAlignmentJustified;

