
// ------------------ channel define
// 0_# bufferFULL_brickA #_0
// ------------------

// https://www.shadertoy.com/view/MddGzf

// Created by inigo quilez - iq/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

//
// Game rendering. Regular 2D distance field rendering.
//


// storage register/texel addresses
const vec2 txBallPosVel = vec2(0.0,0.0);
const vec2 txPaddlePos  = vec2(1.0,0.0);
const vec2 txPoints     = vec2(2.0,0.0);
const vec2 txState      = vec2(3.0,0.0);
const vec2 txLastHit    = vec2(4.0,0.0);
const vec4 txBricks     = vec4(0.0,1.0,13.0,12.0);

const float ballRadius = 0.035;
const float paddleSize = 0.30;
const float paddleWidth = 0.06;
const float paddlePosY  = -0.90;
const float brickW = 2.0/13.0;
const float brickH = 1.0/15.0;

//----------------

const vec2 shadowOffset = vec2(-0.03,0.03);

//=================================================================================================
// distance functions
//=================================================================================================

float udSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float udHorizontalSegment( in vec2 p, in float xa, in float xb, in float y )
{
    vec2 pa = p - vec2(xa,y);
    float ba = xb - xa;
    pa.x -= ba*clamp( pa.x/ba, 0.0, 1.0 );
    return length( pa );
}

float udRoundBox( vec2 p, vec2 c, vec2 b, float r )
{
  return length(max(abs(p-c)-b,0.0))-r;
}

//=================================================================================================
// utility
//=================================================================================================

float hash1( float n )
{
    return fract(sin(n)*138.5453123);
}

