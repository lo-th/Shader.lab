
// ------------------ channel define
// 0_# tex02 #_0
// 1_# tex06 #_1
// ------------------

/*
    Steel Lattice
    -------------
    
    Shadertoy user FabriceNeyret2's "Crowded Pillars 3" inspired me to dig up some old
    "lattice with holes" code. Here's the link to his particular example: 
    https://www.shadertoy.com/view/4lfSDn
    
    The lattice structure in this example is really simple to construct, and represents 
    just one of infinitely many combinations. I was going for that oldschool, 3D-tube 
    screensaver look and had originally hoped to set the thing ablaze.

    Unfortunately, I couldn't achieve even mild realism whilst maintaining a decent 
    framerate, so have copped out and settled for a very subtle reflective firey afterglow. 
    I haven't given up on the original idea, though.
    
    There's a whole bunch of notes in there. Probably too many, but hopefully, someone
    will find some of it useful. I spent far too long reading up on blackbody radiation, 
    then barely used it. Typical. :)

    If anyone spots any errors, feel free to let me know.

*/

// https://www.shadertoy.com/view/4tlSWl

#define FIRE_REFLECTION // Comment this out, to get rid of the reflective afterglow.

#define sEPS 0.005 // Minimum surface distance threshold.
#define FAR 20. // Maximum ray distance threshold.

// Grey scale.
float getGrey(vec3 p){ return p.x*0.299 + p.y*0.587 + p.z*0.114; }


// Smooth minimum function. There are countless articles, but IQ explains it best here:
// http://iquilezles.org/www/articles/smin/smin.htm
float sminP( float a, float b, float smoothing ){

    float h = clamp( 0.5+0.5*(b-a)/smoothing, 0.0, 1.0 );
    return mix( b, a, h ) - smoothing*h*(1.0-h);
}


// 2D rotation. Always handy.
mat2 rot(float th){ float cs = cos(th), si = sin(th); return mat2(cs, -si, si, cs); }


// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    //n = abs(n)/1.732051;
    n = max((abs(n) - 0.2)*7., 0.001); // n = max(abs(n), 0.001), etc.
    n /= (n.x + n.y + n.z );  
    
    return (texture2D(tex, p.yz)*n.x + texture2D(tex, p.zx)*n.y + texture2D(tex, p.xy)*n.z).xyz;
}


