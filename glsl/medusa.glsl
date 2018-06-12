// ------------------ channel define
// 0_# noise #_0
// 1_# cube_grey1 #_1
// ------------------

//https://www.shadertoy.com/view/XssfRl

// created by florian berger (flockaroo) - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// medusa's hairdo
// another tiling variation, reminding me of medusa's hair.
//...in a slight green tint - just as medusa likes it ;-)

//uncomment this if you want a snake-skin surfce
//#define SNAKE_SKIN
    
// golden ratio - used for icosahedron
#define G (.5+sqrt(5./4.))
#define PI 3.141592653

#define XCHGV3(a,b) { vec3 d=a; a=b; b=d; }

void sortXYZ(inout vec3 p1, inout vec3 p2, inout vec3 p3)
{
    #define W(p) (p.x+p.y*.01+p.z*.0001)
    if(W(p3)>W(p2)) XCHGV3(p3,p2);
    if(W(p2)>W(p1)) XCHGV3(p2,p1);
    if(W(p3)>W(p2)) XCHGV3(p3,p2);
    if(W(p2)>W(p1)) XCHGV3(p2,p1);
}

// get closest icosahedron triangle
void getIcosaTri(vec3 pos, out vec3 p1, out vec3 p2, out vec3 p3)
{
    float dot1 = -1000.0;
    float dot2 = -1000.0;
    float dot3 = -1000.0;
    for(int s1=0;s1<2;s1++)
    {
    	for(int s2=0;s2<2;s2++)
        {
    		for(int perm=0;perm<3;perm++)
            {
                vec3 p0 = normalize(vec3(G,1,0))*vec3(s1*2-1,s2*2-1,0);
                if     (perm>1) p0 = p0.yzx;
                else if(perm>0) p0 = p0.zxy;
                float dot0 = dot(pos,p0);
                if(dot0>dot1){
                    dot3=dot2; p3=p2;
                    dot2=dot1; p2=p1; 
                    dot1=dot0; p1=p0;
                }
                else if(dot0>dot2){
                    dot3=dot2; p3=p2;
                    dot2=dot0; p2=p0; 
                }
                else if(dot0>dot3){
                    dot3=dot0; p3=p0;
                }
            }
        }
    }
}

// check if pos hits triangle
bool thruTriangle(vec3 pos, vec3 v1, vec3 v2, vec3 v3)
{
    vec3 n = cross(v2-v1,v3-v1);
    // calc where pos hits triangle plane
    pos = pos*dot(v1,n)/dot(pos,n);
    v1-=pos; v2-=pos; v3-=pos;
 	vec3 c1=cross(v1,v2);
    vec3 c2=cross(v2,v3);
    vec3 c3=cross(v3,v1);
    // check if the cross products of all the pos-edge-vectors show into the same direction
    return dot(c1,c2)>0. && dot(c2,c3)>0. && dot(c3,c1)>0. ;
}

// subdivide 1 triangle into 4 triangles and give back closest triangle
void getTriSubDiv(vec3 pos, inout vec3 p1, inout vec3 p2, inout vec3 p3)
{
    vec3 p4 = normalize(p1+p2);
    vec3 p5 = normalize(p2+p3);
    vec3 p6 = normalize(p3+p1);

    if     (thruTriangle(pos,p1,p4,p6)) { p1=p1; p2=p4; p3=p6; }
    else if(thruTriangle(pos,p6,p5,p3)) { p1=p6; p2=p5; p3=p3; }
    else if(thruTriangle(pos,p6,p4,p5)) { p1=p6; p2=p4; p3=p5; }
    else if(thruTriangle(pos,p4,p2,p5)) { p1=p4; p2=p2; p3=p5; }
}

float tri01(float x)
{
    return abs(fract(x)-.5)*2.;
}


// get some 3d rand values by multiplying 2d rand in xy, yz, zx plane
vec4 getRand(vec3 pos)
{
    vec4 r = vec4(1.0);
    r*=texture2D(iChannel0,pos.xy)*2.-1.;
    r*=texture2D(iChannel0,pos.xz)*2.-1.;
    r*=texture2D(iChannel0,pos.zy)*2.-1.;
    return r;
}

// distancefield of torus around arbitrary axis z
// similar to http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float distTorus(vec3 pos, float r1, float r2, vec3 z)
{
    float pz = dot(pos,normalize(z));
    return length(vec2(length(pos-z*pz)-r1,pz))-r2;
}

