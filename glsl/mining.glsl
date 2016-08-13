
// ------------------ channel define
// 0_# tex06 #_0
// 1_# tex09 #_1
// 2_# tex02 #_2
// ------------------

// mine + cart, fragment shader by movAX13h (filip.sound@gmail.com), June 2014
// sound by srtuss

// https://www.shadertoy.com/view/4dsXzS

#define CART
#define RAILS
#define PILLARS
#define POST

#define resolution iResolution
#define time iGlobalTime
#define mouse iMouse

#define pi2 6.283185307179586476925286766559
#define focus 5.0
#define far 14.0

float atime = time*5.0;
vec3 sun = normalize(vec3(0.6, 1.0, 0.5));

float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float rand(float n)
{
    return fract(sin(n * 12.9898) * 43758.5453);
}

float sdBox(vec3 p, vec3 b) // by iq
{   
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float udBox(vec3 p, vec3 b) // by iq
{   
    return length(max(abs(p)-b,0.0)); 
}

float sdPlane(vec3 p, vec4 n) // by iq
{
    n.xyz = normalize(n.xyz);
    return dot(p,n.xyz) + n.w;
}

float sdCappedCylinder(vec3 p, vec2 h) // by iq, orientation modified
{
  vec2 d = abs(vec2(length(p.yz),p.x)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float smin(float a, float b, float k) // by iq
{
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}

vec2 track(float z)
{
    z *= 0.15;
    return vec2(2.0*sin(z)*(sin(z*0.33)*cos(z*0.2023))+10.0*sin(z*0.01), 
                2.0*cos(z)*(cos(z*0.33)*sin(z*0.2511)));
}

struct Hit
{
    float d;
    vec4 color;
};

Hit scene(vec3 p)
{
    float d, d1;
    
    d = far;
    vec4 col = vec4(0.0);
    
    p.xy -= track(p.z);
    vec3 w = p; w.xy += vec2(0.5*sin(p.z)*sin(p.z*0.2), 0.1*cos(p.z));
    vec3 q = vec3(atan(w.x, w.y) * 8.0 / pi2, length(w.xy), w.z);
    vec2 uv = 0.18*q.xz;
    vec4 tex = texture2D(iChannel0, uv);
    col = 0.15*texture2D(iChannel1, uv) + 0.1*tex;
    col.a = 0.3;

    vec4 col1 = texture2D(iChannel1, 0.18*p.yz);
    vec4 col2 = texture2D(iChannel0, 0.18*p.yx);
    
    
    // tunnel
    d = 1.0-length(w.xy-0.02*tex.rg);
    
    // lights (could be)
    #if 0
    float r = 20.0;
    q.z = mod(q.z, r)-0.5*r;
    d1 = udBox(q-vec3(-2.0, 1.0, 0.0), vec3(0.04, 0.05, 0.1));
    if (d1 < d) { d = d1; col = vec4(0.9, 0.9, 0.9, 1.0); }
    #endif
    
    // floor
    d = smin(d, sdPlane(p-vec3(0.0, -0.6+0.01*tex.r, 0.0), vec4(0.0, 1.0, 0.0, 0.0)), 0.2);

    #ifdef PILLARS
    q = vec3(abs(w.x)-0.93,w.y+0.57, mod(w.z,5.0)-2.5); 
    d1 = min(udBox(q-vec3(0.0, 0.5, 0.0), vec3(0.1, 0.7, 0.04)),
             udBox(q-vec3(-0.5, 1.2, 0.0), vec3(0.5, 0.06, 0.04)));
    if (d1 < d) { d = d1; col = vec4(0.1*(col1.rgb + col2.rgb)*vec3(1.5, 0.9, 0.9), 0.0); }
    #endif
    
    #ifdef RAILS
        q = vec3(abs(p.x)-0.23,p.y+0.57, mod(p.z,5.0)-2.5); 
        d1 =              udBox(q-vec3(0.0,0.07,0.0),   vec3(0.02,0.01,2.49)); 
        d1 = min(d1, smin(udBox(q-vec3(0.0,0.04,0.0),   vec3(0.01,0.04,2.49)),
                          udBox(q-vec3(0.0,-0.01 ,0.0), vec3(0.04,0.02,2.49)),0.03)); 
        if (d1 < d) { d = d1; col = vec4(0.06, 0.05, 0.063, 1.0); }
        
        q = vec3(p.x, p.y+0.6-col.x*0.08, mod(p.z,1.0)-0.5);
        d1 = sdBox(q, vec3(0.4,0.02,0.1)); 
        if (d1 < d) { d = d1; col = 0.7*col + vec4(0.04, 0.0, 0.0, 0.05); }
        
        q.x = abs(q.x)-0.23;
        q.y -= 0.02;
        d1 = sdBox(q, vec3(0.07,0.01,0.01)); 
        if (d1 < d) { d = d1; col = vec4(.2, .2, .2, 1.0); }
    #endif
    
    #ifdef CART
        float z = (mouse.z > 0.0 ? 0.6 : 4.0)+atime;
        tex = texture2D(iChannel2, p.xy*1.3);
        vec4 ccol = vec4(0.2*tex.rgb,0.3);
    
        // basket
        d1 = max(min(max(
                smin(
                    udBox(p-vec3(0.0,-0.07,z), vec3(0.1,0.1,0.27)), // top
                    udBox(p-vec3(0.0,-0.24,z), vec3(0.1,0.15,0.3)), // bottom
                    0.4),
                -sdBox(p-vec3(0.0, 0.0, z), vec3(0.28, 0.1, 0.4))), // cut top
                 sdBox(p-vec3(0.0, -0.138, z), vec3(0.21, 0.03, 0.4))), // frame
                -sdBox(p-vec3(0.0, 0.0, z), vec3(0.18, 0.25, 0.31))); // cut inner
        if (d1 < d) { d = d1; col = ccol*1.6; }
        
    
        // base plate
        d1 = min(udBox(p-vec3(0.0,-0.4,z),vec3(0.185,0.015,0.41)), 
                 udBox(p-vec3(0.0,-0.43,z), vec3(0.19, 0.03, 0.28))); 
        if (d1 < d) { d = d1; col = ccol; }
    
        // wheels
        tex = texture2D(iChannel2, p.xz); // moving with z
        q = vec3(abs(p.x)-0.21,p.y+0.44, p.z-z+0.2); 
        vec2 ws = vec2(0.06-sign(q.x)*0.01, 0.02);
    
        d1 = min(sdCappedCylinder(q, ws),
                 sdCappedCylinder(q-vec3(0.0, 0.0, 0.4), ws));
        if (d1 < d) { d = d1; col = vec4(tex.rgb*0.4, 0.7); }
    #endif
    
    return Hit(d, col);
}

vec3 normal(vec3 p)
{
    float c = scene(p).d;
    vec2 h = vec2(0.01, 0.0);
    return normalize(vec3(scene(p + h.xyy).d - c, 
                          scene(p + h.yxy).d - c, 
                          scene(p + h.yyx).d - c));
}

vec3 colorize(in Hit hit, in vec3 pos, in vec3 dir)
{
    vec3 n = normal(pos);
    vec3 ref = normalize(reflect(dir, n));

    float diffuse = 2.0*max(0.0, dot(n, sun));
    float specular = hit.color.a*pow(max(0.0, dot(ref, sun)), 3.5);

    return (hit.color.rgb * 0.3 +
            hit.color.rgb * diffuse +
            specular * vec3(0.8));
}

void main() {

    //vec2 pos = (fragCoord.xy*2.0 - resolution.xy) / resolution.y;
    vec2 pos = ((vUv * 2.0) - 1.0) * vec2(iResolution.z, 1.0);
    
    vec3 cp = vec3(track(atime)+sin(atime)*sin(atime*0.2)*vec2(rand(atime)*0.02, rand(time)*0.03), atime); 
    cp.y +=0.1;
        
    vec3 ct = vec3(track(atime + 4.0), atime + 4.0);
    vec3 cd = normalize(ct-cp);
    vec3 cu  = vec3(0.1*(ct.x-cp.x), 1.0, 0.0);
    vec3 cs = cross(cd, cu);
    vec3 dir = normalize(cs*pos.x + cu*pos.y + cd*focus);   
    vec3 ray = cp;
    
    Hit h = Hit(0.0, vec4(0.0));
    float dist = 0.0;
    
    for(int i=0; i < 100; i++) 
    {
        h = scene(ray);
            
        if(h.d < 0.0001) break;
        
        dist += h.d;
        ray += dir * h.d;

        if(dist > far) 
        { 
            dist = far;
            break; 
        }
    }

    vec3 c = colorize(h, ray, dir); 
    c *= (1.0 - dist/far);
    
    #ifdef POST
    c *= 2.5 - rand(pos) * 0.1;
    c -= 0.4*smoothstep(0.6,3.7, length(pos));
    #endif

    // tone mapping
    c = toneMap( c );
    
    gl_FragColor = vec4(c, 1.0);
}