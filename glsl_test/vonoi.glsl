/*
    3D Cellular Tiling
    ------------------
    
    Creating a Voronoi feel with minimal instructions by way of a 3D tile constructed via a 
    simplistic cellular pattern algorithm. It works surprisingly well under various situations,
    but isn't a replacement for the standard 3D Voronoi algorithm.

    This is a 3D counterpart to my 2D cellular tiling example. The link is below, where I explain
    the process more thouroughly, for anyone interested. I came up with the idea for a repeatable
    cellular tile when experimenting with 3D Truchet tiles.

    Naturally, there are a few restrictions. The obvious one is that repeatable tiles with low
    object density look very repetitive when you zoom out, so that has to be considered. The 
    upside is quasi 3D celluar surfaces that are fast enough to include in a distance function.

    Anyway, the 3D tiling function is explained below. For anyone interested, the scene itself
    utilizes an oldschool, warping planes trick. Shadertoy user Branch uses it to great effect in 
    the example "18756.2048d," which is well worth the look.

    Related examples: 

    Cellular Tiling - Shane
    https://www.shadertoy.com/view/4scXz2

    18756.2048d - Branch
    https://www.shadertoy.com/view/ld3XzS

*/

#define PI 3.14159265
#define FAR 50.

// Frequencies and amplitudes of tunnel "A" and "B". See then "path" function.
const float freqA = 0.15;
const float freqB = 0.25;
const float ampA = 3.6;
const float ampB = .85;


// Standard 1x1 hash functions. Using "cos" for non-zero origin result.
float hash( float n ){ return fract(cos(n)*45758.5453); }

// Non-standard vec3-to-vec3 hash function.
vec3 hash33(vec3 p){ 
    
    float n = sin(dot(p, vec3(7, 157, 113)));    
    return fract(vec3(2097152, 262144, 32768)*n); 
}

// 2x2 matrix rotation. Note the absence of "cos." It's there, but in disguise, and comes courtesy
// of Fabrice Neyret's "ouside the box" thinking. :)
mat2 rot2( float a ){ vec2 v = sin(vec2(1.570796, 0) + a);  return mat2(v, -v.y, v.x); }


// Tri-Planar blending function. Based on an old Nvidia tutorial.
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max((abs(n) - 0.2)*7., 0.001); // n = max(abs(n), 0.001), etc.
    n /= (n.x + n.y + n.z );  
    
    return (texture2D(tex, p.yz)*n.x + texture2D(tex, p.zx)*n.y + texture2D(tex, p.xy)*n.z).xyz;
}

// More concise, self contained version of IQ's original 3D noise function.
float noise3D(in vec3 p){
    
    // Just some random figures, analogous to stride. You can change this, if you want.
    const vec3 s = vec3(7, 157, 113);
    
    vec3 ip = floor(p); // Unique unit cell ID.
    
    // Setting up the stride vector for randomization and interpolation, kind of. 
    // All kinds of shortcuts are taken here. Refer to IQ's original formula.
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    
    p -= ip; // Cell's fractional component.
    
    // A bit of cubic smoothing, to give the noise that rounded look.
    p = p*p*(3. - 2.*p);
    
    // Standard 3D noise stuff. Retrieving 8 random scalar values for each cube corner,
    // then interpolating along X. There are countless ways to randomize, but this is
    // the way most are familar with: fract(sin(x)*largeNumber).
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    
    // Interpolating along Y.
    h.xy = mix(h.xz, h.yw, p.y);
    
    // Interpolating along Z, and returning the 3D noise value.
    return mix(h.x, h.y, p.z); // Range: [0, 1].
    
}


////////

// The cellular tile routine. Draw a few gradient shapes (six to eight spheres, in this case) 
// using the darken (min(src, dst)) blend at various 3D locations on a cubic tile. Make the 
// tile wrappable by ensuring the objects wrap around the edges. That's it.
//
// Believe it or not, you can get away with as few as four spheres. Of course, there is 8-tap 
// Voronoi, which has the benefit of scalability, and so forth, but if you sum the total 
// instruction count here, you'll see that it's way, way lower. Not requiring a hash function
// provides the biggest benefit, but there is also less setup.
// 
// The result isn't perfect, but 3D cellular tiles can enable you to put a Voronoi looking 
// surface layer on a lot of 3D objects for little cost. In fact, it's fast enough to raymarch.
//
float drawSphere(in vec3 p){
    
    p = fract(p)-.5;    
    return dot(p, p);
    
    //p = abs(fract(p)-.5);
    //return dot(p, vec3(.166));
    
}

