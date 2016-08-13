/*
"Tunnel with lamps" by Emmanuel Keller aka Tambako - June 2016
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Contact: tamby@tambako.ch
*/

#define pi 3.14159265359

// Switches, you can play with them!
#define specular
#define reflections
#define show_water
//#define debug_water
#define show_lamps
#define lamps_blink
#define dirty_tube
#define show_fog

// Lamp structure
struct Lamp
{
    vec3 position;
    vec3 color;
    float intensity;
    float attenuation;
};
    
// Directional lamp structure
struct DirLamp
{
  vec3 direction;
  vec3 color;
  float intensity;
};

struct RenderData
{
    vec3 col;
    vec3 pos;
    vec3 norm;
    int objnr;
};
    
struct TransMat
{
    vec3 col_vol;
    vec3 col_dif;
    vec3 col_fil;
    vec3 col_dev;
    float specint;
    float specshin;
    float ior;
};
    
// Every object of the scene has its ID
#define TUNNEL_OBJ     1
#define WATER_OBJ      2
#define LAMPS_OBJ      3

DirLamp lamps[4];

// Campera options
vec3 campos = vec3(0., 0., 0.);
vec3 camtarget = vec3(0., 0., 0.);
vec3 camdir = vec3(0., 0., -1.);
const float camSpeed = 2.7;
const float camPosY = 0.04;
float fov = 2.8;

// Ambient light
const vec3 ambientColor = vec3(0.3);
const float ambientint = 0.2;

// Color options
const vec3 tunnelColor = vec3(0.9, 0.6, 0.28);
const vec3 tunnelColor2 = vec3(0.26, 0.42, 0.28);
const vec3 lampColor = vec3(1., 0.9, 0.4);

// Shading options
const float specint = 0.8;
const float specshin  = 125.;
const float aoint = 0.4;

// Tracing options
const float normdelta = 0.001;
const float maxdist = 280.;

// Antialias. Change from 1 to 2 or more AT YOUR OWN RISK! It may CRASH your browser while compiling!
const float aawidth = 0.8;
const int aasamples = 2;

// Tunnel options
const float tubeRadius = 0.22;
const float dz = 0.01;
const float tsf = 4.5;
const float ltr0 = 0.9;

// Water options
const float waterLevel = 0.22;
const float wavesLev = 0.004;
const float wavesFreq = 18.;

// Fog options
const float fogDens0 = 5.5;
const vec3 fogColor0 = vec3(0.6, 0.62, 0.67);
const vec3 fogColorT = vec3(1.12, 0.51, 1.37);
const float fogFreq = 15.;

float aaIndex = 0.;
bool traceWater = true;
TransMat waterMat;

// X (left-right) Deviation of the tunnel curve in function of Z
float tunnel_curve(float z)
{
    float fz = 0.4;
    float c1 = 0.5*sin(z*0.1*fz) + 0.3*sin(z*0.18*fz) + 0.2*sin(z*0.47*fz);
    float c2 = 4.*(smoothstep(0.1, 1.0, c1) - smoothstep(-0.1, -1., c1));
    return c2;
}

// Y (height) Deviation of the tunnel curve in function of Z
float tunnel_curve_y(float z)
{
    float fz = 0.2;
    float c1 = 0.7*sin(z*0.114*fz) + 0.3*sin(z*0.144*fz);
    float c2 = 0.25*smoothstep(0.8, 1.0, c1) - 0.78*smoothstep(-0.844, -0.944, c1);
    return c2;
}

// Derivate of the X tunnel curve
float dev_tunnel_curve(float z)
{
    float v1 = tunnel_curve(z - dz*0.5); 
    float v2 = tunnel_curve(z + dz*0.5);
    return (v2-v1)/dz;
}

