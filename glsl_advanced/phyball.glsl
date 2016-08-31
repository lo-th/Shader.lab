
// ------------------ channel define
// 0_# bufferFULL_phyballA #_0
// ------------------

// https://www.shadertoy.com/view/XdGGWz
// mix between shaderology shader [https://www.shadertoy.com/view/ltjGDd]
// and dr2 shader  [https://www.shadertoy.com/view/Xsy3WR]


#define BIAS 0.0001
#define PI 3.1415927
#define SEED 4.

//#define txBuf iChannel0
//#define txSize iChannelResolution[0].xy
//#define txSize iResolution.xy

const int SPH = 16;

mat3 QToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

const float txRow = 64.;

float mmo ( float x, float y ){
  return x - y * floor(x / y);
}

vec4 Loadv4 (int idVar)
{
  float fi = float (idVar);
  vec2 uv = (vec2 (mmo (fi, txRow), floor (fi / txRow)) + 0.5) / iResolution.xy;
  vec4 c = texture2D( iChannel0, uv );
  return c;
  //return texture2D (txBuf, (vec2 (mmo (fi, txRow), floor (fi / txRow)) + 0.5) /
  //   txSize);
}

const float pi = 3.14159;

vec3 ltDir, rdSign;
float dstFar, hbLen;
int idObj;
bool isRefl;


