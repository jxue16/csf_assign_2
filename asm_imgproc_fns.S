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

/* Offsets for PixelAverager struct */
#define PA_R_OFFSET 0
#define PA_G_OFFSET 4
#define PA_B_OFFSET 8
#define PA_A_OFFSET 12
#define PA_COUNT_OFFSET 16

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
	subq $8, %rsp
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
	addq $8, %rsp
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
	subq $8, %rsp
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
		addq $8, %rsp
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
	/*
	 * Register use:
	 *   %r12 - pointer to input Image
	 *   %r13d - index of current pixel
	 *   %r14d - blur distance
	 *   %r15d - outer loop counter
	 *   %ebx - inner loop counter
	 *
	 * Memory use:
	 *   -48(%rbp) - base of output Image address
	 */

	/* set up ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp
	/* save current values of callee-saved registers on stack */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx

	movq %rdi, %r12   /* save pointer to input Image */
	pushq %rsi        /* save pointer to output Image on stack */
	movl %edx, %r14d  /* save blur distance */

	movl $0, %r15d  /* initially set outer loop counter to 0 */

	.Louter_top_imgproc_blur:
		movl IMAGE_HEIGHT_OFFSET(%r12), %r10d  /* get height of Image */
		cmpl %r10d, %r15d  /* compare outer loop counter to height */
		jge .Louter_done_imgproc_blur  /* terminate loop if counter >= height */

		movl $0, %ebx  /* initially set inner loop counter to 0 */

	.Linner_top_imgproc_blur:
		movl IMAGE_WIDTH_OFFSET(%r12), %r11d  /* get width of Image */
		cmpl %r11d, %ebx  /* compare inner loop counter to width */
		jge .Linner_done_imgproc_blur  /* terminate loop if counter >= width */

		movq %r12, %rdi     /* 1st arg = pointer to input Image */
		movl %r15d, %esi    /* 2nd arg = pixel row */
		movl %ebx, %edx     /* 3rd arg = pixel column */
		call compute_index  /* get linear index of this pixel */
		movl %eax, %r13d    /* store index */

		movq %r12, %rdi     /* 1st arg = pointer to input Image */
		movl %r15d, %esi    /* 2nd arg = pixel row */
		movl %ebx, %edx     /* 3rd arg = pixel column */
		movl %r14d, %ecx    /* 4th arg = blur distance */
		call blur_pixel     /* get blurred pixel, store in %eax */

		movq -48(%rbp), %r8               /* get pointer to output Image */
		movq IMAGE_DATA_OFFSET(%r8), %r9  /* get data array of output Image */
		movl %eax, (%r9, %r13, 4)         /* store blurred pixel in output Image */

		incl %ebx                     /* increment inner loop counter */
		jmp .Linner_top_imgproc_blur  /* start next inner loop */

	.Linner_done_imgproc_blur:
		incl %r15d                    /* increment outer loop counter */
		jmp .Louter_top_imgproc_blur  /* start next outer loop */

	.Louter_done_imgproc_blur:
		/* restore values of callee-saved registers */
		popq %rsi
		popq %rbx
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		/* restore stack */
		popq %rbp
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
	/*
	* Register use:
	*   %r12d - total output pixels
	*   %r13d - index counter
	*   %r14  - input image pointer
	*   %r15  - output image pointer
	*   %rbx  - pointer to output data array
	*/

	/* set up ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	/* save callee-saved registers */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx

	movq %rdi, %r14        /* save input image in r14 */
	movq %rsi, %r15        /* save output image in r15 */

	movl IMAGE_WIDTH_OFFSET(%r14), %eax   /* input width */
	shll $1, %eax                         /* output width = input width * 2 */
	movl IMAGE_HEIGHT_OFFSET(%r14), %edx  /* input height */
	shll $1, %edx                         /* output height = input height * 2 */
	imull %edx, %eax                      /* total output pixels = output width * output height */
	movl %eax, %r12d                      /* save total output pixels in r12d */

	movq IMAGE_DATA_OFFSET(%r15), %rbx    /* save pointer to output data array */
	movl $0, %r13d                        /* initialize loop counter to 0 */

	.Ltop_expand:
		cmpl %r12d, %r13d
		jge .Ldone_expand        /* end loop if index >= no. of pixels */

		movq %r14, %rdi          /* set 1st argument register as pointer to input */
		movl %r13d, %esi         /* set 2nd argument register as current index */
		call expand_pixel        /* compute expanded pixel from input */

		movl %eax, (%rbx, %r13, 4)  /* save current pixel */

		incl %r13d               /* increment index */
		jmp .Ltop_expand         /* return to top of loop */

	.Ldone_expand:
		/* restore values of callee-saved registers */
		popq %rbx
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		/* restore stack */
		addq $8, %rsp
		popq %rbp
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
	subq $8, %rsp
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
	addq $8, %rsp
	popq %rbp
	ret

