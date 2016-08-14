// ------------------ channel define
// 0_# tex19 #_0
// ------------------



//    Bioorganic Wall
//    ---------------

//    Raymarching a textured XY plane. Basically, just an excuse to try out the new pebbled texture.

// https://www.shadertoy.com/view/ldt3RN


// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
   
    n = max(n*n, 0.001);
    n /= (n.x + n.y + n.z );  
    
    return (texture2D(tex, p.yz)*n.x + texture2D(tex, p.zx)*n.y + texture2D(tex, p.xy)*n.z).xyz;
    
}

// Raymarching a textured XY-plane, with a bit of distortion thrown in.
float map(vec3 p){

    // A bit of cheap, lame distortion for the heaving in and out effect.
    p.xy += sin(p.xy*7. + cos(p.yx*13. + iGlobalTime))*.01;
    
    // Back plane, placed at vec3(0., 0., 1.), with plane normal vec3(0., 0., -1).
    // Adding some height to the plane from the texture. Not much else to it.
    return 1. - p.z - texture2D(iChannel0, p.xy).x*.1;

    
    // Flattened tops.
    //float t = texture2D(iChannel0, p.xy).x;
    //return 1. - p.z - smoothstep(0., .7, t)*.06 - t*t*.03;
    
}


// Tetrahedral normal, courtesy of IQ.
vec3 getNormal( in vec3 pos )
{
    vec2 e = vec2(0.002, -0.002);
    return normalize(
        e.xyy * map(pos + e.xyy) + 
        e.yyx * map(pos + e.yyx) + 
        e.yxy * map(pos + e.yxy) + 
        e.xxx * map(pos + e.xxx));
}

// Ambient occlusion, for that self shadowed look.
// Based on the original by IQ.
float calculateAO(vec3 p, vec3 n){

   const float AO_SAMPLES = 5.0;
   float r = 1.0, w = 1.0, d0;
    
   for (float i=1.0; i<=AO_SAMPLES; i++){
   
      d0 = i/AO_SAMPLES;
      r += w * (map(p + n * d0) - d0);
      w *= 0.5;
   }
   return clamp(r, 0.0, 1.0);
}

// Cool curve function, by Shadertoy user, Nimitz.
//
// It gives you a scalar curvature value for an object's signed distance function, which 
// is pretty handy for all kinds of things. Here, it's used to darken the crevices.
//
// From an intuitive sense, the function returns a weighted difference between a surface 
// value and some surrounding values - arranged in a simplex tetrahedral fashion for minimal
// calculations, I'm assuming. Almost common sense... almost. :)
//
// Original usage (I think?) - Cheap curvature: https://www.shadertoy.com/view/Xts3WM
// Other usage: Xyptonjtroz: https://www.shadertoy.com/view/4ts3z2
float curve(in vec3 p){

    const float eps = 0.02, amp = 7., ampInit = 0.5;

    vec2 e = vec2(-1., 1.)*eps; //0.05->3.5 - 0.04->5.5 - 0.03->10.->0.1->1.
    
    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);
    
    return clamp((t1 + t2 + t3 + t4 - 4.*map(p))*amp + ampInit, 0., 1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    
    // Unit directional ray.
    vec3 rd = normalize(vec3(fragCoord - iResolution.xy*.5, iResolution.y*1.5));
    
    
    // Rotating the XY-plane back and forth, for a bit of variance.
    // Compact 2D rotation matrix, courtesy of Shadertoy user, "Fabrice Neyret."
    vec2 a = sin(vec2(1.5707963, 0) + sin(iGlobalTime/4.)*.3);
    rd.xy = mat2(a, -a.y, a.x)*rd.xy;
    
    // Ray origin. Moving in the X-direction to the right.
    vec3 ro = vec3(iGlobalTime*.25, 0., 0.);
    
    
    // Light position, hovering around camera.
    vec3 lp = ro + vec3(cos(iGlobalTime/2.)*.5, sin(iGlobalTime/2.)*.5, 0.);
    
    // Standard raymarching segment. Because of the straight forward setup, very few 
    // iterations are needed.
    float d, t=0.;
    for(int j=0;j<16;j++){
      
        d = map(ro + rd*t); // distance to the function.
        t += d*.7; // Total distance from the camera to the surface.
        
        // The plane "is" the far plane, so no far plane break is needed.
        if(d<0.001) break; 
    
    }
    
   
    // Surface postion, surface normal and light direction.
    vec3 sp = ro + rd*t;
    vec3 sn = getNormal(sp);
    vec3 ld = lp - sp;
    
    
    // Retrieving the texel at the surface postion. A tri-planar mapping method is used to
    // give a little extra dimension. The time component is responsible for the texture movement.
    float c = 1. - tex3D(iChannel0, sp*8. - vec3(sp.x, sp.y, iGlobalTime/4.+sp.x+sp.y), sn).x;
    
    // Taking the original grey texel shade and colorizing it. Most of the folowing lines are
    // a mixture of theory and trial and error. There are so many ways to go about it.
    //
    vec3 orange = vec3(min(c*1.5, 1.), pow(c, 2.), pow(c, 8.)); // Cheap, orangey palette.
    
    vec3 oC = orange; // Initializing the object (bumpy wall) color.
    
    // Old trick to shift the colors around a bit. Most of the figures are trial and error.
    oC = mix(oC, oC.zxy, cos(rd.zxy*6.283 + sin(sp.yzx*6.283))*.25+.75);
    oC = mix(oC.yxz, oC, (sn)*.5+.5); // Using the normal to colorize.
    
    oC = mix(orange, oC, (sn)*.25+.75);
    oC *= oC*1.5;
    
    // Plain, old black and white. In some ways, I prefer it. Be sure to comment out the above, though.
    //vec3 oC = vec3(pow(c, 1.25)); 
    
    
    // Lighting.
    //
    float lDist = max(length(ld), 0.001); // Light distance.
    float atten = 1./(1. + lDist*.125); // Light attenuation.
    
    ld /= lDist; // Normalizing the light direction vector.
    
    float diff = max(dot(ld, sn), 0.); // Diffuse.
    float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 32.); // Specular.
    float fre = clamp(dot(sn, rd) + 1., .0, 1.); // Fake fresnel, for the glow.

    
    // Shading.
    //
    // Note, there are no actual shadows. The camera is front on, so the following two 
    // functions are enough to give a shadowy appearance.
    float crv = curve(sp); // Curve value, to darken the crevices.
    float ao = calculateAO(sp, sn); // Ambient occlusion, for self shadowing.

    // Not all that necessary, but adds a bit of green to the crevice color to give a fake,
    // slimey appearance.
    vec3 crvC = vec3(crv, crv*1.3, crv*.7)*.25 + crv*.75;
    crvC *= crvC;
    
    // Combining the terms above to light up and colorize the texel.
    vec3 col = (oC*(diff + .5) + vec3(.5, .75, 1.)*spec*2.) + vec3(.3, .7, 1.)*pow(fre, 3.)*5.;
    // Applying the shades.
    col *= (atten*crvC*ao);
    
    // I might be stating the obvious here, but if you ever want to see what effect each individual
    // component has on the overall scene, just put the variable in at the end, by itself.
    //col = vec3(ao); // col = vec3(crv); // etc.

    // Presenting to the screen.
    fragColor = vec4(sqrt(max(col, 0.)), 1.);
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