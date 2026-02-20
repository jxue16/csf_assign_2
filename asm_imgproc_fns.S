/*
 * x86-64 assembly language implementations of functions
 * CSF Assignment 2
 * Partner 1: Flora Huang (fhuang27@jh.edu)
 * Partner 2: Jonathan Xue (jxue18@jh.edu)
 */

	.section .text

/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

/*
 * TODO: define your helper functions here.
 * Don't forget to use the .globl directive to make
 * them visible to the test code.
 */

/*
 * Definitions of image transformation functions
 */

/*
 *  Transform the entire image by shrinking it down both 
 *  horizontally and vertically (by potentially different
 *  factors). This is equivalent to sampling the orignal image
 *  for every pixel that is in certain rows and columns as 
 *  specified in the function inputs.
 * 
 *  Take the image below where each letter corresponds to a pixel
 * 
 *                  XAAAYBBB
 *                  AAAABBBB
 *                  ZCCCWDDD
 *                  CCCCDDDD
 * 
 *  If the user specified to shrink it horazontally by a factor 
 *  of 4 and shrink it vertically by a factor of 2, you would 
 *  sample pixel that had a row index such that 
 * 
 *              row index % 2 = 0 
 * 
 *  and a column index such that
 * 
 *              column index % 4 = 0
 * 
 *  in the above example, this would mean pixels that are in 
 *  rows 0 and 2 with columns 0 and 4. 
 *  The resultant image is:
 * 
 *                  XY
 *                  ZW
 *  
 *  @param input_img pointer to the input Image
 *  @param output_img pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 *  @param xfac factor to downsize the image horizontally; guaranteed to be positive
 *  @param yfac factor to downsize the image vertically; guaranteed to be positive
 */
	.globl imgproc_squash
imgproc_squash:
	/*
	* Register use:
	*   %r12d - total output pixels
	*   %r13d - index counter
	*   %r14  - input image pointer
	*   %r15  - output image pointer
	*   %rbx  - pointer to output data array
	*   %r10d - xfactor
	*   %r11d - yfactor
	*/

	/* set up ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $40, %rsp
	/* save callee-saved registers */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx

	movq %rdi, %r14        /* save input image in r14 */
	movq %rsi, %r15        /* save output image in r15 */
	movl %edx, %r10d       /* save xfactor in r10d */
	movl %ecx, %r11d       /* save yfactor in r11d */

	movl IMAGE_WIDTH_OFFSET(%r14), %eax	/* input width of image */
	cltd								/* prepare width for division */
	idivl %r10d							/* divide width by xfactor */
	movl %eax, %r8d      			  	/* save output width in r8d */

	movl IMAGE_HEIGHT_OFFSET(%r14), %eax	/* input height of image */
	cltd									/* prepare height for division */
	idivl %r11d								/* divide height by yfactor */
	movl %eax, %r9d       				 	/* save output height in r9d */

	movl %r8d, %r12d	/* store output width in r12d */
	imull %r9d, %r12d	/* multiply output width by output height to get total output pixels in r12d */

	movl $0, %r13d         /* set loop index to 0 */
	movq IMAGE_DATA_OFFSET(%r15), %rbx  /* output data pointer */

.Ltop_squash:
	cmpl %r12d, %r13d
	jge .Ldone_squash		/* end loop if index >= no. of pixels */

	movq %r14, %rdi			/* set 1st argument register as pointer to input */
	movl %r13d, %esi		/* set 2nd argument register as current index */
	movl %r10d, %edx		/* set 3rd argument register as xfactor */
	movl %r11d, %ecx		/* set 4th argument register as yfactor */
	call squash_pixel		/* find original pixel from output */

	movl %eax, (%rbx, %r13, 4)	/* save current pixel */

	incl %r13d			/* increment index */
	jmp .Ltop_squash	/* return to top of loop */

.Ldone_squash:
	/* restore values of callee-saved registers */
	popq %rbx
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	/* restore stack */
	addq $40, %rsp
	popq %rbp
	ret

