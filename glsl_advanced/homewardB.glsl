// ------------------ channel define
// V_# homewardV #_V
// 0_# bufferFULL_homewardA #_0
// 1_# tex07 #_1
// 2_# tex06 #_2
// 3_# noise #_3
// ------------------

/*
#define CAMERA_POS      0
#define CAMERA_TAR      1
#define SUN_DIRECTION   2
#define CROW_POS        3
#define CROW_HEADING    4
#define CROW_FLAPPING   5
#define CROW_HEADTILT   6
#define CROW_TURN       7
#define CROW_CLIMBING   8

#define FAR 850.

#define TAU 6.28318530718
#define SUN_COLOUR vec3(1.1, .95, .85)
#define FOG_COLOUR vec3(.48, .49, .53)

vec3 sunLight, crowPos;

//----------------------------------------------------------------------------------------

vec3 cameraPath( float z )
{
    return vec3(100.2*sin(z * .0045)+90.*cos(z *.012), 43.*(cos(z * .0047)+sin(z*.0013)) + 53.*(sin(z*0.0112)), z);
}
// Set up a camera matrix

//--------------------------------------------------------------------------
mat3 setCamMat( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}
#define HASHSCALE1 .1031

float hash11(float p)
{
    vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
*/

// https://www.shadertoy.com/view/Xllfzl

// Render the lanscape and sky...
// by David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// These are indices into the variable data in Buf A...

float gTime, specular;


//#define FAR 850.0


//========================================================================
// Utilities...

//----------------------------------------------------------------------------------------
// Grab value of variable, indexed 'num' from buffer A...
// Useful because each pixel doesn't need to do a whole bunch of math/code over and over again.
// Like camera positions and animations...
vec4 getStore(int num)
{
    //ivec2 loc = ivec2(num & 63, num/64); // Didn't need that many, doh!
    ivec2 loc = ivec2(num, 0);
    return  texelFetch(iChannel0, loc, 0);
}

//----------------------------------------------------------------------------------------
float  sphere( vec3 p, float s )
{
    return length(p)-s;
}

//--------------------------------------------------------------------------

//--------------------------------------------------------------------------
float noise( in vec3 p )
{
    vec3 f = fract(p);
    p = floor(p);
    f = f*f*(3.0-2.0*f);
    
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = textureLod( iChannel3, (uv+ 0.5)/256.0, 0.0).yx;
    return mix( rg.x, rg.y, f.z );
}

//--------------------------------------------------------------------------

float sMax(float a, float b, float s){
    
    float h = clamp( 0.5 + 0.5*(a-b)/s, 0., 1.);
    return mix(b, a, h) + h*(1.0-h)*s;
}


//--------------------------------------------------------------------------
// This uses mipmapping with the incoming ray distance.
// I think it also helps with the texture cache, but I don't know that for sure...
float map( in vec3 p, float di)
{
  
    di = min(di, 6.0);

    // Grab texture based on 3D coordinate mixing...
    float te = textureLod(iChannel1, p.xz*.0022 + p.xy * 0.0023-p.zy*.0011, di).x*40.0;
    // Make a wibbly wobbly sin/cos dot product..
    float h = dot(sin(p*.0173),(cos(p.zxy*.0191)))*30.;
    // Add them all together...
    float d =  h+p.y*.2 + te;
    //...Then subtract the camera tunnel...
    p.xy -= cameraPath(p.z).xy;
    float tunnel = 15. - length(p.xy)-h; 

    d = sMax(d, tunnel, 80.);
    
    //d = max(tunnel, d); 

    return d;
}

//--------------------------------------------------------------------------

vec3 getSky(vec3 dir, vec2 uv, vec3 pos)
{
    vec3 col;
    vec3 clou = dir * 1. + pos*.025;
    float t = noise(clou);
    t += noise(clou * 2.1) * .5;
    t += noise(clou * 4.3) * .25;
    t += noise(clou * 7.9) * .125;
    col = mix(vec3(FOG_COLOUR), vec3(0.2, 0.2,.2),abs(dir.y))+ FOG_COLOUR *t*.4;
 
    return col;
}


