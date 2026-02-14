#include <assert.h>
#include <stdlib.h>
#include <stdbool.h>
#include "tctest.h"
#include "imgproc.h"

// Maximum number of pixels in a test image
#define MAX_NUM_PIXELS 1500

// Test image data: used to represent small test
// images that can be directly embedded in the test
// source code
struct TestImageData {
  int32_t width, height;
  uint32_t pixels[MAX_NUM_PIXELS];
};

// Include test image data
#include "test_image_data.h"

// Data type for the test fixture object.
// This contains data (including Image objects) that
// can be accessed by test functions. This is useful
// because multiple test functions can access the same
// data (so you don't need to create/initialize that
// data multiple times in different test functions.)
typedef struct {
  // Test images (for basic image transform tests)
  struct Image smol, smol_squash_1_1, smol_squash_3_1, smol_squash_1_3,
               smol_color_rot, smol_blur_0, smol_blur_3, smol_expand;

  // TODO: add additional test fixture data as needed
  uint32_t test_pixel;
  struct PixelAverager pa;
} TestObjs;

// Functions to create and clean up a test fixture object
TestObjs *setup( void );
void cleanup( TestObjs *objs );

// Helper functions used by the test code
void init_image_from_testdata(struct Image *img, struct TestImageData *test_data);
struct Image *create_output_image( const struct Image *src_img );
bool images_equal( struct Image *a, struct Image *b );
void destroy_img( struct Image *img );

// Test functions
void test_squash_basic( TestObjs *objs );
void test_color_rot_basic( TestObjs *objs );
void test_blur_basic( TestObjs *objs );
void test_expand_basic( TestObjs *objs );
// TODO: add prototypes for additional test functions
void test_get_r(TestObjs *objs);
void test_get_g(TestObjs *objs);
void test_get_b(TestObjs *objs);
void test_get_a(TestObjs *objs);
void test_make_pixel();
void test_rot_colors(TestObjs *objs);
void test_compute_index(TestObjs *objs);
void test_valid_position(TestObjs *objs);
void test_pa_init(TestObjs *objs);
void test_pa_update(TestObjs *objs);
void test_pa_update_from_img(TestObjs *objs);
void test_pa_avg_pixel(TestObjs *objs);
void test_blur_pixel(TestObjs *objs);
void test_squash_pixel(TestObjs *objs);

int main( int argc, char **argv ) {
  // allow the specific test to execute to be specified as the
  // first command line argument
  if ( argc > 1 )
    tctest_testname_to_execute = argv[1];

  TEST_INIT();

  // Run tests.
  // Make sure you add additional TEST() macro invocations
  // for any additional test functions you add.
  TEST( test_squash_basic );
  TEST( test_color_rot_basic );
  TEST( test_blur_basic );
  TEST( test_expand_basic );
  TEST(test_get_r);
  TEST(test_get_g);
  TEST(test_get_b);
  TEST(test_get_a);
  TEST(test_make_pixel);
  TEST(test_rot_colors);
  TEST(test_compute_index);
  TEST(test_valid_position);
  TEST(test_pa_init);
  TEST(test_pa_update);
  TEST(test_pa_update_from_img);
  TEST(test_pa_avg_pixel);
  TEST(test_blur_pixel);
  TEST(test_squash_pixel);

  TEST_FINI();
}

////////////////////////////////////////////////////////////////////////
// Test fixture setup/cleanup functions
////////////////////////////////////////////////////////////////////////

TestObjs *setup( void ) {
  TestObjs *objs = (TestObjs *) malloc( sizeof(TestObjs) );

  // Initialize test Images from test image data
  init_image_from_testdata( &objs->smol, &smol );
  init_image_from_testdata( &objs->smol_squash_1_1, &smol_squash_1_1 );
  init_image_from_testdata( &objs->smol_squash_3_1, &smol_squash_3_1 );
  init_image_from_testdata( &objs->smol_squash_1_3, &smol_squash_1_3 );
  init_image_from_testdata( &objs->smol_color_rot, &smol_color_rot );
  init_image_from_testdata( &objs->smol_blur_0, &smol_blur_0 );
  init_image_from_testdata( &objs->smol_blur_3, &smol_blur_3 );
  init_image_from_testdata( &objs->smol_expand, &smol_expand );

  // Initialize other test data
  objs->test_pixel = 0x8888CCCCU;
  pa_init(&objs->pa);

  return objs;
}

void cleanup( TestObjs *objs ) {
  // Note that the test Images don't need to be cleaned
  // up, because their data isn't dynamically allocated

  // TODO: clean up any test fixture data

  free( objs );
}

////////////////////////////////////////////////////////////////////////
// Test code helper functions
////////////////////////////////////////////////////////////////////////

