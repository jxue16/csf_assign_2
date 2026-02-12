// C implementations of image processing functions

#include <stdlib.h>
#include <assert.h>
#include "imgproc.h"

// TODO: define your helper functions here

//! Transform the entire image by shrinking it down both 
//! horizontally and vertically (by potentially different
//! factors). This is equivalent to sampling the orignal image
//! for every pixel that is in certain rows and columns as 
//! specified in the function inputs.
//!
//! Take the image below where each letter corresponds to a pixel
//!
//!                 XAAAYBBB
//!                 AAAABBBB
//!                 ZCCCWDDD
//!                 CCCCDDDD
//!
//! If the user specified to shrink it horazontally by a factor 
//! of 4 and shrink it vertically by a factor of 2, you would 
//! sample pixel that had a row index such that 
//!
//!             row index % 2 = 0 
//!
//! and a column index such that
//!
//!             column index % 4 = 0
//!
//! in the above example, this would mean pixels that are in 
//! rows 0 and 2 with columns 0 and 4. 
//! The resultant image is:
//!
//!                 XY
//!                 ZW
//! 
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
//! @param xfac factor to downsize the image horizontally; guaranteed to be positive
//! @param yfac factor to downsize the image vertically; guaranteed to be positive
void imgproc_squash( struct Image *input_img, struct Image *output_img, int32_t xfac, int32_t yfac ) {
  // TODO: implement
}

//! Transform the color component values in each input pixel
//! by applying a rotation on the values of the color components
//! I.e. the old pixel's red component value will be used for
//! the new pixel's green component value, the old pixel's green
//! component value will be used new pixel's blue component value
//! and the old pixel's blue component value will be used new 
//! pixel's red component value. The alpha value should not change.
//! For instance, if a pixel had the hex value 0xAABBCCDD, the 
//! transformed pixel would become 0xCCAABBDD
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
void imgproc_color_rot( struct Image *input_img, struct Image *output_img) {
  int32_t num_pixels = input_img->width * input_img->height;
  for (int32_t i = 0; i < num_pixels; i++) {
    output_img->data[i] = rot_colors(input_img, i);
  }
}

//! Transform the input image using a blur effect.
//!
//! Each pixel of the output image should have its color components
//! determined by taking the average of the color components of pixels
//! within blur_dist number of pixels horizontally and vertically from
//! the pixel's location in the original image. For example, if
//! blur_dist is 0, then only the original pixel is considered, and the
//! the output image should be identical to the input image. If blur_dist
//! is 1, then the original pixel and the 8 pixels immediately surrounding
//! it would be considered, etc.  Pixels positions not within the bounds of
//! the image should be ignored: i.e., their color components aren't
//! considered in the computation of the result pixels.
//!
//! The alpha value each output pixel should be identical to the
//! corresponding input pixel.
//!
//! Averages should be computed using purely integer arithmetic with
//! no rounding.
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
//! @param blur_dist all pixels whose x/y coordinates are within
//!                  this many pixels of the x/y coordinates of the
//!                  original pixel should be included in the color
//!                  component averages used to determine the color
//!                  components of the output pixel
void imgproc_blur( struct Image *input_img, struct Image *output_img, int32_t blur_dist ) {
  // TODO: implement
}

//! The `expand` transformation doubles the width and height of the image.
//! 
//! Let's say that there are n rows and m columns of pixels in the
//! input image, so there are 2n rows and 2m columns in the output
//! image.  The pixel color and alpha value of the output pixel at row i and column
//! j should be computed as follows.
//! 
//! If both i and j are even, then the color and alpha value of the output
//! pixel are exactly the same as the input pixel at row i/2 and column j/2.
//! 
//! If i is even but j is odd, then the color components and alpha value
//! of the output pixel are computed as the average of those in the input pixels
//! in row i/2 at columns floor(j/2) and floor(j/2) + 1.
//! 
//! If i is odd and j is even, then the color components and alpha value
//! of the output pixel are computed as the average of those in the input pixels
//! in column j/2 at rows floor(i/2) and  floor(i/2) + 1.
//! 
//! If both i and j are odd then the color components and alpha value
//! of the output pixel are computed as the average of the input pixels
//! 
//! 1. At row floor(i/2) and column floor(j/2)
//! 2. At row floor(i/2) and column floor(j/2) + 1
//! 3. At row floor(i/2) + 1 and column floor(j/2)
//! 4. At row floor(i/2) + 1 and column floor(j/2) + 1
//! 
//! Note that in the cases where either i or j is odd, it is not
//! necessarily the case that either row floor(i/2) + 1 or
//! column floor(j/2) + 1 are in bounds in the input image.
//! Only input pixels that are properly in bounds should be incorporated into
//! the averages used to determine the color components and alpha value
//! of the output pixel.
//! 
//! Averages should be computed using purely integer arithmetic with
//! no rounding.
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
void imgproc_expand( struct Image *input_img, struct Image *output_img) {
  // TODO: implement
}

// Gets the 8 bits corresponding to the red component value
//
// @param pixel color in RGBA format
// @return 8-bit red value
uint32_t get_r(uint32_t pixel) {
  uint32_t r_mask = 0xFFU << 24;
  return (pixel & r_mask) >> 24;
}

// Gets the 8 bits corresponding to the green component value
//
// @param pixel color in RGBA format
// @return 8-bit green value
uint32_t get_g(uint32_t pixel) {
  uint32_t g_mask = 0xFFU << 16;
  return (pixel & g_mask) >> 16;
}

// Gets the 8 bits corresponding to the blue component value
//
// @param pixel color in RGBA format
// @return 8-bit blue value
uint32_t get_b(uint32_t pixel) {
  uint32_t b_mask = 0xFFU << 8;
  return (pixel & b_mask) >> 8;
}

// Gets the 8 bits corresponding to the alpha component value
//
// @param pixel color in RGBA format
// @return 8-bit alpha value
uint32_t get_a(uint32_t pixel) {
  uint32_t a_mask = 0xFFU;
  return pixel & a_mask;
}

// Combine individual component values into RGBA color
//
// @param r red component value
// @param g green component value
// @param b blue component value
// @param a alpha component value
// @return pixel color in RGBA format
uint32_t make_pixel(uint32_t r, uint32_t g, uint32_t b, uint32_t a) {
  uint32_t pixel = 0x0U | (r << 24) | (g << 16) | (b << 8) | a;
  return pixel;
}

// Rotates the color of the pixel at the given index
//
// @param img pointer to Image whose pixel we want to color rotate
// @param index row-major linear index of the pixel to be rotated
// @return color in RGBA format after rotation
uint32_t rot_colors(struct Image *img, int32_t index) {
  uint32_t pixel = img->data[index];
  uint32_t r = get_r(pixel);
  uint32_t g = get_g(pixel);
  uint32_t b = get_b(pixel);
  uint32_t a = get_a(pixel);

  return make_pixel(b, r, g, a);
}
