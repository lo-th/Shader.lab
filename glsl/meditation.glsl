// Created by sebastien durand - 2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------

// Lightening, essentially based on one of incredible TekF shaders:
// https://www.shadertoy.com/view/lslXRj

// Pupils effect came from lexicobol shader: [famous iq tutorial]
// https://www.shadertoy.com/view/XsjXz1

// Smooth max from cabbibo shader:
// https://www.shadertoy.com/view/Ml2XDw

//-----------------------------------------------------

// Display distance field in a plane perpendicular to camera crossing pt(0,0,0)
//#define DRAW_DISTANCE


#ifndef DRAW_DISTANCE
// To enable mouse rotation (enable to explore modeling)
//  #define MOUSE

// Change this to improve quality (3 is good)
    #define ANTIALIASING 3

#else

// To enable mouse rotation (enable to explore modeling)
   #define MOUSE

// Change this to improve quality (3 is good)
  #define ANTIALIASING 1

#endif

// consts
const float tau = 6.2831853;
const float phi = 1.61803398875;

// Isosurface Renderer
const int g_traceLimit=48;
const float g_traceSize=.005;

// globals
const vec3 g_nozePos = vec3(0,-.28+.04,.47+.08);
const vec3 g_eyePos = vec3(.14,-.14,.29);
const float g_eyeSize = .09;

vec3 g_envBrightness = vec3(.5,.6,.9); // Global ambiant color
vec3 g_lightPos;
mat2 ma, mb, mc, g_eyeRot, g_headRotH, g_headRot;
float animNoze;
    
bool g_bHead = true, g_bBody = true;

// -----------------------------------------------------------------


float hash( float n ) { return fract(sin(n)*43758.5453123); }

float noise( in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = texture2D( iChannel0, (uv+ 0.5)/256.0, -100.0 ).yx;
    return mix( rg.x, rg.y, f.z );
}

// Smooth HSV to RGB conversion 
// [iq: https://www.shadertoy.com/view/MsS3Wc]
vec3 hsv2rgb_smooth(float x, float y, float z) {
    vec3 rgb = clamp( abs(mod(x*6.+vec3(0.,4.,2.),6.)-3.)-1., 0., 1.);
    rgb = rgb*rgb*(3.-2.*rgb); // cubic smoothing   
    return z * mix( vec3(1), rgb, y);
}

// Distance from ray to point
float distance(vec3 ro, vec3 rd, vec3 p) {
    return length(cross(p-ro,rd));
}

// Intersection ray / sphere
bool intersectSphere(in vec3 ro, in vec3 rd, in vec3 c, in float r, out float t0, out float t1) {
    ro -= c;
    float b = dot(rd,ro), d = b*b - dot(ro,ro) + r*r;
    if (d<0.) return false;
    float sd = sqrt(d);
    t0 = max(0., -b - sd);
    t1 = -b + sd;
    return (t1 > 0.);
}

// -- Modeling Primitives ---------------------------------------------------

float udRoundBox(in vec3 p,in vec3 b, in float r) {
  return length(max(abs(p)-b,0.0))-r ;
}

float sdCapsule(in vec3 p, in vec3 a, in vec3 b, in float r0, in float r1 ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0., 1.);
    return length( pa - ba*h ) - mix(r0,r1,h);
}

// capsule with bump in the middle -> use for neck
vec2 sdCapsule2(in vec3 p,in vec3 a,in vec3 b, in float r0,in float r1,in float bump) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1. );
    float dd = bump*sin(3.14*h);  // Little adaptation
    return vec2(length(pa - ba*h) - mix(r0,r1,h)*(1.+dd), 1.); 
}

float smin(in float a, in float b, in float k ) {
    float h = clamp( .5+.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.-h);
}

// Smooth max from cabbibo shader:
// https://www.shadertoy.com/view/Ml2XDw
float smax(in float a, in float b, in float k) {
    return log(exp(a/k)+exp(b/k))*k;
}

float sdEllipsoid( in vec3 p, in vec3 r) {
    return (length(p/r ) - 1.) * min(min(r.x,r.y),r.z);
}



// -- Modeling Head ---------------------------------------------------------