/*
 * Gets the row-major linear index for a pixel at position (row, col)
 *
 * Parameters:
 *   %rdi - pointer to Image struct
 *	 %esi - pixel row
 *	 %edx - pixel column
 *
 * Returns:
 *    linear index of target pixel
 */
	.globl compute_index
compute_index:
	subq $8, %rsp		                 /* align stack pointer */
	movl IMAGE_WIDTH_OFFSET(%rdi), %eax  /* get width of image */
	imull %esi, %eax                     /* multiply row * image width */
	addl %edx, %eax                      /* add column to get linear index */
	addq $8, %rsp                        /* restore stack pointer */
	ret

/*
 * Determines if the position (row, col) is valid for the given Image
 *
 * Parameters:
 *   %rdi - pointer to Image struct
 *	 %esi - pixel row
 *	 %edx - pixel column
 *
 * Returns:
 *    1 if position valid, 0 otherwise
 */
	.globl valid_position
valid_position:
	subq $8, %rsp                          /* align stack pointer */
	movl IMAGE_WIDTH_OFFSET(%rdi), %r10d   /* get image width */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %r11d  /* get image height */
	
	/* if any of these comparions are true, position is invalid */
	cmpl $0, %esi
	jl .Lvalid_position_false   /* row < 0 */
	cmpl %r11d, %esi
	jge .Lvalid_position_false  /* row >= image height */
	cmpl $0, %edx
	jl .Lvalid_position_false   /* column < 0 */
	cmpl %r10d, %edx
	jge .Lvalid_position_false  /* column >= image width */

	/* if we reach this point, position is valid */
	movl $1, %eax
	addq $8, %rsp
	ret
	
	.Lvalid_position_false:   /* position invalid */
		movl $0, %eax
		addq $8, %rsp
		ret

/*
 * Initialize a PixelAverager instance. All fields initially set to 0
 *
 * Parameters:
 *   %rdi - pointer to PixelAverager
 */
	.globl pa_init
pa_init:
	subq $8, %rsp
	/* set all fields of PixelAverager to 0 */
	movl $0, PA_R_OFFSET(%rdi)
	movl $0, PA_G_OFFSET(%rdi)
	movl $0, PA_B_OFFSET(%rdi)
	movl $0, PA_A_OFFSET(%rdi)
	movl $0, PA_COUNT_OFFSET(%rdi)
	addq $8, %rsp
	ret

/*
 * Update PixelAverager values with values in given pixel
 *
 * Parameters:
 *   %rdi - pointer to PixelAverager
 *   %esi - pixel value to update with
 */
	.globl pa_update
