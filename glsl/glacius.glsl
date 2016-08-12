
// ------------------ channel define
// 0_# grey1 #_0
// 1_# noise #_1
// -----------------

// Created by Stephane Cuillerdier - Aiekick/2015 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
    
//Subo Glacius (Under The Ice in latin)
//I use the famous voronesque func from shane and a texture to displace a plane.
//I have also returned the camera and add a basic fog to the end processing
//The X axis of the mouse can be used for translate on x the camera 
//enjoy :)

// https://www.shadertoy.com/view/Ml2XRW

const vec2 RMPrec = vec2(.2, 0.01); 
const vec2 DPrec = vec2(0.01, 50.); 

const vec3 IceColor = vec3(0,.38,.47);
const vec3 DeepColor = vec3(0,.02,.15);

// by shane from https://www.shadertoy.com/view/4lSXzh
float Voronesque( in vec3 p )
{
    vec3 i  = floor(p + dot(p, vec3(0.333333)) );  p -= i - dot(i, vec3(0.166666)) ;
    vec3 i1 = step(0., p-p.yzx), i2 = max(i1, 1.0-i1.zxy); i1 = min(i1, 1.0-i1.zxy);    
    vec3 p1 = p - i1 + 0.166666, p2 = p - i2 + 0.333333, p3 = p - 0.5;
    vec3 rnd = vec3(7, 157, 113); 
    vec4 v = max(0.5 - vec4(dot(p, p), dot(p1, p1), dot(p2, p2), dot(p3, p3)), 0.);
    vec4 d = vec4( dot(i, rnd), dot(i + i1, rnd), dot(i + i2, rnd), dot(i + 1., rnd) ); 
    d = fract(sin(d)*262144.)*v*2.; 
    v.x = max(d.x, d.y), v.y = max(d.z, d.w); 
    return max(v.x, v.y);
}

vec2 map(vec3 p)
{
    float voro = Voronesque(p);
    float tex = texture2D(iChannel1, p.xz/200.).r*12.;
    return vec2(p.y - tex + voro, 0.);
}

vec3 nor( vec3 pos, float prec )
{
    vec2 e = vec2( prec, 0. );
    vec3 n = vec3(
        map(pos+e.xyy).x - map(pos-e.xyy).x,
        map(pos+e.yxy).x - map(pos-e.yxy).x,
        map(pos+e.yyx).x - map(pos-e.yyx).x );
    return normalize(n);
}

vec3 cam(vec2 uv, vec3 ro, vec3 cu, vec3 cv)
{
    vec3 rov = normalize(cv-ro);
    vec3 u =  normalize(cross(cu, rov));
    vec3 v =  normalize(cross(rov, u));
    vec3 rd = normalize(rov + u*uv.x + v*uv.y);
    return rd;
}

void main(){
    
    vec3 col = vec3(0.0);
    //vec2 g = gl_FragCoord.xy;
    vec2 si = iResolution.xy;
    //vec2 uv = (gl_FragCoord.xy+gl_FragCoord.xy-si)/min(si.x, si.y);

    vec2 uv = ((vUv - 0.5) * 2.0) * vec2(iResolution.z, 1.0);

    vec3 cu = vec3(0,-1,0);
    vec3 ro = vec3(-10., 10., iGlobalTime);
    vec3 cv = vec3(0,0,.08); 
    
    if (iMouse.z>0.) ro.x = -20.*iMouse.x/si.x;
    
    float vy = map(ro + cv).x;// cam h
    
    // smooth cam path
    const int smoothIter = 8;
    for (int i=0;i<smoothIter;i++)
        vy += map(ro + cv * float (i)).x;
    vy /= float(smoothIter);
    
    ro.y -= vy * .78;
    
    vec3 rd = cam(uv, ro, cu, ro + cv);
    
    vec3 d = vec3(0.);
    vec3 p = ro+rd*d.x;
    float sgn = sign(map(p).x);
    vec2 s = vec2(DPrec.y,0.);
    
    for(int i=0;i<150;i++)
    {      
        if(s.x<DPrec.x||s.x>DPrec.y) break;
        s = map(p);
        s.x *= (s.x>DPrec.x?RMPrec.x:RMPrec.y) * sgn;
        d.x += s.x;
        p = ro+rd*d.x;
    }

    if (d.x<DPrec.y)
    {
        vec3 n = nor(p, .1);
        col = textureCube(iChannel0,  n).rgb*.2;// some reflect
        
        if ( s.y < 1.5) // icy color
        {
            rd = reflect(rd, n);
            p += rd*d.x;        
            d.x += map(p).x * RMPrec.x;
            col += exp(-d.x / IceColor / 10.);
        }
    }

    // tone mapping
    col = toneMap( col );
    
    gl_FragColor = mix( vec4(col, 1.0), vec4(DeepColor, 1.), 1.0 - exp( -d.x/3.) ); // fog
}