float dEar(in vec3 p, in float scale_ear) {
    vec3 p_ear = scale_ear*p;
    p_ear.xy *= ma;
    p_ear.xz *= ma; 
    float d = max(-sdEllipsoid(p_ear-vec3(.005,.025,.02), vec3(.07,.11,.07)), 
                       sdEllipsoid(p_ear, vec3(.08,.12,.09)));
    p_ear.yz *= mb; 
    d = max(p_ear.z, d); 
    d = smin(d, sdEllipsoid(p_ear+vec3(.035,.045,.01), vec3(.04,.04,.018)), .01);
    return d/scale_ear;
}

float dSkinPart(in vec3 pgeneral, in vec3 p) {
#ifndef DRAW_DISTANCE    
    if (!g_bHead) return 100.;
#endif
    
// Neck    
    float dNeck = sdCapsule2(pgeneral, vec3(0,-.24,-.11), vec3(0,-.7,-.12), .22, .12, -.45).x;
    
    float d = 1000.;
   
// Skull modeling -------------------------
    d = sdEllipsoid(p-vec3(0,.05,.0), vec3(.39,.48,.46));                 
    d = smin(d, sdEllipsoid(p-vec3(0.,.1,-.15), vec3(.42,.4,.4)),.1);     
    d = smin(d, udRoundBox(p-vec3(0,-.28,.2), vec3(.07,.05,.05),.05),.4); // Basic jaw 
    // small forehead correction with a rotated plane
    vec3 p_plane = p; 
    p_plane.yz *= ma;
    d = smax(d, p_plane.z-.68, .11);  

// Neck -----------------------------------
    d = smin(d, dNeck, .05);

// Symetrie -------------------------------
    p.x = abs(p.x);

// Eye hole 
    d = smax(d, -sdEllipsoid(p-vec3(.12,-.16,.48), vec3(.09,.06,.09)), .07);

// Noze ------------------------------------
    d = smin(d, max(-(length(p-vec3(.032,-.325,.45))-.028),   // Noze hole
                    smin(length(p-vec3(.043,-.29+.015*animNoze,.434))-.01,  // Nostrils
                    sdCapsule(p, vec3(0,-.13,.39), vec3(0,-.28+.004*animNoze,.47), .01,.04), .05)) // Bridge of the nose
            ,.065); 
   
// Mouth -----------------------------------    
    d = smin(d, length(p- vec3(.22,-.34,.08)), .17); // Jaw
    d = smin(d, sdCapsule(p, vec3(.16,-.35,.2), vec3(-.16,-.35,.2), .06,.06), .15); // Cheeks
   
    d = smin(d, max(-length(p.xz-vec2(0,.427))+.015,    // Line under the noze
                max(-p.y-.41+.008*animNoze,                         // Upper lip
                    sdEllipsoid(p- vec3(0,-.34,.37), vec3(.08,.15,.05)))), // Mouth bump
             .032);

// Chin -----------------------------------  
    d = smin(d, length(p- vec3(0,-.5,.26)), .2);   // Chin
    d = smin(d, length(p- vec3(0,-.44,.15)), .25); // Under chin 
  
    //d = smin(d, sdCapsule(p, vec3(.24,-.1,.33), vec3(.08,-.05,.46), .0,.01), .11); // Eyebrow 
    
// Eyelid ---------------------------------
    vec3 p_eye1 = p - g_eyePos;
    p_eye1.xz *= mb;
    
    vec3 p_eye2 = p_eye1;
    float d_eye = length(p_eye1) - g_eyeSize;
          
    p_eye1.yz *= g_eyeRot;
    p_eye2.zy *= mc;
    
    float d1 = min(max(-p_eye1.y,d_eye - .01),
                   max(p_eye2.y,d_eye - .005));
    d = smin(d,d1,.01);

// Ear ------------------------------------
    d = smin(d, dEar(vec3(p.x-.4,p.y+.22,p.z), .9), .01);    

//  d = max(p.y+cos(iGlobalTime),d); // Cut head  :)
    return d; 
}

float dEye(vec3 p_eye) {
    p_eye.xz *= ma;     
    return length(p_eye) - g_eyeSize;
}

vec2 min2(in vec2 dc1, in vec2 dc2) {
    return dc1.x < dc2.x ? dc1 : dc2; 
}