// I just wanted a simple function to produce some firey blackbody colors with a simple explanation 
// to go with it, but computer nerds who write academic papers never make it easy. :) Anyway, to save 
// someone else the trouble, here's some quick, but messy, notes.
//
// The paper located here was pretty helpful. Mind numbingly boring, but helpful:
// http://www.spectralcalc.com/blackbody/CalculatingBlackbodyRadianceV2.pdf
// So was this:
// http://www.scratchapixel.com/old/lessons/3d-advanced-lessons/blackbody/spectrum-of-blackbodies/
//
// If wasting time reading though countless webpages full of physics and mathematics that never get to 
// the point isn't your thing, then this Shadertoy example should be far more accommodating:
// User - Bejit: https://www.shadertoy.com/view/MslSDl
vec3 blackbodyPalette(float t){

    // t = tLow + (tHigh - tLow)*t;
    t *= 4000.; // Temperature range. Hardcoded from 0K to 4000K, in this case. 
    
    // Planckian locus or black body locus approximated in CIE color space... Color theory is not my thing,
    // but I think below is a conversion of the physical temperture (t) above (which has no meaning to a 
    // computer) to chromacity coordinates. 
    float cx = (0.860117757 + 1.54118254e-4*t + 1.28641212e-7*t*t)/(1.0 + 8.42420235e-4*t + 7.08145163e-7*t*t);
    float cy = (0.317398726 + 4.22806245e-5*t + 4.20481691e-8*t*t)/(1.0 - 2.89741816e-5*t + 1.61456053e-7*t*t);
    
    // Converting the chromacity coordinates to XYZ tristimulus color space.
    float d = (2.*cx - 8.*cy + 4.);
    vec3 XYZ = vec3(3.*cx/d, 2.*cy/d, 1. - (3.*cx + 2.*cy)/d);
    
    // Converting XYZ color space to RGB. Note: Below are the transpose of the matrices you'll find all over the 
    // web, because I'm placing XYZ after the conversion matrix, and not before it. If you're getting the wrong
    // colors, that's probably the reason. I found that out the hard way. :) 
    // http://www.cs.rit.edu/~ncs/color/t_spectr.html
    vec3 RGB = mat3(3.240479, -0.969256, 0.055648, 
                    -1.537150, 1.875992, -0.204043, 
                    -0.498535, 0.041556, 1.057311) * vec3(1./XYZ.y*XYZ.x, 1., 1./XYZ.y*XYZ.z);
                    
    // Alternative conversion matrix: http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
    // mat3(3.2404542, -0.9692660, 0.0556434, -1.5371385, 1.8760108, -0.2040259, -0.4985314, 0.0415560, 1.0572252);

    // Apply Stefanâ€“Boltzmann's law to the RGB color, and we're done. 
    // 
    // Appendix A: Algorithms for Computing In-band Radiance.
    // http://www.spectralcalc.com/blackbody/CalculatingBlackbodyRadianceV2.pdf
    // Planck*Light/Boltzman = 0.01438767312;
    // Planck*Light*Light*2. = 1.1910428e-16;
    //
    // Whoever went through the trouble to use the real algorithm to come up with the estimate of 0.0004, "Thank you!" :)
    // The last term relates to the power radiating through the surface... or something to that effect.
    // Some RGB values fall a little below zero, so I've had to rectify that.
    return max(RGB, 0.)*pow(t*0.0004, 4.); 
}

// Surface bump function. Cheap, but with decent visual impact.
float bumpSurf3D( in vec3 p, in vec3 n ){
    
    // Placing raised box-like bumps all over the structure.
    p = abs(mod(p, 0.0625)-0.03125);
    float x = min(p.x,min(p.y,p.z))/0.03125;
    // More even alternative, but not the look I was after.
    //float x = (0.03125-max(p.x,max(p.y,p.z)))/0.03125*1.25;
    
    // More intricate detail.
    //x = sin(x*1.57+sin(x*1.57)*1.57)*0.5 + 0.5; 

    // Very, very lame, but cheap, smooth noise for a bit of roughness. The frequency is 
    // high and the amplitude is very low, so the details won't be discernible enough to 
    // necessitate a real noise algorithm.
    p = sin(p*380.+sin(p.yzx*192.+64.));
    float surfaceNoise = (p.x*p.y*p.z);

    return clamp(x + surfaceNoise*0.05, 0., 1.);//x*32. + //To accentuate x*2./0.03125, etc

}

// Standard function-based bump mapping function.
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor){
    
    const float eps = 0.001;
    float ref = bumpSurf3D(p, nor);                 
    vec3 grad = vec3( bumpSurf3D(vec3(p.x-eps, p.y, p.z), nor)-ref,
                      bumpSurf3D(vec3(p.x, p.y-eps, p.z), nor)-ref,
                      bumpSurf3D(vec3(p.x, p.y, p.z-eps), nor)-ref )/eps;                     
          
    grad -= nor*dot(nor, grad);          
                      
    return normalize( nor + bumpfactor*grad );
    
}

