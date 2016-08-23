/*  
    A SPHERE AMID A PYRAMID
 
    Code is mainly based on
    
    https://www.shadertoy.com/view/Xs3GRB
    Uploaded by tomkh on 2015-Dec-16    
    Simple test/port of Mercury's SDF library to WebGL.
    
    Minor editing and modification by wjb. 
    Excerpted functions with my comments that were removed from this code are
    attached at the bottom of this file, as well as a program flow analysis 
    that helped me figure out what was going on in the original code, in the hope
    that someone else might find them useful.

    Additional sources:
    ===================
    HG_SDF GLSL LIBRARY FOR BUILDING SIGNED DISTANCE BOUNDS by MERCURY
    http://mercury.sexy/hg_sdf

    http://math.hws.edu/graphicsbook/demos/c7/procedural-textures.html
    https://github.com/ashima/webgl-noise

    https://www.shadertoy.com/view/lll3z4
    Gardner Cos Clouds  Uploaded by fab on 2014-Dec-24
    
    http://raymarching.com/WebGL/WebGL_ShadowsReflections.htm
    Source - Raymarching.com
    Author - Gary "Shane" Warne
    eMail - mail@Raymarching.com, mail@Labyrinth.com
    Last update: 28th Aug, 2014

    http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

*/
//==============================================================================

#define PI 3.141592653589793

const int nTerms = 10;
const int iterations = 160;
const float dist_eps = .001;
const float ray_max = 200.0;
const float fog_density = 0.001; 
const float cam_dist = 17.0;
const float eps = 0.005;

vec3 surfNormal = vec3(0.0 );
                                                           
//------------------------------------------------------------------------------
// Function declarations 
vec2 scene(vec3 p); 
float pMirror (inout float p, float dist);
float fSphere(vec3 p, float r);
float fBox(vec3 p, vec3 b);
float fCylinder(vec3 p, float r, float height);
float fOpUnionStairs(float a, float b, float r, float n);
float fCapsule(vec3 p, vec3 a, vec3 b, float r);
float snoise(vec3 v);

//------------------------------------------------------------------------------
// Triangular Prism - signed
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
// Modified from sdTriPrism()

// Prism with apex parallel to z-axis
float sdPrismZ( vec3 p, float angleRads, float height, float depth ) 
{
    // sin 60 degrees = 0.866025
    // sin 45 degrees = 0.707107
    // sin 30 degrees = 0.5
    // sin 15 degrees = 0.258819
    vec3 q = abs( p );
    return max( q.z - depth, 
           max( q.x * angleRads + p.y * 0.5, -p.y ) - height * 0.5 );
}
//------------------------------------------------------------------------------

// Prism with apex parallel to x-axis
float sdPrismX( vec3 p, float angleRads, float height, float depth ) 
{
    vec3 q = abs( p );
    return max( q.x - depth, 
           max( q.z * angleRads + p.y * 0.5, -p.y ) - height * 0.5 );                                                         
}
//------------------------------------------------------------------------------

// For a 60 degree pyramid, height must be equal to depth. If height is greater
// than depth, a square base is drawn beneath the pyramid. 

// If height is less than depth, the drawn depth will only be as large as height.

// For angles less than 60 degrees, the depth must be proportionately larger
// than the height to avoid a square base beneath the pyramid.

float sdPyramid( vec3 p, float angleRads, float height, float depth )
{
    // Limited to range of 15 to 60 degrees ( for aesthetic reasons ).
    angleRads = clamp( angleRads, 0.258819, 0.866025 );
    vec3 q = abs( p );
    
    // Intersection of prisms along two perpendicular axes.
    return max( sdPrismX( p, angleRads, height, depth ), 
                sdPrismZ( p, angleRads, height, depth ) );

}
//------------------------------------------------------------------------------

// SCENE
// -----