// Draw some spheres throughout a repeatable cubic tile. The offsets were partly based on 
// science, but for the most part, you could choose any combinations you want. This 
// particular function is used by the raymarcher, so involves fewer spheres.
//
float cellTile(in vec3 p){
    
    float c = .25; // Set the maximum.
    
    // Draw four overlapping objects (spheres, in this case) using the darken blend 
    // at various positions throughout the tile.
    c = min(c, drawSphere(p - vec3(.81, .62, .53)));
    c = min(c, drawSphere(p - vec3(.39, .2, .11)));
    
    c = min(c, drawSphere(p - vec3(.62, .24, .06)));
    c = min(c, drawSphere(p - vec3(.2, .82, .64)));
    
    
    // Add some smaller spheres at various positions throughout the tile.
    
    p *= 1.4142;
    
    c = min(c, drawSphere(p - vec3(.48, .29, .2)));
    c = min(c, drawSphere(p - vec3(.06, .87, .78)));
    
    // More is better, but I'm cutting down to save cycles.
    //c = min(c, drawSphere(p - vec3(.6, .86, .0)));
    //c = min(c, drawSphere(p - vec3(.18, .44, .58)));
        
    return (c*4.); // Normalize.
    
}

// The same as above, but with an extra two spheres. This is used by the bump map function,
// which although expensive, isn't too bad. Just for the record, even bump mapping a
// reasonably fast cellular function, like 8-Tap Voronoi, can still be a drain on the GPU.
// However, the GPU can bump map this function in its sleep.
//
float cellTile2(in vec3 p){
    
    float c = .25; // Set the maximum.
    
    c = min(c, drawSphere(p - vec3(.81, .62, .53)));
    c = min(c, drawSphere(p - vec3(.39, .2, .11)));
    
    c = min(c, drawSphere(p - vec3(.62, .24, .06)));
    c = min(c, drawSphere(p - vec3(.2, .82, .64)));
    
    p *= 1.4142;
    
    c = min(c, drawSphere(p - vec3(.48, .29, .2)));
    c = min(c, drawSphere(p - vec3(.06, .87, .78)));

    c = min(c, drawSphere(p - vec3(.6, .86, .0)));
    c = min(c, drawSphere(p - vec3(.18, .44, .58)));
        
    return (c*4.);
    
}

// The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
vec2 path(in float z){ return vec2(ampA*sin(z * freqA), ampB*cos(z * freqB)); }


// There's a few simple, warping tricks being employed here. One is the oldscool, "top and bottom
// planes" via "abs(p.y)." The planes are then twisted about the XY plane with respect to distance 
// using the 2D rotation function, "rot2(p.z/12.)," etc, then wrapped aound a curvy path, "path(p.z)."
//
// Finally, some surface detailing is added with a sinusoidal bottom layer, and the cellular layer 
// over the top of it. Normally, adding cellular layering utterly fries the GPU, but the "cellTile"
// function used here merely makes it slightly uncomfortable. :)
//
float map(vec3 p){
    
    
     float sf = cellTile(p*.25); // Cellular layer.
    
     p.xy -= path(p.z); // Move the scene around a sinusoidal path.
     p.xy = rot2(p.z/12.)*p.xy; // Twist it about XY with respect to distance.
    
     float n = dot(sin(p*1. + sin(p.yzx*.5 + iGlobalTime)), vec3(.25)); // Sinusoidal layer.
     
     return 2. - abs(p.y) + n + sf; // Warped double planes, "abs(p.y)," plus surface layers.
   

     // Standard tunnel. Comment out the above first.
     //vec2 tun = p.xy - path(p.z);
     //return 3. - length(tun) - (0.5-surfFunc(p)) +  dot(sin(p*1. + sin(p.yzx*.5 + iGlobalTime)), vec3(.333))*.5+.5;

 
}

/*
// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. I tried to 
// make it as concise as possible. Whether that translates to speed, or not, I couldn't say.
vec3 doBumpMap( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(0.001, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.    
    mat3 m = mat3( tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
    
}
*/

