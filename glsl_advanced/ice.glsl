
// ------------------ channel define
// 0_# tex12 #_0
// 1_# tex08 #_1
// 2_# bufferFULL_iceA #_2
// ------------------

//https://www.shadertoy.com/view/MscXzn

// Author : SÃ©bastien BÃ©rubÃ©
// Created : Dec 2014
// Modified : Feb 2016
//
// Ice raymarching experiment, built on top of primitives shader from Inigo Quilez : 
// https://www.shadertoy.com/view/Xds3zN
//
// You can play with the sliders : 1-Normal map scale
//                                 2-Isosurface thickness
//                                 3-Color / refraction normal / other debug stuff
//                                 4-Refraction index
//
// Notes:
// 
// - distance function map() works as usual, as all boolean operations and signed distance functions do.
// - sphereTracing() function was modified for volume raymarching (sign added, simple as that).
// - triplanar noise projection used for surface normal noise.
// - smooth subtraction was implemented to smooth out boolean shape.
// - "in scattering" is simply approximated with positive inner ice colors (the default color)
// - extinction coefficient is also roughly approximated both by negative inner ice color
//   and with traversal distance (WIP, I'll return to improve this once I better
//   understand scattering equations).
// - RAYMARCH_DFSS is slightly different from inigo's softshadow.
//   A "light cone width" value [0-1] is passed to the function in order to control softness.
//   I don't know how well it would perform in other scenarios, but it seems to do the trick
//   with limited samples in this case. I guess the principle is the same.
//
// License : Creative Commons Non-commercial (NC) license
//

//----------------------
// Constants 
const float GEO_MAX_DIST  = 1000.0;
const int MATERIALID_NONE      = 0;
const int MATERIALID_FLOOR     = 1;
const int MATERIALID_ICE_OUTER = 2;
const int MATERIALID_ICE_INNER = 3;
const int MATERIALID_SKY       = 4;

//----------------------
// Slider bound globals.
float ROUGHNESS      = 0.25; //sliderVal[0]
float ISOVALUE       = 0.03; //sliderVal[1]
float ICE_COLOR      = 0.00; //sliderVal[2]
float REFRACTION_IDX = 1.31; //sliderVal[3]

struct TraceData
{
    float rayLen;
    vec3  rayDir;
    vec3  normal;
    int   matID;
    vec3  matUVW;
    float alpha;
};

#define saturated(x) clamp(x,0.0,1.0)
vec3 normalMap(vec3 p, vec3 n);
TraceData TRACE_geometry(vec3 o, vec3 d);
TraceData TRACE_reflexion(vec3 o, vec3 d);
TraceData TRACE_translucentDensity(vec3 o, vec3 d);
TraceData TRACE_cheap(vec3 o, vec3 d);

float RAYMARCH_DFSS(vec3 ro, vec3 rd, float coneWidth);

vec4 MAT_apply(vec3 pos, TraceData traceData)
{
    vec3 L = normalize(vec3(-0.6,0.7,-0.5));
    vec4 col = vec4(traceData.alpha);
    
    if(traceData.matID==MATERIALID_NONE)
    {
        return vec4(0,0,0,1);
    }
    else if(traceData.matID==MATERIALID_ICE_INNER)
    {
        //NOTE : Coloring is not physically accurate.
        //       For this to be more accurate, 
        //       it should probably be computed like fog.
        //       (in scattering, out scattering / extinction coefficient?).
        vec3 cRed   = vec3( 0.70,-0.5,-0.60);
        vec3 cGreen = vec3(-0.50, 0.0,-0.5);
        vec3 cBlue  = vec3(-0.50,-0.5, 0.30);
        vec3 cGrey = vec3(-0.3); //Glass (~extinction coefficient, more or less)
        vec3 cWhite = vec3(1.0); //Ice (pseudo "in scattering")
        
        col.rgb = mix(cWhite ,cGrey, smoothstep(0.00,0.20,ICE_COLOR));
        col.rgb = mix(col.rgb,cBlue, smoothstep(0.20,0.40,ICE_COLOR));
        col.rgb = mix(col.rgb,cGreen,smoothstep(0.40,0.60,ICE_COLOR));
        col.rgb = mix(col.rgb,cRed , smoothstep(0.60,0.80,ICE_COLOR));    
    }
    else if(traceData.matID==MATERIALID_SKY)
    {
        col.rgb = vec3(0.6,0.7,0.85);
    }
    else if(traceData.matID==MATERIALID_FLOOR)
    {
        vec3 cDiff = pow(texture2D(iChannel1,traceData.matUVW.xz).rgb,vec3(1.2));
        float dfss = RAYMARCH_DFSS(pos, L, 0.07);
        col.rgb = cDiff*(0.45+1.2*(dfss));
    }
    return col;
}