// Shadertoy user FabriceNeyret2's "Crowded Pillars 3" inspired me to dig up some old
// "lattice with holes" code. Here's the link: https://www.shadertoy.com/view/4lfSDn
//
// The technique used here is pretty common: Produce two, or more, repeat field objects, 
// lattices - or whatever you'd like - at different repeat frequencies, then combine them 
// with either a standard operation (min(x1, x2), max(x1, -x2), etc) or something less 
// standard, like the one I've used below (sqrt(x1*x1+x2*x2)-.05). The possibilities are
// endless. Menger cubes, and the like, are constructed using a similar method.
//
// For anyone who wants to experiment, use one line from each of the three sections.
// There are 24 different combinations all up, and I've probably chosen the least
// interesting one. :)
float map(vec3 p){
 
    // SECTION 1
    //
    // Repeat field entity one, which is just some tubes repeated in all directions every 
    // two units, then combined with a smooth minimum function. Otherwise known as a lattice.
    p = mod(p, 2.)-1.;
    float x1 = sminP(length(p.xy),sminP(length(p.yz),length(p.xz), 0.25), 0.25)-0.5; // EQN 1
    //float x1 = sqrt(min(dot(p.xy, p.xy),min(dot(p.yz, p.yz),dot(p.xz, p.xz))))-0.5; // EQN 2
    //p = abs(p); float x1 = min(max(p.x, p.y),min(max(p.y, p.z),max(p.x, p.z)))-0.5; // EQN 3

    // SECTION 2
    //
    // Repeat field entity two, which is just an abstract object repeated every half unit. 
    p = abs(mod(p, 0.5)-0.25);
    float x2 = min(p.x,min(p.y,p.z)); // EQN 1
    //float x2 = min(max(p.x, p.y),min(max(p.y, p.z),max(p.x, p.z)))-0.125; //-0.175, etc. // EQN 2
    
    // SECTION 3
    //
    // Combining the two entities above.
    return sqrt(x1*x1+x2*x2)-.05; // EQN 1
    //return max(x1, x2)-.05; // EQN 2
    
}

// Standard ray marching function: I included some basic optimization notes. I know
// most of it is probably obvious to many, but I thought some might find it useful.
float raymarch(vec3 ro, vec3 rd) {
    
    // Surface distance and total ray distance.
    float d, t = 0.0;
    
    // More iterations means a chance to gain more accuracy, but should be the lowest
    // possible number that will render as many scene details as possible.
    for (int i = 0; i < 128; i++){
        // Surface distance.
        d = map(ro + rd *t);
        
        // If the distance is less than the surface distance threshold (sEPS), or 
        // further than the maximum ray distance threshold (FAR), exit.
        //
        // An early exit can mean the difference between, say, 20 map calls and the 
        // maximum iteration count (128, in this case). In general, you want the 
        // largest sEPS and smallest FAR value that will facilitate an accurate scene. 
        // Tweaking these two figures is an artform. sEPS values ranging from 0.001 
        // to 0.05 tend to work. However, smaller numbers can kill framerate, in some 
        // cases. I tend to favor 0.005 and 0.01. For the FAR value, it depends on 
        // the scene.
        if (d<sEPS || t>FAR) break;  
        
        // Add a portion of the surface distance (d) to the total ray distance (t).
        //
        // Sometimes, the ray can overshoot, so decreasing the jump distance "d" can 
        // help give more accuracy. Of course, the downside is more iterations,
        // which in turn, reduces framerate. Tweaking these numbers is also an artform.
        // Anywhere between 0.5 (if accuracy is really necessary) and 1.0 works for
        // me. 0.75 is a good compromise.
        t += d*0.75;
    }
    
    // Adding the final infinitessimal surface distance to the ray distance. Not sure 
    // if it's necessary, or correct, but I do it anyway. :)
    if (d<sEPS) t += d;
    
    return t;
}

// Based on original by IQ.
float calculateAO(vec3 p, vec3 n){

    const float AO_SAMPLES = 5.0;
    float r = 0.0, w = 1.0, d;
    
    for (float i=1.0; i<AO_SAMPLES+1.1; i++){
        d = i/AO_SAMPLES;
        r += w*(d - map(p + n*d));
        w *= 0.5;
    }
    
    return 1.0-clamp(r,0.0,1.0);
}