pa_update:
	/*
	 * Register use:
	 *   %r12  - pointer to PixelAverager
	 *   %r13d - pixel value
	 */

	/* set up ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp
	/* save current values of callee-saved registers on stack */
	pushq %r12
	pushq %r13

	movq %rdi, %r12   /* save pointer to PixelAverager */
	movl %esi, %r13d  /* save pixel value */

	movl %r13d, %edi
	call get_r
	addl %eax, PA_R_OFFSET(%r12)  /* add R value of pixel to PixelAverager */

	movl %r13d, %edi
	call get_g
	addl %eax, PA_G_OFFSET(%r12)  /* add G value of pixel to PixelAverager */

	movl %r13d, %edi
	call get_b
	addl %eax, PA_B_OFFSET(%r12)  /* add B value of pixel to PixelAverager */

	movl %r13d, %edi
	call get_a
	addl %eax, PA_A_OFFSET(%r12)  /* add A value of pixel to PixelAverager */

	incl PA_COUNT_OFFSET(%r12)    /* increment PixelAverager count */

	/* restore values of callee-saved registers */
	popq %r13
	popq %r12
	/* restore stack */
	popq %rbp
	ret

/*
 * Update PixelAverager with pixel at position (row, col) in given Image
 * Do not update if position is out of bounds
 *
 * Parameters:
 *   %rdi - pointer to PixelAverager
 *   %rsi - pointer to Image
 *   %edx - pixel row
 *   %ecx - pixel column
 */
	.globl pa_update_from_img
pa_update_from_img:
	/*
	 * Register use:
	 *   %r12  - pointer to PixelAverager
	 *   %r13  - pointer to Image
	 *   %r14d - pixel row
	 *   %r15d - pixel column
	 */

	/* set up ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp
	/* save current values of callee-saved registers on stack */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

	movq %rdi, %r12   /* save pointer to PixelAverager */
	movq %rsi, %r13   /* save pointer to Image */
	movl %edx, %r14d  /* save pixel row */
	movl %ecx, %r15d  /* save pixel column */

	/* check that pixel has valid position */
	movq %r13, %rdi               /* first argument = pointer to Image */
	movl %r14d, %esi              /* second argument = pixel row */
	movl %r15d, %edx              /* third argument = pixel column */
	call valid_position
	cmpl $0, %eax
	je .Ldone_pa_update_from_img  /* if function call returned 0, invalid */

	/* get index of pixel we want to update with */
	movq %r13, %rdi     /* first argument = pointer to Image */
	movl %r14d, %esi    /* second argument = pixel row */
	movl %r15d, %edx    /* third argument = pixel column */
	call compute_index  /* %rax now holds pixel index */

	/* update PixelAverager with this pixel */
	movq %r12, %rdi                     /* first argument = pointer to PixelAverager */
	movq IMAGE_DATA_OFFSET(%r13), %r10  /* get Image data array */
	movl (%r10, %rax, 4), %esi          /* second argument = element at pixel index */
	call pa_update

	.Ldone_pa_update_from_img:
		/* restore values of callee-saved registers */
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		/* restore stack */
		popq %rbp
		ret

/*
 * Return a pixel that is the average of all pixels used to update PixelAverager
 *
 * Parameters:
 *   %rdi - pointer to PixelAverager
 *
 * Returns:
 *    pixel whose red, green, blue, and alpha values are the average of
 *    all the pixels used to update PixelAverager
 */
	.globl pa_avg_pixel
pa_avg_pixel:
	subq $8, %rsp  /* align stack pointer */

	movl PA_COUNT_OFFSET(%rdi), %ecx  /* get pixel count */

	movl $0, %edx
	movl PA_R_OFFSET(%rdi), %eax  /* dividend = total R value */
	divl %ecx                     /* compute (R value)/(pixel count) */
	movl %eax, %r8d               /* store quotient */

	movl $0, %edx
	movl PA_G_OFFSET(%rdi), %eax  /* dividend = total G value */
	divl %ecx                     /* compute (G value)/(pixel count) */
	movl %eax, %r9d               /* store quotient */

	movl $0, %edx
	movl PA_B_OFFSET(%rdi), %eax  /* dividend = total B value */
	divl %ecx                     /* compute (B value)/(pixel count) */
	movl %eax, %r10d              /* store quotient */

	movl $0, %edx
	movl PA_A_OFFSET(%rdi), %eax  /* dividend = total A value */
	divl %ecx                     /* compute (A value)/(pixel count) */
	movl %eax, %r11d              /* store quotient */

	movl %r8d, %edi   /* first argument = avg R value */
	movl %r9d, %esi   /* second argument = avg G value */
	movl %r10d, %edx  /* third argument = avg B value */ 
	movl %r11d, %ecx  /* fourth argument = avg A value */
	call make_pixel   /* make pixel with average values */

	addq $8, %rsp  /* restore stack pointer */
	ret