/*
 *  Transform the color component values in each input pixel
 *  by applying a rotation on the values of the color components
 *  I.e. the old pixel's red component value will be used for
 *  the new pixel's green component value, the old pixel's green
 *  component value will be used new pixel's blue component value
 *  and the old pixel's blue component value will be used new 
 *  pixel's red component value. The alpha value should not change.
 *  For instance, if a pixel had the hex value 0xAABBCCDD, the 
 *  transformed pixel would become 0xCCAABBDD
 * 
 *  @param %rdi pointer to the input Image
 *  @param %rsi pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 */
	.globl imgproc_color_rot
imgproc_color_rot:
	/*
	* Register use:
	*   %r12d - total pixels in Image
	*   %r13d - index counter for looping
	*   %r14 - pointer to input Image
	*   %r15 - pointer to output Image
	*   %rbx - pointer to data array of output Image struct
	*/

	/* set up ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $40, %rsp
	/* save current values of callee-saved registers on stack */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx

	movl IMAGE_WIDTH_OFFSET(%rdi), %r8d     /* width of image */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %r12d   /* height of image */
	imull %r8d, %r12d                       /* total pixels in image */

	movl $0, %r13d		                /* set index counter to 0 */
	movq %rdi, %r14                     /* save input img pointer in %r14 */
	movq %rsi, %r15                     /* save output img pointer in %r15 */
	movq IMAGE_DATA_OFFSET(%r15), %rbx  /* pointer to data array of output Image struct */
	
	.Ltop_color_rot:
		cmpl %r12d, %r13d
		jge .Ldone_color_rot  /* end loop if index >= no. of pixels */

		movq %r14, %rdi            /* set 1st argument register as pointer to input img */
		movl %r13d, %esi           /* set 2nd argument register as current index */
		call rot_colors            /* rotate pixel at current index */
		movl %eax, (%rbx, %r13, 4) /* save current rotated pixel in data array */
		
		incl %r13d           /* increment index */
		jmp .Ltop_color_rot  /* return to top of loop */

	.Ldone_color_rot:
		/* restore values of callee-saved registers */
		popq %rbx
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		/* restore stack */
		addq $40, %rsp
		popq %rbp
		ret

/*
 *  Transform the input image using a blur effect.
 * 
 *  Each pixel of the output image should have its color components
 *  determined by taking the average of the color components of pixels
 *  within blur_dist number of pixels horizontally and vertically from
 *  the pixel's location in the original image. For example, if
 *  blur_dist is 0, then only the original pixel is considered, and the
 *  the output image should be identical to the input image. If blur_dist
 *  is 1, then the original pixel and the 8 pixels immediately surrounding
 *  it would be considered, etc.  Pixels positions not within the bounds of
 *  the image should be ignored: i.e., their color components aren't
 *  considered in the computation of the result pixels.
 * 
 *  The alpha value each output pixel should be identical to the
 *  corresponding input pixel.
 * 
 *  Averages should be computed using purely integer arithmetic with
 *  no rounding.
 * 
 *  @param input_img pointer to the input Image
 *  @param output_img pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 *  @param blur_dist all pixels whose x/y coordinates are within
 *                   this many pixels of the x/y coordinates of the
 *                   original pixel should be included in the color
 *                   component averages used to determine the color
 *                   components of the output pixel
 */
	.globl imgproc_blur
imgproc_blur:
	/* TODO: implement */
	ret

/*
 *  The `expand` transformation doubles the width and height of the image.
 *  
 *  Let's say that there are n rows and m columns of pixels in the
 *  input image, so there are 2n rows and 2m columns in the output
 *  image.  The pixel color and alpha value of the output pixel at row i and column
 *  j should be computed as follows.
 *  
 *  If both i and j are even, then the color and alpha value of the output
 *  pixel are exactly the same as the input pixel at row i/2 and column j/2.
 *  
 *  If i is even but j is odd, then the color components and alpha value
 *  of the output pixel are computed as the average of those in the input pixels
 *  in row i/2 at columns floor(j/2) and floor(j/2) + 1.
 *  
 *  If i is odd and j is even, then the color components and alpha value
 *  of the output pixel are computed as the average of those in the input pixels
 *  in column j/2 at rows floor(i/2) and  floor(i/2) + 1.
 *  
 *  If both i and j are odd then the color components and alpha value
 *  of the output pixel are computed as the average of the input pixels
 *  
 *  1. At row floor(i/2) and column floor(j/2)
 *  2. At row floor(i/2) and column floor(j/2) + 1
 *  3. At row floor(i/2) + 1 and column floor(j/2)
 *  4. At row floor(i/2) + 1 and column floor(j/2) + 1
 *  
 *  Note that in the cases where either i or j is odd, it is not
 *  necessarily the case that either row floor(i/2) + 1 or
 *  column floor(j/2) + 1 are in bounds in the input image.
 *  Only input pixels that are properly in bounds should be incorporated into
 *  the averages used to determine the color components and alpha value
 *  of the output pixel.
 *  
 *  Averages should be computed using purely integer arithmetic with
 *  no rounding.
 * 
 *  @param input_img pointer to the input Image
 *  @param output_img pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 */
	.globl imgproc_expand
