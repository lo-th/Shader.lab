
// ------------------ channel define
// 0_# buffer64_iceworldB #_0
// 2_# noise #_2
// ------------------

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// very much inspired by iq's "Volcanic", WAHa_06x36's "Truchet Tentacles" and Shanes "Entangled Vines"

#define readSampler iChannel0
#define randSampler iChannel2
#define time iDate.w

//----- common ------

#define MaxParticleNum 1
#define InRes iChannelResolution[0].xy

struct Particle {
    vec4 pos;
    vec4 vel;
    vec4 angVel;
    vec4 quat;
};

float hash(float seed)
{
    return fract(sin(seed)*158.5453 );
}

vec4 getRand4(float seed)
{
    return vec4(hash(seed),hash(seed+123.21),hash(seed+234.32),hash(seed+453.54));
}

bool isPixel(int x, int y, vec2 fragCoord) { return (int(fragCoord.x)==x && int(fragCoord.y)==y); }
vec4 getPixel(int x, int y, sampler2D s) { vec2 res=InRes; return texture2D(s,(vec2(x,y)+vec2(0.5))/res); }
vec4 getPixel(int x, int y) { return getPixel(x,y,readSampler); }

#define PixPerParticle 5
#define ParticlesPerLine 16
int XC(int idx) { return int(mod(float(idx),float(ParticlesPerLine)))*PixPerParticle; }
int YC(int idx) { return (idx/16)+50; } // first line (y=0) reserved for other than particle-data
int PIdx(int xc, int yc) {
    if(xc/PixPerParticle>=ParticlesPerLine) return -1;
    int pidx = (yc-50)*16 + xc/PixPerParticle;
    if(pidx>=MaxParticleNum) return -1;
    return pidx;
}

void writeParticle( int idx, Particle p, inout vec4 fragColor, vec2 fragCoord)
{
    int xc = XC(idx);
    int yc = YC(idx);
    if (isPixel(xc+0,yc,fragCoord)) fragColor.xyzw=p.pos;
    if (isPixel(xc+1,yc,fragCoord)) fragColor.xyzw=p.vel;
    if (isPixel(xc+2,yc,fragCoord)) fragColor.xyzw=p.angVel;
    if (isPixel(xc+3,yc,fragCoord)) fragColor.xyzw=p.quat;
    // not sure if framebuffer has .w, so store quat.w also in next pixel
    if (isPixel(xc+4,yc,fragCoord)) fragColor.xyzw=vec4(p.quat.w,0,0,1);
}

Particle readParticle( int idx )
{
    Particle p;
    int xc = XC(idx);
    int yc = YC(idx);
    // first line (y=0) reserved (e.g. for growNum, growIdx)
    p.pos    = getPixel(xc+0,yc);
    p.vel    = getPixel(xc+1,yc);
    p.angVel = getPixel(xc+2,yc);
    p.quat   = getPixel(xc+3,yc);
    // not sure if framebuffer has .w, so store quat.w also in next pixel
    vec4 p2  = getPixel(xc+4,yc);
    p.quat.w = p2.x;
    return p;
}

vec3 readParticlePos( int idx )
{
    return getPixel(XC(idx),YC(idx)).xyz;
}

vec3 readCamPos()
{
    return getPixel(0,0).xyz;
}

vec4 readCamQuat()
{
    vec4 q;
    q   = getPixel(1,0);
    q.w = getPixel(2,0).x;
    return q;
}

vec3 readCamNav()
{
    return getPixel(3,0).xyz;
}

void writeCamPos(vec3 pos, inout vec4 fragColor, vec2 fragCoord)
{
    if (isPixel(0,0,fragCoord)) fragColor.xyz=pos;
}

void writeCamQuat(vec4 quat, inout vec4 fragColor, vec2 fragCoord)
{
    if (isPixel(1,0,fragCoord)) fragColor.xyzw=quat;
    if (isPixel(2,0,fragCoord)) fragColor.x=quat.w;
}

void writeCamNav(vec3 nav, inout vec4 fragColor, vec2 fragCoord)
{
    if (isPixel(3,0,fragCoord)) fragColor.xyz=nav;
}

float readSteeringAngle()
{
    return getPixel(4,0).x;
}