struct IceTracingData
{
    TraceData reflectTraceData;
    TraceData translucentTraceData;
    TraceData exitTraceData;
};
    
IceTracingData renderIce(TraceData iceSurface, vec3 ptIce, vec3 dir)
{
    IceTracingData iceData;
    
    vec3 normalDelta = normalMap(ptIce*ROUGHNESS,iceSurface.normal)*ROUGHNESS/10.;
    
    vec3 iceSurfaceNormal = normalize(iceSurface.normal+normalDelta); 
    vec3 refract_dir = refract(dir,iceSurfaceNormal,1.0/REFRACTION_IDX); //Ice refraction index = 1.31
    vec3 reflect_dir = reflect(dir,iceSurfaceNormal);

    //Trace reflection
    iceData.reflectTraceData = TRACE_reflexion(ptIce,reflect_dir);
    
    //Balance between refraction and reflection (not entirely physically accurate, Fresnel could be used here).
    float fReflectAlpha = 0.5*(1.0-abs(dot(normalize(dir),iceSurfaceNormal)));
    iceData.reflectTraceData.alpha = fReflectAlpha;
    vec3 ptReflect = ptIce+iceData.reflectTraceData.rayLen*reflect_dir;

    //Trace refraction
    iceData.translucentTraceData = TRACE_translucentDensity(ptIce,refract_dir);
    
    vec3 ptRefract = ptIce+iceData.translucentTraceData.rayLen*refract_dir;
    vec3 exitRefract_dir = refract(refract_dir,-iceData.translucentTraceData.normal,REFRACTION_IDX);

    //This value fades around total internal refraction angle threshold.
    if(length(exitRefract_dir)<=0.95)
    {
        //Total internal reflection (either refraction or reflexion, to keep things cheap).
        exitRefract_dir = reflect(refract_dir,-iceData.translucentTraceData.normal);
    }
    
    //Trace environment upon exit.
    iceData.exitTraceData = TRACE_cheap(ptRefract,exitRefract_dir);
    iceData.exitTraceData.matID = MATERIALID_FLOOR;
    
    return iceData;
}

vec3 main_render( vec3 o, vec3 dir, vec2 uv)
{ 
    vec3 pt = o;
    
    vec3 ptGeometry = vec3(0);
    vec3 ptReflect = vec3(0);
    
    TraceData geometryTraceData = TRACE_geometry(pt, dir);
    ptGeometry = o+geometryTraceData.rayLen*dir;
    
    IceTracingData iceData;
    iceData.translucentTraceData.rayLen = 0.0;
    if(geometryTraceData.matID == MATERIALID_ICE_OUTER && geometryTraceData.rayLen < GEO_MAX_DIST)
    {
        vec3 ptIce = ptGeometry;
        iceData = renderIce(geometryTraceData, ptIce, dir);
        geometryTraceData = iceData.exitTraceData;
        
        vec3 ptRefract = ptIce+iceData.translucentTraceData.rayLen*iceData.translucentTraceData.rayDir;
        ptReflect = ptIce+iceData.reflectTraceData.rayLen*iceData.reflectTraceData.rayDir;
        ptGeometry = ptRefract+geometryTraceData.rayLen*dir;
        
        //<Debug section, not mandatory>
        //[0.80-1.00] = Debug color range.
        if(ICE_COLOR>0.95) return iceData.exitTraceData.rayDir;
        if(ICE_COLOR>0.90) return max(iceData.exitTraceData.matUVW,vec3(0));
        if(ICE_COLOR>0.85) return iceData.translucentTraceData.rayLen*vec3(1);
        if(ICE_COLOR>0.80) return iceData.reflectTraceData.alpha*vec3(1);
        //</Debug section, not mandatory>
    }
    
    //cTerrain is either direct ray or refract ray.
    vec4 cTerrain  = MAT_apply(ptGeometry,geometryTraceData);
    vec4 cIceInner = MAT_apply(ptGeometry,iceData.translucentTraceData);
    vec4 cReflect  = MAT_apply(ptReflect,iceData.reflectTraceData);
    
    if(iceData.translucentTraceData.rayLen > 0.0 )
    {
        float fTrav = iceData.translucentTraceData.rayLen;
        vec3 cRefract = cTerrain.rgb;
        cRefract.rgb = mix(cRefract,cIceInner.rgb,0.3*fTrav+0.2*sqrt(fTrav*3.0));
        cRefract.rgb += fTrav*0.3;
        vec3 cIce = mix(cRefract,cReflect.rgb,iceData.reflectTraceData.alpha);
        return cIce;
    }
    return cTerrain.rgb;
}




