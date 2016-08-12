// Simple Bitmap Text by Gerard Geer
// 
// Essentially a "hmm, how does that work?" educational rewrite of P_Malin's text renderer:
// https://www.shadertoy.com/view/4sBSWW
// Each character is a 4x5 bitmap encoded into a float, where each hex digit convieniently
// represents one row.
// License: Creative Commons CC0 1.0 Universal (CC-0) 

// https://www.shadertoy.com/view/4dtGD2


#define _f float
const lowp _f CH_A    = _f(0x69f99), CH_B    = _f(0x79797), CH_C    = _f(0xe111e),
              CH_D    = _f(0x79997), CH_E    = _f(0xf171f), CH_F    = _f(0xf1711),
              CH_G    = _f(0xe1d96), CH_H    = _f(0x99f99), CH_I    = _f(0xf444f),
              CH_J    = _f(0x88996), CH_K    = _f(0x95159), CH_L    = _f(0x1111f),
              CH_M    = _f(0x9f999), CH_N    = _f(0x9bd99), CH_O    = _f(0x69996),
              CH_P    = _f(0x79971), CH_Q    = _f(0x69b5a), CH_R    = _f(0x79759),
              CH_S    = _f(0xe1687), CH_T    = _f(0xf4444), CH_U    = _f(0x99996),
              CH_V    = _f(0x999a4), CH_W    = _f(0x999f9), CH_X    = _f(0x99699),
              CH_Y    = _f(0x99e8e), CH_Z    = _f(0xf843f), CH_0    = _f(0x6bd96),
              CH_1    = _f(0x46444), CH_2    = _f(0x6942f), CH_3    = _f(0x69496),
              CH_4    = _f(0x99f88), CH_5    = _f(0xf1687), CH_6    = _f(0x61796),
              CH_7    = _f(0xf8421), CH_8    = _f(0x69696), CH_9    = _f(0x69e84),
              CH_APST = _f(0x66400), CH_PI   = _f(0x0faa9), CH_UNDS = _f(0x0000f),
              CH_HYPH = _f(0x00600), CH_TILD = _f(0x0a500), CH_PLUS = _f(0x02720),
              CH_EQUL = _f(0x0f0f0), CH_SLSH = _f(0x08421), CH_EXCL = _f(0x33303),
              CH_QUES = _f(0x69404), CH_COMM = _f(0x00032), CH_FSTP = _f(0x00002),
              CH_QUOT = _f(0x55000), CH_BLNK = _f(0x00000), CH_COLN = _f(0x00202),
              CH_LPAR = _f(0x42224), CH_RPAR = _f(0x24442);
const lowp vec2 MAP_SIZE = vec2(4,5);
#undef flt


//    returns the status of a bit in a bitmap. This is done value-wise, so
 //   the exact representation of the float doesn't really matter.

float getBit( in float map, in float index )
{
    // Ooh -index takes out that divide :)
    return mod( floor( map*exp2(-index) ), 2.0 );
}


 //   Trades a float for a character bitmap. Here's to eliminating
 //   branches with step()!

float floatToChar( in float x )
{
    float res = CH_BLNK;
    res += (step(-.5,x)-step(0.5,x))*CH_0;
    res += (step(0.5,x)-step(1.5,x))*CH_1;
    res += (step(1.5,x)-step(2.5,x))*CH_2;
    res += (step(2.5,x)-step(3.5,x))*CH_3;
    res += (step(3.5,x)-step(4.5,x))*CH_4;
    res += (step(4.5,x)-step(5.5,x))*CH_5;
    res += (step(5.5,x)-step(6.5,x))*CH_6;
    res += (step(6.5,x)-step(7.5,x))*CH_7;
    res += (step(7.5,x)-step(8.5,x))*CH_8;
    res += (step(8.5,x)-step(9.5,x))*CH_9;
    return res;
}


//    Draws a character, given its encoded value, a position, size and
//    current [0..1] uv coordinate.

float drawChar( in float char, in vec2 pos, in vec2 size, in vec2 uv )
{
    // Subtract our position from the current uv so that we can
    // know if we're inside the bounding box or not.
    uv-=pos;
    
    // Divide the screen space by the size, so our bounding box is 1x1.
    uv /= size;    
    
    // Create a place to store the result.
    float res;
    
    // Branchless bounding box check.
    res = step(0.0,min(uv.x,uv.y)) - step(1.0,max(uv.x,uv.y));
    
    // Go ahead and multiply the UV by the bitmap size so we can work in
    // bitmap space coordinates.
    uv *= MAP_SIZE;
    
    // Get the appropriate bit and return it.
    res*=getBit( char, 4.0*floor(uv.y) + floor(uv.x) );
    return clamp(res,0.0,1.0);
}


 //   Prints a float as an int. Be very careful about overflow.
 //   This as a side effect will modify the character position,