void init()
{
    lamps[0] = DirLamp(vec3(-2., 1., -5.), vec3(0.4, 0.5, 1.), 1.2);   // Blue ambient 1
    lamps[1] = DirLamp(vec3(0., -3., 0.), vec3(0.5, 0.57, 1.), 1.);  // Blue ambient 2
    lamps[2] = DirLamp(vec3(2., -1., 5.), vec3(1., 0.85, 0.75), 0.8);  // Left lamps
    lamps[3] = DirLamp(vec3(2., -1., 5.), vec3(1., 0.85, 0.75), 0.8);  // Right lamps

    waterMat = TransMat(vec3(0.92, 0.94, 0.95),
                        vec3(0.01, 0.02, 0.02),
                        vec3(1.),
                        vec3(0.2, 0.3, 0.8),
                        0.4,
                        45.,
                        1.32);
    
    vec2 iMouse2;
    if (iMouse.x==0. && iMouse.y==0.)
        iMouse2 = vec2(0.5, 0.5);
    else
        iMouse2 = iMouse.xy/iResolution.xy; 
    
    const float cdz = 1.;
    float cz = iGlobalTime*camSpeed;
    float tc = tunnel_curve(cz - cdz);
    float tc2 = tunnel_curve(cz + cdz);
    float tcy = tunnel_curve_y(cz - cdz);
    float tcy2 = tunnel_curve_y(cz + cdz);
    campos = vec3(tc, tcy + camPosY, cz - cdz);
    camtarget = vec3(tc2 + (iMouse2.x - 0.5), tcy2 + (iMouse2.y - 0.5), cz + cdz);
    camdir = camtarget - campos;
}

// Union operation from iq
vec2 opU(vec2 d1, vec2 d2)
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec2 rotateVec(vec2 vect, float angle)
{
    vec2 rv;
    rv.x = vect.x*cos(angle) - vect.y*sin(angle);
    rv.y = vect.x*sin(angle) + vect.y*cos(angle);
    return rv;
}

// 1D hash function
float hash(float n)
{
    return fract(sin(n)*753.5453123);
}

// From https://www.shadertoy.com/view/4sfGzS
float noise(vec3 x)
{
    //x.x = mod(x.x, 0.4);
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix(hash(n +   0.0), hash(n +   1.0),f.x),
                   mix(hash(n + 157.0), hash(n + 158.0),f.x),f.y),
               mix(mix(hash(n + 113.0), hash(n + 114.0),f.x),
                   mix(hash(n + 270.0), hash(n + 271.0),f.x),f.y),f.z);
}

// This function knows when the water in the tunnel is toxic...
float getToxicZone(vec3 pos)
{
    return smoothstep(87., 102., mod(pos.z, 400.))*smoothstep(155., 135., mod(pos.z, 400.));
}

// Mapping function of the tunnel
float map_tunnel(vec3 pos)
{
    float tc = tunnel_curve(pos.z);
    float dc = dev_tunnel_curve(pos.z);
    pos.x-= tc;
    float zz = pos.z;
    pos.z = 0.;
    float a = atan(dc);
    pos.xz = rotateVec (pos.xz, a*0.5);
    pos.z = zz;
    
    pos.y-= tunnel_curve_y(pos.z);
    
    float tdf = (1. + 0.00007/(1.0011 + cos(tsf*pos.z)));
    float df = -length(pos.xy) + tubeRadius*tdf;
    //df = max(df, pos.y);

    return df;
}

float ltr = ltr0;
vec3 lmppos = vec3(0.);
// Mapping function of the lamps
float map_lamps(vec3 pos)
{
    float tc = tunnel_curve(pos.z);
    float dc = dev_tunnel_curve(pos.z);
    pos.x-= tc;
    float zz = pos.z;
    pos.z = 0.;
    float a = atan(dc);
    pos.xz = rotateVec (pos.xz, a);
    pos.z = zz;
    
    pos.y-= tunnel_curve_y(pos.z);
    lmppos = pos;
    a = atan(pos.x, pos.y);
    float tsf2 = tsf/(2.*pi);
    pos.z+= tsf2;
    ltr = 0.9;
    ltr+= 2.*(1. - smoothstep(0.6, 0.65, a)*smoothstep(0.95, 0.9, a))*
         (1. - smoothstep(-0.6, -0.65, a)*smoothstep(-0.95, -0.9, a));
    
    ltr+= 0.3*(1. - smoothstep(0.42, 0.58, abs(pos.z - floor(pos.z*tsf2 + 0.5)/tsf2)));
    float df = -length(pos.xy) + tubeRadius*ltr;
    return df;
}

