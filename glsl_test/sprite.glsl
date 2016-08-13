// by Nikos Papadopoulos, 4rknova / 2014
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/* Sprite Encoding Explained

The following is a simple, comprehensive guide that explains in
plain terms how the technique works. I started writing the shader
as a learning exercise for myself and later on realised that it 
might help others as well. I made an attempt to break down the 
technique into simple steps and deal with each step separately.
If you find that I omitted something important, made an error or
haven't explained something in the best possible way, please do
comment and let me know.

The Bigger Picture
------------------
For the time being we will limit our efforts to encoding monochrome
sprites. A pixel in a monochrome bitmap can be either on or off 
(black or white) which means that we only require a single bit of 
memory to store each pixel's value. The size of an signed integer
in glsl 1.3 or later is 32-bits (ref. M1) which in theory means 
that we can use a single integer to store 31 pixels in the form of
a literal. In practice since we are going to be using floats and due 
to the nature of the mathematical operations involved, we can only 
use 24 bits (M3).

Encoding
--------
Our goal here is to break the sprite into small blocks of 24 pixels
and then encode each block with an integral value. There are a few
options regarding the exact dimensions of the blocks.

Consider the following 4x6 bitmap which contains the character 'l' 
and is part of a very simple font sprite.

  [Bitmap]     Binary Value
   0100        010001000100010001000110
   0100
   0100        Int Literal
   0100        4473926
   0100
   0110

An alternative way to deal with encoding is do it on the fly. The
following macro will encode a 1x16 block with 2bits per pixel. 

Q(i,a,b,c,d,e,f,g,h) if(y==i)m=(a+4.*(b+4.*(c+4.*(d+4.*(e+4.*(f+4.*(g+h*4.)))))));

The first argument (i) is the row index which selects the row to 
sample from when using multiple blocks, 'y' is the current row 
index and 'm' contains the muxed row data.

For each pixel with index n we multiply by 4 (n times) to shift the
pixel data 2 bits to the left at a time and then blit the value in 
place by summation.

Decoding
--------
Now that we know how to encode the sprite blocks, we need to figure 
out how to decode them as well. Normally we would do this by shifting
the bits to the right and then using a bitwise AND operation along with
a mask to extract a single bit or a group of bits. In c that would look 
something like:

int b = (v >> k) & 1;

where v contains the literal that encodes the block data and k is the 
index of the single bit we wish to extract. The problem with the above
is that bitwise operators are not available in GLSL, so we need to find
another way of extracting the bit values.

We'll break the problem down to two steps.

a. Shifting: This is easy to solve as all we have to do is divide by 2
to shift once to the right, or the nth power of 2 to shift by n bits.

b. Masking: For positive values of x, the following is true (ref: M2): 

x % (2^n) == x & ((2^n) - 1)

Therefore for n=1, we get:

x % 2 == x & 1 

which will extract the first bit.

Combining the two together, we can retrieve the nth bit from the encoded 
data using the following formula: (v/(2^n))%2 

The Grid
--------
The only thing that remains to be solved is how to determine which 
bit needs to be extracted for the pixel that is being shaded. The
solution to this problem is simple. We quantize the screen space to
a scalable grid and then use the cell coordinates to determine the 
index of the bit to extract. As we are potentially dealing with 
multidimensional arrays, the correct index should be calculated.

The Block Size
--------------
As mentioned above, there are a few options regarding the dimensions
of the sprite blocks. We could use 1x24, 4x6 or 6x4 blocks or even 
add a 3rd dimension in a 4x3x2 arrangement to store a second frame 
as well for animation purposes. Equally, we could use a 4x5 block 
and reserve the remaining 4 bits to store some sort of metadata.

Adding Color
------------
In order to add colors we can use multiple bits per pixel to store 
a palette index or a threshold value. The process is exactly the same
with the only difference that we now need to extract 2 or more bits 
instead of a single one (ref: S1). Keep in mind that we can only use 
powers of 2 with modulo when masking.

Other Tricks
------------
* For sprites that are symmetric, we can mirror the pixels. (ref: S4)

Examples
--------
Use the EXAMPLE variable below to switch between the available examples.
1. A single 4x6 monochrome block.
2. Multiple 1x16 blocks with 2bits per pixel for palette indexing and
   sprite mirroring.

References
----------
M1. https://www.opengl.org/wiki/Data_Type_%28GLSL%29
M2. http://en.wikipedia.org/wiki/Modulo_operation
M3. http://en.wikipedia.org/wiki/IEEE_754-1985
S1. https://www.shadertoy.com/view/4dfXWj Music - Mario
S2. https://www.shadertoy.com/view/Msj3zD Super Mario Bros
S3. https://www.shadertoy.com/view/ldjGzt FlappyBird
S4. https://www.shadertoy.com/view/MsjGz1 Mario Mushroom
S5. https://www.shadertoy.com/view/4sjGD1 The Legend of Zelda
S6. https://www.shadertoy.com/view/4sXGDH Lemminvade
S7. https://www.shadertoy.com/view/ldSGRW 25 Boxes and a Tunnel
S8. https://www.shadertoy.com/view/lssGDj Ascii Art
S9. https://www.shadertoy.com/view/ls2GRt Flappy Bird

*/