vec2 dToga(vec3 p) {
#ifndef DRAW_DISTANCE        
    if (!g_bBody) return vec2(100.,-1.);
#endif
    
    p -= vec3(0.,0.,-.02);
    
    float d_skin = udRoundBox(p- vec3(0,-1.22,-.12), vec3(.25,.5,.0), .13); // Shoulder

    // Scarf
    float d1 = udRoundBox(p - vec3(-.05, -1.02,-.1), vec3(.15, .25, .0), .22);
    float r = length(p-vec3(1.,0,-.1))-1.25;
    d1 = max(d1, -r);
    d1 = max(d1+.007*sin(r*42.+.6), (length(p-vec3(1.,.1,-.1))-1.62)); 
    
    // Toga
    float d = .004*smoothstep(.0,.45, -p.x)*cos(r*150.)+udRoundBox(p - vec3(-.05, -1.,-.1), vec3(.15, .23, .0), .2);
    
 //   d = min(d , length(p- vec3(0,-.018,.02))-.65);
 //   d = min(d , length(p- vec3(0,-.7,.02))-.5);
        
    return min2(vec2(d_skin,2.), min2(vec2(d,0.), vec2(d1, 1.)));
}


vec3 headRotCenter = vec3(0,-.2,-.07);
float map( vec3 p) {
    float d = dToga(p).x;
    
    vec3 p0 = p;
    p -= headRotCenter;
    p.yz *= g_headRotH;
    p.xz *= g_headRot;
    p += headRotCenter;
    
    d = min(d, dSkinPart(p0,p));
    p.x = abs(p.x);
    d = min(d, dEye(p- g_eyePos));
    return d;
}


// render for color extraction
float colorField(vec3 p) {
    vec2 dc = dToga(p);
    vec3 p0 = p;
    p -= headRotCenter;
    p.yz *= g_headRotH;
    p.xz *= g_headRot;
    p += headRotCenter;

    dc = min2(dc, vec2(dSkinPart(p0,p), 2.));
         
    p.x = abs(p.x);
    return min2(dc, vec2(dEye(p - g_eyePos), 3.)).y;
}


// ---------------------------------------------------------------------------

float SmoothMax( float a, float b, float smoothing ) {
    return a-sqrt(smoothing*smoothing + pow(max(.0,a-b),2.0));
}

vec3 Sky( vec3 ray) {
    return g_envBrightness*mix( vec3(.8), vec3(0), exp2(-(1.0/max(ray.y,.01))*vec3(.4,.6,1.0)) );
}


// -------------------------------------------------------------------
// pupils effect came from lexicobol shader:
// https://www.shadertoy.com/view/XsjXz1
// -------------------------------------------------------------------

vec3 hash3( vec2 p )
{
    vec3 q = vec3( dot(p,vec2(127.1,311.7)), 
                   dot(p,vec2(269.5,183.3)), 
                   dot(p,vec2(419.2,371.9)) );
    return fract(sin(q)*43758.5453);
}

float iqnoise( in vec2 x, float u, float v )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    float k = 1.0+63.0*pow(1.0-v,4.0);
    float va = 0.0;
    float wt = 0.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ ) {
        vec2 g = vec2(i,j);
        vec3 o = hash3( p + g )*vec3(u,u,1.0);
        vec2 r = g - f + o.xy;
        float d = dot(r,r);
        float ww = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), k );
        va += o.z*ww;
        wt += ww;
    }
    
    return va/wt;
}

float noise ( vec2 x)
{
    return iqnoise(x, 0.0, 1.0);
}

mat2 m = mat2( 0.8, 0.6, -0.6, 0.8);

float fbm( vec2 p)
{
    float f = 0.0;
    f += 0.5000 * noise(p); p *= m* 2.02;
    f += 0.2500 * noise(p); p *= m* 2.03;
    f += 0.1250 * noise(p); p *= m* 2.01;
    f += 0.0625 * noise(p); p *= m* 2.04;
    f /= 0.9375;
    return f;
}