imgproc_expand:
	/* TODO: implement */
	ret

/*
 * Gets the 8 bits corresponding to the red component value
 *
 * Parameters:
 *   %edi - pixel color in RGBA format
 *
 * Returns:
 *    8 bits corresponding to red value
 */
	.globl get_r
get_r:
	subq $8, %rsp		/* align stack pointer */
	movl $0xFFU, %eax   /* set %eax to 0xFFU (11111111) */
	shll $24, %eax      /* left shift 24 times to get mask for red bits */
	andl %edi, %eax     /* get value of red bits with bitwise and mask */
	shrl $24, %eax      /* right shift by 24 to isolate 8-bit red value */
	addq $8, %rsp       /* restore stack pointer */
	ret

/*
 * Gets the 8 bits corresponding to the green component value
 *
 * Parameters:
 *   %edi - pixel color in RGBA format
 *
 * Returns:
 *    8 bits corresponding to green value
 */
	.globl get_g
get_g:
	subq $8, %rsp		/* align stack pointer */
	movl $0xFFU, %eax   /* set %eax to 0xFFU (11111111) */
	shll $16, %eax      /* left shift 16 times to get mask for green bits */
	andl %edi, %eax     /* get value of green bits with bitwise and mask */
	shrl $16, %eax      /* right shift by 16 to isolate 8-bit green value */
	addq $8, %rsp       /* restore stack pointer */
	ret

/*
 * Gets the 8 bits corresponding to the blue component value
 *
 * Parameters:
 *   %edi - pixel color in RGBA format
 *
 * Returns:
 *    8 bits corresponding to blue value
 */
	.globl get_b
get_b:
	subq $8, %rsp		/* align stack pointer */
	movl $0xFFU, %eax   /* set %eax to 0xFFU (11111111) */
	shll $8, %eax       /* left shift 8 times to get mask for blue bits */
	andl %edi, %eax     /* get value of blue bits with bitwise and mask */
	shrl $8, %eax       /* right shift by 8 to isolate 8-bit blue value */
	addq $8, %rsp       /* restore stack pointer */
	ret

/*
 * Gets the 8 bits corresponding to the alpha component value
 *
 * Parameters:
 *   %edi - pixel color in RGBA format
 *
 * Returns:
 *    8 bits corresponding to alpha value
 */
	.globl get_a
get_a:
	subq $8, %rsp		/* align stack pointer */
	movl $0xFFU, %eax   /* set %eax to 0xFFU (11111111) */
	andl %edi, %eax     /* get value of alpha bits with bitwise and mask */
	addq $8, %rsp       /* restore stack pointer */
	ret

/*
 * Combine individual component values into RGBA color
 *
 * Parameters:
 *   %edi - red component bits
 *	 %esi - green component bits
 *	 %edx - blue component bits
 *	 %ecx - alpha component bits 
 *
 * Returns:
 *    pixel color in RGBA format
 */
	.globl make_pixel
make_pixel:
	subq $8, %rsp   /* align stack pointer */
	shll $24, %edi	/* left shift red value by 24 */
	shll $16, %esi  /* left shift green value by 16 */
	shll $8, %edx   /* left shift blue value by 8 */
	movl $0, %eax   /* initialize RGBA color as 0 */
	orl %edi, %eax  /* add red bits */
	orl %esi, %eax  /* add green bits */
	orl %edx, %eax  /* add blue bits */
	orl %ecx, %eax  /* add alpha bits */
	addq $8, %rsp   /* restore stack pointer */
	ret