// Surface bump function. Cheap, but with decent visual impact.
float bumpSurf3D( in vec3 p){
    
    float noi = noise3D(p*64.);
    float vor = cellTile2(p*.75);
    
    return vor*.98 + noi*.02;

}

// Standard function-based bump mapping function.
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor){
    
    const vec2 e = vec2(0.001, 0);
    float ref = bumpSurf3D(p);                 
    vec3 grad = (vec3(bumpSurf3D(p - e.xyy),
                      bumpSurf3D(p - e.yxy),
                      bumpSurf3D(p - e.yyx) )-ref)/e.x;                     
          
    grad -= nor*dot(nor, grad);          
                      
    return normalize( nor + grad*bumpfactor );
    
}

// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    float t = 0.0, h;
    for(int i = 0; i < 80; i++){
    
        h = map(ro+rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(h)<0.002*(t*.25 + 1.) || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.)
        t += h*.8;
        
    }

    return min(t, FAR);
}

// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical. Due to 
// the intricacies of this particular scene, it's kind of needed to reduce jagged effects.
vec3 getNormal(in vec3 p) {
    const vec2 e = vec2(0.002, 0);
    return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy), map(p + e.yyx) - map(p - e.yyx)));
}

// XT95's really clever, cheap, SSS function. The way I've used it doesn't do it justice,
// so if you'd like to really see it in action, have a look at the following:
//
// Alien Cocoons - XT95: https://www.shadertoy.com/view/MsdGz2
//
float thickness( in vec3 p, in vec3 n, float maxDist, float falloff )
{
    const float nbIte = 6.0;
    float ao = 0.0;
    
    for( float i=1.; i< nbIte+.5; i++ ){
        
        float l = (i*.75 + fract(cos(i)*45758.5453)*.25)/nbIte*maxDist;
        
        ao += (l + map( p -n*l )) / pow(1. + l, falloff);
    }
    
    return clamp( 1.-ao/nbIte, 0., 1.);
}

/*
// Shadows.
float softShadow(vec3 ro, vec3 rd, float start, float end, float k){

    float shade = 1.0;
    const int maxIterationsShad = 24;

    float dist = start;
    float stepDist = end/float(maxIterationsShad);

    // Max shadow iterations - More iterations make nicer shadows, but slow things down.
    for (int i=0; i<maxIterationsShad; i++){
    
        float h = map(ro + rd*dist);
        shade = min(shade, k*h/dist);

        // +=h, +=clamp( h, 0.01, 0.25 ), +=min( h, 0.1 ), +=stepDist, +=min(h, stepDist*2.), etc.
        dist += min(h, stepDist);
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (h<0.001 || dist > end) break; 
    }

    // Shadow value.
    return min(max(shade, 0.) + 0.3, 1.0); 
}
*/

// Ambient occlusion, for that self shadowed look. Based on the original by XT95. I love this 
// function, and in many cases, it gives really, really nice results. For a better version, and 
// usage, refer to XT95's examples below:
//
// Hemispherical SDF AO - https://www.shadertoy.com/view/4sdGWN
// Alien Cocoons - https://www.shadertoy.com/view/MsdGz2
float calculateAO( in vec3 p, in vec3 n )
{
    float ao = 0.0, l;
    const float maxDist = 4.;
    const float nbIte = 6.0;
    //const float falloff = 0.9;
    for( float i=1.; i< nbIte+.5; i++ ){
    
        l = (i + hash(i))*.5/nbIte*maxDist;
        
        ao += (l - map( p + n*l ))/(1.+ l);// / pow(1.+l, falloff);
    }
    
    return clamp(1.- ao/nbIte, 0., 1.);
}


// Cool curve function, by Shadertoy user, Nimitz.
//
// Original usage (I think?) - Cheap curvature: https://www.shadertoy.com/view/Xts3WM
// Other usage: Xyptonjtroz: https://www.shadertoy.com/view/4ts3z2
float curve(in vec3 p, in float w){

    vec2 e = vec2(-1., 1.)*w;
    
    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);
    
    return 0.125/(w*w) *(t1 + t2 + t3 + t4 - 4.*map(p));
}


