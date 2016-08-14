
// ------------------ channel define
// 0_# tex01 #_0
// 1_# tex18 #_1
// ------------------


/*

    Abstract Island Cavern
    ----------------------

    I made an "Abstract Tunnel" example a while back. The main motivation was to provide a very
    basic tunnel template for anyone interested. I used the term "abstract" to describe the naive 
    rendering style - used to simulate the oldschool flat shaded polygon examples - that is  
    mildly reminiscent of abstract art.

    Anyway, this is a slightly more sophisticated version, but is built on the same premise. Like 
    the previous version, it's a tunnel system surfaced with a very basic triangle noise layer. 
    Rather than a single tunnel, this uses a more complex tunnel system created with some 
    sinusoidal-based gyroid code, but it's simple enough. Other than that, there's some simple 
    water, which is just a glorified, perturbed floor with some fake reflection and refraction.

    For anyone interested in creating a simple tunnel system with minimal effort, the gyroid 
    tunnel setup is worth looking at. As for cheap, jagged, noise-like surfacing, Nimitz's 
    triangle noise is impossible to improve on... but I'm still trying anyway. :)

    The word "abstract" is a bit of a cop out in this case. I didn't have the cycles to perform 
    all the required physics, like multiple reflection\refraction passes, etc, so decided to fake 
    it then call it "abstract." It's kind of like using the terms "alien" and "alternate reality"
    when the physics doesn't make any sense. So, with that in mind, this is an abstract rendering
    of a sea cavern setting on an alien planet in an alternate reality. :)

    All things considered, the rendering speed is pretty reasonable, but I'd like to refine it 
    some more to accommodate slower machines than the one I'm currently on.

    Based on:
    Abstract Corridor - Shane
    https://www.shadertoy.com/view/MlXSWX
    
    // Abstract rendering with triangle noise.
    Somewhere in 1993 - nimitz
    https://www.shadertoy.com/view/Md2XDD

    Much fancier example:

    // One of my favorites. In an idea world with fast computers, this is how I'd do it. :)
    La calanque - XT95
    https://www.shadertoy.com/view/Mst3Wr



*/

// https://www.shadertoy.com/view/Xld3W4

#define FAR 50. // Far plane, or maximum distance.

float objID = 0.; // Object ID - Cavern: 0.; Water: 1..

// 2x2 matrix rotation. Note the absence of "cos." It's there, but in disguise, and comes courtesy
// of Fabrice Neyret's "ouside the box" thinking. :)
mat2 rot2( float a ){ vec2 v = sin(vec2(1.570796, 0) - a);  return mat2(v, -v.y, v.x); }

 

float drawObject(in vec3 p){
    
    // Anything that wraps the domain will work. The following looks pretty intereting.
    //p = cos(p*3.14159 + iGlobalTime)*0.5; 
    //p = abs(cos(p*3.14159)*0.5);
    
    // Try this one for a regular, beveled Voronoi looking pattern. It's faster to
    // hone in on too, which is a bonus.
    p = fract(p)-.5;  
    return dot(p, p);
    
    //p = abs(fract(p)-.5);
    //p = abs(p - (p.x+p.y+p.z)/3.);
    //return dot(p, vec3(.5));
    
    //p = abs(fract(p)-.5);
    //return max(max(p.x, p.y), p.z);

    
}


// The 3D tiling process. I've explained it in the link below, if you're interested in the process.
//
// Cellular Tiled Tunnel
// https://www.shadertoy.com/view/MscSDB
float cellTile(in vec3 p){
    
    
    // Draw four overlapping objects at various positions throughout the tile.
    vec4 v, d; 
    d.x = drawObject(p - vec3(.81, .62, .53));
    p.xy = vec2(p.y-p.x, p.y + p.x)*.7071;
    d.y = drawObject(p - vec3(.39, .2, .11));
    p.yz = vec2(p.z-p.y, p.z + p.y)*.7071;
    d.z = drawObject(p - vec3(.62, .24, .06));
    p.xz = vec2(p.z-p.x, p.z + p.x)*.7071;
    d.w = drawObject(p - vec3(.2, .82, .64));

    v.xy = min(d.xz, d.yw);//, v.z = min(max(d.x, d.y), max(d.z, d.w)), v.w = max(v.x, v.y); 
   
    //d.x =  min(v.z, v.w) - min(v.x, v.y); // Maximum minus second order, for that beveled Voronoi look. Range [0, 1].
    d.x =  min(v.x, v.y); // First order.
        
    return d.x*2.66; // Normalize... roughly.
    
}


