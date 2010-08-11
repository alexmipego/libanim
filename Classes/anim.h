//
//  ImageLoader.h
//  anim
//
//  Created by Alexandre on 8/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>

void **anim_loadframes(const char* filename, void *(*renderer)(UInt32, UInt32, int,  const void*), int *width, int *height, UInt32 *num_frames, float *delay);
void* anim_cgrenderer(UInt32 width, UInt32 height, int color_type,  const void* pixels);
void* anim_glrenderer(UInt32 width, UInt32 height, int color_type,  const void* pixels);