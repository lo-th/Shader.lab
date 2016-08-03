// Water world. Created by Reinder Nijhoff 2013
// @reindernijhoff
//
// https://www.shadertoy.com/view/lslGDB
//
// As usual, almost al code is copy-paste from shaders by inigo quilez 
// Lens flare by musk! (https://www.shadertoy.com/view/4sX3Rs)
// 
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

uniform samplerCube envMap;
uniform vec3 resolution;
uniform vec4 mouse;
uniform float time;

varying vec2 vUv;
varying vec3 vEye;

#define BUMPFACTOR 0.1
#define EPSILON 0.1
#define BUMPDISTANCE 36.
#define MAXDISTANCE 150.

vec3 lig = normalize(vec3(-0.8,0.6,-0.2));
float tt = time + 350.;

float noise(float t) {
    return texture2D(iChannel0,vec2(t,.0)/vec2(256.0)).x;
}

float noise( in vec2 x ) {
    vec2 p = floor(x);
    vec2 f = fract(x);

    vec2 uv = p.xy + f.xy*f.xy*(3.0-2.0*f.xy);

    return -1.0 + 2.0*texture2D( iChannel0, (uv+0.5)/256.0, -100.0 ).x;
}

float noise( in vec3 x )
{
    float  z = x.z*64.0;
    vec2 offz = vec2(0.317,0.123);
    vec2 uv1 = x.xy + offz*floor(z); 
    vec2 uv2 = uv1  + offz;
    return mix(texture2D( iChannel0, uv1 ,-100.0).x,texture2D( iChannel0, uv2 ,-100.0).x,fract(z))-0.5;
}

const mat2 m2 = mat2( 0.80, -0.60, 0.60, 0.80 );

const mat3 m3 = mat3( 0.00,  0.80,  0.60,
                     -0.80,  0.36, -0.48,
                     -0.60, -0.48,  0.64 );

float fbm( vec3 p ) {
    float f = 0.0;
    f += 0.5000*noise( p ); p = m3*p*2.02;
    f += 0.2500*noise( p ); p = m3*p*2.03;
    f += 0.1250*noise( p ); p = m3*p*2.01;
    f += 0.0625*noise( p );
    return f/0.9375;
}

float base( in vec3 p){
    return noise(p*0.005)*20.0;
}

vec3 terrainOffset =  0.5*vec3( 0., -0.4, 0. )*(tt+0.12*sin(tt*4.));
float terrainYFactor = (1.1+sin(tt*0.125));

float mapTerrain( in vec3 p ) {
    vec3 c = p  + terrainOffset;
    return base(c)+7.0+0.03*base(c*10.)+2.0*p.y*terrainYFactor;
}

// intersection functions

bool intersectPlane(vec3 ro, vec3 rd, float height, out float dist) {   
    if (rd.y==0.0) {
        return false;
    }
        
    float d = -(ro.y - height)/rd.y;
    d = min(100000.0, d);
    if( d > 0. ) {
        dist = d;
        return true;
    }
    return false;
}

vec3 intersect( in vec3 ro, in vec3 rd, in float maxd ) {
    float precis = 0.0005;
    float h=precis*2.0;
    float t = 0.0;
    float d = 0.0;
    float m = 1.0;
    for( int i=0; i<150; i++ ) {
        if( abs(h) < precis || t > maxd ) break; {
            t += h;
            h = 0.15*mapTerrain( ro+rd*t );
        }
    }

    if( t>maxd ) m=-1.0;
    return vec3( t, d, m );
}

vec3 calcNormal( vec3 pos ) {
    vec3 eps = vec3(0.1,0.0,0.0);

    return normalize( vec3(
           mapTerrain(pos+eps.xyy) - mapTerrain(pos-eps.xyy),
           mapTerrain(pos+eps.yxy) - mapTerrain(pos-eps.yxy),
           mapTerrain(pos+eps.yyx) - mapTerrain(pos-eps.yyx) ) );
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
    float h = 1.0;
    for( int i=0; i<32; i++ ) {
        h = 0.15*mapTerrain(ro + rd*t);
        res = min( res, k*h/t );
        t += clamp( h, 0.02, 2.0 );
        
        if( h<0.0001 ) break;
    }
    return clamp(res,0.0,1.0);
}

vec4 texcube( sampler2D sam, in vec3 p, in vec3 n ) {
    vec4 x = texture2D( sam, p.yz );
    vec4 y = texture2D( sam, p.zx );
    vec4 z = texture2D( sam, p.xy );

    return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}

float waterHeightMap( vec2 pos ) {
    vec2 posm = 0.01*pos * m2;
    posm.x += 0.001*tt;
    float f = fbm( vec3( posm*1.9, tt*0.01 ));
    float height = 0.5+0.1*f;
    height += 0.05*sin( posm.x*6.0 + 10.0*f );
    
    float h1 = 1.*mapTerrain( vec3(pos.x, -2.0, pos.y ) );
    float h2 = 1.*mapTerrain( vec3(pos.x, -1.5, pos.y ) );
    float h = min(h1,h2);
    height += 0.25*sin( 4.*h-(tt+0.8*noise( pos.xy*2. ))*6. )/(1.5*h1+1.0);
    
    return  height;
}