// Mapping function of the water
float map_water(vec3 pos)
{
    float h = (pos.y/tubeRadius + 1.)/2.;
    h+= wavesLev*(noise(pos*wavesFreq + iGlobalTime*vec3(0., 0.7, 0.3)) - 0.5);
    return h - waterLevel;   
}

// Main mapping function
vec2 map(vec3 pos)
{
    float tunnel = map_tunnel(pos);
    vec2 res = vec2(tunnel, TUNNEL_OBJ);
    #ifdef show_water
    float water = map_water(pos);
    if (traceWater)
       res = opU(res, vec2(water, WATER_OBJ));
    #endif
    float lamps = map_lamps(pos);
    #ifdef show_lamps
    res = opU(res, vec2(lamps, LAMPS_OBJ));
    #endif

    return res;
}

// Main tracing function
vec2 trace(vec3 cam, vec3 ray, float maxdist) 
{
    float t = traceWater?0.01:0.17;
    float objnr = 0.;
    vec3 pos;
    float dist;
    float dist2;
    
    for (int i = 0; i < 85; ++i)
    {
        pos = ray*t + cam;
        vec2 res = map(pos);
        dist = res.x;
        if (dist>maxdist || abs(dist)<0.001)
            break;
        t+= dist*(1. - 0.0018*float(i));
        objnr = abs(res.y);
    }
    return vec2(t, objnr);
}

// From https://www.shadertoy.com/view/MstGDM
// Here the texture maping is only used for the normal, not the raymarching, so it's a kind of bump mapping. Much faster
vec3 getNormal(vec3 pos, float e)
{  
    vec2 q = vec2(0, e);
    return normalize(vec3(map(pos + q.yxx).x - map(pos - q.yxx).x,
                          map(pos + q.xyx).x - map(pos - q.xyx).x,
                          map(pos + q.xxy).x - map(pos - q.xxy).x));
}

// Gets the position of left or right lamp in function of the position (depending on the current section)
vec3 getLampPos(vec3 pos, bool left)
{
    vec3 lpos;
    float tsf2 = tsf/(2.*pi);
    lpos.z = floor(pos.z*tsf2 + 0.5)/tsf2;
    lpos.y = 0.7*tubeRadius + tunnel_curve_y(pos.z);
    float tc = tunnel_curve(pos.z);
    if (left)
        lpos.x = tc + 0.5*tubeRadius;
    else
        lpos.x = tc - 0.5*tubeRadius;
    
    return lpos;
}

// Gets how a lamp blinks in fimctopm of the time
float getLampBlink(float t, float th)
{
    float lb = 0.3*sin(t*5.86) + 0.25*sin(t*8.57) + 0.25*sin(t*17.54) + 0.2*sin(t*21.62);
    return smoothstep(th+0.02, th, lb);
}

// Gets how a lamp blinks in fimctopm of the time and its index and the current position
float getLampBlink2(float t, float lnr, vec3 pos)
{
    float lb = 1.;
    float h = hash(lnr);
    float tz = getToxicZone(pos);
    if (h>0.96 - tz)
    {
        if (hash(lnr*8.54)>0.8)
            lb = 0.;
        else
            lb = getLampBlink(t + lnr*5., -0.1 + 0.4*hash(lnr*43.5));
    }
    if (h>1.37 - tz)
        lb = 0.;
    return lb;
}

