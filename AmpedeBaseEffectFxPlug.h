//
//  AmpedeBaseEffectFxPlug.h
//  AmpedeFxPlug
//
//  Created by Erich Ocean on 12/11/06.
//  Copyright 2006 Erich Atlas Ocean. All rights reserved.
//

#import <FxPlug/FxPlugSDK.h>


@interface AmpedeBaseEffectFxPlug : NSObject < FxBaseEffect, FxCustomParameterViewHost >
{
    id < PROAPIAccessing > apiManager;
}

- initWithAPIManager: (id < PROAPIAccessing >) theApiManager;

@end

//
//  Some utility functions.
//

OSStatus
LaunchBackgroundAppWithURL( NSURL *appURL );
