/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation for a simple class that represents a colored square object.
*/

#import "AAPLSquare.h"

@implementation AAPLSquare

/// Returns the vertices of one square.
/// The default position is centered at the origin.
/// The default color is white.
+(const AAPLVertex *)vertices
{
    const float SquareSize = 64;
    static const AAPLVertex squareVertices[] =
    {
        // Pixel Positions,                          RGBA colors.
        { { -0.5*SquareSize, -0.5*SquareSize },  { 1, 1, 1, 1 } },
        { { -0.5*SquareSize, +0.5*SquareSize },  { 1, 1, 1, 1 } },
        { { +0.5*SquareSize, -0.5*SquareSize },  { 1, 1, 1, 1 } },
        
        { { -0.5*SquareSize, +0.5*SquareSize },  { 1, 1, 1, 1 } },
        { { +0.5*SquareSize, -0.5*SquareSize },  { 1, 1, 1, 1 } },
        { { +0.5*SquareSize, +0.5*SquareSize },  { 1, 1, 1, 1 } }
    };
    return squareVertices;
}

/// Returns the number of vertices for each square.
+(const NSUInteger)vertexCount
{
    return 6;
}

@end