float distTorus(vec3 pos, float r1, float r2, vec3 z, out float ang)
{
    float pz = dot(pos,normalize(z));
    vec2 r = vec2(length(pos-z*pz)-r1,pz);
    ang = atan(r.y,r.x);
    return length(r)-r2;
}

vec4 getRand01Sph(vec3 pos)
{
    vec2 res = iChannelResolution[0].xy;
    vec2 texc=((pos.xy*123.+pos.z)*res+.5)/res;
    return texture2D(iChannel0,texc);
}

float distSphere(vec3 pos, float r)
{
	return length(pos)-r;
}

float calcAngle(vec3 v1, vec3 v2)
{
    return acos(dot(v1,v2)/length(v1)/length(v2));
}

#define mixSq(a,b,f) mix(a,b,cos(f*PI)*.5+.5)

// distance to 2 torus segments in a triangle
// each torus segment spans from the middle of one side to the middle of another side
float distTruchet(vec3 pos, vec3 p1, vec3 p2, vec3 p3, float dz)
{
    float d = 10000.0;
    float rnd =getRand01Sph(p1+p2+p3).x;
    float rnd2=getRand01Sph(p1+p2+p3).y;
    // random rotation of torus-start-edges
    if      (rnd>.75) { vec3 d=p1; p1=p2; p2=d; }
    else if (rnd>.50) { vec3 d=p1; p1=p3; p3=d; }
    else if (rnd>.25) { vec3 d=p2; p2=p3; p3=d; }
    
    vec3 p4 = p1*(1.-dz);
    vec3 p5 = p2*(1.-dz);
    vec3 p6 = p3*(1.-dz);
    
    float r,r1,r2,fact,ang,fullAng;
    vec3 n = normalize(cross(p2-p1,p3-p1));
    // where pos hits triangle
    vec3 pos2 = ((pos-p1)-dot(pos-p1,n)*n)+p1;
    
    // torus segments:
    // actually i have to fade from one torus into another
    // because not all triangles are equilateral
    vec3 v1,v2,v3,v4,v5,v6;
    for(int i=0; i<3 ;i++)
    {
        if(i==0) { v1=p1; v2=p2; v3=p3; v4=p4; v5=p5; v6=p6; }
        if(i==1) { v1=p2; v2=p3; v3=p1; v4=p5; v5=p6; v6=p4; }
        if(i==2) { v1=p3; v2=p1; v3=p2; v4=p6; v5=p4; v6=p5; }
    	ang = calcAngle(pos2-v1,v2-v1);
    	fullAng = calcAngle(v3-v1,v2-v1);
    	fact = ang/fullAng;
        float factUD = fact;
        if(rnd2>.25) {
            if(i==0) factUD=1.;
            if(i==1) factUD=0.;
            //if(i==1) factUD=1.;
        }
    	r1 = .5*mixSq(length(v2-v1),length(v5-v4),factUD);
    	r2 = .5*mixSq(length(v3-v1),length(v6-v4),factUD);
    	r=mix(r1,r2,fact);
        float ang2;
		d=min(d,distTorus(pos-mixSq(v1,v4,factUD)*sqrt(1.0-r*r),r,.11*r,v1,ang2));
        // snake skin pattern
        #ifdef SNAKE_SKIN
        d-=(abs(sin(ang*50.)+sin(ang2*12.)))*.0025*r;
        #endif
        //d-=(tri01(ang*50.*.25)+tri01(ang2*12.*.25))*.004*r;
    }

    return d;
}

// final distance funtion
float dist(vec3 pos)
{
    pos+=.00015*getRand(pos*1.3).xyz*4.;
    pos+=.00006*getRand(pos*3.).xyz*4.;
    pos+=.00040*getRand(pos*.5).xyz*4.;
    vec3 p1,p2,p3;
    float d = 10000.;
    
    // sphere in the middle
	d=min(d,distSphere(pos,.79));
    
    // start with an icosahedron subdivided once
    getIcosaTri(pos, p1, p2, p3);
    getTriSubDiv(pos, p1, p2, p3);
    // always sort by X, then Y, then Z - to get a unique order of the edges
    sortXYZ(p1,p2,p3);
    d=min(d,distTruchet(pos, p1,p2,p3,.08));
    
    #if 1
    float sc = 1.;
    // subdivide again for another detail
    getTriSubDiv(pos,p1,p2,p3);
    sortXYZ(p1,p2,p3);
	sc = 1./.9;
    d=min(d,distTruchet(pos*sc, p1,p2,p3,.04)/sc);
    
    // subdivide again for another detail
	getTriSubDiv(pos,p1,p2,p3);
    sortXYZ(p1,p2,p3);
    sc = 1./.85;
    d=min(d,distTruchet(pos*sc, p1,p2,p3,.02)/sc);
    #endif
    
    return d;
}