vec3 iris(vec2 p, float open)
{
    float background = 1.0;// smoothstep(-0.25, 0.25, p.x);
    
    float r = sqrt( dot (p,p));
    float r_pupil = .15 + .15*smoothstep(.5,2.,open);

    float a = atan(p.y, p.x); // + 0.01*iGlobalTime;
    vec3 col = vec3(1.0);
    
    float ss = 0.5;// + 0.5 * sin(iGlobalTime * 2.0);
    float anim = 1.0 + 0.05*ss* clamp(1.0-r, 0.0, 1.0);
    r *= anim;
        
    if( r< .8) {
        col = vec3(0.12, 0.60, 0.57);
        float f = fbm(5.0 * p);
        col = mix(col, vec3(0.12,0.52, 0.60), f); // iris bluish green mix
        
        f = 1.0 - smoothstep( r_pupil, r_pupil+.2, r);
        col = mix(col, vec3(0.60,0.44,0.12), f); //yellow
        
        a += 0.05 * fbm(20.0*p);
        
        f = smoothstep(0.3, 1.0, fbm(vec2(5.0 * r, 20.0 * a))); // white highlight
        col = mix(col, vec3(1.0), f);
        
        f = smoothstep(0.3, 1.0, fbm(vec2(5.0 * r, 5.0 * a))); // yellow highlight
        col = mix(col, vec3(0.60,0.44,0.12), f);
        
        f = smoothstep(0.5, 1.0, fbm(vec2(5.0 * r, 15.0 * a))); // dark highlight
        col *= 1.0 - f;
        
        f = smoothstep(0.55, 0.8, r); //dark at edge
        col *= 1.0 - 0.6*f;
        
        f = smoothstep( r_pupil, r_pupil + .05, r); //pupil
        col *= f; 
        
        f = smoothstep(0.75, 0.8, r);
        col = .5*mix(col, vec3(1.0), f);
    }
    
    return col * background;
}

// -------------------------------------------------------------------