vec2 scene( vec3 p )
{
    // Domain Manipulation.
    //---------------------
    // Mirror at an axis-aligned plane which is at a specified distance 
    // <dist> from the origin.
    pMirror( p.x, 0.0 );
    pMirror( p.z, 0.0 );
    
    // Object initialization.
    //------------------------  
    // Center pyramid
    //---------------
    float objID = 1.0;
    vec2 pyramid = vec2( sdPyramid( p - vec3( 0.0, -0.25, 0.0 ), 0.866025, 
                                                           3.5, 3.5 ), objID );

    vec2 innerFrontPyramid = vec2( sdPyramid( p - vec3( 0.0, -0.25, 0.55 ), 
                                                0.866025, 2.6, 2.66 ), objID ); 

    vec2 innerEastPyramid = vec2( sdPyramid( p - vec3( 0.55, -0.25, 0.0 ), 
                                                0.866025, 2.6, 2.66 ), objID );     
    // Sphere inside center pyramid
    //-----------------------------
    objID = 2.0;
    vec2 centerSphere = vec2( fSphere( p - vec3( 0.0, -0.25, 0.0 ), 0.8 ), 
                                                                       objID );                
    // Sphere above center pyramid
    //----------------------------
    objID = 3.0;
    vec2 upperSphere = vec2( fSphere( p - vec3( 0.0, 5.0, 0.0 ), 0.3 ), 
                                                                       objID );     
    // Corner gazebo
    //--------------
    objID = 4.0;
    vec2 cornerBox = vec2( fBox( p - vec3( 5.0, -0.225, 5.0 ), 
                                           vec3( 0.75, 1.75, 0.75 ) ), objID );     

    vec2 boxHollow = vec2( fCapsule( p, vec3( 5.0, -1.2, 5.0 ),                                          
                                        vec3( 5.0,  0.6, 5.0 ), 0.9 ), objID );                             
    // Mound beneath corner gazebo                                                                                                             
    //----------------------------
    objID = 5.0;
    vec2 cornerMound = vec2( fSphere( p - vec3( 5.0, -4.25, 5.0 ), 3.0 ), 
                                                                       objID ); 
    vec2 sphereHide = vec2( fBox( p - vec3( 5.0, -5.0, 5.0 ),
                                              vec3( 3.1, 3.0, 3.1 ) ), objID );
    // Pyramid atop gazebo
    //--------------------
    objID = 6.0;
    vec2 cornerPyramid = vec2( sdPyramid( p - vec3( 5.0, 2.15, 5.0 ), 0.866025,
                                                         1.25, 1.25 ), objID ); 

    // Because these cutout pyramids are not at origin, like the center pyramid,
    // one for each side is necessary.
    vec2 innerFrontCornerPyramid = vec2( sdPyramid( p - vec3( 5.0, 2.15, 5.15 ), 
                                                0.866025, 1.0, 1.25 ), objID );

    vec2 innerEastCornerPyramid = vec2( sdPyramid( p - vec3( 5.15, 2.15, 5.0 ), 
                                                0.866025, 1.0, 1.25 ), objID );
                                                                
    vec2 innerBackCornerPyramid = vec2( sdPyramid( p - vec3( 5.0, 2.15, 4.85 ), 
                                                0.866025, 1.0, 1.25 ), objID );

    vec2 innerWestCornerPyramid = vec2( sdPyramid( p - vec3( 4.85, 2.15, 5.0 ), 
                                                0.866025, 1.0, 1.25 ), objID );
    // Corner sphere
    //--------------
    objID = 8.0;
    vec2 cornerSphere = vec2( fSphere( p - vec3( 5.0, 2.25, 5.0 ), 0.25 ), 
                                                                       objID );     
    // Upper corner sphere
    // -------------------
    objID = 9.0;
    vec2 upperCornerSphere = vec2( fSphere( p - vec3( 5.0, 4.0, 5.0 ), 0.15 ), 
                                                                       objID );                
    // East globe platform
    //--------------------
    objID = 16.0;
    vec2 eastGlobePlatform = vec2( fCylinder( p - vec3( 8.0, -1.95, 2.0 ),
                                                         1.25, 0.05 ), objID );     
    // East Globe
    //-----------
    objID = 10.0;
    vec2 eastGlobe = vec2( fSphere( p - vec3( 8.0, -1.0, 2.0 ), 1.0 ), objID );
    
    vec2 innerEastHollowTop = vec2( fCapsule( p, 
               vec3( 7.0, 0.0, 2.0 ), vec3( 9.0, -2.0, 2.0 ), 0.475 ), objID ); 
    
    vec2 innerEastHollowBtm = vec2( fCapsule( p, 
               vec3( 9.0, 0.0, 2.0 ), vec3( 7.0, -2.0, 2.0 ), 0.475 ), objID );
    
    vec2 innerFrontHollowTop = vec2( fCapsule( p, 
               vec3( 8.0, 0.0, 3.0 ), vec3( 8.0, -2.0, 1.0 ), 0.475 ), objID ); 
    
    vec2 innerFrontHollowBtm = vec2( fCapsule( p, 
               vec3( 8.0, 0.0, 1.0 ), vec3( 8.0, -2.0, 3.0 ), 0.475 ), objID );
    
    vec2 innerFrontHollowLeft = vec2( fCapsule( p,
              vec3( 7.0, -1.0, 3.0 ), vec3( 9.0, -1.0, 1.0 ), 0.475 ), objID );
    
    vec2 innerFrontHollowRight = vec2( fCapsule( p,
              vec3( 9.0, -1.0, 3.0 ), vec3( 7.0, -1.0, 1.0 ), 0.475 ), objID );
                
    // Pyramid above east globe
    //-------------------------
    objID = 15.0;
    vec2 globePyramid = vec2( sdPyramid( p - vec3( 8.0, 1.0, 2.0 ), 0.866025,
                                                         0.35, 0.35 ), objID ); 
    // Sphere in globe
    //----------------
    objID = 11.0;
    vec2 sphereInGlobe = vec2( fSphere( p - vec3( 8.0, -1.0, 2.0 ), 0.5 ), 
                                                                       objID );
    // Front pyramid platform
    //-----------------------
    objID = 12.0;
    vec2 frontPyramidPlatform = vec2( fCylinder( p - vec3( 0.0, -1.85, 8.0 ),
                                                         2.25, 0.15 ), objID );
    // Front pyramid
    //--------------    
    objID = 13.0;
    vec2 frontPyramid = vec2( sdPyramid( p - vec3( 0.0, -0.8, 8.0 ), 0.866025, 
                                                         1.75, 1.75 ), objID ); 
    vec2 sphereHollow = vec2( fSphere( p - vec3( 0.0, -1.5, 8.0 ), 1.5 ), 
                                                                       objID );
    // Front pyramid sphere
    objID = 14.0;
    vec2 frontPyramidSphere = vec2( fSphere( p - vec3( 0.0, -0.9, 8.0 ), 0.5 ), 
                                                                       objID );
    // Sphere above front pyramid
    objID = 17.0;
    vec2 frontPyramidUpperSphere = 
                      vec2( fSphere( p - vec3( 0.0, 2.5, 8.0 ), 0.2 ), objID );
                                                                        
    //------------------------------------------
    // Combination operations.
    
    pyramid = max( pyramid, -innerFrontPyramid );
    pyramid = max( pyramid, -innerEastPyramid );
    
    cornerMound = max( cornerMound, -sphereHide );  
    cornerBox = max( cornerBox, -boxHollow );
    
    cornerPyramid = max( cornerPyramid, -innerFrontCornerPyramid );
    cornerPyramid = max( cornerPyramid, -innerEastCornerPyramid );
    cornerPyramid = max( cornerPyramid, -innerBackCornerPyramid );
    cornerPyramid = max( cornerPyramid, -innerWestCornerPyramid );

    objID = 7.0;
    vec2 cornice = vec2( fOpUnionStairs( cornerBox.s, cornerPyramid.s,
                                                          0.25, 4.0 ), objID );

    eastGlobe = max( eastGlobe, -innerEastHollowTop );
    eastGlobe = max( eastGlobe, -innerEastHollowBtm );
    eastGlobe = max( eastGlobe, -innerFrontHollowTop );
    eastGlobe = max( eastGlobe, -innerFrontHollowBtm );
    eastGlobe = max( eastGlobe, -innerFrontHollowLeft );
    eastGlobe = max( eastGlobe, -innerFrontHollowRight );
    
    frontPyramid = max( frontPyramid, -sphereHollow );
    
    //-----------------------------------------------
    // Distance comparisons.
    //----------------------
    // Note that the line comparing 'cornice' must be placed before both 
    // 'cornerBox' and 'cornerPyramid'; otherwise it changes their color
    // and textures to its own.
    vec2 closer = pyramid.s < centerSphere.s ? pyramid : centerSphere;
    closer = pyramid.s < centerSphere.s ? pyramid : centerSphere;
    closer = closer.s < upperSphere.s ? closer : upperSphere;
    closer = closer.s < cornice.s ? closer : cornice;
    closer = closer.s < cornerBox.s ? closer : cornerBox;
    closer = closer.s < cornerPyramid.s ? closer : cornerPyramid;
    closer = closer.s < cornerMound.s ? closer : cornerMound;
    closer = closer.s < cornerSphere.s ? closer : cornerSphere;
    closer = closer.s < upperCornerSphere.s ? closer : upperCornerSphere;
    closer = closer.s < eastGlobe.s ? closer : eastGlobe;
    closer = closer.s < sphereInGlobe.s ? closer : sphereInGlobe;
    closer = closer.s < frontPyramidPlatform.s ? closer : frontPyramidPlatform;
    closer = closer.s < frontPyramid.s ? closer : frontPyramid;
    closer = closer.s < frontPyramidSphere.s ? closer : frontPyramidSphere;
    closer = closer.s < globePyramid.s ? closer : globePyramid;
    closer = closer.s < eastGlobePlatform.s ? closer : eastGlobePlatform;
    closer = closer.s < frontPyramidUpperSphere.s ? closer : 
                                                       frontPyramidUpperSphere; 
    return closer;
}