/////
// Code block to produce four layers of fine mist. Not sophisticated at all.
// If you'd like to see a much more sophisticated version, refer to Nitmitz's
// Xyptonjtroz example. Incidently, I wrote this off the top of my head, but
// I did have that example in mind when writing this.
float trig3(in vec3 p){
    p = cos(p*2. + (cos(p.yzx) + 1. + iGlobalTime*4.)*1.57);
    return dot(p, vec3(0.1666)) + 0.5;
}

// Basic low quality noise consisting of three layers of rotated, mutated 
// trigonometric functions. Needs work, but it's OK for this example.
float trigNoise3D(in vec3 p){

    // 3D transformation matrix.
    const mat3 m3RotTheta = mat3(0.25, -0.866, 0.433, 0.9665, 0.25, -0.2455127, -0.058, 0.433, 0.899519 )*1.5;
  
    float res = 0.;

    float t = trig3(p*PI);
    p += (t - iGlobalTime*0.25);
    p = m3RotTheta*p;
    //p = (p+0.7071)*1.5;
    res += t;
    
    t = trig3(p*PI); 
    p += (t - iGlobalTime*0.25)*0.7071;
    p = m3RotTheta*p;
     //p = (p+0.7071)*1.5;
    res += t*0.7071;

    t = trig3(p*PI);
    res += t*0.5;
     
    return res/2.2071;
}

// Hash to return a scalar value from a 3D vector.
float hash31(vec3 p){ return fract(sin(dot(p, vec3(127.1, 311.7, 74.7)))*43758.5453); }