vec3 Shade( vec3 pos, vec3 ray, vec3 normal, vec3 lightDir1, vec3 lightDir2, vec3 lightCol1, vec3 lightCol2, float shadowMask1, float shadowMask2, float distance )
{
    
    float colorId = colorField(pos);
    
    vec3 ambient = g_envBrightness*mix( vec3(.2,.27,.4), vec3(.4), (-normal.y*.5+.5) ); // ambient
    
    // ambient occlusion, based on my DF Lighting: https://www.shadertoy.com/view/XdBGW3
    float aoRange = distance/20.0;
    
    float occlusion = max( 0.0, 1.0 - map( pos + normal*aoRange )/aoRange ); // can be > 1.0
    occlusion = exp2( -2.0*pow(occlusion,2.0) ); // tweak the curve
    
    ambient *= occlusion*.8+.2; // reduce occlusion to imply indirect sub surface scattering

    float ndotl1 = max(.0,dot(normal,lightDir1));
    float ndotl2 = max(.0,dot(normal,lightDir2));
    
    float lightCut1 = smoothstep(.0,.1,ndotl1);
    float lightCut2 = smoothstep(.0,.1,ndotl2);

    vec3 light = vec3(0);
    

    light += lightCol1*shadowMask1*ndotl1;
    light += lightCol2*shadowMask2*ndotl2;

    
    // And sub surface scattering too! Because, why not?
    float transmissionRange = distance/10.0; // this really should be constant... right?
    float transmission1 = map( pos + lightDir1*transmissionRange )/transmissionRange;
    float transmission2 = map( pos + lightDir2*transmissionRange )/transmissionRange;
    
    vec3 sslight = lightCol1 * smoothstep(0.0,1.0,transmission1) + lightCol2 * smoothstep(0.0,1.0,transmission2);
    vec3 subsurface = vec3(1,.8,.5) * sslight;

    float specularity = .2; 
    vec3 h1 = normalize(lightDir1-ray);
    vec3 h2 = normalize(lightDir2-ray);
    
    float specPower;
    specPower = exp2(3.0+5.0*specularity);

    vec3 p = pos;
    p -= headRotCenter;
    p.yz *= g_headRotH;
    p.xz *= g_headRot;
    p += headRotCenter;

    vec3 albedo;
    if (colorId < .5) {  
        // Toge 1
        albedo = vec3(1.,.6,0.);
        specPower = sqrt(specPower);
    } else if (colorId < 1.5) {  
        // Toge 2
        albedo = vec3(.6,.3,0.);
        specPower = sqrt(specPower);
    } else if (colorId < 2.5) {
         // Skin color
        albedo = vec3(.6,.43,.3); 
        float v = 1.;
        if (p.z>0.) {
            v = smoothstep(.02,.03, length(p.xy-vec2(0,-.03)));
        }
        albedo = mix(vec3(.5,0,0), albedo, v);
         
    } else {
        // Eye
        if (p.z>0.) {
            vec3 g_eyePosloc = g_eyePos;
            g_eyePosloc.x *= sign(p.x);
            vec3 pe = p - g_eyePosloc;
 
            // Light point in face coordinates
            vec3 g_lightPos2 = g_lightPos - headRotCenter;
            g_lightPos2.yz *= g_headRotH;
            g_lightPos2.xz *= g_headRot;
            g_lightPos2 += headRotCenter;

            vec3 dir = normalize(g_lightPos2-g_eyePosloc);
            
            float a = clamp(atan(-dir.x, dir.z), -.6,.6), 
                  ca = cos(a), sa = sin(a);
            pe.xz *= mat2(ca, sa, -sa, ca);

            float b = clamp(atan(-dir.y, dir.z), -.3,.3), 
                  cb = cos(b), sb = sin(b);
            pe.yz *= mat2(cb, sb, -sb, cb);
            
            albedo = (pe.z>0.) ? iris(17.*(pe.xy), length(g_lightPos2-g_eyePosloc)) : vec3(1);
        }
        specPower *= specPower;
     }
    
    vec3 specular1 = lightCol1*shadowMask1*pow(max(.0,dot(normal,h1))*lightCut1, specPower)*specPower/32.0;
    vec3 specular2 = lightCol2*shadowMask2*pow(max(.0,dot(normal,h2))*lightCut2, specPower)*specPower/32.0;
    
    vec3 rray = reflect(ray,normal);
    vec3 reflection = Sky( rray );
    
    // specular occlusion, adjust the divisor for the gradient we expect
    float specOcclusion = max( 0.0, 1.0 - map( pos + rray*aoRange )/(aoRange*max(.01,dot(rray,normal))) ); // can be > 1.0
    specOcclusion = exp2( -2.0*pow(specOcclusion,2.0) ); // tweak the curve
    
    // prevent sparkles in heavily occluded areas
    specOcclusion *= occlusion;

    reflection *= specOcclusion; // could fire an additional ray for more accurate results
    
    float fresnel = pow( 1.0+dot(normal,ray), 5.0 );
    fresnel = mix( mix( .0, .01, specularity ), mix( .4, 1.0, specularity ), fresnel );

    light += ambient;
    light += subsurface;

    vec3 result = light*albedo;
    result = mix( result, reflection, fresnel );
    result += specular1;
    result += specular2;

    return result;
}


float Trace( vec3 pos, vec3 ray, float traceStart, float traceEnd )
{
    float t0=0.,t1=100.;
    float t2=0.,t3=100.;
    // trace only if intersect bounding spheres
#ifndef DRAW_DISTANCE       
    g_bHead = intersectSphere(pos, ray, vec3(0,-.017,.02), .65, t0, t1);
    g_bBody = intersectSphere(pos, ray, vec3(0,-.7,.02), .5, t2, t3);
    if (g_bHead || g_bBody) 
#endif        
    {   
            float t = max(traceStart, min(t2,t0));
            traceEnd = min(traceEnd, max(t3,t1));
            float h;
            for( int i=0; i < g_traceLimit; i++) {
                h = map( pos+t*ray );
                if (h < g_traceSize || t > traceEnd)
                    return t>traceEnd?100.:t;
                t = t+h;
            }
      }
    
    return 100.0;
}



vec3 Normal( vec3 pos, vec3 ray, float t) {

    float pitch = .2 * t / iResolution.x;
    
//#ifdef FAST
//  // don't sample smaller than the interpolation errors in Noise()
    pitch = max( pitch, .005 );
//#endif
    
    vec2 d = vec2(-1,1) * pitch;

    vec3 p0 = pos+d.xxx; // tetrahedral offsets
    vec3 p1 = pos+d.xyy;
    vec3 p2 = pos+d.yxy;
    vec3 p3 = pos+d.yyx;
    
    float f0 = map(p0);
    float f1 = map(p1);
    float f2 = map(p2);
    float f3 = map(p3);
    
    vec3 grad = p0*f0+p1*f1+p2*f2+p3*f3 - pos*(f0+f1+f2+f3);
    //return normalize(grad);
    // prevent normals pointing away from camera (caused by precision errors)
    return normalize(grad - max(.0,dot (grad,ray ))*ray);
}