//------------------------------------------------------------------------------

// CREATE CAMERA ROTATION MATRIX
// -----------------------------

mat4 createCamRotMatrix()
{
    float ang = 0.0, 
          sinAng = 0.0, 
          cosAng = 0.0,
          rotRange = -0.0029;
    
    // Updated 2-16-16 because the shader wouldn't auto-animate until clicked into. This if/else
    // clause was intended to stop auto-animation if user was manipulating world with mouse.
    // if ( iMouse.z < 0.0 )
    if( iMouse.z < 1.0 ) 
    {
        ang = iGlobalTime * 0.2;
    }
    else
    {
        ang = ( iMouse.x - iResolution.x * 0.5 ) * rotRange;
    }
    sinAng = sin(ang); 
    cosAng = cos(ang);
    
    mat4 y_Rot_Cam_Mat = mat4( cosAng, 0.0, sinAng, 0.0,      
                                  0.0, 1.0,    0.0, 0.0,
                              -sinAng, 0.0, cosAng, 0.0,
                                  0.0, 0.0,    0.0, 1.0 );
    
    if ( iMouse.z < 0.0 )
    {
        ang = 1.5 * ( abs( 2.0 * fract( iGlobalTime * 0.01 ) - 1.0 ) - 0.25 );
    }
    else
    {
        ang = ( iMouse.y - iResolution.y * 0.5 ) * rotRange; 
    }
    sinAng = sin(ang); 
    cosAng = cos(ang);
    
    mat4 x_Rot_Cam_Mat = mat4( 1.0,     0.0,    0.0, 0.0,     
                               0.0,  cosAng, sinAng, 0.0,
                               0.0, -sinAng, cosAng, 0.0,
                               0.0,     0.0,    0.0, 1.0 );
    
    return y_Rot_Cam_Mat * x_Rot_Cam_Mat;
    
}

// end createCamRotMatrix()

//------------------------------------------------------------------------------

// GET NORMAL
// ----------

// http://raymarching.com/WebGL/WebGL_ShadowsReflections.htm

// Source - Raymarching.com
// Author - Gary "Shane" Warne
// eMail - mail@Raymarching.com, mail@Labyrinth.com
// Last update: 28th Aug, 2014

vec3 getNormal( in vec3 p ) 
{       
    vec2 e = vec2( eps, 0.0 );
    return normalize( vec3( scene( p + e.xyy ).s - scene( p - e.xyy ).s, 
                            scene( p + e.yxy ).s - scene( p - e.yxy ).s, 
                            scene( p + e.yyx ).s - scene( p - e.yyx ).s ));
}

// end getNormal()

//------------------------------------------------------------------------------

// RAYMARCH
// --------

vec4 raymarch( vec3 rayOrig, vec3 rayDir )
{
   vec3 p = rayOrig;
   vec2 nearest = vec2( 0.0 );
   float rayLength = 0.0;
   
   for( int i = 0; i < iterations; ++i ) 
   {
        nearest = scene( p );
        float dist = nearest.s;
        
        if ( dist < dist_eps )  break;      
        if ( rayLength > ray_max ) return vec4( 0.0 );
        
        p += dist * rayDir;
        rayLength += dist;
   }
   
   return vec4( p, nearest.t );
}

// end raymarch()

//------------------------------------------------------------------------------

// GET TEXTURE
// -----------

// Slightly modified and reformatted the original code from
// http://math.hws.edu/graphicsbook/demos/c7/procedural-textures.html
// by David J. Eck : http://math.hws.edu/graphicsbook/
// ---------------
// Creative Commons Attribution-Noncommercial-ShareAlike 4.0 License.

vec4 getTexture( int texNum, vec3 pos, float scale, float complexity, 
                                                  vec4 objClr, float mixVal )
{
    vec3 v = vec3( 0.0 ),
         color = vec3( 0.0 );
         
    float value = 0.0;
    
    if ( texNum == 19 )
    {
        // wjb modified Perlin Noise 3D
        // With complexity = 1.0, squiggly lines in objColor on white
        v = pos * scale;
        value = log( pow( snoise( v ), 2.0 ) ) * complexity; 
        value = 0.75 + value * 0.25;
        color = vec3( value);               
        return mix( vec4( color, 1.0 ), objClr, mixVal );                       
    }
    else if ( texNum == 20 )
    {
        // wjb modified Perlin Noise 3D
        // white squiggly lines on objClr
        v = pos * scale;
        value = inversesqrt( pow( snoise( v ), 2.0 ) ) * complexity; 
        value = 0.75 + value * 0.25;
        color = vec3( value);               
        return mix( vec4( color, 1.0 ), objClr, mixVal );
    }
    else if ( texNum == 21 )
    {                       
        // wjb modified Perlin Noise 3D
        // Blotches of objClr surrounded by very thin squiggly black lines
        // on white background
        v = pos * scale;
        value = exp( inversesqrt( pow( snoise( v ), 2.0 ) * complexity ) ); 
        value = 0.75 + value * 0.25;
        color = vec3( value);               
        return mix( vec4( color, 1.0 ), objClr, mixVal );                       
    }

    return vec4( 0.0 );
}

// end getTexture()

//------------------------------------------------------------------------------

// APPLY TEXTURE
// -------------

