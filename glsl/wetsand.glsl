
// ------------------ channel define
// 0_# noise #_0
// 1_# tex09 #_1
// -----------------


// Ben Quantock 2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// https://www.shadertoy.com/view/ldfXzS

// artefacts from noise texture interpolation
//#define FAST

// keys
int kA=65,kB=66,kC=67,kD=68,kE=69,kF=70,kG=71,kH=72,kI=73,kJ=74,kK=75,kL=76,kM=77,kN=78,kO=79,kP=80,kQ=81,kR=82,kS=83,kT=84,kU=85,kV=86,kW=87,kX=88,kY=89,kZ=90;
int k0=48,k1=49,k2=50,k3=51,k4=52,k5=53,k6=54,k7=55,k8=56,k9=57;
int kSpace=32,kLeft=37,kUp=38,kRight=39,kDown=40;


// TOGGLES:

// demo mode - cycle through the effects
int kDemoMode = kD;

// aesthetic toggles
int kAnimate = kA;  float pauseTime = 3.6;
//int kPrintedPaper = kP;
int kLensFX = kL;

// lighting
//int kLighting = k0; // turn all diffuse illumination on/off (to see reflections better)
//int kAlbedo = k1;
//int kShadow = k2;
//int kDirectLight = k3;
//int kAmbientGradient = k4;
int kAmbientOcclusion = kA;
int kShowAmbientOcclusion = kQ;

// specular
//int kSpecular = k9; // turn all specular on/off (to see diffuse better)
//int kSpecularHighlight = kQ;
//int kFresnel = kW;
int kReflectionOcclusion = kS;
//int kReflections = kR;
int kShowSpecularOcclusion = kW;


// key is javascript keycode: http://www.webonweboff.com/tips/js/event_key_codes.aspx
bool ReadKey( int key, bool toggle )
{
    float keyVal = texture2D( iChannel3, vec2( (float(key)+.5)/256.0, toggle?.75:.25 ) ).x;
    return (keyVal>.5)?true:false;
}


bool Toggle( int val, int index )
{
// Toggles are breaking the compile! AARGH!
// try removing a few of them, or something
// mostly want to see spec/amb occ
    
/*  float cut = fract(iGlobalTime/30.0)*11.0;
    if ( !ReadKey( kDemoMode, true ) && float(index) > cut )
    {
        return false;
    }*/
    
    // default everything to "on"
    return !ReadKey( val, true );
}


vec2 Noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);

    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;

    // On Chrome 36 I get an artefact where the texture wraps, so do the wrap manually  
    uv = fract(uv/256.0)*256.0;

#ifdef FAST
    vec4 rg = texture2D( iChannel0, (uv+0.5)/256.0, -100.0 );
#else
    // high precision interpolation, if needed
    vec4 rg = mix( mix(
                texture2D( iChannel0, (floor(uv)+0.5)/256.0, -100.0 ),
                texture2D( iChannel0, (floor(uv)+vec2(1,0)+0.5)/256.0, -100.0 ),
                fract(uv.x) ),
                  mix(
                texture2D( iChannel0, (floor(uv)+vec2(0,1)+0.5)/256.0, -100.0 ),
                texture2D( iChannel0, (floor(uv)+1.5)/256.0, -100.0 ),
                fract(uv.x) ),
                fract(uv.y) );
#endif            

    return mix( rg.yw, rg.xz, f.z );
}

float Granite( in vec3 x )
{
    return (
             abs(Noise(x* 1.0).x-.5)/1.0
            +abs(Noise(x* 2.0).x-.5)/2.0
            +abs(Noise(x* 4.0).x-.5)/4.0
            +abs(Noise(x* 8.0).x-.5)/8.0
            +abs(Noise(x*16.0).x-.5)/16.0
        )*32.0/31.0;
//          +abs(Noise(x*32.0).x-.5)/32.0
//          +abs(Noise(x*64.0).x-.5)/64.0
//      )*128.0/127.0;
}