// Camera
vec3 Ray( float zoom, in vec2 fragCoord) {
    return vec3( fragCoord.xy-iResolution.xy*.5, iResolution.x*zoom );
}

vec3 Rotate( inout vec3 v, vec2 a ) {
    vec4 cs = vec4( cos(a.x), sin(a.x), cos(a.y), sin(a.y) );
    
    v.yz = v.yz*cs.x+v.zy*cs.y*vec2(-1,1);
    v.xz = v.xz*cs.z+v.zx*cs.w*vec2(1,-1);
    
    vec3 p;
    p.xz = vec2( -cs.w, -cs.z )*cs.x;
    p.y = cs.y;
    
    return p;
}


// Camera Effects

void BarrelDistortion( inout vec3 ray, float degree ){
    // would love to get some disperson on this, but that means more rays
    ray.z /= degree;
    ray.z = ( ray.z*ray.z - dot(ray.xy,ray.xy) ); // fisheye
    ray.z = degree*sqrt(ray.z);
}


mat2 matRot(in float a) {
    float ca = cos(a), sa = sin(a);
    return mat2(ca,sa,-sa,ca);
}

#ifdef DRAW_DISTANCE

// ---------------------------------------------
const vec3 ep2 = vec3(.001,0.,0.); 
vec3 gradAt(in vec3 p) {
    return vec3(
            map(p+ep2.xyy) - map(p-ep2.xyy),
            map(p+ep2.yxy) - map(p-ep2.yxy),
            map(p+ep2.yyx) - map(p-ep2.yyx));
}

float isoline(vec3 p, vec3 n, float pas, float tickness) {
    float dist = map(p);
    vec3 grad = (dist - vec3(map(p-ep2.xyy), map(p-ep2.yxy), map(p-ep2.yyx)));
    grad -= n*dot(grad,n);
    float k = length(grad);
    if (k != 0.) {
        k = (iResolution.x*ep2.x)/(k*tickness);
        float v1 = abs(mod(dist+pas*.5, pas)-pas*.5)*k/3.;
        float v2 = abs(mod(dist+pas*2., pas*4.)-pas*2.)*k/4.;
        float v3 = abs(dist)*k/8.;
        return smoothstep(.01,.99, v3) * (.5+.5*smoothstep(.01,.99, v1)) * smoothstep(.01,.99, v2);
    } 
    return 1.;
}

vec3 heatmapGradient(in float t) {
    return clamp((pow(t, 1.5) * .8 + .2) * vec3(smoothstep(0., .35, t) + t * .5, smoothstep(.5, 1., t), max(1. - t * 1.7, t * 7. - 6.)), 0., 1.);
}

bool intersectPlane(in vec3 ro, in vec3 rd, in vec3 pt, in vec3 n, out float t) {
    float k = dot(rd, n);
    if (k == 0.) return false;
    t = (dot(pt, n)-dot(ro,n))/k;
    return t>0.;
}
#endif

// -------------------------------------------

const float
    a_eyeClose = .55, 
    a_eyeOpen = -.3;


const float 
    t_apear = 5.,
    t_noze = t_apear+8., 
    t_openEye = t_noze + 1.,
    t_g_headRot = t_openEye + 4.5,
    t_rotDown = t_g_headRot + 3.5,
    t_outNoze = t_rotDown + 3.,
    t_night = t_outNoze + 4.,
    t_colorfull = t_night + 5.,
    t_disapear = t_colorfull + 2.,
    t_closeEye = t_disapear + 3.;