// Gets the position of the "dirtyness" at the bottom of the tunnel
float getTunnelHT(vec3 pos)
{
    float h = (pos.y/tubeRadius + 1.)/2.;
    return smoothstep(waterLevel + 0.07, waterLevel + 0.03, h) - 
      0.19*smoothstep(waterLevel + 0.05, waterLevel - 0.01, h);
}

// Gets the color of the tunnel
vec3 getTunnelColor(vec3 pos)
{
    #ifdef dirty_tube
    pos+= 0.006*(noise(pos*45.) - 0.5);
    return mix(tunnelColor, tunnelColor2, 0.65*getTunnelHT(pos)*(1. + 0.25*noise(pos*35.)));
    #else
    return tunnelColor;    
    #endif    
}

// Gets the color of the water
vec3 getWaterColor(vec3 pos)
{
    #ifdef debug_water
    return waterMat.col_dev;
    #else
    return waterMat.col_dif;
    #endif
}

// Gets the color of the lamps
vec3 getLampsColor(vec3 pos)
{
    vec3 lamppos = getLampPos(pos, true);
    float lnr = 15.*(2. + (abs(pos.x-lamppos.x)>0.1?1.:0.)) + lamppos.z/tsf;
    float lb =  getLampBlink2(iGlobalTime, lnr, pos);
    return mix(lampColor, vec3(0.22 + lb + 0.05*sin(pos.y*2100.)), smoothstep(ltr0*1.05, ltr0, ltr));
}

// Combines the colors
vec3 getColor(vec3 norm, vec3 pos, int objnr, vec3 ray)
{
   return objnr==TUNNEL_OBJ?getTunnelColor(pos):
         (objnr==LAMPS_OBJ?getLampsColor(pos):
         (objnr==WATER_OBJ?getWaterColor(pos):vec3(0.)));
}

#ifdef show_fog
// Repartition of the fog in function of the position
float getFogDensity(vec3 pos)
{
    float h = (pos.y/tubeRadius + 1.)/2.;
    float dens = smoothstep(waterLevel + 0.04, waterLevel + 0.06, h)*
                 smoothstep(waterLevel + 0.3 + 0.2*pow(noise(pos*0.6), 3.), waterLevel + 0.1, h);
    dens*= clamp(0.15*noise(pos*0.8) + 1.65*noise(pos*fogFreq + iGlobalTime*vec3(0.04, 0.23, -0.14)) - 0.3, 0., 1.);
    return dens;
}

// Color of the fog in function of the position
vec3 getFogColor(vec3 pos)
{
    vec3 lampposl = getLampPos(pos, false);
    vec3 lampposr = getLampPos(pos, true);
    
    float lnrl = 45. + lampposl.z/tsf;
    float lbl = getLampBlink2(iGlobalTime, lnrl, pos);
    float lnrr = 30. + lampposr.z/tsf;
    float lbr = getLampBlink2(iGlobalTime, lnrr, pos);
    
    float lfl = lbl*0.17/pow(0.33 + distance(lampposl, pos), 2.);
    float lfr = lbr*0.17/pow(0.33 + distance(lampposr, pos), 2.);
    float lf = 0.9 + lfl + lfr;
    
    vec3 fogColor = fogColor0;
    //float h = (pos.y/tubeRadius + 1.)/2.;
    //vec3 fogColor = mix(fogColor0, vec3(1.2, 0., 0.), smoothstep(waterLevel + 0.14, waterLevel + 0.16, h));
    
    return lf*mix(fogColor, fogColorT, clamp(1.1*getToxicZone(pos) - 0.1, 0., 1.)); 
}