float DistanceField( vec3 p, float t )
{
    //return p.y;
    //return (p.y - max(.0,Granite(p.xzy*vec3(1,1,0))-.5)) / 1.2;

// this doesn't get good occlusion, because the lumps don't have a gradient to their sides
    //return min(p.y, ( p.y - (Granite(p.xzy*vec3(1,1,0))-.5) ) / 1.2);

    return min(p.y, ( p.y - (Granite(p)-.5) ) * (.65-.2*2.0/max(2.0,t)) ); // adjust accuracy with depth
}

float DistanceField( vec3 p )
{
    return DistanceField( p, 0.0 );
}


vec3 Sky( vec3 ray )
{
    return mix( vec3(.8), vec3(0), exp2(-(1.0/max(ray.y,.01))*vec3(.4,.6,1.0)) );
}


vec3 Shade( vec3 pos, vec3 ray, vec3 normal, vec3 lightDir, vec3 lightCol, float shadowMask, float distance )
{
    vec3 ambient = vec3(.5);
//  if ( Toggle(kAmbientGradient,2) )
        ambient = mix( vec3(.2,.27,.4), vec3(.4), (-normal.y*.5+.5) ); // ambient
//      ambient = mix( vec3(.03,.05,.08), vec3(.1), (-normal.y+1.0) ); // ambient
    // ambient occlusion, based on my DF Lighting: https://www.shadertoy.com/view/XdBGW3
    float aoRange = distance/20.0;
    
    float occlusion = max( 0.0, 1.0 - DistanceField( pos + normal*aoRange )/aoRange ); // can be > 1.0
//  occlusion = min( 1.0, occlusion ); // prevent excessive occlusion
    occlusion = exp2( -2.0*pow(occlusion,2.0) ); // tweak the curve
//  occlusion *= mix(.5,1.0,pow(grainq,.2));
    if ( Toggle(kAmbientOcclusion,1) )
        ambient *= occlusion;

    float ndotl = max(.0,dot(normal,lightDir));
    float lightCut = smoothstep(.0,.1,ndotl);//pow(ndotl,2.0);
    vec3 light = vec3(0);

//  if ( Toggle(kDirectLight,3) )
            light += lightCol*shadowMask*ndotl;

    light += ambient;


    // And sub surface scattering too! Because, why not?
    float transmissionRange = .1;//distance/5.0;
    float transmission = max( 0.0, DistanceField( pos + lightDir*transmissionRange )/transmissionRange );
    vec3 subsurface = vec3(1,.8,.5) * .5 * lightCol * transmission;
//  commented out because it's a little buggy with small distances, and sand shouldn't have a lot of sss
//  light += subsurface;


    float specularity = smoothstep( .5,1.0, texture2D( iChannel0, pos.xz/256.0 ).r )
                        *pow(smoothstep( 0.05, 0.0, pos.y ),2.0); // don't let the lumps be too shiny
    
    vec3 h = normalize(lightDir-ray);
    float specPower = exp2(3.0+6.0*specularity);
    vec3 specular = lightCol*shadowMask*pow(max(.0,dot(normal,h))*lightCut, specPower)*specPower/32.0;
    
    vec3 rray = reflect(ray,normal);
    vec3 reflection = vec3(0);
    
//  if ( Toggle(kReflections,6) )
        reflection = Sky( rray );
    
    
    // specular occlusion, adjust the divisor for the gradient we expect
    float specOcclusion = max( 0.0, 1.0 - DistanceField( pos + rray*aoRange )/(aoRange*max(.01,dot(rray,normal))) ); // can be > 1.0
    specOcclusion = exp2( -2.0*pow(specOcclusion,2.0) ); // tweak the curve
    
    // prevent sparkles in heavily occluded areas
    specOcclusion *= occlusion;

    if ( Toggle(kReflectionOcclusion,7) )
        reflection *= specOcclusion; // could fire an additional ray for more accurate results
    
    float fresnel = pow( 1.0+dot(normal,ray), 5.0 );
    fresnel = mix( mix( .0, .05, specularity ), mix( .4, 1.0, specularity ), fresnel );
    
//  if ( !Toggle(kFresnel,8) )
//      fresnel = 1.0; // chrome
    
    vec3 albedo = vec3(.5,.3,.13);
    
//  if ( !Toggle(kAlbedo,5) ) albedo = vec3(1);
    
    vec3 result = vec3(0);
//  if ( Toggle(kLighting,-1) )
        result = light*albedo;

//  if ( Toggle(kSpecular,6) )
    {
        result = mix( result, reflection, fresnel );
    
//      if ( Toggle(kSpecularHighlight,9) )
            result += specular;
    }

    if ( !Toggle(kShowAmbientOcclusion,-1) )
        result = vec3(occlusion);

    if ( !Toggle(kShowSpecularOcclusion,-1) )
        result = vec3(specOcclusion);
    
    return result;
}




