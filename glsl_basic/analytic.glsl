
// ------------------ channel define
// 0_# noise #_0
// ------------------


// Author : SÃ©bastien BÃ©rubÃ©
// Created : May 2015
// Modified : Feb 2016
//
// This shader was written with the intent of easing the pain of finding and validating 
// analytic derivatives. I had decided to do this after having read an interesting article, from Inigo Quilez :
// http://www.iquilezles.org/www/articles/morenoise/morenoise.htm
//
// Although deriving a function in a theorical context is not so difficult, it can still 
// quickly become an overwhelming task if you stack up multiple layers of rotated, scaled, and distorted noise.
// How do you rotate the derivatives, do you simply rotate the gradient in the same direction as the noise function?
// What do you do with time multiplier, is it always derived as a constant factor?
// Do you also have to derive the bilinear / trilinear equation, or just the ease function?
// 
// One way to check you did not do any error is to visualize the final result.
//
// License : Creative Commons Non-commercial (NC) license

// Of course, you could also skip all that and get Matlab or Maple...

// https://www.shadertoy.com/view/lscSzn

//----------------------
// Constants
const float LINE_WIDTH = 0.18; //From 0.0 to 1.0
const float AXIS_WIDTH = 0.035;
const float AXIS_LEN   = 0.5;
const float CELL_SIZE  = 2.25;
const int MAT_GROUND = 0;
const int MAT_AXIS   = 1;
const int MAT_SKY    = 2; 

//----------------------
// Globals
mat2 m2,m2t;
float DOMAIN_SCALING   = 12.0;

vec4 trilinearNoiseDerivative(vec3 p)
{
    p /= DOMAIN_SCALING;
    const float TEXTURE_RES = 256.0; //Noise texture resolution
    vec3 pixCoord = floor(p);//Pixel coord, integer [0,1,2,3...256...]
    vec2 layer_translation = -pixCoord.z*vec2(37.0,17.0)/TEXTURE_RES; //noise volume stacking trick : g layer = r layer shifted by (37x17 pixels -> this is no keypad smashing, but the actual translation embedded in the noise texture).
    
    vec2 c1 = texture2D(iChannel0,layer_translation+(pixCoord.xy+vec2(0,0)+0.5)/TEXTURE_RES,-16.0).xy;
    vec2 c2 = texture2D(iChannel0,layer_translation+(pixCoord.xy+vec2(1,0)+0.5)/TEXTURE_RES,-16.0).xy; //+x
    vec2 c3 = texture2D(iChannel0,layer_translation+(pixCoord.xy+vec2(0,1)+0.5)/TEXTURE_RES,-16.0).xy; //+z
    vec2 c4 = texture2D(iChannel0,layer_translation+(pixCoord.xy+vec2(1,1)+0.5)/TEXTURE_RES,-16.0).xy; //+x+z
    
    vec3 x = p-pixCoord;     //Pixel interpolation position, linear range [0-1] (fractional part)
    vec3 t = (3.0 - 2.0 * x) * x * x;
    
    //Lower quad corners
    float a = c1.x; //(x+0,y+0,z+0)
    float b = c2.x; //(x+1,y+0,z+0)
    float c = c3.x; //(x+0,y+1,z+0)
    float d = c4.x; //(x+1,y+1,z+0)
    
    //Upper quad corners
    float e = c1.y; //(x+0,y+0,z+1)
    float f = c2.y; //(x+1,y+0,z+1)
    float g = c3.y; //(x+0,y+1,z+1)
    float h = c4.y; //(x+1,y+1,z+1)
    
    //Trilinear noise interpolation : (1-t)*v1+(t)*v2, repeated along the 3 axis of the interpolation cube.
    float za = ((a+(b-a)*t.x)*(1.-t.y)
               +(c+(d-c)*t.x)*(   t.y));
    float zb = ((e+(f-e)*t.x)*(1.-t.y)
               +(g+(h-g)*t.x)*(   t.y));
    float value = (1.-t.z)*za+t.z*zb;
    
    //Derivative scaling
    float sx =  ((b-a)+t.y*(a-b-c+d))*(1.-t.z)
               +((f-e)+t.y*(e-f-g+h))*(   t.z);
    float sy =  ((c-a)+t.x*(a-b-c+d))*(1.-t.z)
               +((g-e)+t.x*(e-f-g+h))*(   t.z);
    float sz =  zb-za;
    
    //Ease-in ease-out derivative : (3x^2-2x^3)' = 6x-6x^2
    vec3 dxyz = 6.*x*(1.-x);
    
    return vec4(value*DOMAIN_SCALING,
                vec3(dxyz.x*sx,
                     dxyz.y*sy,
                     dxyz.z*sz));
}