/*
 * Blur the pixel at the given position
 *
 * Parameters:
 *   %rdi - pointer to Image
 *   %esi - pixel row
 *   %edx - pixel column
 *   %ecx - blur distance
 * 
 * Returns:
 *    blurred pixel
 */
	.globl blur_pixel
blur_pixel:
	/*
	 * Register use:
	 *   %r12d - pixel row, blurred R value
	 *   %r13d - pixel column, blurred G value
	 *   %r14d - blur distance, blurred B value
	 *   %r15d - outer loop counter, A value
	 *   %ebx - inner loop counter, averaged pixel
	 *
	 * Memory use:
     * -20(%rbp) - base address of PixelAverager instance
     * -72(%rbp) - base address of Image struct
	 */

	/* set up ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $24, %rsp
	/* save current values of callee-saved registers on stack */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx

	pushq %rdi        /* save pointer to Image on stack */
	movl %esi, %r12d  /* save pixel row */
	movl %edx, %r13d  /* save pixel column */
	movl %ecx, %r14d  /* save blur distance */

	leaq -20(%rbp), %rdi  /* 1st arg = address of PixelAverager */
	call pa_init          /* initialize PixelAverager */

	movl %r12d, %r15d  /* initially set outer loop counter to # rows */
	subl %r14d, %r15d  /* subtract blur distance from outer loop counter */

	.Louter_top_blur_pixel:
		movl %r12d, %r10d
		addl %r14d, %r10d  /* %r10d now holds value row + blur distance */
		cmpl %r10d, %r15d  /* compare outer loop counter to row + blur distance */
		jg .Louter_done_blur_pixel  /* terminate loop if counter > row + blur distance */

		movl %r13d, %ebx  /* initially set inner loop counter to # cols */
		subl %r14d, %ebx  /* subtract blur distance from inner loop counter */

	.Linner_top_blur_pixel:
		movl %r13d, %r11d
		addl %r14d, %r11d  /* %r11d now holds col + blur distance */
		cmpl %r11d, %ebx   /* compare inner loop counter to col + blur distance */
		jg .Linner_done_blur_pixel  /* terminate loop if counter > col + blur distance */

		leaq -20(%rbp), %rdi     /* 1st arg = pointer to PixelAverager */
		movq -72(%rbp), %rsi     /* 2nd arg = pointer to Image */
		movl %r15d, %edx         /* 3rd arg = pixel row */
		movl %ebx, %ecx          /* 4th arg = pixel column */
		call pa_update_from_img  /* update PixelAverager */

		incl %ebx                   /* increment inner loop counter */
		jmp .Linner_top_blur_pixel  /* start next inner loop */

	.Linner_done_blur_pixel:
		incl %r15d                  /* increment outer loop counter */
		jmp .Louter_top_blur_pixel  /* start next outer loop */

	.Louter_done_blur_pixel:
	/* get linear index of pixel */
	movq -72(%rbp), %rdi  /* 1st arg = pointer to Image */
	movl %r12d, %esi      /* 2nd arg = pixel row */
	movl %r13d, %edx      /* 3rd arg = pixel column */
	call compute_index    /* after call, index stored in %rax */

	/* get alpha value */
	movq -72(%rbp), %r10                /* get pointer to Image */
	movq IMAGE_DATA_OFFSET(%r10), %r11  /* get Image data array */
	movl (%r11, %rax, 4), %edi          /* 1st arg = element at pixel's index */
	call get_a
	movl %eax, %r15d                    /* save alpha value */

	/* get averaged pixel */
	leaq -20(%rbp), %rdi  /* 1st arg = pointer to PixelAverager */
	call pa_avg_pixel     /* call function for averaging pixel */
	movl %eax, %ebx       /* save averaged pixel */

	/* get red value */
	movl %ebx, %edi   /* 1st arg = averaged pixel */
	call get_r
	movl %eax, %r12d  /* save red value */

	/* get green value */
	movl %ebx, %edi   /* 1st arg = averaged pixel */
	call get_g
	movl %eax, %r13d  /* save green value */

	/* get blue value */
	movl %ebx, %edi   /* 1st arg = averaged pixel */
	call get_b
	movl %eax, %r14d  /* save blue value */

	/* make pixel with blurred values */
	movl %r12d, %edi  /* 1st arg = red value */
	movl %r13d, %esi  /* 2nd arg = green value */
	movl %r14d, %edx  /* 3rd arg = blue value */
	movl %r15d, %ecx  /* 4th arg = alpha value */
	call make_pixel

	/* restore values of callee-saved registers */
	popq %rdi
	popq %rbx
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	/* restore stack */
	addq $24, %rsp
	popq %rbp
	ret

	.globl expand_pixel