float SampleDigit(const in float n, const in vec2 vUV)
{
    if( abs(vUV.x-0.5)>0.5 || abs(vUV.y-0.5)>0.5 ) return 0.0;

    // digit data by P_Malin (https://www.shadertoy.com/view/4sf3RN)
    float data = 0.0;
         if(n < 0.5) data = 7.0 + 5.0*16.0 + 5.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    else if(n < 1.5) data = 2.0 + 2.0*16.0 + 2.0*256.0 + 2.0*4096.0 + 2.0*65536.0;
    else if(n < 2.5) data = 7.0 + 1.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 3.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 4.5) data = 4.0 + 7.0*16.0 + 5.0*256.0 + 1.0*4096.0 + 1.0*65536.0;
    else if(n < 5.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
    else if(n < 6.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
    else if(n < 7.5) data = 4.0 + 4.0*16.0 + 4.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 8.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    else if(n < 9.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    
    vec2 vPixel = floor(vUV * vec2(4.0, 5.0));
    float fIndex = vPixel.x + (vPixel.y * 4.0);
    
    return mod(floor(data / pow(2.0, fIndex)), 2.0);
}

float PrintInt( in vec2 uv, in float value )
{
    float res = 0.0;
    float maxDigits = 1.0+ceil(.01+log2(value)/log2(10.0));
    float digitID = floor(uv.x);
    if( digitID>0.0 && digitID<maxDigits )
    {
        float digitVa = mod( floor( value/pow(10.0,maxDigits-1.0-digitID) ), 10.0 );
        res = SampleDigit( digitVa, vec2(fract(uv.x), uv.y) );
    }

    return res;
}

//=================================================================================================

float doBrick( in vec2 id, out vec3 col, out float glo, out vec2 cen )
{
    float alp = 0.0;
    
    glo = 0.0;
    col = vec3(0.0);
    cen = vec2(0.0);
    
    //if( id.x>=0.0 && id.x<13.0 && id.y>=0.0 && id.y<12.0 )
    if( abs(id.x-6.0)<=6.5 && abs(id.y-5.5)<6.0 )
    {
        vec2 brickHere = texture2D( iChannel0, (txBricks.xy+id+0.5)/iChannelResolution[0].xy, -100.0 ).xy;

        alp = 1.0;
        glo = 0.0;
        if( brickHere.x < 0.5 )
        {
            float t = max(0.0,iGlobalTime-brickHere.y-0.1);
            alp = exp(-2.0*t );
            glo = exp(-4.0*t );
        }
         
        if( alp>0.001 )
        {
            float fid = hash1(id.x*3.0 + id.y*16.0);
            col = vec3(0.5,0.5,0.6) + 0.4*sin( fid*2.0 + 4.5 + vec3(0.0,1.0,1.0) );
            if( hash1(fid*13.1)>0.85 )
            {
                col = 1.0 - 0.9*col;
                col.xy += 0.2;
            }
        }
        
        cen = vec2( -1.0 + float(id.x)*brickW + 0.5*brickW,
                     1.0 - float(id.y)*brickH - 0.5*brickH );
    }

    return alp;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (-iResolution.xy + 2.0*fragCoord.xy) / iResolution.y;
    float px = 2.0/iResolution.y;
    
    //------------------------
    // load game state
    //------------------------
    vec2  ballPos   = texture2D( iChannel0, (txBallPosVel+0.5)/iChannelResolution[0].xy ).xy;
    float paddlePos = texture2D( iChannel0, (txPaddlePos+0.5)/iChannelResolution[0].xy ).x;
    float points    = texture2D( iChannel0, (txPoints+0.5)/iChannelResolution[0].xy ).x;
    float state     = texture2D( iChannel0, (txState+0.5)/iChannelResolution[0].xy ).x;
    vec3  lastHit   = texture2D( iChannel0, (0.5+txLastHit)/iChannelResolution[0].xy, -100.0 ).xyz;

    
    //------------------------
    // draw
    //------------------------
    vec3 col = vec3(0.0);
    vec3 emi = vec3(0.0);
    
    // board
    {
        col = 0.6*vec3(0.4,0.6,0.7)*(1.0-0.4*length( uv ));
        col *= 1.0 - 0.1*smoothstep( 0.0,1.0,sin(uv.x*80.0)*sin(uv.y*80.0))*(1.0 - smoothstep( 1.0, 1.01, abs(uv.x) ) );
    }    

    // bricks
    {
        float b = brickW*0.17;

        // soft shadow
        {
            vec2 st = uv + shadowOffset;
            vec2 id = floor( vec2( (1.0+st.x)/brickW, (1.0-st.y)/brickH) );

            vec3 bcol; vec2 bcen; float bglo;

            float sha = 0.0;
            for( int j=-1; j<=1; j++ )
            for( int i=-1; i<=1; i++ )
            {
                vec2 idr = id + vec2(float(i), float(j) );
                float alp = doBrick( idr, bcol, bglo, bcen );
                float f = udRoundBox( st, bcen, 0.5*vec2(brickW,brickH)-b, b );
                float s = 1.0 - smoothstep( -brickH*0.5, brickH*1.0, f ); 
                s = mix( 0.0, s, alp );
                sha = max( sha, s );
            }
            col = mix( col, col*0.4, sha );
        }
    

        vec2 id = floor( vec2( (1.0+uv.x)/brickW, (1.0-uv.y)/brickH) );
        
        // shape
        {
            vec3 bcol; vec2 bcen; float bglo;
            float alp = doBrick( id, bcol, bglo, bcen );
            if( alp>0.0001 )
            {
                float f = udRoundBox( uv, bcen, 0.5*vec2(brickW,brickH)-b, b );
                bglo  += 0.6*smoothstep( -4.0*px, 0.0, f );

                bcol *= 0.7 + 0.3*smoothstep( -4.0*px, -2.0*px, f );
                bcol *= 0.5 + 1.7*bglo;
                col = mix( col, bcol, alp*(1.0-smoothstep( -px, px, f )) );
            }
        }
        
        // gather glow
        for( int j=-1; j<=1; j++ )
        for( int i=-1; i<=1; i++ )
        {
            vec2 idr = id + vec2(float(i), float(j) );
            vec3 bcol = vec3(0.0); vec2 bcen; float bglo;
            float alp = doBrick( idr, bcol, bglo, bcen );
            float f = udRoundBox( uv, bcen, 0.5*vec2(brickW,brickH)-b, b );
            emi += bcol*bglo*exp(-600.0*f*f);
        }
    }    
    
    
    // ball 
    {
        float hit = exp(-4.0*(iGlobalTime-lastHit.y) );

        // shadow
        float f = 1.0-smoothstep( ballRadius*0.5, ballRadius*2.0, length( uv - ballPos + shadowOffset ) );
        col = mix( col, col*0.4, f );

        // shape
        f = length( uv - ballPos ) - ballRadius;
        vec3 bcol = vec3(1.0,0.6,0.2);
        bcol *= 1.0 + 0.7*smoothstep( -3.0*px, -1.0*px, f );
        bcol *= 0.7 + 0.3*hit;
        col = mix( col, bcol, 1.0-smoothstep( 0.0, px, f ) );
        
        emi  += bcol*0.75*hit*exp(-500.0*f*f );
    }
    
    
    // paddle
    {
        float hit = exp(-4.0*(iGlobalTime-lastHit.x) ) * sin(20.0*(iGlobalTime-lastHit.x));
        float hit2 = exp(-4.0*(iGlobalTime-lastHit.x) );
        float y = uv.y + 0.04*hit * (1.0-pow(abs(uv.x-paddlePos)/(paddleSize*0.5),2.0));

        // shadow
        float f = udHorizontalSegment( vec2(uv.x,y)+shadowOffset, paddlePos-paddleSize*0.5,paddlePos+paddleSize*0.5,paddlePosY );
        f = 1.0-smoothstep( paddleWidth*0.5*0.5, paddleWidth*0.5*2.0, f );
        col = mix( col, col*0.4, f );

        // shape
        f = udHorizontalSegment( vec2(uv.x,y), paddlePos-paddleSize*0.5, paddlePos+paddleSize*0.5,paddlePosY ) - paddleWidth*0.5;
        vec3 bcol = vec3(1.0,0.6,0.2);
        bcol *= 1.0 + 0.7*smoothstep( -3.0*px, -1.0*px, f );
        bcol *= 0.7 + 0.3*hit2;
        col = mix( col, bcol, 1.0-smoothstep( -px, px, f ) );
        emi  += bcol*0.75*hit2*exp( -500.0*f*f );

    }

    
    // borders
    {
        float f = abs(abs(uv.x)-1.02);
        f = min( f, udHorizontalSegment(uv,-1.0,1.0,1.0) );
        f *= 2.0;
        float a = 0.8 + 0.2*sin(2.6*iGlobalTime) + 0.1*sin(4.0*iGlobalTime);
        float hit  = exp(-4.0*(iGlobalTime-lastHit.z) );
        //
        a *= 1.0-0.3*hit;
        col += a*0.5*vec3(0.6,0.30,0.1)*exp(- 30.0*f*f);
        col += a*0.5*vec3(0.6,0.35,0.2)*exp(-150.0*f*f);
        col += a*1.7*vec3(0.6,0.50,0.3)*exp(-900.0*f*f);
    }
    
    // score
    {
        float f = PrintInt( (uv-vec2(-1.5,0.8))*10.0, points );
        col = mix( col, vec3(1.0,1.0,1.0), f );
    }
    
    
    // add emmission
    col += emi;
    

    //------------------------
    // game over
    //------------------------
    col = mix( col, vec3(1.0,0.5,0.2), state * (0.5+0.5*sin(30.0*iGlobalTime)) );

    fragColor = vec4(col,1.0);
}