// The iterations should be higher for proper accuracy, but in this case, the shadows are a subtle background feature.
float softShadow(vec3 ro, vec3 rd, float start, float end, float k){

    float shade = 1.0;
    const int maxIterationsShad = 16; // 24 or 32 would be better.

    // The "start" value, or minimum, should be set to something more than the stop-threshold, so as to avoid a collision with 
    // the surface the ray is setting out from. It doesn't matter how many times I write shadow code, I always seem to forget this.
    // If adding shadows seems to make everything look dark, that tends to be the problem.
    float dist = start;
    float stepDist = end/float(maxIterationsShad);

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i=0; i<maxIterationsShad; i++){
        // End, or maximum, should be set to the distance from the light to surface point. If you go beyond that
        // you may hit a surface not between the surface and the light.
        float h = map(ro + rd*dist);
        shade = min(shade, k*h/dist);
        
        // What h combination you add to the distance depends on speed, accuracy, etc. To be honest, I find it impossible to find 
        // the perfect balance. Faster GPUs give you more options, because more shadow iterations always produce better results.
        // Anyway, here's some posibilities. Which one you use, depends on the situation:
        // +=max(h, 0.001), +=clamp( h, 0.01, 0.25 ), +=min( h, 0.1 ), +=stepDist, +=min(h, stepDist*2.), etc.
        
        
        // I'm always torn between local shadowing (clamp(h, 0.0005, 0.2), etc) and accounting for shaowing from
        // distant objects all the way to the light source. If in doubt, local shadowing is probably best, but
        // here, I'm trying to do the latter.
        dist += clamp(h, 0.0005, stepDist*2.); // The best of both worlds... I think. 
        
        // There's some accuracy loss involved, but early exits from accumulative distance function can help.
        if (h<0.001 || dist > end) break; 
    }

    // I usually add a bit to the final shade value, which lightens the shadow slightly. It's a preference thing. Really dark
    // shadows look too brutal to me.
    return min(max(shade, 0.) + 0.4, 1.0); 
}

// Standard normal function.
vec3 getNormal(in vec3 p) {
    const float eps = 0.001;
    return normalize(vec3(
        map(vec3(p.x+eps,p.y,p.z))-map(vec3(p.x-eps,p.y,p.z)),
        map(vec3(p.x,p.y+eps,p.z))-map(vec3(p.x,p.y-eps,p.z)),
        map(vec3(p.x,p.y,p.z+eps))-map(vec3(p.x,p.y,p.z-eps))
    ));

}