/*
 * Rotates the color of the pixel at the given index
 *
 * Parameters:
 *   %rdi - pointer to Img struct
 *	 %rsi - index of pixel we want to rotate
 *
 * Returns:
 *    rotated pixel color in RGBA format
 */
	.globl rot_colors
rot_colors:
	/*
	 * Register use:
	 *   %r12d - RGBA value of pixel at given index
	 *   %r13d - red value of given pixel
	 *   %r14d - green value of given pixel
	 *   %r15d - blue value of given pixel
	 *   %ebx - alpha value of given pixel
	 */

	/* set up ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $40, %rsp
	/* save current values of callee-saved registers on stack */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx

	movq IMAGE_DATA_OFFSET(%rdi), %r10  /* get address of data array */
	movl (%r10, %rsi, 4), %r12d         /* get color of pixel at specified index */

	movl %r12d, %edi  /* pass pixel color to argument register */
	call get_r        /* get r value */
	movl %eax, %r13d  /* save r value in %r13d */

	movl %r12d, %edi  /* pass pixel color to argument register */  
	call get_g        /* get g value */
	movl %eax, %r14d  /* save g value in %r14d */

	movl %r12d, %edi  /* pass pixel color to argument register */
	call get_b        /* get b value */
	movl %eax, %r15d  /* save b value in %r15d */

	movl %r12d, %edi  /* pass pixel color to argument register */ 
	call get_a        /* get a value */
	movl %eax, %ebx   /* save a value in %ebx */

	movl %r15d, %edi  /* b as first argument */
	movl %r13d, %esi  /* r as second argument */
	movl %r14d, %edx  /* g as third argument */
	movl %ebx, %ecx   /* a as fourth argument */
	call make_pixel   /* call function to create pixel */

	/* restore values of callee-saved registers */
	popq %rbx
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	/* restore stack */
	addq $40, %rsp
	popq %rbp
	ret

	.globl compute_index
compute_index:
	/* TODO: implement */
	ret

	.globl valid_position
valid_position:
	/* TODO: implement */
	ret

	.globl pa_init
pa_init:
	/* TODO: implement */
	ret

	.globl pa_update
pa_update:
	/* TODO: implement */
	ret

	.globl pa_update_from_img
pa_update_from_img:
	/* TODO: implement */
	ret

	.globl pa_avg_pixel
pa_avg_pixel:
	/* TODO: implement */
	ret

	.globl blur_pixel
blur_pixel:
	/* TODO: implement */
	ret

	.globl expand_pixel
expand_pixel:
	/* TODO: implement */
	ret

	.globl squash_pixel
squash_pixel:
	/*
	 * Register use:
	 *   %r12d - input width
	 *   %r13d - output width
	 *   %r14d - row
	 *   %r15d - col
	 *   %ebx - input data pointer
	 *	 %r8d - xfactor
	 *	 %r9d - yfactor
	 */

	/* set up ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $40, %rsp
	/* save current values of callee-saved registers on stack */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx

	/* preserve xfactor and yfactor */
	movl %edx, %r8d
	movl %ecx, %r9d

	
	movl IMAGE_WIDTH_OFFSET(%rdi), %r12d	/* load input width */

	movl %r12d, %eax	/* pass input width to argument register */
	cltd				/* prepare width for idiv */
	idivl %r8d			/* divide input width by xfactor to get output width */
	movl %eax, %r13d	/* store output width in register */

	movl %esi, %eax		/* pass index to argument register */
	cltd				/* prepare index for idiv */
	idivl %r13d			/* divide index by output width */
	movl %eax, %r14d	/* quotient is row */
	movl %edx, %r15d	/* remainder is col */

	imull %r9d, %r14d	/* input row = row * yfactor */
	imull %r8d, %r15d 	/* input col = col * xfactor */

	imull %r12d, %r14d	/* input row * input width */
	addl %r15d, %r14d	/* input index = above + input col */

	movq IMAGE_DATA_OFFSET(%rdi), %rbx 	/* load input data pointer */

	movl (%rbx, %r14, 4), %eax 	/* return pixel */

	/* restore values of callee-saved registers */
	popq %rbx
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	/* restore stack */
	addq $40, %rsp
	popq %rbp
	ret

/*
vim:ft=gas:
*/