vec3 applyTexture( vec4 hitPosAndID )
{
    vec4 objClr = vec4( 0.0 );
    
    vec3 pos = hitPosAndID.xyz,
         base_color = vec3( 0.0 );
    
    float scale = 0.0,
          complexity = 0.0,
          mixVal = 0.0; 

    int texNum = 0,
        objNum = int ( hitPosAndID.w );
          
    //  1: pyramid
    // 11: sphere in globe
    // 12: front pyramid platform
    // 16: east globe platform  
    if ( objNum == 1 || objNum == 11 || objNum == 12 || objNum == 16 )
    {               
        texNum = 20;
        objClr = vec4( 0.15, 0.5, 1.0, 1.0 );
        scale = 1.5;
        complexity = 4.0,
        mixVal = 0.85;    
        base_color = getTexture( texNum, pos, scale, complexity, 
                                                          objClr, mixVal ).xyz;
    }       
    //  2: center sphere
    // 15: globe pyramid
    else if ( objNum == 2 || objNum == 15 )
    {
        texNum = 21;
        objClr = vec4( 0.0, 0.15, 1.0, 1.0 );
        scale = 2.0;
        complexity = 1.5,
        mixVal = 0.9;     
        base_color = getTexture( texNum, pos, scale, complexity, 
                                                          objClr, mixVal ).xyz;
    }       
    // 3: upper sphere
    else if ( objNum == 3 )
    {
        texNum = 21;
        objClr = vec4( 0.0, 0.15, 1.0, 1.0 );
        scale = 5.0;
        complexity = 5.0,
        mixVal = 0.9;     
        base_color = getTexture( texNum, pos, scale, complexity, 
                                                          objClr, mixVal ).xyz;
    }               
    // 4: corner gazebo
    else if ( objNum == 4 )
    {
        texNum = 19;
        objClr = vec4( 0.2, 0.275, 1.0, 1.0 );
        scale = 2.0;
        complexity = 0.5,
        mixVal = 0.6;     
        base_color = getTexture( texNum, pos, scale, complexity, 
                                                          objClr, mixVal ).xyz;
    }       
    // 5: mound beneath corner gazebo
    else if ( objNum == 5 || objNum == 7 )
    {   
        texNum = 19;
        objClr = vec4( 0.66, 0.66, 1.0, 1.0 );
        scale = 3.0;
        complexity = 0.75,
        mixVal = 0.5;     
        base_color = getTexture( texNum, pos, scale, complexity, 
                                                          objClr, mixVal ).xyz;
    }       
    //  6: pyramid atop corner gazebo
    // 14: front pyramid sphere
    // 17: front pyramid upper sphere
    else if ( objNum == 6 || objNum == 14 || objNum == 17 )
    {
        texNum = 20;
        objClr = vec4( 0.5, 0.4, 1.0, 1.0 );
        scale = 3.0;
        complexity = 5.0,
        mixVal = 0.85;    
        base_color = getTexture( texNum, pos, scale, complexity, 
                                                          objClr, mixVal ).xyz;
    }
    // 8: corner sphere 
    else if ( objNum == 8 )
    {
        texNum = 21;
        objClr = vec4( 0.0, 0.15, 1.0, 1.0 );
        scale = 2.0;
        complexity = 1.5,
        mixVal = 0.9;     
        base_color = getTexture( texNum, pos, scale, complexity, 
                                                          objClr, mixVal ).xyz;
    }       
    // 9: upper corner sphere
    else if ( objNum == 9 )
    {
        texNum = 21;
        objClr = vec4( 0.0, 0.15, 1.0, 1.0 );
        scale = 2.0;
        complexity = 1.5,
        mixVal = 0.9;     
        base_color = getTexture( texNum, pos, scale, complexity, 
                                                          objClr, mixVal ).xyz;
    }
    // 10: east globe
    // 13: front pyramid
    else if ( objNum == 10 || objNum == 13 )
    {
        texNum = 19;
        objClr = vec4( 0.0, 0.15, 1.0, 1.0 );
        scale = 2.0;
        complexity = 1.5,
        mixVal = 0.9;     
        base_color = getTexture( texNum, pos, scale, complexity, 
                                                      objClr, mixVal ).xyz;     
    } 
    
    return base_color;
}

// end applyTexture()

//------------------------------------------------------------------------------

// SKY COLOR
// ---------
// https://www.shadertoy.com/view/lll3z4
// Gardner Cos Clouds  Uploaded by fab on 2014-Dec-24
/*
 * Gardner Cos Clouds
 *
 * Translated/adapted from the RenderMan implementation in
 * Texturing & Modeling; a Procedural Approach (3rd ed, p. 50)
 */
 
vec3 skyColor( vec2 pix )
{   
    float zoom = 1.0,
          cloudDensity = 0.0,
          amplitude = 0.45,
          xphase = 0.9 * iGlobalTime,
          yphase = 0.7,
          xfreq = 2.0 * PI * 0.023,
          yfreq = 2.0 * PI * 0.021,
    
          offset = 0.5,
          xoffset = 37.0,
          yoffzet = 523.0,
    
          x = pix.x,
          y = pix.y,
          scale = 1.0 / iResolution.x * 60.0 * 1.0 / zoom;

    x = x * scale + offset + iGlobalTime * 1.5;
    y = y * scale + offset - iGlobalTime / 2.3;
    
    for ( int i = 0; i < nTerms; i++ )
    {
        float fx = amplitude * ( offset + cos( xfreq * ( x + xphase ) ) );
        float fy = amplitude * ( offset + cos( yfreq * ( y + yphase ) ) );
        cloudDensity += fx * fy;
        xphase = PI * 0.5 * 0.9 * cos( yfreq * y );
        yphase = PI * 0.5 * 1.1 * cos( xfreq * x );
        amplitude *= 0.602;
        xfreq *= 1.9 + float( i ) * .01;
        yfreq *= 2.2 - float( i ) * 0.08;
    }

    //return mix( vec3(0.5, 0.55, 0.96 ), vec3( 1.0 ), cloudDensity );   
    return mix( vec3(0.6, 0.66, 0.96 ), vec3( 1.0 ), cloudDensity * 4.0 );   

}

// end skyColor()

//------------------------------------------------------------------------------

// DEBUG PLANE
// ===========
 
vec4 debug_plane( vec3 rayOrig, vec3 rayDir, float cut_plane, 
                                                        inout float rayLength )
{
    if ( rayOrig.y > cut_plane && rayDir.y < 0.0 ) 
    {       
        float d = ( rayOrig.y - cut_plane ) / -rayDir.y;
        
        if ( d < rayLength ) 
        {
            vec3 hit = rayOrig + rayDir * d;
            
            float hit_dist = scene( hit ).s,
                  contourSpacing = 10.0,
                  whole_iso = hit_dist * contourSpacing,           
                  iso = fract( whole_iso ),                                   
                  markedContour = 5.0,          
                  modContour = mod( whole_iso, markedContour );
            
            vec3 dist_color = mix( vec3( 0.3, 0.5, 0.7 ), 
                                   vec3( 0.3, 0.3, 0.5 ), iso );
                
            if ( modContour >= markedContour - 1.0 && 
                 modContour <  markedContour )
            {
                dist_color = mix( vec3( 0.1, 0.3, 0.6 ), 
                                  vec3( 0.1, 0.1, 0.4 ), iso );
            }
                         
            dist_color *= 1.0 / ( max( 0.0, hit_dist ) + 0.001 );
            rayLength = d;
                     
            return vec4( dist_color, 0.1 );
       }
    }
    
    return vec4( 0.0 );
}

// end debug_plane()

//------------------------------------------------------------------------------

// SHADE
// -----
 
