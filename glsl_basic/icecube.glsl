// https://www.shadertoy.com/view/Xsd3Rs


// Everyday003 - IceCube
// By David Ronai / @Makio64

// Thanks to XT95 to implement SSS in this shadertoy:
// https://www.shadertoy.com/view/MsdGz2
// Base on this papper :
// http://colinbarrebrisebois.com/2011/03/07/gdc-2011-approximating-translucency-for-a-fast

//------------------------------------------------------------------ VISUAL QUALITY
#define POSTPROCESS
#define RAYMARCHING_STEP 35
#define RAYMARCHING_JUMP 1.
//------------------------------------------------------------------ DEBUG
//#define RENDER_DEPTH
//#define RENDER_NORMAL
//#define RENDER_AO

const float PI = 3.14159265359;
float snoise(vec3 v);

//------------------------------------------------------------------  SIGNED PRIMITIVES
float vmax(vec3 v) {return max(max(v.x, v.y), v.z);}
float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}
float pModPolar(inout vec2 p, float repetitions) {
    float angle = 2./repetitions*PI;
    float a = atan(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = mod(a,angle) - angle/2.;
    p = vec2(cos(a), sin(a))*r;
    if (abs(c) >= (repetitions/2.)) c = abs(c);
    return c;
}
float fOpUnionRound(float a, float b, float r) {
    vec2 u = max(vec2(r - a,r - b), vec2(0));
    return max(r, min (a, b)) - length(u);
}

//------------------------------------------------------------------ MAP
float map( in vec3 pos ) {
    float d = pos.y;
    pos -= snoise(pos*0.15);
    vec3 q = pos-vec3(0.,5.,0.);
    pModPolar(q.xz, 6.);
    q -= vec3(30,0,0);
    d = fOpUnionRound(d, fBox(q,vec3(5.)),4.4);
    q = pos;
    pModPolar(q.xz,8.);
    d = fOpUnionRound(d, fBox(q,vec3(6.,20.,6.)),6.);
    return d;
}

//------------------------------------------------------------------ RAYMARCHING

#ifdef RENDER_DEPTH
float castRay( in vec3 ro, in vec3 rd, inout float depth )
#else
float castRay( in vec3 ro, in vec3 rd )
#endif
{
    float t = 0.0;
    float res;
    for( int i=0; i<RAYMARCHING_STEP; i++ )
    {
        vec3 pos = ro+rd*t;
        res = map( pos );
        if( res < 0.01 || t > 100. ) break;
        t += res*RAYMARCHING_JUMP;
        #ifdef RENDER_DEPTH
        depth += 1./float(RAYMARCHING_STEP);
        #endif
    }
    return t;
}

vec3 calcNormal(vec3 p) {
    float eps = 0.01;
    const vec3 v1 = vec3( 1.0,-1.0,-1.0);
    const vec3 v2 = vec3(-1.0,-1.0, 1.0);
    const vec3 v3 = vec3(-1.0, 1.0,-1.0);
    const vec3 v4 = vec3( 1.0, 1.0, 1.0);
    return normalize( v1 * map( p + v1*eps ) +
                      v2 * map( p + v2*eps ) +
                      v3 * map( p + v3*eps ) +
                      v4 * map( p + v4*eps ) );
}


float hash( float n ){
    return fract(sin(n)*3538.5453);
}

float calcAO( in vec3 p, in vec3 n, float maxDist, float falloff ){
    float ao = 0.0;
    const int nbIte = 6;
    for( int i=0; i<nbIte; i++ )
    {
        float l = hash(float(i))*maxDist;
        vec3 rd = n*l;
        ao += (l - map( p + rd )) / pow(1.+l, falloff);
    }
    return clamp( 1.-ao/float(nbIte), 0., 1.);
}

// calculate local thickness
// base on AO but : inverse the normale(line117) & inverse the color(line 118)
float thickness( in vec3 p, in vec3 n, float maxDist, float falloff )
{
    float ao = 0.0;
    const int nbIte = 6;
    for( int i=0; i<nbIte; i++ )
    {
        float l = hash(float(i))*maxDist;
        vec3 rd = -n*l;
        ao += (l + map( p + rd )) / pow(1.+l, falloff);
    }
    return clamp( 1.-ao/float(nbIte), 0., 1.);
}

//------------------------------------------------------------------ POSTEFFECTS

#ifdef POSTPROCESS
vec3 postEffects( in vec3 col, in vec2 uv, in float time )
{
    // gamma correction
    // col = pow( clamp(col,0.0,1.0), vec3(0.45) );
    // vigneting
    col *= 0.7+0.3*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.15 );
    return col;
}
#endif

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv )
{
    vec3 col = vec3(.0,.0,1.2);

    #ifdef RENDER_DEPTH
    float depth = 0.;
    float t = castRay(ro,rd,depth);
    #else
    float t = castRay(ro,rd);
    #endif

    #ifdef RENDER_DEPTH
    return vec3(depth/10.,depth/5.,depth);
    #endif

    vec3 pos = ro + t * rd;
    vec3 nor = calcNormal(pos);

    #ifdef RENDER_NORMAL
    return nor;
    #endif

    float ao = calcAO(pos,nor,10.,1.2);
    #ifdef RENDER_AO
    return vec3(ao);
    #endif

    float thi = thickness(pos, nor, 6., 1.5);

    vec3 lpos1 = vec3(0.0,15.+sin(iGlobalTime)*5.,0.0);
    vec3 ldir1 = normalize(lpos1-pos);
    float latt1 = pow( length(lpos1-pos)*.1, 1.5 );
    float trans1 =  pow( clamp( dot(-rd, -ldir1+nor), 0., 1.), 1.) + 1.;
    vec3 diff1 = vec3(.0,.5,1.) * (max(dot(nor,ldir1),0.) ) / latt1;
    col =  diff1;
    col += vec3(.3,.2,.05) * (trans1/latt1)*thi;

    for(int i = 0; i<6; i++){
        float angle = float(i)/6.*PI*2.;
        float radius = 30.;
        vec3 lpos1 = vec3(cos(angle)*radius,5.,sin(angle)*radius);
        vec3 ldir1 = normalize(lpos1-pos);
        float latt1 = pow( length(lpos1-pos)*(.3+abs(sin(iGlobalTime)*2.)), 1. );
        float trans1 =  pow( clamp( dot(-rd, -ldir1+nor), 0., 1.), 1.) + 1.;
        col += vec3(.2,.2,.4) * (trans1/latt1)*thi;
    }
    
    col = max(vec3(.05),col);
    col *= ao;
    return col;
}


mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 orbit(float phi, float theta, float radius)
{
    return vec3(
        radius * sin( phi ) * cos( theta ),
        radius * cos( phi ),
        radius * sin( phi ) * sin( theta )
    );
}

//------------------------------------------------------------------ MAIN
void mainImage( out vec4 fragColor, in vec2 coords )
{
    float time = iGlobalTime;
    vec2 uv = coords.xy / iResolution.xy;
    vec2 mouse = iMouse.xy / iResolution.xy;
    vec2 q = coords.xy/iResolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= iResolution.x/iResolution.y;

    //Camera
    float radius = 50.;
    vec3 ro = orbit(PI/2.-.5,PI/2.+time,radius);
    vec3 ta  = vec3(0.0, 0., 0.0);
    mat3 ca = setCamera( ro, ta, 0. );
    vec3 rd = ca * normalize( vec3(p.xy,1.6) );

    // Raymarching
    vec3 color = render( ro, rd, uv );
    #ifdef POSTPROCESS
    color = postEffects( color, uv, time );
    #endif
    fragColor = vec4(color,1.0);
}

//------------------------------------------------------------------ NOISE
//AshimaOptim https://www.shadertoy.com/view/Xd3GRf
vec4 permute(vec4 x){return mod(x*x*34.0+x,289.);}
float snoise(vec3 v){
  const vec2  C = vec2(0.166666667, 0.33333333333) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 = v - i + dot(i, C.xxx) ;
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy;
  vec3 x3 = x0 - D.yyy;
  i = mod(i,289.);
  vec4 p = permute( permute( permute(
      i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
    + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
    + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));
  vec3 ns = 0.142857142857 * D.wyz - D.xzx;
  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
  vec4 x_ = floor(j * ns.z);
  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = floor(j - 7.0 * x_ ) *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);
  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));
  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);
  vec4 norm = inversesqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m * m;
  return .5 + 12.0 * dot( m, vec4( dot(p0,x0), dot(p1,x1),dot(p2,x2), dot(p3,x3) ) );
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