expand_pixel:
	/*
	 * Register use:
	 *   %r12d - input width
	 *   %r13d - output width
	 *   %r14d - row
	 *   %r15d - col
	 *   %ebx - input data pointer
	 * Memory use:
	 *	-8(%rbp)  - pointer to input image
	 */

	/* set up ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	/* save callee-saved registers */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx

	movq %rdi, -8(%rbp)		/* save input image pointer on stack */

	movl IMAGE_WIDTH_OFFSET(%rdi), %r15d	/* input width */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %ebx	/* input height */

	movl %r15d, %r14d		/* output width = input width * 2 */
	shll $1, %r14d

	movl %esi, %eax			/* set dividend to output index */
	cltd					/* prepare width for idiv */
	idivl %r14d				/* divide index by output width */
	movl %eax, %r12d		/* quotient = output row (i) */
	movl %edx, %r13d		/* remainder = output col (j) */

	/* begin 4 cases using parity of i and j */
	movl %r12d, %eax
	andl $1, %eax				/* eax = (i is odd) */
	movl %r13d, %ecx
	andl $1, %ecx				/* ecx = (j is odd) */

	cmpl $0, %eax
	jne .Li_odd_expand_pixel	/* i is odd */

	/* if get here, i is even */
	cmpl $0, %ecx
	jne .Li_even_j_odd_expand_pixel	/* i is even, j is odd */

	/* case 1: i is even, j is even */
	movl %r12d, %esi		/* input row = i/2 */
	sarl $1, %esi
	movl %r13d, %edx		/* input col = j/2 */
	sarl $1, %edx
	movq -8(%rbp), %rdi		/* pointer to input image */
	call compute_index		/* get linear index */
	movq -8(%rbp), %r10
	movq IMAGE_DATA_OFFSET(%r10), %r11
	movl (%r11, %rax, 4), %eax	/* return pixel at (i/2, j/2) */
	jmp .Ldone_expand_pixel

.Li_even_j_odd_expand_pixel:
	/* case 2: i is even, j is odd */
	subq $32, %rsp					/* allocate bytes for PixelAverager */
	leaq (%rsp), %rdi				/* pointer to PixelAverager */
	call pa_init

	movl %r12d, %r8d
	sarl $1, %r8d					/* input row = i/2 */
	movl %r13d, %r9d
	sarl $1, %r9d					/* input col = floor(j/2) */

	leaq (%rsp), %rdi				/* 1st arg = pointer to PixelAverager */
	movq -8(%rbp), %rsi				/* 2nd arg = pointer to image */
	movl %r8d, %edx					/* 3rd arg = row */
	movl %r9d, %ecx					/* 4th arg = col */
	call pa_update_from_img

	leaq (%rsp), %rdi				/* same call as above but with 4th arg as col + 1 */
	movq -8(%rbp), %rsi
	movl %r8d, %edx
	leal 1(%r9d), %ecx				/* 4th arg = col + 1 */
	call pa_update_from_img

	leaq (%rsp), %rdi
	call pa_avg_pixel				/* average pixel values */

	addq $32, %rsp
	jmp .Ldone_expand_pixel