// Isosurface Renderer
#ifdef FAST
const int traceLimit=40;
const float traceSize=.005;
#else
const int traceLimit=60;
const float traceSize=.002;
#endif  

float Trace( vec3 pos, vec3 ray, float traceStart, float traceEnd )
{
    float t = traceStart;
    float h;
    for( int i=0; i < traceLimit; i++ )
    {
        h = DistanceField( pos+t*ray, t );
        if ( h < traceSize || t > traceEnd )
            break;
        t = t+h;
    }
    
    if ( t > traceEnd )//|| h > .001 )
        return 0.0;
    
    return t;
}

float TraceMin( vec3 pos, vec3 ray, float traceStart, float traceEnd )
{
    float Min = traceEnd;
    float t = traceStart;
    float h;
    for( int i=0; i < traceLimit; i++ )
    {
        h = DistanceField( pos+t*ray, t );
        Min = min(h,Min);
        if ( /*h < .001 ||*/ t > traceEnd )
            break;
        t = t+max(h,.1);
    }
    
    return Min;
}

vec3 Normal( vec3 pos, vec3 ray, float t )
{
    // in theory we should be able to get a good gradient using just 4 points

    float pitch = .5 * t / iResolution.x;
#ifdef FAST
    // don't sample smaller than the interpolation errors in Noise()
    pitch = max( pitch, .005 );
#endif
    
    vec2 d = vec2(-1,1) * pitch;

    vec3 p0 = pos+d.xxx; // tetrahedral offsets
    vec3 p1 = pos+d.xyy;
    vec3 p2 = pos+d.yxy;
    vec3 p3 = pos+d.yyx;
    
    float f0 = DistanceField(p0,t);
    float f1 = DistanceField(p1,t);
    float f2 = DistanceField(p2,t);
    float f3 = DistanceField(p3,t);
    
    vec3 grad = p0*f0+p1*f1+p2*f2+p3*f3 - pos*(f0+f1+f2+f3);
    
    // prevent normals pointing away from camera (caused by precision errors)
    float gdr = dot ( grad, ray );
    grad -= max(.0,gdr)*ray;
    
    return normalize(grad);
}


// Camera

vec3 Ray( float zoom, in vec2 fragCoord )
{
    return vec3( fragCoord.xy-iResolution.xy*.5, iResolution.x*zoom );
}

vec3 Rotate( inout vec3 v, vec2 a )
{
    vec4 cs = vec4( cos(a.x), sin(a.x), cos(a.y), sin(a.y) );
    
    v.yz = v.yz*cs.x+v.zy*cs.y*vec2(-1,1);
    v.xz = v.xz*cs.z+v.zx*cs.w*vec2(1,-1);
    
    vec3 p;
    p.xz = vec2( -cs.w, -cs.z )*cs.x;
    p.y = cs.y;
    
    return p;
}


// Camera Effects

void BarrelDistortion( inout vec3 ray, float degree )
{
    // would love to get some disperson on this, but that means more rays
    ray.z /= degree;
    ray.z = ( ray.z*ray.z - dot(ray.xy,ray.xy) ); // fisheye
    ray.z = degree*sqrt(ray.z);
}