// Smooth maximum, based on IQ's smooth minimum.
float smax(float a, float b, float s){
    
    float h = clamp(.5 + .5*(a - b)/s, 0., 1.);
    return mix(b, a, h) + h*(1. - h)*s;
}

// The triangle function that Shadertoy user Nimitz has used in various triangle noise demonstrations.
// See Xyptonjtroz - Very cool. Anyway, it's not really being used to its full potential here.
// https://www.shadertoy.com/view/4ts3z2
vec3 tri(in vec3 x){return abs(fract(x)-.5);} // Triangle function.

// The function used to perturb the walls of the cavern: There are infinite possibities, but this one is 
// just a cheap...ish routine - based on the triangle function - to give a subtle jaggedness. Not very fancy, 
// but it does a surprizingly good job at laying the foundations for a sharpish rock face. Obviously, more 
// layers would be more convincing. However, this is a GPU-draining distance function, so the finer details 
// are bump mapped.
float surfFunc(in vec3 p){

    
    return dot(tri(p*.5 + tri(p*.25).yzx), vec3(0.666));
    
    //p /= 2.5;//6.283;
    //return dot(tri(p + tri(p.zxy)), vec3(0.666));
    
    //return dot(tri(p*.5 + tri(p.yzx*0.25)), vec3(4.5/9.)) + dot(tri(p.yzx + tri(p*.5)), vec3(1.5/9.));
 
    //p *= 6.283;
    //return dot(sin(p*.5 + sin(p.yzx*0.25))*.66 + sin(p.yzx + sin(p*.5))*.34, vec3(.166)) + .5;
 

}

// Perturbing the sea floor. Just a very basic sinusoidal combination.
float surfFunc2(in vec3 p){

    
    return dot(sin(p + sin(p.yzx*2. + iGlobalTime*2.)), vec3(.1666)) + .5;
 

}


// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tpl( sampler2D t, in vec3 p, in vec3 n ){
   
    n = max(abs(n), 0.001);
    n /= (n.x + n.y + n.z );  
    p = (texture2D(t, p.yz)*n.x + texture2D(t, p.zx)*n.y + texture2D(t, p.xy)*n.z).xyz;
    return p*p;
}


// Camera path. Arranged to coincide with the frequency of the lattice.
vec3 camPath(float t){
  
    //return vec3(0, 0, t); // Straight path.
    //return vec3(-sin(t/2.), sin(t/2.)*.5 + 1.57, t); // Windy path.
    
    //float s = sin(t/24.)*cos(t/12.);
    //return vec3(s*12., 0., t);
    
    float a = sin(t * 0.11);
    float b = cos(t * 0.14);
    return vec3(a*4. -b*1.5, b*1.2 + a*1., t);
    
}