.Li_odd_expand_pixel:
	/* i is odd */
	cmpl $0, %ecx
	jne .Li_odd_j_odd_expand_pixel	/* i is odd, j is odd */

	/* case 3: i is odd, j is even */
	subq $32, %rsp			/* allocate bytes for PixelAverager */
	leaq (%rsp), %rdi
	call pa_init

	movl %r12d, %r8d
	sarl $1, %r8d			/* input row = floor(i/2) */
	movl %r13d, %r9d
	sarl $1, %r9d			/* input col = j/2 */

	leaq (%rsp), %rdi		/* 1st arg = pointer to PixelAverager */
	movq -8(%rbp), %rsi		/* 2nd arg = pointer to image */
	movl %r8d, %edx			/* 3rd arg = row */
	movl %r9d, %ecx			/* 4th arg = col */
	call pa_update_from_img

	leaq (%rsp), %rdi		/* same call as above but with 3rd arg as row + 1 */
	movq -8(%rbp), %rsi
	leal 1(%r8d), %edx		/* 3rd arg = row + 1 */
	movl %r9d, %ecx
	call pa_update_from_img

	leaq (%rsp), %rdi
	call pa_avg_pixel	/* average pixel values */

	addq $32, %rsp
	jmp .Ldone_expand_pixel

.Li_odd_j_odd_expand_pixel:
	/* case 4: i is odd, j is odd */
	subq $32, %rsp			/* allocate bytes for PixelAverager */
	leaq (%rsp), %rdi
	call pa_init

	movl %r12d, %r8d
	sarl $1, %r8d			/* r8d = floor(i/2) */
	movl %r13d, %r9d
	sarl $1, %r9d			/* r9d = floor(j/2) */

	/* (floor(i/2), floor(j/2)) */
	leaq (%rsp), %rdi		/* 1st arg = pointer to PixelAverager */
	movq -8(%rbp), %rsi		/* 2nd arg = pointer to image */
	movl %r8d, %edx			/* 3rd arg = row */
	movl %r9d, %ecx			/* 4th arg = col */
	call pa_update_from_img

	/* (floor(i/2), floor(j/2)+1) */
	leaq (%rsp), %rdi		/* same call as above but with 4th arg as col + 1 */
	movq -8(%rbp), %rsi
	movl %r8d, %edx
	leal 1(%r9d), %ecx		/* 4th arg = col + 1 */
	call pa_update_from_img

	/* (floor(i/2)+1, floor(j/2)) */
	leaq (%rsp), %rdi		/* same call as first but with 3rd arg as row + 1 */
	movq -8(%rbp), %rsi
	leal 1(%r8d), %edx		/* 3rd arg = row + 1 */
	movl %r9d, %ecx
	call pa_update_from_img

	/* (floor(i/2)+1, floor(j/2)+1) */
	leaq (%rsp), %rdi		/* same call as first but with 3rd arg as row + 1, 4th arg as col + 1 */
	movq -8(%rbp), %rsi
	leal 1(%r8d), %edx		/* 3rd arg = row + 1 */
	leal 1(%r9d), %ecx		/* 4th arg = col + 1 */
	call pa_update_from_img

	leaq (%rsp), %rdi
	call pa_avg_pixel	/* average pixel values */

	addq $32, %rsp

.Ldone_expand_pixel:
	/* restore values of callee-saved registers */
	popq %rbx
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	/* restore stack */
	addq $8, %rsp
	popq %rbp
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
	subq $8, %rsp
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
	addq $8, %rsp
	popq %rbp
	ret

/*
vim:ft=gas:
*/