vec3 LensFlare( vec3 ray, vec3 light, float lightVisible, float sky, in vec2 fragCoord )
{
    vec2 dirtuv = fragCoord.xy/iResolution.x;
    
    float dirt = 1.0-texture2D( iChannel1, dirtuv ).r;
    
    float l = (dot(light,ray)*.5+.5);
    
    return (((pow(l,30.0)+.05)*dirt*.1 + 1.0*pow(l,200.0))*lightVisible + sky*1.0*pow(l,5000.0))*vec3(1.05,1,.95);
}


void main(){
    vec3 ray = Ray(1.0, gl_FragCoord.xy);
    
    if ( Toggle(kLensFX,10) )
        BarrelDistortion( ray, .5 );
    
    ray = normalize(ray);
    vec3 localRay = ray;

    vec2 mouse = vec2(0.0);
    if ( iMouse.z > 0.0 ) mouse = .5-iMouse.yx/iResolution.yx;
        
    float T = iGlobalTime*.1;
    vec3 pos = 2.0*Rotate( ray, vec2(.2,2.8-T)+vec2(-.5,-6.3)*mouse );
    pos += vec3(0,.3,0) + T*vec3(0,0,-1);
    
    float top = .5, bottom = .0;
    
    vec3 col;

    vec3 lightDir = normalize(vec3(3,1,-2));
    
    float topIntersection = (top-pos.y)/ray.y;
    float bottomIntersection = (bottom-pos.y)/ray.y;
    
    float traceStart = .5;
    float traceEnd = 40.0;
    
    if ( ray.y > 0.0 )
        traceEnd = min(traceEnd,topIntersection);
    else if ( ray.y < 0.0 )
    {
        traceEnd = min(traceEnd,bottomIntersection);
        if ( pos.y > top )
            traceStart = min(traceEnd,topIntersection);
    }
    
    float t = Trace( pos, ray, traceStart, traceEnd );
    if ( t > .0 )
    {
        vec3 p = pos + ray*t;
        
        // shadow test
        float s = 0.0;
//      if ( Toggle(kShadow,4) )
            s = Trace( p, lightDir, .05, (top-p.y)/lightDir.y );
        
        vec3 n = Normal(p, ray, t);
        col = Shade( p, ray, n, lightDir, vec3(1.1,1,.9), (s>.0)?0.0:1.0, t );
        
        // fog
        float f = 80.0;
        col = mix( vec3(.8), col, exp2(-t*vec3(.4,.6,1.0)/f) );
    }
    else
    {
        col = Sky( ray );
    }

    // tone mapping
    #if defined( TONE_MAPPING ) 
    col = toneMapping( col ); 
    #endif
    
    if ( Toggle(kLensFX,10) )
    {
        // lens flare
        float sun = 1.0;//TraceMin( pos, lightDir, .5, 40.0 );
        col += LensFlare( ray, lightDir, smoothstep(-.04,.1,sun), step(t,.0), gl_FragCoord.xy );
    
        // vignetting:
        col *= smoothstep( .5, .0, dot(localRay.xy,localRay.xy) );
    
        // compress bright colours, ( because bloom vanishes in vignette )
        vec3 c = (col-1.0);
        c = sqrt(c*c+.05); // soft abs
        col = mix(col,1.0-c,.48); // .5 = never saturate, .0 = linear
        
        // grain
        vec2 grainuv = gl_FragCoord.xy + floor(iGlobalTime*60.0)*vec2(37,41);
        vec2 filmNoise = texture2D( iChannel0, .5*grainuv/iChannelResolution[0].xy ).rb;
        col *= mix( vec3(1), mix(vec3(1,.5,0),vec3(0,.5,1),filmNoise.x), .1*filmNoise.y );
    }

    col = pow(col,vec3(1.0/2.6));

    
    
    gl_FragColor = vec4(col,1);
}