// returns t and normal
float iBox( in vec3 roo, in vec3 rdd, in vec3 rad, out float tN, out float tF, out vec3 nN, out vec3 nF) 
{
    // ray-box intersection in box space
    vec3 m = 1.0/rdd;
    vec3 n = m*roo;
    vec3 k = abs(m)*rad;
    
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

    tN = max( max( t1.x, t1.y ), t1.z );
    tF = min( min( t2.x, t2.y ), t2.z );
    
    if( tN > tF || tF < 0.0) 
        return -1.;

    nN = -sign(rdd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
    nF = -sign(rdd)*(1.-step(t2.yzx,t2.xyz))*(1.-step(t2.zxy,t2.xyz));

    return 1.;
}


float sphIntersect( in vec3 ro, in vec3 rd, in vec4 sph )
{
  vec3 oc = ro - sph.xyz;
  float b = dot( oc, rd );
  float c = dot( oc, oc ) - sph.w*sph.w;
  float h = b*b - c;
  if( h<0.0 ) return -1.0;
  return -b - sqrt( h );
}

float sphOcclusion( in vec3 pos, in vec3 nor, in vec4 sph )
{
    vec3  r = sph.xyz - pos;
    float l = length(r);
    float d = dot(nor,r);
    float res = d;

    if( d<sph.w ) res = pow(clamp((d+sph.w)/(2.0*sph.w),0.0,1.0),1.5)*sph.w;
    
    return clamp( res*(sph.w*sph.w)/(l*l*l), 0.0, 1.0 );
}


float sphAreaShadow( vec3 P, in vec4 L, vec4 sph )
{
  vec3 ld = L.xyz - P;
  vec3 oc = sph.xyz - P;
  float r = sph.w - BIAS;
  
  float d1 = sqrt(dot(ld, ld));
  float d2 = sqrt(dot(oc, oc));
  
  if (d1 - L.w / 2. < d2 - r) return 1.;
  
  float ls1 = L.w / d1;
  float ls2 = r / d2;

  float in1 = sqrt(1.0 - ls1 * ls1);
  float in2 = sqrt(1.0 - ls2 * ls2);
  
  if (in1 * d1 < in2 * d2) return 1.;
  
  vec3 v1 = ld / d1;
  vec3 v2 = oc / d2;
  float ilm = dot(v1, v2);
  
  if (ilm < in1 * in2 - ls1 * ls2) return 1.0;
  
  float g = length( cross(v1, v2) );
  
  float th = clamp((in2 - in1 * ilm) * (d1 / L.w) / g, -1.0, 1.0);
  float ph = clamp((in1 - in2 * ilm) * (d2 / r) / g, -1.0, 1.0);
  
  float sh = acos(th) - th * sqrt(1.0 - th * th) 
           + (acos(ph) - ph * sqrt(1.0 - ph * ph))
           * ilm * ls2 * ls2 / (ls1 * ls1);
  
  return 1.0 - sh / PI;
}


//-------------------------------------------------------------------------------------------


vec4 sphere[SPH];
vec4 L;

vec3 rand3( float x, float seed )
{ 
  float f = x+seed;
  return fract( PI*sin( vec3(f,f+5.33,f+7.7)) );
}

float areaShadow( in vec3 P )
{
  float s = 1.0;
  for( int i=0; i<SPH; i++ )
    s = min( s, sphAreaShadow(P, L, sphere[i] ) );
  return s;           
}

vec3 reflections( vec3 P, vec3 R, vec3 tint, int iid )
{
  float t = 1e20;

  vec3 s = vec3(.5); //vec3(R.y < 0. ? 1.-sqrt(-R.y/(P.y+1.)) : 1.); // P.y+1 floor pos
  for( int i=0; i<SPH; i++ ) {    
    float h = sphIntersect( P, R, sphere[i] );
    if( h>0.0 && h<t ) {
      s = i == iid ? tint * 2. : vec3(0.);
      t = h;        
    }
  }     
  return max(vec3(0.), s);           
}

float occlusion( vec3 P, vec3 N ) {
  float s = 1.0;
  for( int i=0; i<SPH; i++ )
    s *= 1.0 - sphOcclusion( P, N, sphere[i] ); 
  return s;           
}

float sphLight( vec3 P, vec3 N, vec4 L) {
  vec3 oc = L.xyz  - P;
  float dst = sqrt( dot( oc, oc ));
  vec3 dir = oc / dst;
  
  float c = dot( N, dir );
  float s = L.w  / dst;
    
  return max(0., c * s);
}
  
//-------------------------------------------------------------------------------------------

vec3 shade( vec3 I, vec3 P, vec3 N, float id, float iid ) {
    
  vec3 base = rand3( id, SEED );
  vec3 wash = mix( vec3(0.9), base, 0.4);
  vec3 hero = rand3( iid, SEED );
  
  vec3 ref = reflections( P, I - 2.*(dot(I,N))*N, hero, int(iid) );
  float occ = occlusion( P, N );
 // float ocf = 1.-sqrt((0.5 + 0.5*-N.y)/(P.y+1.25))*.5; //floor occusion. 1.25 floor P.
  float fre = clamp( 1. + dot( I, N), 0., 1.); 
        fre = (0.01+0.4*pow(fre,3.5));
    
  float lgh = sphLight( P, N, L) * areaShadow( P );
  float inc = ( id == iid ? 1.0 : 0.0 );
   
  // Env light
  vec3 C = wash * occ*.2; // * ocf * .2;
  
  // Sphere light
  C += ( inc + lgh * 1.3 ) * hero;

  // Reflections
  C = mix( .3*C, ref, fre );
  
  return C;
}    

vec3 trace( vec3 E, vec3 I, vec3 C, float px, float iid)
{
  float t = 1e20;
  float id  = -1.0;
  vec4  obj = vec4(0.);
  for( int i=0; i<SPH; i++ ) {
    vec4 sph = sphere[i];
    float h = sphIntersect( E, I, sph ); 
    if( h>0.0 && h<t ) 
    {
      t = h;
      obj = sph;
      id = float(i);
    }
  }
              
  if( id>-0.5 )
  {
    vec3 P = E + t*I;
    vec3 N = normalize(P-obj.xyz);
    C = shade( I, P, N, id, iid  );
  }

  return C;
}


void GetMols() {
  for (int n = 0; n < SPH; n ++) 
      sphere[n] = Loadv4 (2 * n);
  hbLen = Loadv4 (2 * SPH).y;
}



void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 qtVu;
  vec3 col, rd, ro;
  vec2 canvas, uv, ut;
  float tCur;
    
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
    
  tCur = iGlobalTime;
  ut = abs (uv) - vec2 (1.);
  //if (max (ut.x, ut.y) > 0.003) col = vec3 (0.82);
  //else {
    
    float fov = 4.;
    dstFar = 100.;
    qtVu = Loadv4 (2 * SPH + 1);
    vuMat = QToRMat (qtVu);
    rd = normalize (vec3 (uv, fov)) * vuMat;
    ro = vec3 (0., 0., -18.) * vuMat;
    ltDir = normalize (vec3 (1., 1.5, -1.2)) * vuMat;
   
    
    GetMols();
    

    ////////////////////////////////////////////
    
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = (2.0*fragCoord.xy-iResolution.xy)/iResolution.y;
    vec2 m = step(0.0001,iMouse.z) * iMouse.xy/iResolution.xy;
    
    //-----------------------------------------------------
    
    float time = iGlobalTime+1.;  
    float spI = floor(mmo(time,float(SPH)));
  float sec = mmo(time,1.);
    //-----------------------------------------------------
    for( int i=0; i<SPH; i++ ) {

        if( i == int(spI) ) {
             sphere[i].w += .02*sin(sec*50.) / sqrt(sec) * ( 1.-sqrt(sec));

            L = sphere[i];
        }
    }

    //-----------------------------------------------------
    

    float px = 1.0*(2.0/iResolution.y)*(1.0/fov);

    vec3 C = vec3(.2);

    float tN, tF;
    vec3 nN, nF;

    if (iBox(ro, rd, vec3(hbLen-.9), tN, tF, nN, nF)>0.) {
        C += .4*shade(rd, ro + tF*rd, nF, px, spI);
        C = trace( ro, rd, C, px, spI);       
        C += .4*shade(rd, ro + tN*rd, nN, px, spI );
    }
    
    //-----------------------------------------------------

    // post
    C = pow( C, vec3(0.41545) );   
    C *= pow(18.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.12);

    fragColor = vec4( C, 1. );
}