vec3 shade( vec3 rayOrig, vec3 rayDir, vec3 lightDir, vec4 hit, vec2 curPix )                                                                 
{
    vec3 fogColor = skyColor( curPix ) + vec3( 0.33, 0.66, 0.8 );
    
    float rayLength = 0.0;
    vec3 color = vec3( 0.0 );
    
    if ( hit.w == 0.0 ) 
    {
        rayLength = 1e16;
        color = fogColor;
    } 
    else 
    {
        vec3 dir = hit.xyz - rayOrig;
        vec3 surfNormal = getNormal(hit.xyz);
        rayLength = length(dir);
        
        // Texture
        // -------
        vec3 base_color = applyTexture( hit );
        float diffuse = max( 0.0, dot( surfNormal, lightDir ) );
        float spec = max( 0.0, dot( reflect( lightDir, surfNormal ), 
                                                          normalize( dir ) ) );
        spec = pow( spec, 16.0 ) * 0.5;
        vec3 ambient = vec3( 0.1 );
        vec3 white = vec3( 1.0 );
        color = mix( ambient, white, diffuse ) * base_color + spec * white;
                                            
        float fog_dist = rayLength;
        float fog = 1.0 - 1.0 / exp( fog_dist * fog_density );
        color = mix( color, fogColor, fog );
    
    } // end else( hit.w != 0 )
    
    //------------------------------------------------------------
    // Debug Plane
    // -----------
    float planeY = -2.0,        
          mixVal = 0.75;
    
    vec4 dpcol = debug_plane( rayOrig, rayDir, planeY, rayLength );
    color = mix( color, dpcol.xyz, mixVal );
            
    return color;
}

// end shade()

//------------------------------------------------------------------------------
 
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // For Gardner Cos Clouds skyColor()
    vec2 st = fragCoord.xy;
    st.x *= 0.4;
    st.y *= 1.5;

    vec2 uv = ( fragCoord.xy - iResolution.xy * 0.5 ) / iResolution.y;
    
    mat4 cam_mat = createCamRotMatrix();
    vec3 camPos = vec3( cam_mat * vec4( 0.0, 0.0, -cam_dist, 1.0 ) );   
    vec3 rayDir = normalize( vec3( cam_mat * vec4( uv, 1.0, 1.0 ) ) );
    vec3 lightDir = normalize( vec3( 0.5, 1.0, -0.25 ) );   
    vec4 hit = raymarch( camPos, rayDir );
    vec3 color = shade( camPos, rayDir, lightDir, hit, st );                                                                                
    color = pow( color, vec3( 0.3 ) );
    fragColor = vec4( color, 1.0 ); 
}

//------------------------------------------------------------------------------

// This section is excerpted from:

////////////////////////////////////////////////////////////////
//
//                           HG_SDF
//
//     GLSL LIBRARY FOR BUILDING SIGNED DISTANCE BOUNDS
//
//     version 2015-12-15 (initial release)
//
//     Check http://mercury.sexy/hg_sdf for updates
//     and usage examples. Send feedback to spheretracing@mercury.sexy.
//
//     Brought to you by MERCURY http://mercury.sexy
//
//
//
// Released as Creative Commons Attribution-NonCommercial (CC BY-NC)
//
////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////
//
//             HELPER FUNCTIONS/MACROS
//
////////////////////////////////////////////////////////////////

#define saturate(x) clamp(x, 0., 1.)

// Maximum/minumum elements of a vector
 float vmax(vec2 v){
    return max(v.x, v.y);
}

float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

////////////////////////////////////////////////////////////////
//
//             PRIMITIVE DISTANCE FUNCTIONS
//
////////////////////////////////////////////////////////////////

float fSphere(vec3 p, float r) {
    return length(p) - r;
}

// Box: correct distance to corners
float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

// Cylinder standing upright on the xz plane
float fCylinder(vec3 p, float r, float height) {
    float d = length(p.xz) - r;
    d = max(d, abs(p.y) - height);
    return d;
}

// Distance to line segment between <a> and <b>, used for fCapsule() version 2below
float fLineSegment(vec3 p, vec3 a, vec3 b) {
    vec3 ab = b - a;
    float t = saturate(dot(p - a, ab) / dot(ab, ab));
    return length((ab*t + a) - p);
}

// Capsule version 2: between two end points <a> and <b> with radius r 
float fCapsule(vec3 p, vec3 a, vec3 b, float r) {
    return fLineSegment(p, a, b) - r;
}


////////////////////////////////////////////////////////////////
//
//                DOMAIN MANIPULATION OPERATORS
//
////////////////////////////////////////////////////////////////

// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// Shortcut for 45-degrees rotation
void pR45(inout vec2 p) {
    p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
float pMirror (inout float p, float dist) {
    float s = sign(p);
    p = abs(p)-dist;
    return s;
}

////////////////////////////////////////////////////////////////
//
//             OBJECT COMBINATION OPERATORS
//
////////////////////////////////////////////////////////////////

// The "Stairs" flavour produces n-1 steps of a staircase:
float fOpUnionStairs(float a, float b, float r, float n) {
    float d = min(a, b);
    vec2 p = vec2(a, b);
    pR45(p);
    p = p.yx - vec2((r-r/n)*0.5*sqrt(2.));
    p.x += 0.5*sqrt(2.)*r/n;
    float x = r*sqrt(2.)/n;
    pMod1(p.x, x);
    d = min(d, p.y);
    pR45(p);
    return min(d, vmax(p -vec2(0.5*r/n)));
}
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

//
    // FOLLOWING CODE was OBTAINED FROM https://github.com/ashima/webgl-noise
    // This is the code for 3D Perlin noise, using simplex method.
    //
    
    //------------------------------- 3D Noise ------------------------------------------
    
    // Description : Array and textureless GLSL 2D/3D/4D simplex 
    //               noise functions.
    //      Author : Ian McEwan, Ashima Arts.
    //  Maintainer : ijm
    //     Lastmod : 20110822 (ijm)
    //     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
    //               Distributed under the MIT License. See LICENSE file.
    //               https://github.com/ashima/webgl-noise
    // 
    
    vec3 mod289(vec3 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    
    vec4 mod289(vec4 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    
    vec4 permute(vec4 x) {
         return mod289(((x*34.0)+1.0)*x);
    }
    
    vec4 taylorInvSqrt(vec4 r)
    {
      return 1.79284291400159 - 0.85373472095314 * r;
    }
    
    float snoise(vec3 v)
      { 
        const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
        const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);
      
      // First corner
        vec3 i  = floor(v + dot(v, C.yyy) );
        vec3 x0 =   v - i + dot(i, C.xxx) ;
      
      // Other corners
        vec3 g = step(x0.yzx, x0.xyz);
        vec3 l = 1.0 - g;
        vec3 i1 = min( g.xyz, l.zxy );
        vec3 i2 = max( g.xyz, l.zxy );
      
        //   x0 = x0 - 0.0 + 0.0 * C.xxx;
        //   x1 = x0 - i1  + 1.0 * C.xxx;
        //   x2 = x0 - i2  + 2.0 * C.xxx;
        //   x3 = x0 - 1.0 + 3.0 * C.xxx;
        vec3 x1 = x0 - i1 + C.xxx;
        vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
        vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y
      
      // Permutations
        i = mod289(i); 
        vec4 p = permute( permute( permute( 
                   i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
                 + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
                 + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));
      
      // Gradients: 7x7 points over a square, mapped onto an octahedron.
      // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
        float n_ = 0.142857142857; // 1.0/7.0
        vec3  ns = n_ * D.wyz - D.xzx;
      
        vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)
      
        vec4 x_ = floor(j * ns.z);
        vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)
      
        vec4 x = x_ *ns.x + ns.yyyy;
        vec4 y = y_ *ns.x + ns.yyyy;
        vec4 h = 1.0 - abs(x) - abs(y);
      
        vec4 b0 = vec4( x.xy, y.xy );
        vec4 b1 = vec4( x.zw, y.zw );
      
        //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
        //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
        vec4 s0 = floor(b0)*2.0 + 1.0;
        vec4 s1 = floor(b1)*2.0 + 1.0;
        vec4 sh = -step(h, vec4(0.0));
      
        vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
        vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
      
        vec3 p0 = vec3(a0.xy,h.x);
        vec3 p1 = vec3(a0.zw,h.y);
        vec3 p2 = vec3(a1.xy,h.z);
        vec3 p3 = vec3(a1.zw,h.w);
      
      //Normalise gradients
        vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
        p0 *= norm.x;
        p1 *= norm.y;
        p2 *= norm.z;
        p3 *= norm.w;
      
      // Mix final noise value
        vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
        m = m * m;
        return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                      dot(p2,x2), dot(p3,x3) ) );
      }
    
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
/*
 EXCERPTED FUNCTIONS that contained additional comments removed from the
 code above. Apologies if there are mistakes in my interpretations, or if some
 of the variable names are wrong; these comments were compiled from multiple
 older sources.
 
//------------------------------------------------------------------------------
// Function declarations allow function bodies to be placed below the position
// in the program from which they're called.

// This one's here because I ended up putting the IQ distance functions just
// above it, because it was convenient while creating the scene.
vec2 scene(vec3 p);

// Functions from the Mercury SDF Library.  
vec2 pMirrorOctant (inout vec2 p, vec2 dist);
float pMirror (inout float p, float dist);
float pModPolar(inout vec2 p, float repetitions);
float fSphere(vec3 p, float r);
float fBox(vec3 p, vec3 b);
float fCylinder(vec3 p, float r, float height);
float fOpUnionColumns(float a, float b, float r, float n);
float fOpUnionStairs(float a, float b, float r, float n);
float fCapsule(vec3 p, vec3 a, vec3 b, float r);
float fTorus(vec3 p, float smallRadius, float largeRadius);

// From the Ashima Arts 3D Noise code.
float snoise(vec3 v);

//------------------------------------------------------------------------------

// CREATE CAMERA ROTATION MATRIX
// -----------------------------

// I changed the code the day after this was uploaded to add mouse camera control,
// but Shadertoy insisted that the rotation around the x-axis should be opposite
// what I describe below ( actually I was too lazy to figure out what else needed
// to change to keep it the way it was ).
// So now, when the mouse is at the top of the screen, the camera is looking up
// from the bottom, and vice-versa. I also changed the y-axis rotation, so now
// moving the mouse right rotates the scene to the right.

mat4 createCamRotMatrix()
{
    float ang = 0.0, 
          sinAng = 0.0, 
          cosAng = 0.0,
          rotRange = -0.0029;
    
    // Rotation around x-axis = approx. +/- eightTenthsPI = approx 288 degrees
    // ----------------------
    // Assuming mouse at horizontal screen center is non-rotated position, and
    // rotations are viewed looking along the positive y-axis, i.e., looking up
    // from below scene:
    // Mouse at left of screen = 180 degree counterclockwise rotation from
    // non-rotated position.
    // Mouse at right of screen = 180 degree clockwise rotation from non-rotated
    // position.
    
    // A distance from screen center is calculated in screen coordinates, and
    // scaled to radian rotation angle values. (mouse vals are in screen coords)
    
    // When mouse.x = 0, rot angle = 2.494
    // When mouse.x = 1919, rot angle = -2.4911   =   +/- 0.79PI
        
    if( iMouse.z < 0.0 ) 
    {
        // Steady auto rotation around the y-axis.
        ang = iGlobalTime * 0.2;
    }
    else
    {
        ang = ( iMouse.x - iResolution.x * 0.5 ) * rotRange;
    }
    sinAng = sin(ang); 
    cosAng = cos(ang);
    
    mat4 y_Rot_Cam_Mat = mat4( cosAng, 0.0, sinAng, 0.0,      
                                  0.0, 1.0,    0.0, 0.0,
                              -sinAng, 0.0, cosAng, 0.0,
                                  0.0, 0.0,    0.0, 1.0 );
    
    // Rotation around y-axis = approx +/- halfPI = approx 180 degrees
    // ----------------------
    // Mouse at top of screen = looking straight down negative y-axis from
    //                          above scene
    // Mouse at bottom of screen = looking straight up positive y-axis from
    //                          below scene
    
    // When mouse.y = 0 ( top of screen ), rotY = 1.566
    // When mouse.y = 1079 ( btm of screen ), rotY = -1.5631    = +/- 0.49PI

    // Auto rotation around the x-axis.
    // The value "abs( 2.0 * fract( iGlobalTime ) - 1.0 )" ranges from 1 to 0, then
    // *reverses* from 0 to 1. So it's a means to a steady value shuttling
    // between 1 -> 0 -> 1. 

    // Multiplying by 1.5 allows the camera to go higher and lower above and
    // below the plane. The value range is now 1.5 -> 0 -> 1.5.
    // Subtracting -0.25 shifts the range to 1.25 to -0.25. This lets the camera
    // go higher above the plane, and not as low below the plane.

    if ( iMouse.z < 0.0 )
    {
        ang = 1.5 * ( abs( 2.0 * fract( iGlobalTime * 0.01 ) - 1.0 ) - 0.25 );
    }
    else
    {
        ang = ( iMouse.y - iResolution.y * 0.5 ) * rotRange; 
    }
    sinAng = sin(ang); 
    cosAng = cos(ang);
    
    mat4 x_Rot_Cam_Mat = mat4( 1.0,     0.0,    0.0, 0.0,     
                               0.0,  cosAng, sinAng, 0.0,
                               0.0, -sinAng, cosAng, 0.0,
                               0.0,     0.0,    0.0, 1.0 );
    
    return y_Rot_Cam_Mat * x_Rot_Cam_Mat;
    
}

// end createCamRotMatrix()

//------------------------------------------------------------------------------

// GET NORMAL
// ----------

// http://raymarching.com/WebGL/WebGL_ShadowsReflections.htm

// Source - Raymarching.com
// Author - Gary "Shane" Warne
// eMail - mail@Raymarching.com, mail@Labyrinth.com
// Last update: 28th Aug, 2014

vec3 getNormal( in vec3 p ) 
{       
    // wjb: scene() now returns a vec2( dist, objID ), so reference only the
    // first component. ( modified from original which returned a float distance
    // only.
    
    // The remainder are Shane's comments.
*/
/*
    // 6-tap normalization. Probably the most accurate, but a bit of a cycle 
    // waster.
    return normalize( vec3(
    scene( vec3( p.x + eps, p.y, p.z ) ) - 
                                        scene( vec3( p.x - eps, p.y, p.z ) ).s,
    scene( vec3( p.x, p.y + eps, p.z ) ) - 
                                        scene( vec3( p.x, p.y - eps, p.z ) ).s,
    scene( vec3( p.x, p.y, p.z + eps ) ) - 
                                        scene( vec3( p.x, p.y, p.z - eps ) ).s
    ));
*/
/*
// Shorthand version of the above. 
    vec2 e = vec2( eps, 0.0 );
    return normalize( vec3( scene( p + e.xyy ).s - scene( p - e.xyy ).s, 
                            scene( p + e.yxy ).s - scene( p - e.yxy ).s, 
                            scene( p + e.yyx ).s - scene( p - e.yyx ).s ));



// If speed is an issue, here's a slightly-less-accurate, 4-tap version.  
// Visually speaking, it's virtually the same, so often this is the one I'll 
// use. However, if speed is really an issue, you could take away the 
// "normalization" step, then  divide by "eps," but I'll usually avoid doing 
// that.
*/
/*    
    float ref = scene( p );
    return normalize( vec3( scene( vec3( p.x + eps, p.y, p.z ) ).s - ref,
                            scene( vec3( p.x, p.y + eps, p.z ) ).s - ref,
                            scene( vec3( p.x, p.y, p.z + eps ) ).s - ref ) ); 

*/  
/*
// The tetrahedral version, which does involve fewer calculations, but doesn't 
// seem as accurate on some surfaces.
    
    vec2 e = vec2( -0.5 * eps, 0.5 * eps );   
    return normalize( e.yxx * scene( p + e.yxx ).s + 
                      e.xxy * scene( p + e.xxy ).s + 
                      e.xyx * scene( p + e.xyx ).s +
                      e.yyy * scene( p + e.yyy ).s ); 
*/
/*
}

// end getNormal()

//------------------------------------------------------------------------------

// RAYMARCH
// --------

vec4 raymarch( vec3 rayOrig, vec3 rayDir )
{
   vec3 p = rayOrig;
   vec2 nearest = vec2( 0.0 );
   float rayLength = 0.0;
   
   for( int i = 0; i < iterations; ++i ) 
   {
        // Distance to the nearest object in scene.
        nearest = scene( p );
        
        // The first component of the vec2 contains the distance value.
        float dist = nearest.s;
        
        // Distance is within minimum range to be declared a hit.
        if ( dist < dist_eps )  break;      

        // wjb : Distance is not within hit distance. If distance is greater 
        // than back view plane, return background color, and ID 0.0.
        if ( rayLength > ray_max ) return vec4( 0.0 );
        
        // Distance indicates that neither an ojbect has been hit nor has 
        // the back view plane been reached. Move current ray position along the
        // ray direction by distance, and continue marching.
        p += dist * rayDir;

        //Add distance to the ray length.
        rayLength += dist;
   }
   
   // A hit was declared. Return the current ray position, and the ID of
   // the hit object
   return vec4( p, nearest.t );
}

// end raymarch()

//------------------------------------------------------------------------------

// DEBUG PLANE
// ===========
 * Draw a single debug plane. The original TestPortMercury code drew four
 * planes at varying heights.
 *
 * debug_plane() is called from the shade() function.
 *
 * 'rayOrig' is passed here unchanged from the call to shade() made from
 * main(). It represents the variable in main() : 'camPos', camera position.
 *
 * 'rayDir' is passed here unchanged from the call to shade() made from main().
 * It represents the variable 'rayDir' in main(), which is the normalized
 * concatenation of the current camera position with the up vector. 'rayDir'
 * represents a normalized step length along the ray from camera to object.
 *
 * 'cut_plane' represents the variable 'planeY' in the shade() function.
 * It's the y-position of the debug_plane(s) tested for here.
 *
 * 'rayLength' is the length of the ray measured from the camera to the hit 
 * object position.
 
vec4 debug_plane( vec3 rayOrig, vec3 rayDir, float cut_plane, 
                                                        inout float rayLength )
{
    // Test that the camera is above the cut_plane ( y-coord ) and that
    // it's looking down the negative y-axis.
    if ( rayOrig.y > cut_plane && rayDir.y < 0.0 ) 
    {       
        // Since rayOrig.y must be above the cut_plane y position, the
        // result of subtracting them must be a positive value. Dividing by
        // the negative value of rayDir yields a ray step length oriented in
        // the correct direction down the negative y-axis.
        float d = ( rayOrig.y - cut_plane ) / -rayDir.y;
               
        // If d is >= the distance from the camera to a hit obect, there
        // won't be any debug_plane in this case, return a vec4 debug plane
        // color of 0.0.
        if ( d < rayLength ) 
        {
            // Otherwise, find out where the ray intersects the debug plane by
            // starting at the camera and moving in the correct direction along
            // the ray by the 'rayDir' step distance, d times.
            vec3 hit = rayOrig + rayDir * d;
            
            // Send the vec3 representing the point where the ray hits the
            // debug plane to the distance estimation function, which will 
            // return the distance to the nearest object.
            float hit_dist = scene( hit ).s,
            
            // Spacing between debug plane contours can be adjusted here.
            // Larger value = narrower contour spacing.
                  contourSpacing = 10.0,
                  
            // Calculate the non-fracted value of iso, for use in demarcating
            // repeating distances in the contour colors.
                  whole_iso = hit_dist * contourSpacing,           
                  iso = fract( whole_iso ),                                   
                  markedContour = 5.0,          
                  modContour = mod( whole_iso, markedContour );
            
            // The contours are colored with a gradient created by mixing two
            // colors, from the lighter top color, closer to the object, to the 
            // darker bottom color, farther from the object.
            vec3 dist_color = mix( vec3( 0.3, 0.5, 0.7 ), 
                                   vec3( 0.3, 0.3, 0.5 ), iso );
                
            // Demarcate repeating distances from the objects
            // using a different color mix to represent the contour lines at
            // that repeated distance, i.e., make every fifth contour line a
            // different color.
            if ( modContour >= markedContour - 1.0 && 
                 modContour <  markedContour )
            {
                // Create a gradient by mixing two colors, from the lighter
                // top color, closer to the object, to the darker bottom 
                // color, farther from the object.
                dist_color = mix( vec3( 0.1, 0.3, 0.6 ), 
                                  vec3( 0.1, 0.1, 0.4 ), iso );
            }
                         
            dist_color *= 1.0 / ( max( 0.0, hit_dist ) + 0.001 );
            rayLength = d;
                     
            return vec4( dist_color, 0.1 );
       }
    }
    
    return vec4( 0.0 );
}

// end debug_plane()

//------------------------------------------------------------------------------

// SHADE
// -----
 * Called from main(), the returned vec3 is assigned to 'color'.
 * 'rayOrig' is 'camPos' in main() = current camera position
 * 'hit' is the vec4 returned from "raymarch( pos, dir )" in main()
 
vec3 shade( vec3 rayOrig, vec3 rayDir, vec3 lightDir, vec4 hit, vec2 curPix )                                                                 
{
    vec3 fogColor = skyColor( curPix ) + vec3( 0.33, 0.66, 0.8 );
    
    float rayLength = 0.0;
    vec3 color = vec3( 0.0 );
    
    // The raymarch() function is called in main() as the 4th argument to 
    // shade(), and is represented here by the vec4 'hit'. The raymarch() 
    // function returns a w-component value of 0.0 if the ray reaches the back 
    // view plane without hitting an object.
    if ( hit.w == 0.0 ) 
    {
        rayLength = 1e16;
        color = fogColor;
    } 
    else 
    {
        // 'dir' is assigned the distance between the camera and the point
        // where an object was hit.
        vec3 dir = hit.xyz - rayOrig;
        
        // Calculate the surface normal at the hit-position of the hit object.    
        vec3 surfNormal = getNormal(hit.xyz);
        
        rayLength = length(dir);
        
        // Texture
        // -------
        vec3 base_color = applyTexture( hit );
        
        // 'diffuse' is a non-negative value describing the angle between the  
        // hit object's normal and the direction from which the light is shining.
        float diffuse = max( 0.0, dot( surfNormal, lightDir ) );
        
        
        // Specular light:
        //----------------
        // reflect( lightDir, surfNormal ): reflect function returns a vector
        // that points in the direction of reflection. Two input parameters:
        // first, the incident vector, and second, the normal vector of the 
        // reflecting surface.
        
        // The dot product returns the cosine of the angle between the two 
        // normalized vectors ( reflection vector and ray direction vector ) 
        // = a value between -1 and +1 
        
        // If this value is greater than 0, it's raised to a power, and results
        // in a value darker close to 0, and brighter as it approaches 1.
        // If the value is less than 0, it's clamped to 0.
        float spec = max( 0.0, dot( reflect( lightDir, surfNormal ), 
                                                          normalize( dir ) ) );
        spec = pow( spec, 16.0 ) * 0.5;

        vec3 ambient = vec3( 0.1 );
        vec3 white = vec3( 1.0 );
        color = mix( ambient, white, diffuse ) * base_color + spec * white;
                                            
        float fog_dist = rayLength;
        float fog = 1.0 - 1.0 / exp( fog_dist * fog_density );
        color = mix( color, fogColor, fog );
    
    } // end else( hit.w != 0 )
    
    //------------------------------------------------------------
    // Debug Plane
    // -----------
    float planeY = -2.0,        
          mixVal = 0.75;
    
    vec4 dpcol = debug_plane( rayOrig, rayDir, planeY, rayLength );
    color = mix( color, dpcol.xyz, mixVal );
            
    return color;
}

// end shade()

//------------------------------------------------------------------------------


*/
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

