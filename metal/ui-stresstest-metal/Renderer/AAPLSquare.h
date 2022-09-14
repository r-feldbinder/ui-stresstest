/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for a simple class that represents a colored square object.
*/

@import MetalKit;
#import "AAPLShaderTypes.h"

@interface AAPLSquare : NSObject

+(const AAPLVertex*)vertices;
+(NSUInteger)vertexCount;

@end