#define DISPLAY_GRID 1
#define EXAMPLE      2
#define BACKGROUND   vec3(.15, .20, .25)

#define _ 0. // Color Palette Index 0
#define B 1. // Color Palette Index 1
#define D 2. // Color Palette Index 2
#define O 3. // Color Palette Index 3
#define Q(i,a,b,c,d,e,f,g,h) if(y==i)m=(a+4.*(b+4.*(c+4.*(d+4.*(e+4.*(f+4.*(g+h*4.)))))));

vec2 grid(vec2 p, vec2 sz)
{
    return floor(p * sz);    
}

// Sprite 1
vec4 l(vec2 p, vec2 scale, vec3 color)
{    
    vec2  gv = grid(p, scale); // The grid guide
    float dt = 4473926.;       // The encoded sprite
    
    vec4 res = vec4(0);
    
    if (gv.x >= 0. && gv.y >= 0. &&
        gv.x <= 3. && gv.y <= 5.) {
        
        #if (DISPLAY_GRID == 1)
            res = vec4(mod(gv.x + gv.y, 2.) * .05 + BACKGROUND, 1.);
        #endif
        
            float idx = gv.y * 4. + 3. - gv.x;      // Calculate the bit index
            float bit = mod(dt / pow(2., idx), 2.); // Decode
            bit = floor(bit);                       // Sharpen
            if (bit > 0.) res = vec4(color, 1.);
    }

    return res;
}


// Sprite 2
// Artwork from Abstract_Algorithm's - Mario mushroom
// https://www.shadertoy.com/view/MsjGz1
vec3 mushroom(vec2 p, vec2 scale)
{
    vec3 res = BACKGROUND;

    vec2 gv = grid(p, scale); // The grid guide
    
    if (gv.x >= 0. && gv.y >= 0. &&
        gv.x <= 15. && gv.y <= 15.) {
        
        #if (DISPLAY_GRID == 1)
            res = vec3(mod(gv.x + gv.y, 2.) * .05 + BACKGROUND);
        #endif
        
        // Indexing is upside down.
        int y = int(scale.y - gv.y - 5.);

        float m = 0.;
        Q(0, _,_,_,_,_,B,B,B)
        Q(1, _,_,_,B,B,B,D,O)
        Q(2, _,_,B,B,D,D,D,O)
        Q(3, _,B,B,O,D,D,O,O)
        Q(4, _,B,D,O,O,O,O,O)
        Q(5, B,B,D,D,O,O,D,D)
        Q(6, B,D,D,D,O,D,D,D)
        Q(7, B,D,D,D,O,D,D,D)
        Q(8, B,D,D,O,O,D,D,D)
        Q(9, B,O,O,O,O,O,D,D)
        Q(10,B,O,O,B,B,B,B,B)
        Q(11,B,B,B,B,D,D,B,D)
        Q(12,_,B,B,D,D,D,B,D)
        Q(13,_,_,B,D,D,D,D,D)
        Q(14,_,_,B,B,D,D,D,D)
        Q(15,_,_,_,B,B,B,B,B)
        
        float ldx = 15. - gv.x; // Calculate the left  bit index
        float rdx = gv.x;       // Calculate the right bit index
        float bit = 0.;
        
        if (gv.x >= 8.) bit = mod(m / pow(4., ldx), 4.); // Decode
        else            bit = mod(m / pow(4., rdx), 4.); // Mirror
        bit = floor(bit);                                // Sharpen    
        
        // Colorize
             if (bit > 2.) res = vec3(1,0,0);
        else if (bit > 1.) res = vec3(1);
        else if (bit > 0.) res = vec3(0);
    }
    
    return res;
}

vec3 example_1(vec2 p)
{
    vec4 r = l(p - vec2(0.35,.1), vec2(99.), vec3(1,0,0))
           + l(p - vec2(0.44,.1), vec2(70.), vec3(1,1,0))
           + l(p - vec2(0.55,.1), vec2(40.), vec3(0,1,0))
           + l(p - vec2(0.70,.1), vec2(30.), vec3(0,1,1))
           + l(p - vec2(0.90,.1), vec2(20.), vec3(0,0,1))
           + l(p - vec2(1.20,.1), vec2(10.), vec3(1,1,1));
    
    return r.w == 1. ? r.xyz : BACKGROUND;
}

vec3 example_2(vec2 p)
{
    return mushroom(p - vec2(.5, .1), vec2(20.));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy 
            * vec2(iResolution.x / iResolution.y, 1.);
    
    vec3 res = BACKGROUND;
    
         if (EXAMPLE==1) res = example_1(uv);
    else if (EXAMPLE==2) res = example_2(uv);
    
    fragColor = vec4(res, 1);
}