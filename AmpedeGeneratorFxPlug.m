//
//  AmpedeGeneratorFxPlug.m
//  AmpedeFxPlug
//
//  Created by Erich Ocean on 12/9/06.
//  Copyright 2006 Erich Atlas Ocean. All rights reserved.
//

#import "AmpedeGeneratorFxPlug.h"


@implementation AmpedeGeneratorFxPlug

#pragma mark -
#pragma mark FxGenerator protocol

//
//  This method will be called before the host app sets up a render. A plug-in can indicate here whether it supports
//  CPU (software) rendering, GPU (hardware) rendering, or both.
//

- (BOOL)
frameSetup: (FxRenderInfo) renderInfo
hardware:   (BOOL *)       canRenderHardware
software:   (BOOL *)       canRenderSoftware
{
	*canRenderSoftware = NO;
	*canRenderHardware = NO;
	
	return NO;
}

//
//  This method renders the plug-in's output into the given destination, with the given render options. The plug-in may
//  retrieve parameters as needed here, using the appropriate host APIs. The output image will either be an FxBitmap
//  or an FxTexture, depending on the plug-in's capabilities, as declared in the frameSetup:hardware:software: method.
//

- (BOOL)
renderOutput: (FxImage *)    outputImage
withInfo:     (FxRenderInfo) renderInfo
{
    return NO;
}

//
//  This method is called when the host app is done with a frame. A plug-in may release any per-frame retained objects
//  at this point.
//

- (BOOL) frameCleanup
{
	return YES;
}

@end
