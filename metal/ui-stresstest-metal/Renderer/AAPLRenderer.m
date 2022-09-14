/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation for a renderer class that performs Metal setup and per-frame rendering.
*/

@import MetalKit;

#import "AAPLRenderer.h"
#import "AAPLSquare.h"
#import "AAPLShaderTypes.h"

// The maximum number of frames in flight.
static const NSUInteger MaxFramesInFlight = 3;

// The number of squares in the scene, determined to fit the screen.
static const NSUInteger NumSquares = 80;
static const float NormalSize = 1.0 / NumSquares;

float lerpf(float a, float b, float t)
{
    return a + t * (b - a);
}

// Array of colors.
static const vector_float4 Colors[] =
{
    { 0.8, 0.2, 0.2, 1.0 },
    { 0.2, 0.8, 0.2, 1.0 },
    { 0.2, 0.2, 0.8, 1.0 },
    { 0.8, 0.2, 0.8, 1.0 },
    { 0.2, 0.8, 0.8, 1.0 },
    { 0.8, 0.8, 0.2, 1.0 },
    { 0.5, 0.5, 0.2, 1.0 },
};
static const NSUInteger NumColors = 7;
static const vector_float4 Gray = { 0.5, 0.5, 0.5, 1.0 };


// The main class performing the rendering.
@implementation AAPLRenderer
{
    // A semaphore used to ensure that buffers read by the GPU are not simultaneously written by the CPU.
    dispatch_semaphore_t _inFlightSemaphore;

    // A series of buffers containing dynamically-updated vertices.
    id<MTLBuffer> _vertexBuffers[MaxFramesInFlight];

    // The index of the Metal buffer in _vertexBuffers to write to for the current frame.
    NSUInteger _currentBuffer;

    id<MTLDevice> _device;

    id<MTLCommandQueue> _commandQueue;

    id<MTLRenderPipelineState> _pipelineState;

    NSUInteger _totalVertexCount;

    float _floatingPosition;
}

/// Initializes the renderer with the MetalKit view from which you obtain the Metal device.
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        _device = mtkView.device;

        _inFlightSemaphore = dispatch_semaphore_create(MaxFramesInFlight);

        // Load all the shader files with a metal file extension in the project.
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

        // Load the vertex shader.
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];

        // Load the fragment shader.
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

        // Create a reusable pipeline state object.
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"MyPipeline";
        pipelineStateDescriptor.sampleCount = mtkView.sampleCount;
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipelineStateDescriptor.vertexBuffers[AAPLVertexInputIndexVertices].mutability = MTLMutabilityImmutable;

        NSError *error;

        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        
        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);
        
        // Create the command queue.
        _commandQueue = [_device newCommandQueue];

        // Calculate vertex data and allocate vertex buffers.
        const NSUInteger squareVertexCount = [AAPLSquare vertexCount];
        _totalVertexCount = (NumSquares * NumSquares + 1) * squareVertexCount;
        const NSUInteger squareVertexBufferSize = _totalVertexCount * sizeof(AAPLVertex);

        for(NSUInteger bufferIndex = 0; bufferIndex < MaxFramesInFlight; bufferIndex++)
        {
            _vertexBuffers[bufferIndex] = [_device newBufferWithLength:squareVertexBufferSize
                                                               options:MTLResourceStorageModeShared];
            _vertexBuffers[bufferIndex].label = [NSString stringWithFormat:@"Vertex Buffer #%lu", (unsigned long)bufferIndex];
        }
        
        _floatingPosition = 0;
    }
    return self;
}


/// Updates the position of each square and also updates the vertices for each square in the current buffer.
- (void)updateState
{
    // Vertex data for a single default square.
    const AAPLVertex *squareVertices = [AAPLSquare vertices];
    const NSUInteger squareVertexCount = [AAPLSquare vertexCount];

    // Vertex data for the current squares.
    AAPLVertex *currentSquareVertices = _vertexBuffers[_currentBuffer].contents;
    NSUInteger currentVertex = 0;

    for(NSUInteger row = 0; row < NumSquares; row++)
    {
        float y = lerpf(-1, 1, (float)row / NumSquares * 1.0);
        
        for(NSUInteger column = 0; column < NumSquares; column++)
        {
            float x = lerpf(-1, 1, (float)column / NumSquares * 1.0);
            vector_float2 pos = {x, y};

            for(NSUInteger vertex = 0; vertex < squareVertexCount; vertex++)
            {
                currentSquareVertices[currentVertex].position = squareVertices[vertex].position * NormalSize + pos;
                currentSquareVertices[currentVertex].color = Colors[(row + column) % NumColors];
                currentVertex++;
            }
        }
    }
    
    const float floatingSize = NormalSize * 10;
    const float floatingSpeed = 0.05;
    _floatingPosition = _floatingPosition + floatingSpeed;
    float xy = sin(_floatingPosition) * (1 - floatingSize);
    vector_float2 pos = {-xy - floatingSize, xy - floatingSize};
    
    for(NSUInteger vertex = 0; vertex < squareVertexCount; vertex++)
    {
        currentSquareVertices[currentVertex].position = squareVertices[vertex].position * floatingSize + pos;
        currentSquareVertices[currentVertex].color = Gray;
        currentVertex++;
    }
}

#pragma mark - MetalKit View Delegate

/// Handles view orientation or size changes.
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

/// Handles view rendering for a new frame.
- (void)drawInMTKView:(nonnull MTKView *)view
{
    // Wait to ensure only `MaxFramesInFlight` number of frames are getting processed
    // by any stage in the Metal pipeline (CPU, GPU, Metal, Drivers, etc.).
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    // Iterate through the Metal buffers, and cycle back to the first when you've written to the last.
    _currentBuffer = (_currentBuffer + 1) % MaxFramesInFlight;

    // Update buffer data.
    [self updateState];

    // Create a new command buffer for each rendering pass to the current drawable.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommandBuffer";

    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if(renderPassDescriptor != nil)
    {
        // Create a render command encoder to encode the rendering pass.
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        // Set render command encoder state.
        [renderEncoder setRenderPipelineState:_pipelineState];

        // Set the current vertex buffer.
        [renderEncoder setVertexBuffer:_vertexBuffers[_currentBuffer]
                                offset:0
                               atIndex:AAPLVertexInputIndexVertices];

        // Draw the square vertices.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:_totalVertexCount];

        // Finalize encoding.
        [renderEncoder endEncoding];

        // Schedule a drawable's presentation after the rendering pass is complete.
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    // Add a completion handler that signals `_inFlightSemaphore` when Metal and the GPU have fully
    // finished processing the commands that were encoded for this frame.
    // This completion indicates that the dynamic buffers that were written-to in this frame, are no
    // longer needed by Metal and the GPU; therefore, the CPU can overwrite the buffer contents
    // without corrupting any rendering operations.
    __block dispatch_semaphore_t block_semaphore = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_semaphore);
     }];

    // Finalize CPU work and submit the command buffer to the GPU.
    [commandBuffer commit];
}

@end