//   so that multiple calls to this can be made without worrying
//    much about kerning.

float drawIntCarriage( in int val, inout vec2 pos, in vec2 size, in vec2 uv, in int places )
{
    // Create a place to store the current values.
    float res = 0.0,digit = 0.0;
    // Surely it won't be more than 10 chars long, will it?
    // (MAX_INT is 10 characters)
    for( int i = 0; i < 10; ++i )
    {
        // If we've run out of film, cut!
        if(val == 0 && i >= places) break;
        // The current lsd is the difference between the current
        // value and the value rounded down one place.
        digit = float( val-(val/10)*10 );
        // Draw the character. Since there are no overlaps, we don't
        // need max().
        res += drawChar(floatToChar(digit),pos,size,uv);
        // Move the carriage.
        pos.x -= size.x*1.2;
        // Truncate away this most recent digit.
        val /= 10;
    }
    return res;
}


//    Draws an integer to the screen. No side-effects, but be ever vigilant
//    so that your cup not overfloweth.

float drawInt( in int val, in vec2 pos, in vec2 size, in vec2 uv )
{
    vec2 p = vec2(pos);
    float s = sign(float(val));
    val *= int(s);
    
    float c = drawIntCarriage(val,p,size,uv,1);
    return c + drawChar(CH_HYPH,p,size,uv)*max(0.0, -s);
}


//    Prints a fixed point fractional value. Be even more careful about overflowing.

float drawFixed( in float val, in int places, in vec2 pos, in vec2 size, in vec2 uv )
{
    // modf() sure would be nice right about now.
    vec2 p = vec2(pos);
    float res = 0.0;
    
    // Draw the floating point part.
    res = drawIntCarriage( int( fract(val)*pow(10.0,float(places)) ), p, size, uv, places );
    // The decimal is tiny, so we back things up a bit before drawing it.
    p.x += size.x*.4;
    res = max(res, drawChar(CH_FSTP,p,size,uv)); p.x-=size.x*1.2;
    // And after as well.
    p.x += size.x *.1;
    // Draw the integer part.
    res = max(res, drawIntCarriage(int(floor(val)),p,size,uv,1));
    return res;
}

float text( in vec2 uv )
{
    // Set a general character size...
    vec2 charSize = vec2(.03, .0375);
    // and a starting position.
    vec2 charPos = vec2(0.05, 0.90);
    // Draw some text!
    float chr = 0.0;
    // Bitmap text rendering!
    chr += drawChar( CH_B, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_I, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_T, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_M, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_A, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_P, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_BLNK, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_T, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_E, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_X, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_T, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_BLNK, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_R, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_E, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_N, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_D, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_E, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_R, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_I, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_N, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_G, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_EXCL, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_EXCL, charPos, charSize, uv); charPos.x += .04;
    
    // Today's Date: {date}
    charPos = vec2(0.05, .75);
    chr += drawChar( CH_T, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_O, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_D, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_A, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_Y, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_APST, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_S, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_BLNK, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_D, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_A, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_T, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_E, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_BLNK, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_LPAR, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_M, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_M, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_HYPH, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_D, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_D, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_HYPH, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_Y, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_Y, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_Y, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_Y, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_RPAR, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_COLN, charPos, charSize, uv); charPos.x += .1;
    // The date itself.
    charPos.x += .3;
    chr += drawIntCarriage( int(iDate.x), charPos, charSize, uv, 4);
    chr += drawChar( CH_HYPH, charPos, charSize, uv); charPos.x-=.04;
    chr += drawIntCarriage( int(iDate.z)+1, charPos, charSize, uv, 2);
    chr += drawChar( CH_HYPH, charPos, charSize, uv); charPos.x-=.04;
    chr += drawIntCarriage( int(iDate.y)+1, charPos, charSize, uv, 2);
    
    // Shader uptime:
    charPos = vec2(0.05, .6);
    chr += drawChar( CH_I, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_G, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_L, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_O, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_B, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_A, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_L, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_T, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_I, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_M, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_E, charPos, charSize, uv); charPos.x += .04;
    chr += drawChar( CH_COLN, charPos, charSize, uv); charPos.x += .04;
    // The uptime itself.
    charPos.x += .3;
    chr += drawFixed( iGlobalTime, 2, charPos, charSize, uv);
    return chr;
}

// Shadertoy's fancy entry function.

void main(){

    // Get normalized UV coords.
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    uv.x *= iResolution.x/iResolution.y; //fix aspect ratio
    
    // Draw some text!
    float txt = text(uv);
    
    gl_FragColor = vec4(txt,txt,txt,1.0);
}