// Helper function to initialize an Image from
// a TestImageData instance. Note that the Image will
// point directly to the TestImageData's pixel data,
// so don't call img_cleanup() on the resulting Image.
void init_image_from_testdata(struct Image *img, struct TestImageData *test_data) {
  img->width = test_data->width;
  img->height = test_data->height;
  img->data = test_data->pixels;
}

// Helper function to create a temporary output Image
// the same size as a given one
struct Image *create_output_image( const struct Image *src_img ) {
  struct Image *img;
  img = malloc( sizeof( struct Image ) );
  img_init( img, src_img->width, src_img->height );
  return img;
}

// Returns true IFF both Image objects are identical
bool images_equal( struct Image *a, struct Image *b ) {
  if ( a->width != b->width || a->height != b->height )
    return false;

  for ( int i = 0; i < a->height; ++i )
    for ( int j = 0; j < a->width; ++j ) {
      int index = i*a->width + j;
      if ( a->data[index] != b->data[index] )
        return false;
    }

  return true;
}

void destroy_img( struct Image *img ) {
  if ( img != NULL )
    img_cleanup( img );
  free( img );
}

////////////////////////////////////////////////////////////////////////
// Test functions
////////////////////////////////////////////////////////////////////////

#define SQUASH_TEST( xfac, yfac ) \
do { \
  struct Image *out_img = create_output_image( &objs->smol_squash_##xfac##_##yfac ); \
  imgproc_squash( &objs->smol, out_img, xfac, yfac ); \
  ASSERT( images_equal( out_img, &objs->smol_squash_##xfac##_##yfac ) ); \
  destroy_img( out_img ); \
} while (0)

#define XFORM_TEST( xform ) \
do { \
  struct Image *out_img = create_output_image( &objs->smol_##xform ); \
  imgproc_##xform( &objs->smol, out_img ); \
  ASSERT( images_equal( out_img, &objs->smol_##xform ) ); \
  destroy_img( out_img ); \
} while (0)

#define BLUR_TEST( blur_dist) \
do { \
  struct Image *out_img = create_output_image( &objs->smol_blur_##blur_dist ); \
  imgproc_blur( &objs->smol, out_img, blur_dist ); \
  ASSERT( images_equal( out_img, &objs->smol_blur_##blur_dist ) ); \
  destroy_img( out_img ); \
} while (0)

void test_squash_basic( TestObjs *objs ) {
  SQUASH_TEST( 1, 1 );
  SQUASH_TEST( 3, 1 );
  SQUASH_TEST( 1, 3 );
}

void test_color_rot_basic( TestObjs *objs ) {
  XFORM_TEST( color_rot );
}

void test_blur_basic( TestObjs *objs ) {
  BLUR_TEST( 0 );
  BLUR_TEST( 3 );
}

void test_expand_basic( TestObjs *objs ) {
  XFORM_TEST( expand );
}

void test_get_r(TestObjs *objs) {
  uint32_t r = get_r(objs->test_pixel);
  ASSERT(r == 0x88U);
}

void test_get_g(TestObjs *objs) {
  uint32_t g = get_g(objs->test_pixel);
  ASSERT(g == 0x88U);
}

void test_get_b(TestObjs *objs) {
  uint32_t b = get_b(objs->test_pixel);
  ASSERT(b == 0xCCU);
}

void test_get_a(TestObjs *objs) {
  uint32_t a = get_a(objs->test_pixel);
  ASSERT(a == 0xCCU);
}

void test_make_pixel() {
  uint32_t pixel_1 = make_pixel(0xFFU, 0xCCU, 0xAAU, 0xFFU);
  ASSERT(pixel_1 == 0xFFCCAAFFU);

  uint32_t pixel_2 = make_pixel(0xFFU, 0x66U, 0x99U, 0x80U);
  ASSERT(pixel_2 == 0xFF669980U);
}

void test_rot_colors(TestObjs *objs) {
  uint32_t rot_color_1 = rot_colors(&objs->smol, 0);
  ASSERT(rot_color_1 == 0x90ac9dffU);

  uint32_t rot_color_2 = rot_colors(&objs->smol, 314);
  ASSERT(rot_color_2 == 0x253f31ffU);
}

void test_compute_index(TestObjs *objs) {
  int32_t index_1 = compute_index(&objs->smol, 10, 11);
  ASSERT(index_1 == 221);

  int32_t index_2 = compute_index(&objs->smol_squash_3_1, 0, 0);
  ASSERT(index_2 == 0);

  int32_t index_3 = compute_index(&objs->smol_squash_1_3, 4, 20);
  ASSERT(index_3 == 104);
}

void test_valid_position(TestObjs *objs) {
  ASSERT(valid_position(&objs->smol, 15, 10) == false);
  ASSERT(valid_position(&objs->smol, 10, 21) == false);
  ASSERT(valid_position(&objs->smol, 20, 20) == false);
  ASSERT(valid_position(&objs->smol, 0, 0) == true);
  ASSERT(valid_position(&objs->smol, 10, 18) == true);
  ASSERT(valid_position(&objs->smol, -1, 2) == false);
  ASSERT(valid_position(&objs->smol, 6, -1) == false);
}

void test_pa_init(TestObjs *objs) {
  // Initialization function called during object setup
  // Correct initialization should set all values to 0
  ASSERT(objs->pa.r == 0);
  ASSERT(objs->pa.g == 0);
  ASSERT(objs->pa.b == 0);
  ASSERT(objs->pa.a == 0);
  ASSERT(objs->pa.count == 0);
}

void test_pa_update(TestObjs *objs) {
  pa_update(&objs->pa, objs->test_pixel);

  // Check that PixelAverager values were updated correctly
  // test_pixel has value 0x8888CCCC
  ASSERT(objs->pa.r == 0x88U);
  ASSERT(objs->pa.g == 0x88U);
  ASSERT(objs->pa.b == 0xCCU);
  ASSERT(objs->pa.a == 0xCCU);
  ASSERT(objs->pa.count == 1);
}

void test_pa_update_from_img(TestObjs *objs) {
  // Pixel at this position has value 0x574439ff
  pa_update_from_img(&objs->pa, &objs->smol_squash_3_1, 5, 5);
  ASSERT(objs->pa.r == 0x57U);
  ASSERT(objs->pa.g == 0x44U);
  ASSERT(objs->pa.b == 0x39U);
  ASSERT(objs->pa.a == 0xffU);
  ASSERT(objs->pa.count == 1); 

  // Pixel at this position has value 0x3b2e23ff
  pa_update_from_img(&objs->pa, &objs->smol_squash_1_3, 4, 20);
  ASSERT(objs->pa.r == 0x57U + 0x3bU);
  ASSERT(objs->pa.g == 0x44U + 0x2eU);
  ASSERT(objs->pa.b == 0x39U + 0x23U);
  ASSERT(objs->pa.a == 0xffU + 0xffU);
  ASSERT(objs->pa.count == 2); 

  // Out of bounds position should leave PixelAverager unchanged
  pa_update_from_img(&objs->pa, &objs->smol, -1, 4);
  ASSERT(objs->pa.r == 0x57U + 0x3bU);
  ASSERT(objs->pa.g == 0x44U + 0x2eU);
  ASSERT(objs->pa.b == 0x39U + 0x23U);
  ASSERT(objs->pa.a == 0xffU + 0xffU);
  ASSERT(objs->pa.count == 2); 
}

void test_pa_avg_pixel(TestObjs *objs) {
  pa_update(&objs->pa, 0x690E6CFFU);
  pa_update(&objs->pa, 0x87E61DBFU);
  pa_update(&objs->pa, 0x24516099U);

  uint32_t avg_pixel = pa_avg_pixel(&objs->pa);
  ASSERT(avg_pixel == 0x5C6C4DC7U);
}

void test_blur_pixel(TestObjs *objs) {
  // Blur distance of 0 should leave pixel unchanged
  uint32_t blurred_1 = blur_pixel(&objs->smol, 10, 10, 0);
  ASSERT(blurred_1 == objs->smol.data[220]);

  // Pixel at very edge of image
  uint32_t blurred_2 = blur_pixel(&objs->smol, 0, 20, 3);
  ASSERT(blurred_2 == objs->smol_blur_3.data[20]);

  // Pixel in middle of image
  uint32_t blurred_3 = blur_pixel(&objs->smol, 5, 5, 3);
  ASSERT(blurred_3 == objs->smol_blur_3.data[110]);
}

void test_squash_pixel(TestObjs *objs) {
  int32_t xfac = 3;
  int32_t yfac = 1;

  int32_t out_r = 2;
  int32_t out_c = 4;

  int32_t in_r = out_r * yfac;
  int32_t in_c = out_c * xfac;

  uint32_t squashed = squash_pixel(&objs->smol, out_r, out_c, xfac, yfac);

  ASSERT(squashed == objs->smol.data[compute_index(&objs->smol, in_r, in_c)]);
}

void test_expand_pixel(TestObjs *objs) {
  int32_t i = 3;
  int32_t j = 5;

  int32_t base_r = i / 2;
  int32_t base_c = j / 2;

  struct PixelAverager pa;
  pa_init(&pa);

  pa_update_from_img(&pa, &objs->smol, base_r, base_c);
  pa_update_from_img(&pa, &objs->smol, base_r, base_c + 1);
  pa_update_from_img(&pa, &objs->smol, base_r + 1, base_c);
  pa_update_from_img(&pa, &objs->smol, base_r + 1, base_c + 1);

  uint32_t expanded = expand_pixel(&objs->smol, i, j);

  ASSERT(expanded == pa_avg_pixel(&pa));
}