//-----------------------------------------------------
// Lens flare
//
// by musk License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// Trying to get some interesting looking lens flares.
// 
//  13/08/13: 
//  published
// 
// muuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuusk!
//-----------------------------------------------------

vec3 lensflare(vec2 uv,vec2 pos) {
    vec2 main = uv-pos;
    vec2 uvd = uv*(length(uv));
    
    float ang = atan(main.x,main.y);
    float dist=length(main); dist = pow(dist,.1);
    float n = noise(vec2(ang*16.0,dist*32.0));
    
    float f0 = 1.0/(length(uv-pos)*16.0+1.0);
    
    f0 = f0+f0*(sin(noise((pos.x+pos.y)*2.2+ang*4.0+5.954)*16.0)*.1+dist*.1+.8);
    
    float f1 = max(0.01-pow(length(uv+1.2*pos),1.9),.0)*7.0;

    float f2 = max(1.0/(1.0+32.0*pow(length(uvd+0.8*pos),2.0)),.0)*00.25;
    float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*pos),2.0)),.0)*00.23;
    float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*pos),2.0)),.0)*00.21;
    
    vec2 uvx = mix(uv,uvd,-0.5);
    
    float f4 = max(0.01-pow(length(uvx+0.4*pos),2.4),.0)*6.0;
    float f42 = max(0.01-pow(length(uvx+0.45*pos),2.4),.0)*5.0;
    float f43 = max(0.01-pow(length(uvx+0.5*pos),2.4),.0)*3.0;
    
    uvx = mix(uv,uvd,-.4);
    
    float f5 = max(0.01-pow(length(uvx+0.2*pos),5.5),.0)*2.0;
    float f52 = max(0.01-pow(length(uvx+0.4*pos),5.5),.0)*2.0;
    float f53 = max(0.01-pow(length(uvx+0.6*pos),5.5),.0)*2.0;
    
    uvx = mix(uv,uvd,-0.5);
    
    float f6 = max(0.01-pow(length(uvx-0.3*pos),1.6),.0)*6.0;
    float f62 = max(0.01-pow(length(uvx-0.325*pos),1.6),.0)*3.0;
    float f63 = max(0.01-pow(length(uvx-0.35*pos),1.6),.0)*5.0;
    
    vec3 c = vec3(.0);
    
    c.r+=f2+f4+f5+f6; c.g+=f22+f42+f52+f62; c.b+=f23+f43+f53+f63;
    c = c*1.3 - vec3(length(uvd)*.05);
    c+=vec3(f0);
    
    return c;
}

//-----------------------------------------------------
    

vec3 path( float t ) {
    return vec3( 26.0*cos(0.2+0.35*.1*t*1.5), 1.5, 26.0*sin(0.1+0.5*0.099*t*1.5) );   
}