void main(){

    float st = 1.2; // speed coeff
    float time = mod(iGlobalTime*st+55., 62.831);
    
// constantes
    ma = matRot(-.5);
    mb = matRot(-.15);
    mc = matRot(-.6);

// Eye blink
    float a_PaupieresCligne = mix(a_eyeOpen,a_eyeClose, hash(floor(time*10.))>.98?2.*abs(fract(20.*time)-.5):0.);    
    float a_Paupieres = mix(a_eyeClose, .2, smoothstep(t_openEye, t_openEye+2., time));    
    a_Paupieres = mix(a_Paupieres, a_PaupieresCligne, smoothstep(t_rotDown, t_rotDown+1., time));
    a_Paupieres = mix(a_Paupieres, a_eyeClose, smoothstep(t_closeEye, t_closeEye+3., time));

    g_eyeRot = matRot(a_Paupieres);

// rotation de la tete 
    float a_headRot = 0.1, a_headRotH = 0.1;
    
    a_headRot = mix(0., .2*cos(20.*(time-t_g_headRot)), smoothstep(t_g_headRot, t_g_headRot+.5, time)-smoothstep(t_g_headRot+1., t_g_headRot+1.5, time));
    a_headRotH = mix(-.1, .2*sin(20.*(time-t_g_headRot)), smoothstep(t_g_headRot+1.5, t_g_headRot+2., time)-smoothstep(t_g_headRot+2., t_g_headRot+2.5, time));
    a_headRotH = mix(a_headRotH, .3, smoothstep(t_g_headRot+2.6, t_rotDown, time));
    a_headRotH = mix(a_headRotH, -.2, smoothstep(t_outNoze, t_outNoze+2., time));
    a_headRotH = mix(a_headRotH, -.1, smoothstep(t_closeEye, t_closeEye+3., time));
    
    g_headRot = matRot(a_headRot); 
    g_headRotH = matRot(a_headRotH); 
    mat2 g_headRot2 = matRot(-a_headRot); 
    mat2 g_headRotH2 = matRot(-a_headRotH); 

// Position du nez
    animNoze = smoothstep(t_openEye+2., t_openEye+2.1, time) - smoothstep(t_openEye+2.1, t_openEye+2.3, time)
             + smoothstep(t_openEye+2.5, t_openEye+2.6, time) - smoothstep(t_openEye+2.6, t_openEye+2.8, time);
    
    vec3 p_noze = g_nozePos - headRotCenter;
    p_noze.xz *= g_headRot2;
    p_noze.yz *= g_headRotH2;
    p_noze += headRotCenter;

// Positon du point lumineux
    float distLightRot = mix(1., .4, smoothstep(3.,t_noze-2., time));
    vec3 centerLightRot = vec3(0,.2,1.7);
                              
    float lt = 3.*(time-1.);
    vec3 lightRot = centerLightRot + distLightRot*vec3(cos(lt*.5), .025*sin(2.*lt), sin(lt*.5));
    
    g_lightPos = mix(lightRot, p_noze+.004*animNoze, smoothstep(t_noze, t_noze + 1., time));
    g_lightPos = mix(g_lightPos, lightRot, smoothstep(t_outNoze,t_outNoze+2., time));

// intensitee et couleur du point
    float lightAppear = smoothstep(t_apear, t_apear+2., time)-smoothstep(t_disapear, t_disapear+3., time);
    vec3 lightCol2 = hsv2rgb_smooth(.6*(floor(st*iGlobalTime/62.831))+.04,1.,.5);
    
    // Ambiant color
    g_envBrightness = mix(vec3(.6,.65,.9), vec3(.02,.03,.05), smoothstep(t_night, t_night+3., time));
    g_envBrightness = mix(g_envBrightness, lightCol2, smoothstep(t_colorfull, t_colorfull+1., time));
    g_envBrightness = mix(g_envBrightness, vec3(.6,.65,.9), smoothstep(t_disapear+5., t_disapear+9., time));
    

    vec3 lightDir1 = normalize(vec3(.5,1.5,1.5));
    vec3 lightCol1 = vec3(1.1,1.,.9)*.7*g_envBrightness;

    float lightRange2 = .4; 
    float traceStart = 0.;
    float traceEnd = 40.0;

    vec3 col, colorSum = vec3(0.);

#if (ANTIALIASING == 1) 
    int i=0;
#else
    for (int i=0;i<ANTIALIASING;i++) {
#endif
        col = vec3(0);

        // Camera    

#if (ANTIALIASING == 1)         
        float randPix = 0.;
#else 
        float randPix = hash(iGlobalTime); // Use frame rate to improve antialiasing ... not sure of result
#endif        
        vec2 subPix = .4*vec2(cos(randPix+6.28*float(i)/float(ANTIALIASING)),
                              sin(randPix+6.28*float(i)/float(ANTIALIASING)));
        vec3 ray = Ray(2.0,gl_FragCoord.xy+subPix);
        
        BarrelDistortion(ray, .5 );
        
        ray = normalize(ray);
        vec3 localRay = ray;
        vec2 mouse = vec2(0);
    #ifdef MOUSE
        if ( iMouse.z > 0.0 )
            mouse = .5-iMouse.yx/iResolution.yx;
        vec3 pos = 5.*Rotate(ray, vec2(-.1,1.+time*.1)+vec2(-1.0,-3.3)*mouse );        
    #else    
        vec3 pos = vec3(0,0,.6) + 5.5*Rotate(ray, vec2(-.1,1.+time*.1));        
    #endif

        
#ifdef DRAW_DISTANCE    
        float tPlane;
        if (intersectPlane(pos, ray, vec3(0.), -ray, tPlane)) {
            vec3 p = pos+tPlane*ray;
            float dist = map(p);
            if (dist > 0.) {
                col = .1+.8*heatmapGradient(clamp(1.2*dist,0.,10.));   
            }
            else {
                col.brg = .1+.8*heatmapGradient(clamp(-1.2*dist,0.,10.));     
            }
            col *= isoline(p, -ray, .05, 1.); 
          
        } 
        else {
            col = vec3(0);
        }
#else            
        float t = Trace(pos, ray, traceStart, traceEnd );
        if ( t < 10.0 )
        {           
            vec3 p = pos + ray*t;
            
            // Shadows
            vec3 lightDir2 = g_lightPos-p;
            float lightIntensity2 = length(lightDir2);
            lightDir2 /= lightIntensity2;
            lightIntensity2 = lightAppear*lightRange2/(.1+lightIntensity2*lightIntensity2);
            
            float s1 = 0.0;
            s1 = Trace(p, lightDir1, .05, 4.0 );
            float s2 = 0.0;
            s2 = Trace(p, lightDir2, .05, 4.0 );
            
            vec3 n = Normal(p, ray, t);
            col = Shade(p, ray, n, lightDir1, lightDir2,
                        lightCol1, lightCol2*lightIntensity2,
                        (s1<20.0)?0.0:1.0, (s2<20.0)?0.0:1.0, t );
            
            // fog
            float f = 200.0;
            col = mix( vec3(.8), col, exp2(-t*vec3(.4,.6,1.0)/f) );
        }
        else
        {
            col = Sky( ray );
        }
        // Draw light
        float s1 = max(distance(pos, ray, g_lightPos)+.03,0.);
        float dist = length(g_lightPos-pos);
        if (dist < t) {
            vec3 col2 = lightCol2*2.5*exp( -.01*dist*dist );
            float BloomFalloff = 15000.; //mix(1000.,5000., Anim);
            col = col *(1.-lightAppear) + lightAppear*mix(col2, col, smoothstep(.037,.047, s1));
            col += lightAppear*col2*col2/(1.+s1*s1*s1*BloomFalloff);
        }
        
#endif          
        

    // Post traitments -----------------------------------------------------    
        // Vignetting:
        col *= smoothstep(.5, .0, dot(localRay.xy,localRay.xy) );

            
        colorSum += col;
        
#if (ANTIALIASING > 1)  
    }
    
    col = colorSum/float(ANTIALIASING);
#else
    col = colorSum;
#endif

    #if defined( TONE_MAPPING ) 
    col = toneMapping( col ); 
    #endif

    // Compress bright colours, (because bloom vanishes in vignette)
    vec3 c = (col-1.0);
    c = sqrt(c*c+.05); // soft abs
    col = mix(col,1.0-c,.48); // .5 = never saturate, .0 = linear
    
    // compress bright colours
    float l = max(col.x,max(col.y,col.z));//dot(col,normalize(vec3(2,4,1)));
    l = max(l,.01); // prevent div by zero, darker colours will have no curve
    float l2 = SmoothMax(l,1.0,.01);
    col *= l2/l;
    
    gl_FragColor =  vec4(pow(col,vec3(1./1.6)),1);
}
