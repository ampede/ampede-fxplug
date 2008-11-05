//
//  AmpedeTestPlugIn.mm
//  AmpedeFxPlug
//
//  Created by Erich Ocean on 12/11/06.
//  Copyright 2006 Erich Atlas Ocean. All rights reserved.
//

#import "AmpedeTestPlugIn.h"

#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <OpenGL/glu.h>


// Parameters
#define kColorParamID 1000

//
// Templated software implementation
//

template < class PEL >
static
void
solidcolor( FxBitmap *outMap
          , double   red
          , double   green
          , double   blue
          , double   alpha
          , PEL      max     )
{
	PEL *outData = NULL;
	PEL pelColor[4];
	
	pelColor[0] = (PEL)( alpha * max );
	pelColor[1] = (PEL)( red * max );
	pelColor[2] = (PEL)( green * max );
	pelColor[3] = (PEL)( blue * max );
	
	for ( uint32_t y = 0; y < [outMap height]; ++y )
	{
		outData = (PEL *)[outMap dataPtrForPositionX:0 Y:y];
		
		for ( uint32_t x = 0; x < [outMap width]; ++x )
		{
			*outData++ = pelColor[0];
			*outData++ = pelColor[1];
			*outData++ = pelColor[2];
			*outData++ = pelColor[3];
		}
	}
}

@implementation AmpedeTestPlugIn

#pragma mark -
#pragma mark FxBaseEffect protocol

//
//  This method should return YES if the plug-in's output can vary over time even when all of its parameter values remain
//  constant. Returning NO means that a rendered frame can be cached and reused for other frames with the same parameter
//  values.
//

- (BOOL) variesOverTime
{
    return NO;
}

//
//  This method should return an NSDictionary defining the properties of the effect.
//

- (NSDictionary *) properties
{
    // it'd be nice to set this in the plugin's info.plist; this is dumb
	return [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: YES], kFxPropertyKey_SupportsRowBytes,
                                                       [NSNumber numberWithBool: NO],  kFxPropertyKey_SupportsR408,
                                                       [NSNumber numberWithBool: NO],  kFxPropertyKey_SupportsR4fl,
                                                       [NSNumber numberWithBool: NO],  kFxPropertyKey_MayRemapTime,
                                                       [NSNumber numberWithInt: 0],    kFxPropertyKey_EquivalentSMPTEWipeCode,
                                                       NULL ];
}

//
//  This method is where a plug-in defines its list of parameters.
//

- (BOOL) addParameters
{
	id parmsApi = [apiManager apiForProtocol: @protocol( FxParameterCreationAPI )];
	
	if ( parmsApi )
	{
		[parmsApi addColorParameterWithName: [self localizedStringForKey: @"Color"]
                  parmId:                    kColorParamID
                  defaultRed:                0.0
                  defaultGreen:              0.0
                  defaultBlue:               1.0
                  parmFlags:                 kFxParameterFlag_DEFAULT];
                  
		return YES;
	}
	else return NO;
}

//
//  This method will be called whenever a parameter value has changed. This provides a plug-in an opportunity to respond
//  by changing the value or state of some other parameter.
//

- (BOOL)
parameterChanged: (UInt32) parmId
{
    return YES;
}

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
	*canRenderSoftware = YES;
	*canRenderHardware = YES;
	
	return YES;
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
	BOOL retval = YES;
	id parmsApi	= [apiManager apiForProtocol: @protocol( FxParameterRetrievalAPI )];
	
	if ( parmsApi )
	{
		double red, green, blue;
		
		// Get the parm(s)
		[parmsApi getRedValue:&red
				   GreenValue:&green
					BlueValue:&blue
					 fromParm:kColorParamID
					   atTime:renderInfo.frame];
		
		switch ( [outputImage imageType] )
		{
            case kFxImageType_TEXTURE:
                double left, right, top, bottom;
                FxTexture *outTex = (FxTexture *)outputImage;
                
                [outTex getTextureCoords:&left
                                   right:&right
                                  bottom:&bottom
                                     top:&top];
                
                glColorMask( GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE );
                
                glBegin( GL_QUADS );
                
                glColor4f( red, green, blue, 1.0 );
                
                glVertex2f( left, bottom );
                glVertex2f( right, bottom );
                glVertex2f( right, top );
                glVertex2f( left, top );
                
                glEnd();
                break;
            case kFxImageType_BITMAP:
                FxBitmap *outMap = (FxBitmap *)outputImage;
                switch( [outputImage depth] )
                {
                    case 8:
                        solidcolor( outMap,
                                    red, 
                                    green, 
                                    blue,
                                    1.0,
                                    (UInt8)255 );
                        break;
                    case 16:
                        solidcolor( outMap,
                                    red, 
                                    green, 
                                    blue,
                                    1.0,
                                    (UInt16)65535 );
                        break;
                    case 32:
                        solidcolor( outMap,
                                    red, 
                                    green, 
                                    blue,
                                    1.0,
                                    (float)1.0 );
                        break;
                }
                break;
            default:
                retval = NO;
        }
	}
	else retval = NO;
	
	return retval;
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