struct FuncValue
{
    float height;
    float dh_dx;
    float dh_dz;
};
    
//----------------------
// Surface Definition
FuncValue evalSurface(vec2 p_xz, float fTime)
{
    FuncValue val;
    vec4 h_dx_dy_dz = trilinearNoiseDerivative(vec3(p_xz.x,DOMAIN_SCALING*iGlobalTime*0.2,p_xz.y));
    val.height = h_dx_dy_dz[0];
    val.dh_dx  = h_dx_dy_dz[1];
    //val.dh_dy  = h_dx_dy_dz[2];
    val.dh_dz  = h_dx_dy_dz[3];
    return val;
}

struct SurfaceAxis
{
    vec3 normal;
    vec3 tangent;
    vec3 binormal;
    vec3 pos;
};

SurfaceAxis computeSurfaceVectors(vec2 p)
{
    vec2 rp = m2*p; //rotated point
    FuncValue val = evalSurface(rp, iGlobalTime);
    vec2 dx = m2t*vec2(1,0); //rotated x+ vector
    vec2 dz = m2t*vec2(0,1); //rotated z+ vector
    SurfaceAxis surfAxis;
    surfAxis.tangent  = normalize(vec3(dx[0],val.dh_dx,dx[1]));
    surfAxis.binormal = normalize(vec3(dz[0],val.dh_dz,dz[1]));
    surfAxis.normal   = cross(surfAxis.binormal, surfAxis.tangent);
    surfAxis.pos      = vec3(p, val.height).xzy;
    return surfAxis;
}

vec3 textureGrid(vec2 uv, float eps)
{
    uv = m2*uv;
    float Ix = smoothstep(0.5*(LINE_WIDTH-eps),0.5*(LINE_WIDTH+eps),abs(fract(uv.x)-0.5));
    float Iy = smoothstep(0.5*(LINE_WIDTH-eps),0.5*(LINE_WIDTH+eps),abs(fract(uv.y)-0.5));
    return vec3(Ix*Iy);
}

struct Cell
{
    vec2 localSample;
    vec2 center;
};
    
Cell repeat(vec2 p, vec2 cellSize)
{
    Cell cell;
    cell.localSample = (fract(p/cellSize+0.5)-0.5)*cellSize;
    cell.center = p-cell.localSample;
    return cell;
}

float distanceToLineSeg3D(vec3 p, vec3 a, vec3 b)
{
    vec3 ap = p-a;
    vec3 ab = b-a;
    vec3 e = a+clamp(dot(ap,ab)/dot(ab,ab),0.0,1.0)*ab;
    return length(p-e);
}

struct HitInfo
{
    float d;
    int matID;
};
    
HitInfo map(vec3 p)
{
    SurfaceAxis surfInfo = computeSurfaceVectors(p.xz);
    float dSurf = dot((p-surfInfo.pos),surfInfo.normal);
    
    Cell probeCell = repeat(p.xz, vec2(CELL_SIZE));
    p.xz = probeCell.localSample;
    SurfaceAxis surfAxis = computeSurfaceVectors(probeCell.center);
    vec3 pAxis = vec3(0,surfAxis.pos.y,0);
        
    float d1 = distanceToLineSeg3D(p,pAxis+surfAxis.normal *AXIS_LEN,pAxis-surfAxis.normal *AXIS_LEN)-AXIS_WIDTH;
    float d2 = distanceToLineSeg3D(p,pAxis+surfAxis.tangent*AXIS_LEN,pAxis-surfAxis.tangent*AXIS_LEN)-AXIS_WIDTH;
    float d3 = distanceToLineSeg3D(p,pAxis+surfAxis.binormal*AXIS_LEN,pAxis-surfAxis.binormal*AXIS_LEN)-AXIS_WIDTH;
    float dAxis = min(min(d1,d2),d3); 
    
    HitInfo info;
    info.d = min(dSurf,dAxis);
    info.matID = (dSurf<dAxis)?MAT_GROUND:MAT_AXIS;    
    return info;
}

