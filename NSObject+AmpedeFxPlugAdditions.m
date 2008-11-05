//
//  NSObject+AmpedeFxPlugAdditions.m
//  AmpedeFxPlug
//
//  Created by Erich Ocean on 12/11/06.
//  Copyright 2006 Erich Atlas Ocean. All rights reserved.
//

#import "NSObject+AmpedeFxPlugAdditions.h"


@implementation NSObject ( AmpedeFxPlugAdditions )

- (NSString *)
localizedStringForKey: (NSString *) key
{
    NSBundle *bundle = [NSBundle bundleForClass: [self class]];
    
    if ( bundle )
    {
        return [bundle localizedStringForKey: [NSString stringWithFormat: @"%@::%@", NSStringFromClass( [self class] ), key]
                       value:                 NULL
                       table:                 NSStringFromClass( [self class] )                                            ];
    }
    else return nil;
}

@end