struct DF_out
{
    float d;  //Distance to geometry
    int matID;//Geometry material ID
};
    

float sdPlane( vec3 p )
{
    return p.y;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float sdTorus( vec3 p, vec2 t )
{
  return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
#if 0
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
#else
    float d1 = q.z-h.y;
    float d2 = max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
}

float sdCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float length2( vec2 p )
{
    return sqrt( p.x*p.x + p.y*p.y );
}

float length8( vec2 p )
{
    p = p*p; p = p*p; p = p*p;
    return pow( p.x + p.y, 1.0/8.0 );
}

float sdTorus88( vec3 p, vec2 t )
{
  vec2 q = vec2(length8(p.xz)-t.x,p.y);
  return length8(q)-t.y;
}


//----------------------------------------------------------------------

float opSmoothSubtract( float d1, float d2 )
{
    return length(vec2(max(d1,0.),min(d2,0.0)));
}

float opU( float d1, float d2 )
{
    return (d1<d2) ? d1 : d2;
}

vec3 opTwist( vec3 p )
{
    float  c = cos(10.0*p.y+10.0);
    float  s = sin(10.0*p.y+10.0);
    mat2   m = mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
}

DF_out map( in vec3 pos )
{
    float dist = opU( sdPlane(     pos-vec3( -1.4) ),
                    sdSphere(    pos-vec3( 0.0,0.25, 0.0), 0.25 ) );
    dist = opU( dist, udRoundBox(  pos-vec3( 1.0,0.25, 1.0), vec3(0.15), 0.1 ) );
    dist = opU( dist, sdTorus(     pos-vec3( 0.0,0.25, 1.0), vec2(0.20,0.05) ) );
    dist = opU( dist, sdTriPrism(  pos-vec3(-1.0,0.25,-1.0), vec2(0.25,0.05) ) );
    dist = opU( dist, sdCylinder(  pos-vec3( 1.0,0.30,-1.0), vec2(0.10,0.20) ) );
    dist = opU( dist, sdTorus88(   pos-vec3(-1.0,0.25, 1.0), vec2(0.20,0.05) ) );
    dist = opU( dist, opSmoothSubtract(
                          udRoundBox(  pos-vec3(-1.0,0.2, 0.0), vec3(0.15),0.05),
                          sdSphere(    pos-vec3(-1.0,0.2, 0.0), 0.25)) );
    dist = opU( dist, sdBox(       pos-vec3( 0.0,0.20,-1.0), vec3(0.25)) );
    dist = opU( dist, 0.5*sdTorus( opTwist(pos-vec3( 1.0,0.25, 0.0)),vec2(0.15,0.02)) );

    DF_out outData;
    outData.d = dist-ISOVALUE;
    outData.matID = MATERIALID_ICE_OUTER;
    return outData;
}

vec3 gradient( in vec3 p )
{
    const float d = 0.001;
    vec3 grad = vec3(map(p+vec3(d,0,0)).d-map(p-vec3(d,0,0)).d,
                     map(p+vec3(0,d,0)).d-map(p-vec3(0,d,0)).d,
                     map(p+vec3(0,0,d)).d-map(p-vec3(0,0,d)).d);
    return grad;
}

vec2 sphereTracing( const vec3 o, const vec3 d, const float tmin, const float eps, const bool bInternal)
{
    //http://www.iquilezles.org/www/articles/raymarchingdf/raymarchingdf.htm
    //http://mathinfo.univ-reims.fr/IMG/pdf/hart94sphere.pdf p.5-89
    //[modified for internal marching]
    float tmax = 10.0;
    float t = tmin;
    float dist = GEO_MAX_DIST;
    for( int i=0; i<50; i++ )
    {
        vec3 p = o+d*t;
        dist = (bInternal?-1.:1.)*map(p).d;
        if( abs(dist)<eps || t>tmax )
            break;
        t += dist;
    }
    
    dist = (dist<tmax)?dist:GEO_MAX_DIST;
    return vec2( t, dist );
}

TraceData TRACE_getFront(const in TraceData tDataA, const in TraceData tDataB)
{
    if(tDataA.rayLen<tDataB.rayLen)
    {
        return tDataA;
    }
    else
    {
        return tDataB;
    }
}

float RAYCAST_floor(vec3 o, vec3 d)
{
    vec3 n = vec3(0,1,0);
    vec3 p = vec3(-0.1);
    float t = dot(p-o,n)/dot(d,n);
    return (t<0.0)?GEO_MAX_DIST:t;
}

//o=origin, d = direction
TraceData TRACE_cheap(vec3 o, vec3 d)
{
    TraceData floorData;
    floorData.rayLen  = RAYCAST_floor(o, d);
    floorData.rayDir  = d;
    floorData.normal  = vec3(0,1,0);
    floorData.matUVW  = o+d*floorData.rayLen;
    floorData.matID   = MATERIALID_FLOOR;
    floorData.alpha   = 1.0;
    
    TraceData skyData;
    skyData.rayLen  = 50.0;
    skyData.rayDir  = d;
    skyData.normal  = -d;
    skyData.matUVW  = d;
    skyData.matID   = MATERIALID_SKY;
    skyData.alpha   = 1.0;
    return TRACE_getFront(floorData,skyData);
}

TraceData TRACE_reflexion(vec3 o, vec3 d)
{
    return TRACE_cheap(o,d);
}

//o=origin, d = direction
TraceData TRACE_geometry(vec3 o, vec3 d)
{
    TraceData cheapTrace = TRACE_cheap(o,d);
    
    TraceData iceTrace;
    vec2 rayLen_geoDist = sphereTracing(o,d,0.1,0.0001,false);
    vec3 iceHitPosition = o+rayLen_geoDist.x*d;
    iceTrace.rayDir     = d;
    iceTrace.rayLen     = rayLen_geoDist.x;
    iceTrace.normal     = normalize(gradient(iceHitPosition));
    iceTrace.matUVW     = iceHitPosition;
    iceTrace.matID      = MATERIALID_ICE_OUTER;
    iceTrace.alpha      = 0.0;
    
    return TRACE_getFront(cheapTrace,iceTrace);
}

//o=origin, d = direction
TraceData TRACE_translucentDensity(vec3 o, vec3 d)
{
    TraceData innerIceTrace;
    
    vec2 rayLen_geoDist   = sphereTracing(o,d,0.01,0.001,true).xy;
    vec3 iceExitPosition  = o+rayLen_geoDist.x*d;
    innerIceTrace.rayDir  = d;
    innerIceTrace.rayLen  = rayLen_geoDist.x;
    innerIceTrace.normal  = normalize(gradient(iceExitPosition));
    innerIceTrace.matUVW  = iceExitPosition;
    innerIceTrace.matID   = MATERIALID_ICE_INNER;
    innerIceTrace.alpha   = rayLen_geoDist.x;
    return innerIceTrace;
}

#define saturated(x) clamp(x,0.0,1.0)
//o=origin, L = light direction
float RAYMARCH_DFSS( vec3 o, vec3 L, float coneWidth )
{
    //Variation of the Distance Field Soft Shadow from : https://www.shadertoy.com/view/Xds3zN
    //Initialize the minimum aperture (angle tan) allowable with this distance-field technique
    //(45deg: sin/cos = 1:1)
    float minAperture = 1.0; 
    float t = 0.0;
    float dist = GEO_MAX_DIST;
    for( int i=0; i<6; i++ )
    {
        vec3 p = o+L*t; //Sample position = ray origin + ray direction * travel distance
        float dist = map( p ).d;
        float curAperture = dist/t; //Aperture ~= cone angle tangent (sin=dist/cos=travelDist)
        minAperture = min(minAperture,curAperture);
        t += 0.03+dist; //0.03 : min step size.
    }
    
    //The cone width controls shadow transition. The narrower, the sharper the shadow.
    return saturated(minAperture/coneWidth); //Should never exceed [0-1]. 0 = shadow, 1 = fully lit.
}

vec3 smoothSampling(vec2 uv)
{
    const float T_RES = 64.0;
    vec2 x = fract(uv*T_RES+0.5);
    vec2 pc1 = uv-(x)/T_RES;
    //vec2 t = x * x * (3.0 - 2.0 * x);
    vec2 t = (6.*x*x-15.0*x+10.)*x*x*x; //ease function
    return texture2D(iChannel0,pc1+t/T_RES,-100.0).xyz;
}

float triplanarSampling(vec3 p, vec3 n)
{
    float fTotal = abs(n.x)+abs(n.y)+abs(n.z);
    return  (abs(n.x)*smoothSampling(p.yz).x
            +abs(n.y)*smoothSampling(p.xz).x
            +abs(n.z)*smoothSampling(p.xy).x)/fTotal;
}

const mat2 m2 = mat2(0.90,0.44,-0.44,0.90);
float triplanarNoise(vec3 p, vec3 n)
{
    const float BUMP_MAP_UV_SCALE = 0.2;
    float fTotal = abs(n.x)+abs(n.y)+abs(n.z);
    float f1 = triplanarSampling(p*BUMP_MAP_UV_SCALE,n);
    p.xy = m2*p.xy;
    p.xz = m2*p.xz;
    p *= 2.1;
    float f2 = triplanarSampling(p*BUMP_MAP_UV_SCALE,n);
    p.yx = m2*p.yx;
    p.yz = m2*p.yz;
    p *= 2.3;
    float f3 = triplanarSampling(p*BUMP_MAP_UV_SCALE,n);
    return f1+0.5*f2+0.25*f3;
}

vec3 normalMap(vec3 p, vec3 n)
{
    float d = 0.005;
    float po = triplanarNoise(p,n);
    float px = triplanarNoise(p+vec3(d,0,0),n);
    float py = triplanarNoise(p+vec3(0,d,0),n);
    float pz = triplanarNoise(p+vec3(0,0,d),n);
    return normalize(vec3((px-po)/d,
                          (py-po)/d,
                          (pz-po)/d));
}

struct Cam
{
    vec3 R;//Right, 
    vec3 U;//Up,
    vec3 D;//Direction,
    vec3 o;//origin (pos)
};
Cam CAM_animate(vec2 uv)
{
    float PI = 3.14159;
    float rotX = 2.0*PI*(iMouse.x/iResolution.x+iGlobalTime*0.05);
    Cam cam;
    cam.o = vec3(cos(rotX),0.475,sin(rotX))*2.3;
    cam.D = normalize(vec3(0,-0.25,0)-cam.o);
    cam.R = normalize(cross(cam.D,vec3(0,1,0)));
    cam.U = cross(cam.R,cam.D);
    return cam;
}
vec3 CAM_getRay(Cam cam,vec2 uv)
{
    uv *= 2.0*iResolution.x/iResolution.y;;
    return normalize(uv.x*cam.R+uv.y*cam.U+cam.D*2.5);
}

vec4 processSliders(in vec2 fragCoord)
{
    vec4 sliderVal = texture2D(iChannel2,vec2(0,0));
    ROUGHNESS       = sliderVal[0]*4.0;
    ISOVALUE        = 0.005+sliderVal[1]*0.1;
    ICE_COLOR       = sliderVal[2];
    REFRACTION_IDX  = 1.0+sliderVal[3];
    
    if(length(fragCoord.xy-vec2(0,0))>1.)
    {
        return texture2D(iChannel2,fragCoord.xy/iResolution.xy);
    }
    return vec4(0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 cSlider = processSliders(fragCoord);
    vec2 uv = (fragCoord.xy-0.5*iResolution.xy) / iResolution.xx;
    
    Cam cam = CAM_animate(uv);
    vec3 d = CAM_getRay(cam,uv);
    vec3 c = main_render(cam.o, d, uv);
    
    //Vignetting
    float lensRadius = 0.65;
    uv /= lensRadius;
    float sin2 = uv.x*uv.x+uv.y*uv.y;
    float cos2 = 1.0-min(sin2*sin2,1.0);
    float cos4 = cos2*cos2;
    c *= cos4;
    
    //Gamma
    c = pow(c,vec3(0.4545)); //2.2 Gamma compensation
    
    //Apply slider overlay
    c = mix(c,cSlider.rgb,cSlider.a);
    
    fragColor = vec4(c,1.0);
}