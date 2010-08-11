//
//  ImageLoader.m
//  anim
//
//  Created by Alexandre on 8/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "anim.h"
#import <OpenGLES/ES1/gl.h>
#include "png.h"

#define TEXTURE_LOAD_ERROR 0

void colortype2GlTex(int color_type, GLint *internalFormat, GLenum *format);

void **anim_loadframes(const char* filename, void *(*renderer)(UInt32, UInt32, int,  const void*), int *width, int *height, UInt32 *num_frames, float *delay)
{
	//header for testing if it is a png
	png_byte header[8];
	
	//open file as binary
	FILE *fp = fopen(filename, "rb");
	if (!fp) { return TEXTURE_LOAD_ERROR; }
	
	//read the header
	fread(header, 1, 8, fp);
	
	//test if png
	int is_png = !png_sig_cmp(header, 0, 8);
	if (!is_png) { fclose(fp); return TEXTURE_LOAD_ERROR; }
	
	//create png struct
	png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if (!png_ptr) { fclose(fp); return (TEXTURE_LOAD_ERROR); }
	
	//create png info struct
	png_infop info_ptr = png_create_info_struct(png_ptr);
	if (!info_ptr) {
		png_destroy_read_struct(&png_ptr, (png_infopp) NULL, (png_infopp) NULL);
		fclose(fp);
		return (TEXTURE_LOAD_ERROR);
	}
	
	//create png info struct
	png_infop end_info = png_create_info_struct(png_ptr);
	if (!end_info) {
		png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp) NULL);
		fclose(fp);
		return (TEXTURE_LOAD_ERROR);
	}
	
	//png error stuff, not sure libpng man suggests this.
	if (setjmp(png_jmpbuf(png_ptr))) {
		png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
		fclose(fp);
		return (TEXTURE_LOAD_ERROR);
	}
	
	//init png reading
	png_init_io(png_ptr, fp);
	
	//let libpng know you already read the first 8 bytes
	png_set_sig_bytes(png_ptr, 8);
	
	// read all the info up to the image data
	png_read_info(png_ptr, info_ptr);
	
	if(!png_get_valid(png_ptr, info_ptr, PNG_INFO_acTL)) { printf("Source must be a valid APNG file."); fclose(fp); return TEXTURE_LOAD_ERROR; }
	
	//variables to pass to get info
	int bit_depth, color_type;
	png_uint_32 twidth, theight, width2, height2;
	
	bit_depth = png_get_bit_depth(png_ptr, info_ptr);
	color_type = png_get_color_type(png_ptr, info_ptr);
	
	if( color_type == PNG_COLOR_TYPE_PALETTE )
		png_set_palette_to_rgb( png_ptr );
	if( png_get_valid( png_ptr, info_ptr, PNG_INFO_tRNS ) )
		png_set_tRNS_to_alpha (png_ptr);
	if( bit_depth == 16 )
		png_set_strip_16( png_ptr );
	else if( bit_depth < 8 )
		png_set_packing( png_ptr );
	
	png_read_update_info(png_ptr, info_ptr);
	
	// get info about png
	png_get_IHDR(png_ptr, info_ptr, &twidth, &theight, &bit_depth, &color_type,
				 NULL, NULL, NULL);
	
	int bits;
	switch(color_type)
	{
		case PNG_COLOR_TYPE_GRAY:
			bits = 1;
			break;
			
		case PNG_COLOR_TYPE_GRAY_ALPHA:
			bits = 2;
			break;
			
		case PNG_COLOR_TYPE_RGB:
			bits = 3;
			break;
			
		case PNG_COLOR_TYPE_RGB_ALPHA:
			bits = 4;
			break;
	}
	
	// wdith2 and height2 are the power of 2 versions of width and height
	height2 = theight;
	width2 = twidth;
	
	// this resizes!
	unsigned int i = 0;
	if((width2 != 1) && (width2 & (width2 - 1))) {
		i = 1;
		while( i < width2)
			i *= 2;
		width2 = i;
	}
	if((height2 != 1) && (height2 & (height2 - 1))) {
		i = 1;
		while(i < height2)
			i *= 2;
		height2 = i;
	}
	
	png_byte* pixels = (png_byte*)calloc(width2 * height2 * bits, sizeof(png_byte));
	png_byte** row_ptrs = (png_byte**)malloc(theight * sizeof(png_bytep));
	
	for (i=0; i<theight; i++)
		row_ptrs[i] = pixels + i*width2*bits;
	
	//update width and height based on png info
	*width = width2;
	*height = height2;
	
	*num_frames = png_get_num_frames(png_ptr, info_ptr);
	void **data = (void**)malloc(*num_frames * sizeof(void*));
	for(int count = 0; count < *num_frames; count++)
    {
		png_uint_32 next_frame_width, next_frame_height, next_frame_x_offset, next_frame_y_offset;
		png_uint_16 next_frame_delay_num, next_frame_delay_den;
		png_byte next_frame_dispose_op, next_frame_blend_op;
		
        png_read_frame_head(png_ptr, info_ptr);
        
        if(png_get_valid(png_ptr, info_ptr, PNG_INFO_fcTL))
        {
            png_get_next_frame_fcTL(png_ptr, info_ptr, 
									&next_frame_width, &next_frame_height, &next_frame_x_offset, &next_frame_y_offset, &next_frame_delay_num, &next_frame_delay_den, &next_frame_dispose_op, &next_frame_blend_op);
        }
        else
        {
            /* the first frame doesn't have an fcTL so it's expected to be hidden, 
			 * but we'll extract it anyway */
            next_frame_width = png_get_image_width(png_ptr, info_ptr);
            next_frame_height = png_get_image_height(png_ptr, info_ptr);
        }
		
		png_read_image(png_ptr, row_ptrs);
		
		*delay = (float)(next_frame_delay_num/next_frame_delay_den);
		data[count] = (void *)(*renderer)(*width, *height, color_type, pixels);
	}
	
	png_read_end( png_ptr, NULL);
	png_destroy_read_struct( &png_ptr, &info_ptr, &end_info );
	free(row_ptrs);
	free(pixels);	
	fclose(fp);
	
	return data;
}