vec3 getGrad(vec3 pos, float eps)
{
    vec2 d=vec2(eps,0);
    float d0=dist(pos);
    return vec3(dist(pos+d.xyy)-d0,
                dist(pos+d.yxy)-d0,
                dist(pos+d.yyx)-d0)/eps;
                
}

// march it...
vec4 march(inout vec3 pos, vec3 dir)
{
    // cull the sphere
    if(length(pos-dir*dot(dir,pos))>1.05) 
    	return vec4(0,0,0,1);
    
    float eps=0.001;
    float bg=1.0;
    for(int cnt=0;cnt<52;cnt++)
    {
        float d = dist(pos);
        pos+=d*dir*.8;
        if(d<eps) { bg=0.0; break; }
    }
    vec3 n = getGrad(pos,.001);
    return vec4(n,bg); // .w=1 => background
}

mat3 rotX(float ang)
{
    float c=cos(ang), s=sin(ang);
    return mat3(1,0,0, 0,c,s, 0,-s,c);
}

mat3 rotZ(float ang)
{
    float c=cos(ang), s=sin(ang);
    return mat3(c,s,0, -s,c,0, 0,0,1);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // screen coord -1..1
    vec2 sc = (fragCoord.xy/iResolution.xy)*2.-1.;
    // viewer position
    vec3 pos = vec3(0,-3.5,0);
    // pixel view direction
    vec3 dir = normalize(2.*normalize(-pos)+vec3(sc.x,0,sc.y*iResolution.y/iResolution.x));
    // rotate view around x,z
    float phi = iMouse.x/iResolution.x*7.;
    float th  = iMouse.y/iResolution.y*7.;
    if (iMouse.x==0.) { phi=iGlobalTime*.5; th=.27*.5*iGlobalTime; }
    mat3 rx = rotX(th);
    mat3 rz = rotZ(phi);
    pos = rz*(rx*pos);
    dir = rz*(rx*dir);
    
    // march it...
   	vec4 n=march(pos,dir);
    float bg=n.w;
        
    // calc some ambient occlusion
    float ao=1.;
    #if 0
    // calc simple ao by stepping along radius
    ao*=dist(pos*1.02)/.02;
    ao*=dist(pos*1.05)/.05;
    ao*=dist(pos*1.1)/.1;
    #else
    // calc ao by stepping along normal
    ao*=dist(pos+n.xyz*.02)/.02;
    ao*=dist(pos+n.xyz*.05)/.05;
    ao*=dist(pos+n.xyz*.10)/.10;
    #endif
    // adjust contrast of ao
    ao=pow(ao,.4);
    
    // reflection dir
    vec3 R = pos-2.0*dot(pos,n.xyz)*n.xyz;
    R = -((R*rz)*rx).yzx;
    
    vec3 c = vec3(1);
    // simply add some parts of the normal to the color
    // gives impression of 3 lights from different dir with different color temperature
    c += n.xyz*.05+.05;
    // slight green tint
    c+=vec3(0,.15,0);

    //  reflection of cubemap
    vec3 raf = textureCube(iChannel1,R).xyz;
    c *= (raf*1.2)+.4;
    
    // add some depth darkening
	c *= clamp(-dot(dir,pos)*.7+.7, .2, 1.);
    
    // apply ambient occlusion
    c *= ao;
    
    // apply background (medusa poison green)
    float aspect=iResolution.y/iResolution.x;
    phi=atan(sc.y*aspect,sc.x);
    float r = length(vec2(sc.y*aspect,sc.x));
    if(bg>=.5) c=vec3(.55,.75,.6)-.25-.03*sin(phi*17.+.7*sin(14.*r-3.*iGlobalTime));
    
    // vignetting
    float vign = (1.1-.3*length(sc.xy));
    
	fragColor = vec4(c*vign,1);
}