// Curvature function, which Shadertoy user Nimitz wrote. I've hard-coded this one to
// get just the range I want. Not very scientific at all.
//
// From an intuitive sense, the function returns a weighted difference between a surface 
// value and some surrounding values. Almost common sense... almost. :) If anyone 
// could provide links to some useful articles on the function, I'd be greatful.
//
// Original usage (I think?) - Cheap curvature: https://www.shadertoy.com/view/Xts3WM
// Other usage: Xyptonjtroz: https://www.shadertoy.com/view/4ts3z2
float curve(in vec3 p){

    vec2 e = vec2(-1., 1.)*0.05; //0.05->7. - 0.04->11. - 0.03->20.->0.1->2.
    
    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);
    
    return 7. * (t1 + t2 + t3 + t4 - 4.*map(p));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    // Screen coordinates.
    vec2 uv = (fragCoord.xy - iResolution.xy*0.5) / iResolution.y;
    
    // No camera setup. Just lazily heading straight to the unit direction vector.
    vec3 rd = normalize(vec3(uv, 0.5));
    //vec3 rd = normalize(vec3(uv, sqrt(1.-dot(uv, uv))*0.5)); // Mild fish lens, if you'd prefer.
    
    // Rotating the unit direction vector about the XY and XZ places for a bit of a look around.
    rd.xy *= rot(iGlobalTime*0.5);
    rd.xz *= rot(iGlobalTime*0.25); // Extra variance.
    
    // Ray origin. Set off linearly in the Z-direction. A bit of a lattice cliche, but effective.
    vec3 ro = vec3(0.0, 0.0, iGlobalTime*1.0);
    //vec3 ro = vec3(0.5 + iGlobalTime*0.7, 0.0, iGlobalTime*0.7); // Another lattice traversal cliche.
    
    // Light position. Rotated a bit, then placed a little above the viewing position.
    vec3 lp = vec3(0.0, 0.125, -0.125);
    lp.xy *= rot(iGlobalTime*0.5);
    lp.xz *= rot(iGlobalTime*0.25);
    lp += ro + vec3(0.0, 1.0, 0.0);
    
    // Initiate the scene color to black.
    vec3 sceneCol = vec3(0.);
    
    // Distance to the surface in the scene.
    float dist = raymarch(ro, rd);
    
    // If the surface has been hit, light it up.
    if (dist < FAR){

        // Surface point.
        vec3 sp = ro + rd*dist;
        
        // Surface normal.
        vec3 sn = getNormal(sp);
        
        
        // Standard function-based bump map - as opposed to texture bump mapping. It's possible to 
        // taper the bumpiness (last term) with distance, using something like: 0.0125/(1.+dist*0.125).
        sn = doBumpMap(sp, sn, 0.01);
        
        
        // Light direction vector.
        vec3 ld = lp-sp;

        // Object color at the surface point.
        vec3 objCol = tex3D( iChannel0, sp, sn );
        // Using the bump function to shade the surface a bit more to enhance the bump mapping a little.
        // Not mandatory, but I prefer it sometimes.
        objCol *= bumpSurf3D(sp, sn)*0.5+0.5;
        

        float lDist = max(length(ld), 0.001); // Distance from the light to the surface point.
        ld /= lDist; // Normalizing the light-to-surface, aka light-direction, vector.
        float atten = min( 1.0 /( lDist*0.5 + lDist*lDist*0.1 ), 1.0 ); // Light falloff, or attenuation.
        
        float ambient = .25; //The object's ambient property. You can also have a global and light ambient property.
        float diffuse = max( 0.0, dot(sn, ld) ); //The object's diffuse value.
        float specular = max( 0.0, dot( reflect(-ld, sn), -rd) ); // Specular component.
        specular = pow(specular, 8.0); // Ramping up the specular value to the specular power for a bit of shininess.
        
        // Soft shadows. I really cheaped out on the iterations, so the shadows are not accurate. Thankfully, 
        // they're not a dominant feature, and everything's moving enough so that it's not really noticeable.
        float shadow = softShadow(sp, ld, sEPS*2., lDist, 32.);
        // Ambient occlusion.
        float ao = calculateAO(sp, sn)*0.5+0.5;
            
        // Fresnel term. Good for giving a surface a bit of a reflective glow.
        //float fre = pow( clamp(dot(sn, rd) + 1., .0, 1.), 1.);
        

        #ifdef FIRE_REFLECTION
        // The firey reflection: Not very sophisticated. Use the relected vector to index into a
        // moving noisey texture, etc, to obtain a reflective shade value (refShade). Combine it
        // with the surface curvature (crv - higher curvature, more reflective heat... probably), 
        // then feed the result into a blackbody palette function to obtain the reflective color. 
        // It's mostly made up, with a tiny bit of science thrown in, so is not meant to be taken 
        // seriously.
        
        // Surface reflection vector.
        vec3 sf = reflect(rd, sn);
        
        // Curvature. This function belongs to Shadertoy user Nimitz.
        float crv = clamp(curve(sp), 0., 1.);
        
        float refShade = getGrey(tex3D( iChannel1, sp/4. + iGlobalTime/64., sf ));
        refShade = refShade*0.4 + max(dot(sf, vec3(0.166)), .0);
        vec3 refCol = blackbodyPalette(refShade*(crv*0.5+0.5));
        #endif

        // Combining the terms from above in a pretty standard way to produce the final color.
        sceneCol = objCol*(vec3(1.,0.97,0.92)*diffuse + ambient)  + vec3(1.,0.9,0.92)*specular*0.75;
        #ifdef FIRE_REFLECTION
        // Add the subtle relected firey afterglow.
        sceneCol += refCol; //*(diffuse + ambient + specular*0.75);
        #endif
        
        // Shading the color.
        sceneCol *= atten*ao*shadow;
    
    }

    // Done!
    fragColor = vec4(clamp(sceneCol, 0., 1.), 1.0);
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