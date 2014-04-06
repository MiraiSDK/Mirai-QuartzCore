/* CAShapeLayer.h

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

@interface CAShapeLayer : CALayer

@property CGPathRef path;
@property CGColorRef fillColor;
@property(copy) NSString *fillRule;
@property CGColorRef strokeColor;
@property CGFloat strokeStart, strokeEnd;
@property CGFloat lineWidth;
@property CGFloat miterLimit;
@property(copy) NSString *lineCap;
@property(copy) NSString *lineJoin;
@property CGFloat lineDashPhase;
@property(copy) NSArray *lineDashPattern;

@end

CA_EXTERN NSString *const kCAFillRuleNonZero;
CA_EXTERN NSString *const kCAFillRuleEvenOdd;

CA_EXTERN NSString *const kCALineJoinMiter;
CA_EXTERN NSString *const kCALineJoinRound;
CA_EXTERN NSString *const kCALineJoinBevel;

CA_EXTERN NSString *const kCALineCapButt;
CA_EXTERN NSString *const kCALineCapRound;
CA_EXTERN NSString *const kCALineCapSquare;