/* PROGRAM FLOW ANALYSIS 
 * =====================

main()
------  
    Store a non-normalized, scaled screen coord for use in skyColor();
    
    Adjust aspect ratio, normalize coords, translate origin to screen cntr.
    
    Create camera rotation matrices for rotation around the x and y axes.
    Multiply them together to create the camera rotation matrix.
    
    The rotation range is defined by a float value, which, when multiplied by
    mouse position offset from screen center in world coordinates, creates a
    range for vert and horiz movement in radians angles.
    
    The mouse manipulation of the camera has been replaced in this version with
    automatic rotations around the x and y axes.
    
    camPos is initialized as the original, static cam position multiplied by
    the camera rotation matrix.
    
    lightDir is initialized.
    
    color is calculated.
    
    raymarch() : the ray marching   
    -------
    'dist' is assigned a value returned from 
    
        scene(), which checks for the nearest object in the world by calling        
        --------  the Mercury SDF Library functions or IQ functions for each 
                  object, each of which returns a distance from the current ray 
                  position. This is combined with an object ID and returned to
                  raymarch() as a vec2.
        
    A vec4 'hit' is returned to main(), containing the vec3 hit position, 'p'. 
    // The w-component contains the ID of the object that was hit.
    
    shade() :
    -------
        sky_color() is combined with a vec3 ambient light value, and assigned to 
        ----------- 'fogColor'.
                                        
        The w-component flag is checked. If the back plane was reached, the ray
        length is set to a tiny value, and color is set to fog.
        
        If an object was hit, the distance from ray origin to hit position is
        calculated, and 
        
        getNormal() : the average normal vector in the hit position vicinity is     
        ---------   calculated
        
        base_color is assigned a vec3 from
        
            applyTexture(). The object ID number determines the values sent to          
            --------------
            
                getTexture(), which calculates the pixel color for the current
                ------------  pixel.
                
        Diffuse light value is calculated as the dot product of the hit normal
        and the light direction.
        
        Specular light value is calculated.
    
        color is calculated as a mix of the base_color, and the diffuse and
        specular colors, and a calculated fog color.
    
        debug_plane() : a dist_color is calculated based on the distance from       
        -------------   the ray position to the debug plane.
    
        color is mixed with the debug plane color.
    
main()
------

color is modified ( brightened ) by an exponent, and assigned to gl_FragColor.  
    
*/

//---------------------------

// THREE JS TRANSPHERE

void main(){

    vec4 color = vec4(0.0);

    // screen space
    //vec2 coord = gl_FragCoord.xy;
    // object space
    vec2 coord = vUv * iResolution.xy;

    mainImage( color, coord );

    // tone mapping
    #if defined( TONE_MAPPING ) 
    color.rgb = toneMapping( color.rgb ); 
    #endif

    gl_FragColor = color;

}

//---------------------------