#define saturated(x) clamp(x,0.0,1.0)
float softProjLight( vec3 o, vec3 L, vec3 N)
{
    float coneWidth   = 0.1;
    float minAperture = 1.0; 
    float t = 0.001;
    for( int i=0; i<8; i++ )
    {
        vec3 p = o+L*t;
        float dist = map( p ).d;
        float curAperture = dist/t;
        minAperture = min(minAperture,curAperture);
        t += 0.05+dist;
    }
    return saturated(minAperture/coneWidth)*dot(L,N);
}

float itCount = 0.0;
HitInfo rayMarch(vec3 o, vec3 d)
{
    const float tMax = 75.0;
    float t = 0.0;
    for(int i=0; i < 80; ++i)
    {
        itCount += 1.0;
        float d = map(o+t*d).d;
        t += d>0.?d:0.75*d;
        if(abs(d)<0.001 || t > tMax)
            break;
    }
    
    HitInfo info = map(o+t*d);
    info.matID = (t>tMax)?MAT_SKY:info.matID;
    info.d = min(t,tMax);
    return info;
}

vec3 apply_atmosphere(float travelDist, vec3 color, vec3 p)
{
    //From this nice article on fog:
    //http://iquilezles.org/www/articles/fog/fog.htm
    //or this PowerPoint from Crytek:
    //GDC2007_RealtimeAtmoFxInGamesRev.ppt p17
    vec3 c_atmosphere = mix(vec3(0.87,0.94,1.0),vec3(0.6,0.80,1.0),clamp(3.0*p.y/length(p.xz),0.,1.));
    float c = 15.68;
    float b = 0.001;

    float cumul_density = c * exp(-1.0*b) * (1.0-exp( -travelDist*1.0*b ))/1.0;
    cumul_density = clamp(cumul_density,0.0,1.0);
    vec3 FinalColor = mix(color,c_atmosphere,cumul_density);
    return FinalColor;
}

#define m2Transpose(m) mat2(m[0][0],m[1][0],m[0][1],m[1][1])
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord.xy-iResolution.xy*0.5) / iResolution.xx;
    float t = 12.+iGlobalTime*0.35;
    DOMAIN_SCALING *= (1.0+0.8*sin(t));
    
    m2  = mat2(cos(t),-sin(t),sin(t),cos(t));
    m2t = m2Transpose(m2);
    
    vec3 camR = vec3(1,0,0);
    vec3 camU = vec3(0,1,0);
    vec3 camD = vec3(0,0,-1);
    vec3 dir  = normalize(uv.x*camR+uv.y*camU+camD);
    vec3 vpos = vec3(0,evalSurface(vec2(0), t).height,0)+4.5;
    
    HitInfo hit = rayMarch(vpos, dir);
    
    vec3 p = vpos+hit.d*dir;
    vec3 c = vec3(0);
    if     (hit.matID == MAT_SKY    ) c = mix(vec3(0.87,0.94,1.0),vec3(0.6,0.80,1.0),clamp(3.0*p.y/length(p.xz),0.,1.));
    else if(hit.matID == MAT_GROUND ) c = textureGrid(16.0*p.xz/DOMAIN_SCALING,0.1+0.0025*hit.d).xyz;
    else if(hit.matID == MAT_AXIS )   c = vec3(1,0,0);
    
    if(hit.matID != MAT_SKY)
    {
        vec3  L = vec3(-0.31, 0.924, -0.23);
        float I = softProjLight(p, L, computeSurfaceVectors(p.xz).normal);
        c *= (0.25+0.75*I);
        c = apply_atmosphere(hit.d,c,p);
    }
    
    fragColor = vec4(c,1);
}


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