// Gets the fog density and color along the ray
vec4 getFogDensColor(vec3 campos, vec3 pos, float l0, float sl0, float lf, float jitter)
{
    vec3 currPos = campos;
    vec3 ray = normalize(pos - campos);
    float tl = distance(campos, pos);
    if (tl<l0)
        return vec4(0.);
    float totl = l0;
    float sl = sl0;
    float totDens = 0.;
    vec3 totCol = vec3(0.);
    int i2 = 0;
    for (int i = 0; i < 80; ++i)
    {   
        float j = i<20?sl0/sl*jitter*(hash(13.5*aaIndex + iGlobalTime + 54.3*float(i) + 65.3*currPos.x + 28.*currPos.y + 34.*currPos.z) - 0.5):0.;
        totl+= sl*(1. + j);
        currPos = campos + ray*totl;
        float dens = getFogDensity(currPos)*pow(sl, 0.4);
        totDens+= dens;
        totCol+= getFogColor(currPos)*dens;
        i2 = i;
        if (totl>=tl)          
            break;
        sl*=lf;
    }
    float tz = getToxicZone(pos);
    return vec4(totCol/(totDens+0.001), clamp(fogDens0*totDens*(1. - 0.12*tz)/float(i2), 0., 1.));
}
#endif

// Combines the scene color with the fog
vec3 combineFog(vec3 col, vec4 fogDensColor)
{
   return mix(col, fogDensColor.rgb, fogDensColor.a) + 0.34*fogDensColor.rgb*fogDensColor.a;
}

// Fresnel reflectance factor through Schlick's approximation: https://en.wikipedia.org/wiki/Schlick's_approximation
float fresnel(vec3 ray, vec3 norm, float n2)
{
   float n1 = 1.; // air
   float angle = acos(-dot(ray, norm));
   float r0 = dot((n1 - n2)/(n1 + n2), (n1 - n2)/(n1 + n2));
   float r = r0 + (1. - r0)*pow(1. - cos(angle), 5.);
   return clamp(r, 0., 0.9);
}

// Shading of the objects pro lamp
vec3 lampShading(DirLamp lamp, vec3 norm, vec3 pos, vec3 ocol, int objnr, int lampnr)
{
    vec3 pl;
    float li;
    vec3 col;
    
    // Special shading for the lamps which are regularly attached in the tunnel
    if (lampnr>1)
    {
        vec3 lamppos = getLampPos(pos, lampnr==2);
        pl = normalize(lamppos - pos);
        float lb;
        float lnr = float(15*lampnr) + lamppos.z/tsf;
        #ifdef lamps_blink
        lb = getLampBlink2(iGlobalTime, lnr, pos);
        #else
        lb = 1.;
        #endif

        li = lb*lamp.intensity*(0.05 + 0.8/pow(0.7 + distance(lamppos*vec3(1., 1., .6), pos*vec3(1., 1., .6)), 2.));
        
        float a = atan(lmppos.x, lmppos.y);
        if (lampnr==2)
            li*= smoothstep(0.62, 0.35, a) + smoothstep(0.9, 1.15, a);
        else
            li*= smoothstep(-0.62, -0.35, a) + smoothstep(-0.9, -1.15, a);
        // Diffuse shading
        #ifdef show_lamps
        col = ocol*lamp.color*mix(li*(clamp(dot(norm, pl), 0., 1.)), 1., smoothstep(ltr0*1.05, ltr0, ltr));
        #else
        col = ocol*lamp.color*li*(clamp(dot(norm, pl), 0., 1.));
        #endif
    }
    else
    {
        pl = normalize(lamp.direction);
        li = lamp.intensity;
        float laf;
        if (objnr==WATER_OBJ)
            laf = mix(clamp(dot(norm, pl), 0., 1.), 1., getToxicZone(pos));
        else
            laf = clamp(dot(norm, pl), 0., 1.);
        // Diffuse shading
        vec3 lc = mix(lamp.color, vec3(0.6, 1., 0.8), getToxicZone(pos));
        col = ocol*lc*li*laf;
    }
    
    // Specular shading
    #ifdef specular
    float specint2 = specint*(1. - getTunnelHT(pos));
    //if (dot(norm, lamp.direction) > 0.0)
        col+= lamp.color*li*specint2*pow(max(0.0, dot(reflect(pl, norm), normalize(pos - campos))), specshin);
    #endif
    
    return col;
}