//--------------------------------------------------------------------------

vec3 getNormal(vec3 p, float e)
{
    return normalize( vec3( map(p+vec3(e,0.0,0.0), e) - map(p-vec3(e,0.0,0.0), e),
                            map(p+vec3(0.0,e,0.0), e) - map(p-vec3(0.0,e,0.0), e),
                            map(p+vec3(0.0,0.0,e), e) - map(p-vec3(0.0,0.0,e), e) ) );
}

//--------------------------------------------------------------------------

float BinarySubdivision(in vec3 rO, in vec3 rD, vec2 t)
{
    float halfwayT;
  
    for (int i = 0; i < 5; i++)
    {

        halfwayT = dot(t, vec2(.5));
        float d = map(rO + halfwayT*rD, halfwayT*.008); 
        t = mix(vec2(t.x, halfwayT), vec2(halfwayT, t.y), step(0.02, d));
    }

    return halfwayT;
}

//--------------------------------------------------------------------------
float marchScene(in vec3 rO, in vec3 rD, vec2 co)
{
    float t = 10.+10.*hash12(co), oldT = 0.;
    vec2 dist = vec2(1000);
    vec3 p;
    bool hit = false;
    
    for( int j=0; j < 150; j++ )
    {
        if (t >= FAR) break;
        p = rO + t*rD;

        float h = map(p, t*0.008);
        if(h < 0.02)
        {
            dist = vec2(oldT, t);
            break;
         }
        oldT = t;
        t += h * .4 + t*.004;
    }
    if (t < FAR) 
    {
       t = BinarySubdivision(rO, rD, dist);
    }
    return t;
}

//--------------------------------------------------------------------------
float noise2d(vec2 p)
{
    vec2 f = fract(p);
    p = floor(p);
    f = f*f*(3.0-2.0*f);
    
    float res = mix(mix( hash12(p),             hash12(p + vec2(1,0)),f.x),
                    mix( hash12(p + vec2(0,1)), hash12(p + vec2(1,1)),f.x),f.y);
    return res;
}

//--------------------------------------------------------------------------
float findClouds2D(in vec2 p)
{
    float a = 1.0, r = 0.0;
    p*= .001;
    for (int i = 0; i < 5; i++)
    {
        r+= noise2d(p*=2.563)*a;
        a*=.5;
    }
    return max(r-1.1, 0.0);
}

//--------------------------------------------------------------------------
// Use the difference between two cloud densities to light clouds in the direction of the sun.
vec4 getClouds(vec3 pos, vec3 dir)
{
    if (dir.y < 0.0) return vec4(0.0);
    float d = (600. / dir.y);
    vec2 p = pos.xz+dir.xz*d;
    float r = findClouds2D(p);
    float t = findClouds2D(p+normalize(sunLight.xz)*15.);    
    t = sqrt(max((r-t)*30., .8));
    vec3 col = vec3(t) * SUN_COLOUR;
    // returns colour and alpha...
    return vec4(col, r);
}

//--------------------------------------------------------------------------
// Turn a 2D texture into a six sided one...
vec3 texCube(in sampler2D tex, in vec3 p, in vec3 n )
{
    vec3 x = textureLod(tex, p.yz, 0.0).xyz;
    vec3 y = textureLod(tex, p.zx, 0.0).xyz;
    vec3 z = textureLod(tex, p.xy, 0.0).xyz;
    return (x*abs(n.x) + y*abs(n.y) + z*abs(n.z))/(1e-20+abs(n.x)+abs(n.y)+abs(n.z));
}

