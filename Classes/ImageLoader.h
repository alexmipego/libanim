//
//  ImageLoader.h
//  anim
//
//  Created by Alexandre on 8/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>

void **loadTexture(NSString *filename, void* (*generatorFunc)(UInt32, UInt32, int,  const void*), int *width, int *height, UInt32 *num_frames, float *delay);

void colortype2GlTex(int color_type, GLint *internalFormat, GLenum *format);
void* createTexture(UInt32 width, UInt32 height, int color_type,  const void* pixels);