// Shading of the objects over all lamps
vec3 lampsShading(vec3 norm, vec3 pos, vec3 ocol, int objnr)
{
    vec3 col = vec3(0.);
    for (int l=0; l<4; l++) // lamps.length()
        col+= lampShading(lamps[l], norm, pos, ocol, objnr, l);
    
    return col;
}

// From https://www.shadertoy.com/view/lsSXzD, modified
vec3 GetCameraRayDir(vec2 vWindow, vec3 vCameraDir, float fov)
{
    vec3 vForward = normalize(vCameraDir);
    vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
    vec3 vUp = normalize(cross(vForward, vRight));
    
    vec3 vDir = normalize(vWindow.x * vRight + vWindow.y * vUp + vForward * fov);

    return vDir;
}

// Tracing and rendering a ray
RenderData trace0(vec3 tpos, vec3 ray, float maxdist)
{
    vec2 tr = trace(tpos, ray, maxdist);
    float tx = tr.x;
    int objnr = int(tr.y);
    vec3 col;
    vec3 pos = tpos + tx*ray;
    vec3 norm;

    if (tx<maxdist*0.95)
    {
        norm = getNormal(pos, normdelta);
        col = getColor(norm, pos, objnr, ray);
      
        // Shading
        col = ambientColor*ambientint + lampsShading(norm, pos, col, objnr);
    }
    else
    {
        col = vec3(0.);
    }
    return RenderData(col, pos, norm, objnr);
}

// Gets the turbidence of transparent material in function of the thickness and basic absorption color
vec3 getGlassAbsColor(float dist, vec3 color)
{
    return pow(color, vec3(5. + pow(dist*25., 2.3)));
}

// Main render function with reflections and refractions
vec4 render(){   

    //vec2 uv = fragCoord.xy / iResolution.xy; 
    //uv = uv*2.0 - 1.0;
    //uv.x*= iResolution.x / iResolution.y;

    vec2 uv = ((vUv - 0.5) * 2.0) * vec2(iResolution.z, 1.0);

    vec3 ray0 = GetCameraRayDir(uv, camdir, fov);
    vec3 ray = ray0;
    RenderData traceinf = trace0(campos, ray, maxdist);
    vec3 col = traceinf.col;
    vec3 pos0 = traceinf.pos;
    vec3 refray;
    int oObjNr = traceinf.objnr;
    vec3 pos;
    
    vec3 glassf = vec3(1.);

    #ifndef debug_water
    #ifdef reflections
    if (traceinf.objnr==WATER_OBJ)
    {   
        refray = reflect(ray, traceinf.norm);
        RenderData traceinf_ref = trace0(traceinf.pos, refray, 20.);
        float rf = 0.9*fresnel(ray, traceinf.norm, waterMat.ior);
        glassf*= (1. - rf);
        col = mix(col, traceinf_ref.col, rf);
    }
    #endif
    if (traceinf.objnr==WATER_OBJ)
    {
        vec3 ray_r = refract(ray, traceinf.norm, 1./waterMat.ior);           
        traceWater = false;
        pos = traceinf.pos;
        traceinf = trace0(pos, ray_r, 10.);   
        traceWater = true;
        glassf*= getGlassAbsColor(distance(pos, traceinf.pos), 
                                  mix(waterMat.col_vol, vec3(0.72, 1.05, 0.78), getToxicZone(pos)));
        glassf*= waterMat.col_fil;

        col+= clamp(traceinf.col*glassf, 0., 1.);
    }
    #endif
    
    // Combines the fog
    #ifdef show_fog
    vec4 fogDensColor = getFogDensColor(campos, pos0, 0.05, 0.008, 1.05, 1.1);
    col = combineFog(col, fogDensColor);
    #endif

    return vec4(col, 1.0);
}

void main(){   
    
    init();

    gl_FragColor = render();
}