// The cavern scene. The tunnel system is created with a sinusoidal lattice structure,
// and a triangle function variation provides the jagged surfacing. The sea is nothing
// more than a plane perturbed with a sinusoidal function. Everything is wrapped around
// a winding path.
// 
// By the way, I could use all sorts of trickery to slim this down and speed things up
// but it's more readable this way.
//
float map(vec3 p){
       
    
    float sea = p.y + 3.5; // Sea level. Just a plane.
    float sf = surfFunc(p); // Tunnel surface function.
    // Sinusoial tunnel system. It doesn't need to be produced here, but it looks more
    // random if it is.
    float cav = abs(dot(cos(p*3.14159/6.), sin(p.yzx*3.14159/6.)) + 1.5);
    
    p.xy -= camPath(p.z).xy; // Offsetting the main tunnel by the camera path.
  
    float tun = 2. - length(p.xy); // Main tunnel.
    
    // Smoothly combining the main tunnel with the sinusoidal tunnel system.
    tun = smax(tun, 1.-cav, 1.) + .35 + (.5-sf);
    
    // Perturbing the sea floor to create a watery effect... Lame watery effect. :)
    sf = surfFunc2(p);
    sea += (.5-sf)*.5;
    
    objID = step(sea, tun); // Determining the sea or cavern object ID.
    
    return min(sea, tun); // Combining the sea with the cavern (tunnel system).
 
}




// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float cao(in vec3 p, in vec3 n)
{
    float sca = 1.5, occ = 0.;
    for(float i=0.; i<5.; i++){
    
        float hr = .01 + i*.5/4.;        
        float dd = map(n * hr + p);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp(1.0 - occ, 0., 1.);    
}


// The normal function with some edge detection rolled into it. Sometimes, it's possible to get away
// with six taps, but we need a bit of epsilon value variance here, so there's an extra six.
vec3 nr(vec3 p, inout float edge) { 
    
    vec2 e = vec2(.01, 0); // Larger epsilon for greater sample spread, thus thicker edges.

    // Take some distance function measurements from either side of the hit point on all three axes.
    float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
    float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
    float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    float d = map(p)*2.;    // The hit point itself - Doubled to cut down on calculations. See below.
     
    // Edges - Take a geometry measurement from either side of the hit point. Average them, then see how
    // much the value differs from the hit point itself. Do this for X, Y and Z directions. Here, the sum
    // is used for the overall difference, but there are other ways. Note that it's mainly sharp surface 
    // curves that register a discernible difference.
    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = max(max(abs(d1 + d2 - d), abs(d3 + d4 - d)), abs(d5 + d6 - d)); // Etc.
    
    // Once you have an edge value, it needs to normalized, and smoothed if possible. How you 
    // do that is up to you. This is what I came up with for now, but I might tweak it later.
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));
    
    // Redoing the calculations for the normal with a more precise epsilon value.
    e = vec2(.0025, 0);
    d1 = map(p + e.xyy), d2 = map(p - e.xyy);
    d3 = map(p + e.yxy), d4 = map(p - e.yxy);
    d5 = map(p + e.yyx), d6 = map(p - e.yyx); 
    
    // Return the normal.
    // Standard, normalized gradient mearsurement.
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    float t = 0.0, h;
    for(int i = 0; i < 128; i++){
    
        h = map(ro+rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(h)<0.002*(t*.25 + 1.) || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.)
        t += h*.85;
        
    }

    return min(t, FAR);
}



// Shadows.
float sha(in vec3 ro, in vec3 rd, in float start, in float end, in float k){

    float shade = 1.0;
    const int maxIterationsShad = 20; 

    float dist = start;
    float stepDist = end/float(maxIterationsShad);

    for (int i=0; i<maxIterationsShad; i++){
        float h = map(ro + rd*dist);
        //shade = min(shade, k*h/dist);
        shade = min(shade, smoothstep(0.0, 1.0, k*h/dist));

        dist += clamp(abs(h), 0.01, 0.25);
        
        // There's some accuracy loss involved, but early exits from accumulative distance function can help.
        if (h<0.001 || dist > end) break; 
    }
    
    return min(max(shade, 0.) + 0.2, 1.0); 
}

// Surface bump function. Cheap, but with decent visual impact. Used for the water surface.
float bumpSurf3D( in vec3 p){
    
    return cellTile(p*.5)*.7 + cellTile(p)*.3;

}