//--------------------------------------------------------------------------
// Grab the colour...
vec3 albedo(vec3 pos, vec3 nor)
{
    specular  = .8;
    vec3 alb  = texCube(iChannel2, pos*.03, nor);

    // Brown the texture in places for warmth...
    float v = noise(pos*.04+20.);
    alb *= vec3(.85+v, .9+v*.5, .9);
    
    // Mossy rocky bits...
    v = pow(max(noise(pos*.03)-.4, 0.0), .7);
    alb = mix(alb, vec3(.45,.55,.45), v*v*4.);
    
    // Do ice on flat areas..
    float ice = smoothstep(0.4, .7,nor.y);
    alb = mix(alb, vec3(.5, .8,1.), ice);
    specular+=ice*.5;
    
    return alb*1.8;
}

//--------------------------------------------------------------------------
float mapCrowShad(vec3 p)
{
    float d = 0.;
    p= p-crowPos;
    d = sphere(p, 3.);
    return smoothstep(.0, 8.0, d)+.8;
}

//--------------------------------------------------------------------------
float shadow(in vec3 ro, in vec3 rd)
{
    float res = 1.0;
    
    float t = .1;
    for( int i = 0; i < 14; i++ )
    {
        float h = map(ro + rd*t, 4.);
        float g = mapCrowShad(ro + rd*t);
        h = min(g, h); 
        res = min( res, 4.*h/t );
        t += h+.35;
    }
    return clamp( res, 0., 1.0 );
}


//--------------------------------------------------------------------------
vec3 lighting(in vec3 mat, in vec3 pos, in vec3 normal, in vec3 eyeDir, in float d)
{
  
    float sh = shadow(pos+normal*.5,  sunLight);
    //sh*=curve(pos)+1.;
    // Light surface with 'sun'...
    vec3 col = mat * SUN_COLOUR*(max(dot(sunLight,normal), 0.0))*sh;

    
    // Ambient...
    col += mat  * abs(normal.y*.14);
    
    normal = reflect(eyeDir, normal); // Specular...
    col += pow(max(dot(sunLight, normal), 0.0), 10.0)  * SUN_COLOUR * sh * specular;

    return min(col, 1.0);
}


//--------------------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (-iResolution.xy + 2.0 * fragCoord ) / iResolution.y;
    specular = 0.0;
    vec3 col;

    sunLight    = getStore(SUN_DIRECTION).xyz;
    vec3 camPos = getStore(CAMERA_POS).xyz;
    vec3 camTar = getStore(CAMERA_TAR).xyz;
    crowPos     = getStore(CROW_POS).xyz;
  
    // Setup an epic fisheye lens for the ray 'dir'....
    mat3 camMat = setCamMat(camPos, camTar, (camTar.x-camPos.x)*.02);
    vec3 dir = camMat * normalize( vec3(uv, cos((length(uv*.5)))));

    // The sky is a general mix of blue to fog colour with 3D 'cold' clouds, for mixing with the distance fogging effect...
    vec3 sky = getSky(dir, uv, camPos);
    //March it...
    float dhit = marchScene(camPos, dir, fragCoord);
    // Render at distance value...
    if (dhit < FAR)
    {
        vec3  p = camPos+dhit*dir;
        float pixel = iResolution.y;
        vec3 nor =  getNormal(p, dhit/pixel);
        vec3 mat = albedo(p, nor);
        vec3  temp = lighting(mat, p, nor, dir, dhit);
        // Distance fog...
        temp = mix(sky, temp , exp(-dhit*.0015)-.1);
        col = temp;
    }else
    {
 
        // Clouds and Sun...
        col = sky;
        vec4 cc = getClouds(camPos, dir);
       
        col = mix(col, cc.xyz, cc.w);

        col+= pow(max(dot(sunLight, dir), 0.0), 200.0)*SUN_COLOUR;
    }
    //col *= vec3(1.1,1.0,1.0);
    
    //col = mix( col, vec3(dot(col,vec3(0.333))), 0.4 );
    //col = col*0.5+0.5*col*col*(3.0-2.0*col);
    
    fragColor = vec4(col, dhit);
    
}