void releasePixels(void *info, const void *data, size_t size) { free((void*)data); }

void* anim_cgrenderer(UInt32 width, UInt32 height, int color_type,  const void* pixels) {
	const int bytes = 4;
	
	void * pixelsCopy = malloc(width * height * bytes);
	memcpy(pixelsCopy, pixels, width * height * bytes);
	
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pixelsCopy, 4*512*512, &releasePixels);
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	
	CGImageRef imgRef = CGImageCreate(width, height, 8, 4*8, 512*4, space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big, provider, NULL, NO, kCGRenderingIntentDefault);
	CGColorSpaceRelease(space);
	CGDataProviderRelease(provider);

	return imgRef;
}

void* anim_glrenderer(UInt32 width, UInt32 height, int color_type,  const void* pixels) {
	GLuint texture = 0;
	glGenTextures(1, &texture);
	glBindTexture(GL_TEXTURE_2D, texture);
	
	GLint internalFormat = 0;
	GLenum format = 0;
	colortype2GlTex(color_type, &internalFormat, &format);
	
	glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid*)pixels);
	
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); 
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);	
	return (void*)texture;
}

void colortype2GlTex(int color_type, GLint *internalFormat, GLenum *format) {
	switch(color_type)
	{
		case PNG_COLOR_TYPE_GRAY:
			*internalFormat = GL_LUMINANCE;
			*format = GL_LUMINANCE;
			break;
			
		case PNG_COLOR_TYPE_GRAY_ALPHA:
			*internalFormat = GL_LUMINANCE_ALPHA;
			*format = GL_LUMINANCE_ALPHA;
			break;
			
		case PNG_COLOR_TYPE_RGB:
			*internalFormat = GL_RGB;
			*format = GL_RGB;
			break;
			
		case PNG_COLOR_TYPE_RGB_ALPHA:
			*internalFormat = GL_RGBA;
			*format = GL_RGBA;
			break;
			
		default:
			*internalFormat = GL_RGBA;
			*format = GL_RGBA;
	}	
}