// Standard function-based bump mapping function.
vec3 dbF(in vec3 p, in vec3 nor, float bumpfactor){
    
    const vec2 e = vec2(0.001, 0);
    float ref = bumpSurf3D(p);                 
    vec3 grad = (vec3(bumpSurf3D(p - e.xyy),
                      bumpSurf3D(p - e.yxy),
                      bumpSurf3D(p - e.yyx) )-ref)/e.x;                     
          
    grad -= nor*dot(nor, grad);          
                      
    return normalize( nor + grad*bumpfactor );
    
}


// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total.
vec3 db( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(0.001, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.    
    mat3 m = mat3( tpl(tx, p - e.xyy, n), tpl(tx, p - e.yxy, n), tpl(tx, p - e.yyx, n));
    
    vec3 g = vec3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
    g = (g - dot(tpl(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
    
}

// Compact, self-contained version of IQ's 3D value noise function. I have a transparent noise
// example that explains it, if you require it.
float n3D(vec3 p){
    
    const vec3 s = vec3(7, 157, 113);
    vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

// Simple environment mapping. Pass the reflected vector in and create some
// colored noise with it. The normal is redundant here, but it can be used
// to pass into a 3D texture mapping function to produce some interesting
// environmental reflections.
//
// More sophisticated environment mapping:
// UI easy to integrate - XT95    
// https://www.shadertoy.com/view/ldKSDm
vec3 eMap(vec3 rd, vec3 sn){
    
    vec3 sRd = rd; // Save rd, just for some mixing at the end.
    
    // Add a time component, scale, then pass into the noise function.
    rd.xy -= iGlobalTime*.25;
    rd *= 3.;
    
    //vec3 tx = tpl(iChannel1, rd/3., sn).zyx;
    //tx = smoothstep(0.2, 1., tx*2.); 
    //float c = dot(tx, vec3(.299, .587, .114));
    
    float c = n3D(rd)*.57 + n3D(rd*2.)*.28 + n3D(rd*4.)*.15; // Noise value.
    c = smoothstep(0.4, 1., c); // Darken and add contast for more of a spotlight look.
    
    vec3 col = vec3(c, c*c, c*c*c*c).zyx; // Simple, warm coloring.
    //vec3 col = vec3(min(c*1.5, 1.), pow(c, 2.5), pow(c, 12.)); // More color.
    
    // Mix in some more red to tone it down and return.
    return mix(col, col.yzx, sRd*.25+.25); 
    
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    
    // Screen coordinates.
    vec2 u = (fragCoord - iResolution.xy*0.5)/iResolution.y;
    
    // Camera Setup.
    float speed = 6.;
    vec3 o = camPath(iGlobalTime*speed); // Camera position, doubling as the ray origin.
    vec3 lk = camPath(iGlobalTime*speed + .1);  // "Look At" position.
    vec3 l = camPath(iGlobalTime*speed + 4.); // Light position, somewhere near the moving camera.
    
    // Light postion offset. Since the lattice structure is rotated about the XY plane, the light
    // has to be rotated to match. See the "map" equation.
    vec3 loffs =  vec3(0, .25, 0);
    vec2 a = sin(vec2(1.57, 0) - l.z*1.57/10.);
    //loffs.xy = mat2(a, -a.y, a.x)*loffs.xy; 
    l += loffs;

    // Using the above to produce the unit ray-direction vector.
    float FOV = 3.14159/3.; ///3. FOV - Field of view.
    vec3 fwd = normalize(lk-o);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    vec3 up = cross(fwd, rgt);

    // Unit direction ray.
    vec3 r = normalize(fwd + FOV*(u.x*rgt + u.y*up));
    // Lens distortion.
    //vec3 r = fwd + FOV*(u.x*rgt + u.y*up);
    //r = normalize(vec3(r.xy, (r.z - length(r.xy)*.25)));
    
    // Swiveling the camera from left to right when turning corners.
    r.xy = rot2(-camPath(lk.z).x/16. )*r.xy;


    // Raymarch.
    float t = trace(o, r);
    
    // Save the object ID directly after the raymarching equation, since other equations that
    // use the "map" function will distort the results. I leaned that the hard way. :)
    float sObjID = objID;

    // Initialize the scene color to the background.
    vec3 col = vec3(0);
    
    // If the surface is hit, light it up.
    if(t<FAR){
    
        // Position and normal.
        vec3 p = o + r*t;
        
        float ed; // Edge variable.
        vec3 n = nr(p, ed);
        
        vec3 svn = n;
        
        // Texture bump the normal.

        // Bump mapping.
        float sz = 1.;
        if(sObjID>.5) { // Sea.
            sz/=4.;
            n = dbF(p, n, .25); // Function bump.
            n = db(iChannel1, p*sz, n, .005/(1. + t/FAR)); // Texture bump.
        } 
        else { // Cavern. 
            n = db(iChannel0, p*sz, n, .02/(1. + t/FAR)); // Texture bump only.
        }


        l -= p; // Light to surface vector. Ie: Light direction vector.
        float d = max(length(l), 0.001); // Light to surface distance.
        l /= d; // Normalizing the light direction vector.
        
        float at = 1./(1. + d*.25 + d*d*.05); // Light attenuation.
        
        // Ambient occlusion and shadowing.
        float ao =  cao(p, n);
        float sh = sha(p, l, 0.04, d, 16.);
        
        // Diffuse, specular, fresnel. Only the latter is being used here.
        float di = max(dot(l, n), 0.);
        float sp = pow(max( dot( reflect(r, n), l ), 0.0 ), 16.); // Specular term.
        //float fr = clamp(1.0 + dot(r, n), 0.0, 1.0); // Fresnel reflection term.
        
        // Texturing the surface with some tri-planar mapping.
        vec3 tx;
        if(sObjID<.5) {
            tx = tpl(iChannel0, p*sz, n)*1.35; // Rock texturing.
            
        }
        else {
            tx = tpl(iChannel1, p*sz, n)*vec3(2, 2.4, 2.8); // Sea water texturing.
        }

        

        // Extra shading. Not really necessary, but I like it for extra depth.
        float sf;
        
        if(sObjID<.5){ // Rock surface shading.
            sf = surfFunc(p); 
        }
        else { // Sea surface shading.
            vec3 txp = p;
            txp.xy -= camPath(txp.z).xy;
            sf = surfFunc2(txp)*.8 + .2;
            sf *= bumpSurf3D(p)*.8 + .2;
        }
        
        tx *= sf; // Applying the surface shading to the texture value.
        

        // Very simple scene coloring. Diffuse, ambience and specular.
        col = tx*(di + vec3(.75, .75, 1)) + vec3(.5, .7, 1)*sp;
        
        // Edges.
        col *= 1. - ed*.75; // Darker edges.

        // Fake environment mapping.
        vec3 ref, refr;
        vec3 em; 
        
        if(sObjID>.5){ // Water.
            // Fake reflection and refraction to give a bit of a watery look, albeit
            // in a nonbelievable abstract fashion.
            ref = reflect(r, svn*.5 + n*.5);
            em = eMap(ref, n);
            col += tpl(iChannel0, ref, n)*em*4.;
            refr = refract(r, svn*.5 + n*.5, 1./1.33);
            em = eMap(refr, n); 
            col += tpl(iChannel0, refr, n)*em*2.;
        }
        else {
            ref = reflect(r, svn*.75 + n*.25);
            em = eMap(ref, n);
            col += col*em*4.; // Cavern walls.
        }
        
        // Apply some shading.
        col *= ao*sh*at;

        
    }
    
    // If we've hit the far plane, calulate "l" only.
    if(t>=FAR) l = normalize(l - o - r*FAR);
    
    // Produce some colored fog.
    vec3 bg = mix(vec3(.5, .7, 1), vec3(1, .5, .6), l.y*.5 + .5);
    col = mix(clamp(col, 0., 1.), bg.yzx, smoothstep(0., FAR-2., t));
     
    
    // Rough gamma correction, and we're done.
    fragColor = vec4(sqrt(clamp(col, 0., 1.)), 1.);
    
    
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