void main() {

    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0*q;
    p.x *= resolution.x / resolution.y;
    
    
    // camera   
    float off = step( 0.001, mouse.z )*6.0*mouse.x/resolution.x;
    tt += off;
    vec3 ro = path( tt+0.0 );
    vec3 ta = path( tt+1.6 );
    
    ro.y += clamp(0.4-mapTerrain(ro), 0., 1.);
    
    ta.y *= 0.8 + 0.25*sin(0.09*tt);
    float roll = 0.3*sin(1.0+0.07*tt);
    
    // camera tx
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(roll), cos(roll),0.0);
    vec3 cu = normalize(cross(cw,cp));
    vec3 cv = normalize(cross(cu,cw));
    
    vec3 rd = normalize( p.x*cu + p.y*cv + 2.1*cw );

    float flare = dot( lig, normalize(ta-ro) );
    
    //-----------------------------------------------------
    // render
    //-----------------------------------------------------
    
    // raymarch
    bool reflection = false;    
    float dist, totaldist = 0., depth = 0.;
    vec3 normal;
    bool planeIntersect = intersectPlane( ro, rd, -2., dist );
        
    vec3 tmat = intersect(ro,rd, planeIntersect?dist:MAXDISTANCE );
    
    if( planeIntersect && dist < tmat.x ) {         
        ro = ro+rd*dist;
        totaldist = dist;
        
        depth = mapTerrain(ro);
        
        vec2 coord = ro.xz;
        vec2 dx = vec2( EPSILON, 0. );
        vec2 dz = vec2( 0., EPSILON );
        
        float bumpfactor = BUMPFACTOR * (1. - smoothstep( 0., BUMPDISTANCE, dist) );
        
        normal = vec3( 0., 1., 0. );
        normal.x = -bumpfactor * (waterHeightMap(coord + dx) - waterHeightMap(coord-dx) ) / (2. * EPSILON);
        normal.z = -bumpfactor * (waterHeightMap(coord + dz) - waterHeightMap(coord-dz) ) / (2. * EPSILON);
        normal = normalize( normal );
        
        rd = reflect( rd, normal );
        
        tmat = intersect(ro,rd, MAXDISTANCE);
        reflection = true;
    } 
        
    totaldist += tmat.x;
    
    // sky   
    vec3 col = 2.0*vec3(0.32,0.36,0.4) - rd.y*0.6;
    float sun = clamp( dot(rd,lig), 0.0, 1.0 );
    col += vec3(1.0,0.8,0.4)*0.2*pow( sun, 6.0 );
        
    col += 0.1*vec3( fbm( rd*0.2 ) );
    
    vec3 bgcol = col;
            
    if( tmat.z>-0.5 && totaldist < MAXDISTANCE)
    {
        // geometry
        vec3 pos = ro + tmat.x*rd;
        vec3 nor = calcNormal(pos);
        vec3 ref = reflect( rd, nor );
                
        // material
        vec4 mate = vec4(0.0);
        vec3 matpos = pos+terrainOffset;
        
        mate.w = 0.0;
        mate.xyz = texcube( iChannel1, 0.1*matpos*vec3(1.0,2.2,1.0), nor ).xyz;
        mate.xyz *= vec3(0.4,0.4,0.4);
        
        mate.xyz *= 3.0*vec3(0.32,0.36,0.4) - nor.y*0.6;

        // lighting
        float occ = 1.0;//(0.5 + 0.5*nor.y);//*mate2.y;
        float amb = clamp(0.5 + 0.5*nor.y,0.0,1.0);
        float bou = clamp(-nor.y,0.0,1.0)*clamp(1.0-pos.y/10.0,0.0,1.0);
        float dif = max(dot(nor,lig),0.0);
        float bac = max(0.2 + 0.8*dot(nor,normalize(vec3(-lig.x,0.0,-lig.z))),0.0);
        float sha = 0.0; if( dif>0.01 ) sha=softshadow( pos+0.05*nor, lig, 0.0005, 32.0 );
        float fre = mate.w;//pow( clamp( 1.0 + dot(nor,rd), 0.0, 1.0 ), 2.0 );
        float spe = max( 0.0, pow( clamp( dot(lig,reflect(rd,nor)), 0.0, 1.0), 100.0 ) );
        
        // lights
        vec3 brdf = vec3(0.0);
        brdf += 3.0*dif*vec3(1.10,0.90,0.80)*pow(vec3(sha),vec3(1.0,1.2,1.5));
        brdf += 1.0*amb*vec3(0.10,0.15,0.30)*occ;
        brdf += 1.0*bac*vec3(0.09,0.06,0.04)*occ;
        brdf += 2.5*bou*vec3(0.02,0.06,0.09)*occ;
        
        brdf += 50.0*spe*vec3(1.0)*occ*dif*sha*clamp( (4.-pos.y)/6., 0., 1.)*clamp( 0.5+fbm(matpos), 0., 1.);

        // surface-light interacion
        col = mate.xyz* brdf + 0.7*sha*vec3(0.3,0.5,0.6)*fre*mate.w + mate.w*vec3(1.0,0.9,0.8)*spe*sha;         
    } 

    if( reflection ) {
        col = mix( bgcol, col, exp(-0.000001*pow(totaldist-dist,3.0)) );
        
        col *= 0.9*vec3( 0.8, 0.9, 1. )*(0.5+clamp( depth*2., 0.0, 0.5));

        float spe = max( 0.0, pow( clamp( dot(lig,rd), 0.0, 1.0), 100.0 ) )*softshadow( ro, lig, 0.0005, 32.0 );
        
        col += 2.0*spe*vec3(1.0);
        
        if( dist != totaldist ) totaldist = dist;
    } 
    col = mix( bgcol, col, exp(-0.000001*pow(totaldist,3.0)) );
    
    // sun glow
    col += vec3(1.0,0.6,0.2)*0.2*pow( sun, 2.0 )*clamp( (rd.y+0.4)/(0.0+0.4),0.0,1.0);

    
    vec2 sunuv =  2.7*vec2( dot( lig, cu ), dot( lig, cv ) );
    
    col += vec3(1.4,1.2,1.0)*lensflare(p, sunuv)
        *clamp( 3.*flare, 0., 1.);  
    
    //-----------------------------------------------------
    // postprocessing
    //-----------------------------------------------------
    // gamma
    col = clamp( col, 0.0, 1.0 );
    col = pow( clamp(col,0.0,1.0), vec3(0.45) );
    
    // contrast, desat, tint and vignetting 
    col = col*0.7 + 0.3*col*col*(3.0-2.0*col);
    col = mix( col, vec3(col.x+col.y+col.z)*0.33, 0.1 );
    col *= vec3(1.03,1.02,1.0);
    col *= 0.5 + 0.5*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
    
    gl_FragColor = vec4( col, 1.0 );
}