void writeSteeringAngle(float st, inout vec4 fragColor, vec2 fragCoord)
{
    if (isPixel(4,0,fragCoord)) fragColor.x=st;
}

float readGas()
{
    return getPixel(4,0).y;
}

void writeGas(float gas, inout vec4 fragColor, vec2 fragCoord)
{
    if (isPixel(4,0,fragCoord)) fragColor.y=gas;
}

vec4 inverseQuat(vec4 q)
{
    //return vec4(-q.xyz,q.w)/length(q);
    // if already normalized this is enough
    return vec4(-q.xyz,q.w);
}

vec4 multQuat(vec4 a, vec4 b)
{
    return vec4(cross(a.xyz,b.xyz) + a.xyz*b.w + b.xyz*a.w, a.w*b.w - dot(a.xyz,b.xyz));
}

vec4 rotateQuatbyAngle(vec4 quat, vec3 angle)
{
    float angleScalar=length(angle);
    if (angleScalar<0.00001) return quat;
    return multQuat(quat,vec4(angle*(sin(angleScalar*0.5)/angleScalar),cos(angleScalar*0.5)));
}

vec3 transformVecByQuat( vec3 v, vec4 q )
{
    return v + 2.0 * cross( q.xyz, cross( q.xyz, v ) + q.w*v );
}

vec4 transformVecByQuat( vec4 v, vec4 q )
{
    return vec4( transformVecByQuat( v.xyz, q ), v.w );
}

void getEyeCoords(out vec3 right, out vec3 fwd, out vec3 up, out vec3 eye, out vec3 dir, float aspect, vec2 spos)
{
    float speed=0.0;
    float elev = float(iMouse.y/iResolution.y)*0.5*1.0+0.7*sin(time*0.3*speed);
    float azim = float(iMouse.x/iResolution.x)*0.5*1.0+0.5*time*speed;
    right = vec3(sin(azim),cos(azim),0);
    fwd   = vec3(vec2(-1,1)*right.yx*cos(elev),sin(elev));
    up    = cross(right,fwd);
    eye = -(60.0+4.0*sin(1.0*time*speed)+4.0*sin(0.65264*time*speed))*fwd+vec3(0,0,10);
    eye = readCamPos();
    vec4 cq = readCamQuat();
    right = transformVecByQuat(vec3(1,0,0),cq);
    up    = transformVecByQuat(vec3(0,0,1),cq);
    fwd   = transformVecByQuat(vec3(0,1,0),cq);
    dir = normalize(spos.x*right+spos.y*aspect*up+1.5*fwd);
}

vec2 calcScreenPos(vec3 eye, vec3 right, vec3 fwd, vec3 up, vec3 pos, float aspect)
{
    return vec2(dot(pos-eye,right)/dot(pos-eye,fwd)*1.5,dot(pos-eye,up)/dot(pos-eye,fwd)*1.5/aspect);
}

// some distance primitives - from iq's site (http://iquilezles.org/www/articles/smin/smin.htm)
float maxcomp(in vec3 p ) { return max(p.x,max(p.y,p.z));}

float getDistanceBoxS(vec3 rpos, vec3 size)
{
    vec3 di = abs(rpos) - size;
    return min( maxcomp(di), length(max(di,0.0)) );
}