// Four layers of cheap trigonometric noise to produce some subtle mist.
// Start at the ray origin, then take four samples of noise between it
// and the surface point. Apply some very simplistic lighting along the 
// way. It's not particularly well thought out, but it doesn't have to be.
float getMist(in vec3 ro, in vec3 rd, in vec3 lp, in float t){

    float mist = 0.;
    ro += rd*t/8.; // Edge the ray a little forward to begin.
    
    for (int i = 0; i<4; i++){
        // Lighting. Technically, a lot of these points would be
        // shadowed, but we're ignoring that.
        float sDi = length(lp-ro)/FAR; 
        float sAtt = min(1./(1. + sDi*0.25 + sDi*sDi*0.05), 1.);
        // Noise layer.
        mist += trigNoise3D(ro/2.)*sAtt;
        // Advance the starting point towards the hit point.
        ro += rd*t/4.;
    }
    
    // Add a little noise, then clamp, and we're done.
    return clamp(mist/2. + hash31(ro)*0.1-0.05, 0., 1.);

}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    // Screen coordinates.
    vec2 uv = (fragCoord - iResolution.xy*0.5)/iResolution.y;
    
    // Camera Setup.
    //vec3 lookAt = vec3(0., 0.25, iGlobalTime*2.);  // "Look At" position.
    //vec3 camPos = lookAt + vec3(2., 1.5, -1.5); // Camera position, doubling as the ray origin.
    
    vec3 lookAt = vec3(0., 0.0, iGlobalTime*6. + 0.1);  // "Look At" position.
    vec3 camPos = lookAt + vec3(0.0, 0.0, -0.1); // Camera position, doubling as the ray origin.

 
    // Light positioning. One is a little behind the camera, and the other is further down the tunnel.
    vec3 light_pos = camPos + vec3(0., 1, 8);// Put it a bit in front of the camera.

    // Using the Z-value to perturb the XY-plane.
    // Sending the camera, "look at," and two light vectors down the tunnel. The "path" function is 
    // synchronized with the distance function. Change to "path2" to traverse the other tunnel.
    lookAt.xy += path(lookAt.z);
    camPos.xy += path(camPos.z);
    light_pos.xy += path(light_pos.z);

    // Using the above to produce the unit ray-direction vector.
    float FOV = PI/2.; // FOV - Field of view.
    vec3 forward = normalize(lookAt-camPos);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);

    // rd - Ray direction.
    //vec3 rd = normalize(forward + FOV*uv.x*right + FOV*uv.y*up);
    
    
    vec3 rd = normalize(forward + FOV*uv.x*right + FOV*uv.y*up);
    //rd = normalize(vec3(rd.xy, rd.z - dot(rd.xy, rd.xy)*.25));    
    
    // Swiveling the camera about the XY-plane (from left to right) when turning corners.
    // Naturally, it's synchronized with the path in some kind of way.
    rd.xy = rot2( path(lookAt.z).x/16. )*rd.xy;
        
    // Standard ray marching routine. I find that some system setups don't like anything other than
    // a "break" statement (by itself) to exit. 
    float t = trace(camPos, rd);
    
    // Initialize the scene color.
    vec3 sceneCol = vec3(0);
    
    // The ray has effectively hit the surface, so light it up.
    if(t<FAR){
    
    
        // Surface position and surface normal.
        vec3 sp = t * rd+camPos;
        vec3 sn = getNormal(sp);
        
        
        // Texture scale factor.
        const float tSize0 = 1./4.; 
        
        //vec3 tsp = sp-vec3(path(sp.z), 0.);
       
        // Texture-based bump mapping.
        //sn = doBumpMap(iChannel0, tsp*tSize0, sn, 0.025);//
        
        
        // Function based bump mapping.
        sn = doBumpMap(sp, sn, .2);///(1.+t*.5/FAR)
        
        // Ambient occlusion.
        float ao = calculateAO(sp, sn);
        
        // Light direction vectors.
        vec3 ld = light_pos-sp;

        // Distance from respective lights to the surface point.
        float distlpsp = max(length(ld), 0.001);
        
        // Normalize the light direction vectors.
        ld /= distlpsp;
        
        // Light attenuation, based on the distances above.
        float atten = 1./(1. + distlpsp*0.25); // + distlpsp*distlpsp*0.025
        
        // Ambient light.
        float ambience = 0.5;
        
        // Diffuse lighting.
        float diff = max( dot(sn, ld), 0.0);
    
        // Specular lighting.
        float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 32.);
        
        
        // Curvature.
        float crv = clamp(curve(sp, 0.125)*0.5+0.5, .0, 1.);
        
        // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow( clamp(dot(sn, rd) + 1., .0, 1.), 1.);
        
        // Obtaining the texel color. 
        vec3 ref = reflect(sn, rd);

        // Object texturing.
        vec3 texCol = tex3D(iChannel0, sp*tSize0, sn);
        texCol = smoothstep(0., 1., texCol)*(smoothstep(-.5, 1., crv)*.75+.25);
        
        /////////   
        // Translucency, courtesy of XT95. See the "thickness" function.
        vec3 hf =  normalize(ld + sn);
        float th = thickness( sp, sn, 1., 1. );
        float tdiff =  pow( clamp( dot(rd, -hf), 0., 1.), 1.);
        float trans = (tdiff + .0)*th;  
        trans = pow(trans, 4.)*1.;        
        ////////        

        
        // Darkening the crevices. Otherwise known as cheap, scientifically-incorrect shadowing.    
        float shading = 1.;// crv*0.5+0.5; 
        
        // Shadows - They didn't add enough aesthetic value to justify the GPU drain, so they
        // didn't make the cut.
        //shading *= softShadow(sp, ld, 0.05, distlpsp, 8.);
        
        // Combining the above terms to produce the final color. It was based more on acheiving a
        // certain aesthetic than science.
        sceneCol = texCol*(diff + ambience) + vec3(.7, .9, 1.)*spec;// + vec3(.5, .8, 1)*spec2;
        sceneCol += texCol*vec3(.8, .95, 1)*pow(fre, 4.)*2.;
        sceneCol += vec3(1, 0, 0)*trans;
        
        //vec3 refCol = vec3(.7, .9, 1)*smoothstep(.2, 1., noise3D((sp + ref*2.)*2.)*.66 + noise3D((sp + ref*2.)*4.)*.34 );
        //sceneCol += refCol*.5;


        // Shading.
        sceneCol *= atten*shading*ao;
        
        //sceneCol = vec3(ao);
       
    
    }
       
    // Blend the scene and the background with some very basic, 4-layered fog.
    float mist = getMist(camPos, rd, light_pos, t);
    vec3 sky = vec3(1.4, 1.1, .72)* mix(1., .85, mist)*(rd.y*.25 + 1.);
    sceneCol = mix(sceneCol, sky, min(pow(t, 1.)*2./FAR, 1.));

    // Clamp and present the pixel to the screen.
    fragColor = vec4(clamp(sceneCol, 0., 1.), 1.0);
    
}