float getDistanceBoxRounded( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float getDistanceTorusS(vec3 rpos,float r1,float r2)
{
    vec3 ptor = normalize(vec3(rpos.xy,0))*r1;
    return length(rpos-ptor)-r2;
}

#define torusWorldRadius1 90.0
#define torusWorldRadius2 30.0



// ---- truchet cell funcs -----
// derived from WAHa_06x36 - shadertoy (https://www.shadertoy.com/view/ldfGWn)

float truchetRand(vec3 r) { return fract(sin(dot(r.xy,vec2(1.38984*sin(r.z),1.13233*cos(r.z))))*653758.5453); }

float truchetArc(vec3 pos, float radius)
{
    pos=fract(pos);
    float r=length(pos.xy);
    return length(vec2(r-0.5,pos.z-0.5))-radius;
}

float truchetCell(vec3 pos, float r)
{
    return min(min(
        truchetArc(pos.xyz               ,r),
        truchetArc(pos.zxy*vec3( 1,-1, 1),r)),
        truchetArc(pos.yzx*vec3(-1,-1, 1),r));
}

float sphere(vec3 pos, float r) { return length(pos)-r; }

float truchetCell2(vec3 pos, float r)
{
    return min(min(
        min(sphere(fract(pos)-vec3(0,0.5,0.5),r),sphere(fract(pos)-vec3(0.5,0,0.5),r)),
        truchetArc(pos.zxy*vec3( 1,-1, 1),r)),
        truchetArc(pos.yzx*vec3(-1,-1, 1),r));
}

float truchetCell3(vec3 pos, float r)
{
    return min(min(
        truchetArc(pos.xyz    ,r),
        truchetArc(pos.xyz*vec3(-1,-1,1) ,r)),
        length(fract(pos.xy)-vec2(0.5))-r
              );
}

// i tried to put all if's from WAHa_06x36's version into
// one modulo operation, and left away the swizzling.
// i think all roatational/mirrored cases are covered this way.
// yet im not completely sure...
float truchetDist(vec3 pos, float r)
{
    vec3 cellpos=fract(pos);
    vec3 gridpos=floor(pos);
    float rnd=truchetRand(gridpos);
    vec3 fact=floor(mod(rnd*vec3(2.0,4.0,8.0),vec3(2.0)))*2.0-vec3(1.0);
    return truchetCell(cellpos*fact,r);
}

float truchetDist2(vec3 pos, float r)
{
    vec3 cellpos=fract(pos);
    vec3 gridpos=floor(pos);
    float rnd=truchetRand(gridpos);
    float rnd2=truchetRand(gridpos+vec3(3.2,4.432,6.32))*3.0;
    float rnd3=truchetRand(gridpos-vec3(3.2,4.432,6.32))*3.0;
    vec3 fact=floor(mod(rnd*vec3(2.0,4.0,8.0),vec3(2.0)))*2.0-vec3(1.0);
    if     (rnd3>2.0) cellpos = cellpos.yzx;
    else if(rnd3>1.0) cellpos = cellpos.zxy;

    if     (rnd2<1.0)
        return truchetCell(cellpos*fact,r);
    else if(rnd2<2.0)
        return truchetCell2(cellpos*fact,r);
    else if(rnd2<3.0)
        return truchetCell3(cellpos.zxy,r);

    return truchetCell(cellpos*fact,r);
}

//#define randSampler iChannel2

vec4 snoise(vec2 texc) { return  2.0*texture2D(randSampler,texc, -16.0)-vec4(1.0); }

vec4 snoise3Dv4S(vec3 texc)
{
    vec3 x=texc*256.0;
    vec3 p = floor(x);
    vec3 f = fract(x);
    // using iq's improved texture filtering (https://www.shadertoy.com/view/XsfGDn)
    f = f*f*(3.0-2.0*f);
    vec2 uv = ((p.xy+vec2(17.0,7.0)*p.z) + 0.5 + f.xy)/256.0;
    vec4 v1 = texture2D( randSampler, uv, -16.0);
    vec4 v2 = texture2D( randSampler, uv+vec2(17.0,7.0)/256.0, -16.0);
    return mix( v1, v2, f.z )-vec4(0.50);
}

// this is a somewhat modified version of iq's noise in "volcanic"
vec4 snoise3Dv4(vec3 texc)
{
    vec3 x=texc*256.0;
    vec3 p = floor(x);
    vec3 f = fract(x);
    //f = f*f*(3.0-2.0*f);
    vec2 uv;
    uv = (p.xy+vec2(17,7)*p.z) + 0.5 + f.xy;
    vec4 v1 = texture2D( randSampler, uv/256.0, -16.0);
    vec4 v2 = texture2D( randSampler, (uv+vec2(17,7))/256.0, -16.0);
    return mix( v1, v2, f.z )-vec4(0.50);
}

float snoise3D(vec3 texc)
{
    return snoise3Dv4(texc).x;
}

float snoise3DS(vec3 texc)
{
    return snoise3Dv4S(texc).x;
}

float mScaleNoise(vec3 texc)
{
    float d=0.0;
    d+=snoise3DS(texc);
    d+=snoise3DS(texc*2.553)*0.5;
    d+=snoise3DS(texc*5.154)*0.25;
    //d+=snoise3DS(texc*400.45)*0.009;
    d+=snoise3DS(texc*400.45*vec3(0.1,0.1,1.0))*0.009;
    //d+=snoise3DS(texc*900.45*vec3(0.1,1.0,0.1))*0.005;
    //d+=snoise3DS(texc*900.45*vec3(1.0,0.1,0.1))*0.005;
    d*=0.5;
    return d;
}

float getDistanceWorldS(vec3 pos)
{
    vec3 pos0=pos;

    float dist = 100000.0;
    dist=truchetDist(pos*0.006,0.13+0.05*cos(0.02*(pos.x+pos.y+pos.z)))/0.006;
    float f=sin(0.01*(pos.x+pos.y+pos.z));
    dist+=clamp(15.5*mScaleNoise(0.035*pos/256.0),-100.0,1000.0)*(0.2+0.8*f*f);

    return dist;
}

vec3 getDistanceWorldSGradientSlow(vec3 pos, float delta)
{
    return vec3 (
                 getDistanceWorldS( pos+delta*vec3(1,0,0) )-getDistanceWorldS( pos-delta*vec3(1,0,0) ),
                 getDistanceWorldS( pos+delta*vec3(0,1,0) )-getDistanceWorldS( pos-delta*vec3(0,1,0) ),
                 getDistanceWorldS( pos+delta*vec3(0,0,1) )-getDistanceWorldS( pos-delta*vec3(0,0,1) )
                )/2.0/delta;
}

vec3 getDistanceWorldSGradient(vec3 pos, float delta)
{
    delta*=2.0;
    vec3 eps=vec3(delta,0,0);
    float d=getDistanceWorldS(pos);
    return vec3(getDistanceWorldS(pos+eps.xyy)-d,
                getDistanceWorldS(pos+eps.yxy)-d,
                getDistanceWorldS(pos+eps.yyx)-d)/delta;
}

float getDistanceSphereS(vec3 pos, float r)
{
    return length(pos)-r;
}

#define WheelFR vec3( 0.8, 1.2,-0.1)
#define WheelFL vec3(-0.8, 1.2,-0.1)
#define WheelBR vec3( 0.8,-1.2,-0.1)
#define WheelBL vec3(-0.8,-1.2,-0.1)

#define Mass 2.0
#define Iinv (mat3( 1.6,0,0, 0,3.0,0, 0,0,1.4 )/Mass)
#define WheelRadius 0.45

// smoothed minimum - copied from iq's site (http://iquilezles.org/www/articles/smin/smin.htm)
float smin( float a, float b, float k )
{
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}

vec4 getDistanceObjS(vec3 pos)
{
    float obj=0.0;
    float dist = 100000.0;
    float steeringAngle=readSteeringAngle();
    vec4 q = vec4(0,sin(steeringAngle*0.5),0,cos(steeringAngle*0.5));
    dist = min(dist, getDistanceBoxRounded(pos-vec3(0.0, 0.0,0.3),vec3(0.8-0.1, 1.8-0.1,0.35-0.1),0.1));
    dist = smin(dist, getDistanceBoxRounded(pos-vec3(0.0,-0.5,0.7),vec3(0.75-0.15,1.1-0.15,0.5-0.15),0.15),10.0);
    float dist2 = dist;
    dist = max(dist, -getDistanceSphereS((pos-WheelFL).yzx,WheelRadius*1.2));
    dist = max(dist, -getDistanceSphereS((pos-WheelFR).yzx,WheelRadius*1.2));
    dist = max(dist, -getDistanceSphereS((pos-WheelBL).yzx,WheelRadius*1.2));
    dist = max(dist, -getDistanceSphereS((pos-WheelBR).yzx,WheelRadius*1.2));
    dist = min(dist, getDistanceTorusS(transformVecByQuat((pos-WheelFR).yzx,q),WheelRadius-0.15,0.15));
    dist = min(dist, getDistanceTorusS(transformVecByQuat((pos-WheelFL).yzx,q),WheelRadius-0.15,0.15));
    dist = min(dist, getDistanceTorusS((pos-WheelBR).yzx,WheelRadius-0.15,0.15));
    dist = min(dist, getDistanceTorusS((pos-WheelBL).yzx,WheelRadius-0.15,0.15));
    if(dist!=dist2) obj=1.0;
    return vec4(dist,obj,0,0);
}
//----- render ------

//#define randSampler iChannel2

vec4 getDistanceExt(vec3 pos)
{
    float dist=1000000.0;
    float oldDist=1000000.0;
    float obj=0.0;
    dist=min(dist,getDistanceWorldS(pos));

    for(int i=0;i<MaxParticleNum;i++)
    {
        Particle p = readParticle(i);
        oldDist=dist;
        vec4 ov = getDistanceObjS(transformVecByQuat(pos-p.pos.xyz,inverseQuat(p.quat)));
        dist=min(dist,ov.x);
        if(dist!=oldDist) obj=float(i)+1.0+ov.y*0.1;
    }

    return vec4(dist,obj,0,0);
}

float getDistance(vec3 pos)
{
    return getDistanceExt(pos).x;
}

vec3 getDistanceGradientSlow(vec3 pos, float delta)
{
    vec3 eps=vec3(delta,0,0);
    return vec3 (
                 getDistance( pos+eps.xyy )-getDistance( pos-eps.xyy ),
                 getDistance( pos+eps.yxy )-getDistance( pos-eps.yxy ),
                 getDistance( pos+eps.yyx )-getDistance( pos-eps.yyx )
                );
}

vec3 getDistanceGradient(vec3 pos, float delta)
{
    delta*=2.0;
    vec3 eps=vec3(delta,0,0);
    float d=getDistance(pos);
    return vec3(getDistance(pos+eps.xyy)-d, getDistance(pos+eps.yxy)-d, getDistance(pos+eps.yyx)-d)/delta;
}


// Ambient occlusion approximation.
// Based upon boxplorer's implementation which is derived from:
// http://www.iquilezles.org/www/material/nvscene2008/rwwtt.pdf
#define AoIterationsMax 4
float ambientOcclusion(vec3 p, vec3 n, float eps, float aoSpread, float aoIntensity, int aoIterations)
{
    float o = 1.0;                  // Start at full output colour intensity
    eps *= aoSpread;                // Spread diffuses the effect
    float k = aoIntensity / eps;    // Set intensity factor
    float d = 2.0 * eps;            // Start ray a little off the surface
    
    for (int i = 0; i < AoIterationsMax; ++i) {
        o -= (d - getDistance(p + n * d)) * k;
        d += eps;
        k *= 0.5;                   // AO contribution drops as we move further from the surface
        if(i > aoIterations) break;
    }
    
    return clamp(o, 0.0, 1.0);
}

#define RaytraceMaxStepNum 200
#define glowColor vec3(0.1,0.3,0.4)
#define ambientColor (vec3(0.35,0.55,0.65)*0.7)
#define diffuseColor vec3(0.8,0.95,1.0)

float gauss(float x) { return exp(-x*x); }

vec4 shadeCar(vec3 pos, float glow, float dist, vec3 dir, float obj)
{
    vec4 col=vec4(1.0);
    vec3 normal=normalize(getDistanceGradient(pos,0.001));
    float ao = 1.0;
    ao *= ambientOcclusion(pos, normal, 0.03,
                           8.0,    //spread,
                           0.1, //intensity,
                           4     //iterations
                          );
    col *= ao;
    //col *= vec4(normal.xyz*0.5+vec3(0.5),1);
    vec3 lightDir = normalize(vec3(-16.0, 100.0, -60.0));
    float diff = clamp(dot(vec3(0,0,1),normal),0.0,1.0);
    diff*=1.2;
    //diff*=diff;
    vec3 diffuseColorL = vec3(1,1,1);
    //if(obj>=1.0) diffuseColorL =vec3(0.5); // tire

    vec3  eye=-dir;
    float spec = dot(-eye+2.0*normal*dot(normal,eye),vec3(0,0,1));
    float shin1 = 0.6;
    float shin2 = 0.05;
    float shTot = 1.0;
    //if(obj>=1.0) { shin1 = 0.8; shin2 = 0.4; shTot=0.3; }
    vec3 specv = shTot*(0.9*gauss((spec+0.4)/shin1)*vec3(ambientColor) + 0.7*gauss((spec-0.95)/shin2)*vec3(1));

    col.xyz *= mix(ambientColor*diffuseColorL,diffuseColorL,diff);
    col.xyz += vec3(specv);

    return col;
}

vec4 shadeTerrain(vec3 pos, float glow, float dist, vec3 dir)
{
    vec4 col=vec4(1);
    vec3 normal=normalize(getDistanceGradient(pos,0.2123));

    float ao = 1.0;
    ao *= ambientOcclusion(pos, normal, 0.03,
                           8.0,    //spread,
                           0.1, //intensity,
                           4     //iterations
                          );
    ao *= ambientOcclusion(pos, normal, 2.5,
                           8.0,    //spread,
                           0.07, //intensity,
                           4     //iterations
                          );
    //ao*=ao;

    vec3 lightDir = normalize(vec3(-16.0, 100.0, -60.0));
    float diff = clamp(dot(vec3(0,0,1),normal),0.0,1.0);
    diff=1.2*pow(diff,1.0);
    vec3 eye=-dir;
    vec3 rnormal = normalize(snoise3Dv4(pos*0.1).xyz);
    float spec1 = dot(-eye+2.0*rnormal*dot(rnormal,eye),vec3(0,0,1));
    float spec2 = dot(-eye+2.0*normal*dot(normal,eye),vec3(0,0,1));
    float spec=2.0*gauss((spec1-0.8)/0.01)*diff+0.7*gauss((spec2-0.99)/0.2)*(1.0-dot(eye,normal));

    col.xyz *= mix(diffuseColor, ambientColor, 1.0-diff);
    col.xyz *= mix(vec3(ao),vec3(1,1,1),vec3(0.1,0.4,0.6));
    col.xyz += 0.7*spec*vec3(1,1,1);
    col.xyz += glowColor*glow;
    return col;
}

vec4 raytraceDistfield(vec3 pos0, vec3 dir, float maxDist)
{
    vec3 colbg = mix(vec3(0.35,0.6,0.65)*0.5,1.2*vec3(0.8,0.95,1.0),dir.z*0.5+0.5);
    vec4 col = vec4(1,1,1,1);

    vec3 rpos = pos0;
    vec3 rpos0 = rpos;

    float dist=0.0;
    float ddist=100.0;
    int cnt=0;
    float eps=0.0001; // m
    vec4 dv;
    for( int i=0 ; i<RaytraceMaxStepNum ; i++ )
    {
        cnt=i;
        if(ddist<eps) break;
        dv=getDistanceExt(rpos.xyz+dir*dist);
        ddist=dv.x;
        dist+=ddist*0.8;
        if(dist>maxDist) break;
    }


    float ddistsurf=ddist;
    float distsurf=dist;

    if(ddistsurf<=eps) {
        if(dv.y>=1.0)
            col=shadeCar(rpos.xyz+dir*distsurf,float(cnt)/100.0,dist,dir,fract(dv.y)*10.0);
        else
            col=shadeTerrain(rpos.xyz+dir*distsurf,float(cnt)/100.0,dist,dir);
    }
    else
    {
        col.w = 0.0;
        col.xyz=colbg.xyz;
    }

    if(cnt>=RaytraceMaxStepNum-2) col=vec4(0.8,0.95,1.0,1.0);

    float fog = 1.0-exp(-dist/maxDist*3.0);
    col.xyz = mix(col.xyz,colbg,fog);


    return col;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float aspect=iResolution.y/iResolution.x;
    vec2 spos = fragCoord.xy/iResolution.xy*2.0-vec2(1.0);
    vec3 right, fwd, up, pos, dir;
    getEyeCoords(right,fwd,up,pos,dir,aspect,spos);
    fragColor = raytraceDistfield(pos,dir,1000.0);
    Particle p = readParticle(0);
    //drawFloat(length(p.vel.xyz)*3.6,2,vec2(10,10),2.0,fragColor,fragCoord);
    //drawFloat(readGas(),2,vec2(10,45),2.0,fragColor,fragCoord);
    //drawFloat(readSteeringAngle(),2,vec2(10,30),2.0,fragColor,fragCoord);
}
