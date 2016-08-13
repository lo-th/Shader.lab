// Started as Star Nest by Pablo RomÃ¡n Andrioli
// Modifications by Beibei Wang and Huw Bowles.
// This content is under the MIT License.

// On reducing the spatial high frequency noise:

// We simply limit the size of each contribution of each iteration of the fractal using min():
// a += i > 7 ? min( 12.,abs(length(p)-pa)) : abs(length(p)-pa)
// The test on the iteration count is optional, we found that most of the problem noise is introduced in the later
// iterations so we found that keeping the original formula for the earlier iterations helps to retain the 'volume'
// without the noise.


// On reducing the temporal noise:

// This version has volume samples aligned along view space Z isolines. When the camera moves
// forwards, the samples are shifted towards the viewer, allowing the camera to move forward
// smoothly without aliasing (besides the high frequency speckle noise).

// However if the  camera were to rotate around its origin, the volume samples towards
// the sides of the image sweep in Z and aliasing would occur. To make this case work, the samples
// need to be arranged in concentric rings around the camera. However in this configuration
// there will be some aliasing at the sides of the screen when the camera moves forward,
// because the motion of the camera can no longer be compensated for completely - one can
// pull in the vert rings but they will move at different rates in Z

// I had similar issues in a different context and made some diagrams etc, see
// http://advances.realtimerendering.com/s2013/OceanShoestring_SIGGRAPH2013_Online.pptx
// And developed a fast realtime version of adaptive stationary sampling:
// https://www.shadertoy.com/view/XdBXWW


// Question - the derivative can be computed for "free" using dual numbers, as in https://www.shadertoy.com/view/Xd2GzR .
// The derivate may help to eliminate noise? Or perhaps the second derivate. It would be very interesting to see these
// derivatives rendered.

// https://www.shadertoy.com/view/XllGzN

#define iterations 17
#define formuparam 0.53

#define volsteps 18
#define stepsize 0.050

#define zoom   0.800
#define tile   0.850
#define speed  0.10 

#define brightness 0.0015
#define darkmatter 0.300
#define distfading 0.760
#define saturation 0.800


void main(){

    //get coords and direction
    //vec2 uv=fragCoord.xy/iResolution.xy-.5;
    //uv.y*=iResolution.y/iResolution.x;

    vec2 uv = ((vUv * 2.0) - 1.0) * vec2(iResolution.z, 1.0);


    vec3 dir=vec3(uv*zoom,1.);
    float time=(iGlobalTime-3311.)*speed;

    
    vec3 from=vec3(1.,.5,0.5);
    
    
    vec3 forward = vec3(0.,0.,1.);
    
    //mouse rotation
    float a1 = 0.3;//3.1415926 * (iMouse.x/iResolution.x-.5);
    mat2 rot1 = mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
    float a2 = .6;//3.1415926 * (iMouse.y/iResolution.y-.5);
    mat2 rot2 = mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
    dir.xz*=rot1;
    forward.xz *= rot1;
    dir.yz*=rot1;
    forward.yz *= rot1;

    // pan (dodgy)
    from += (iMouse.x/iResolution.x-.5)*vec3(-forward.z,0.,forward.x);
    
    //zoom
    float zooom = time;
    from += forward* zooom;
    float sampleShift = mod( zooom, stepsize );
    float zoffset = -sampleShift;
    sampleShift /= stepsize; // make from 0 to 1
    
    //volumetric rendering
    float s=0.1;
    vec3 v=vec3(0.);
    for (int r=0; r<volsteps; r++) {
        vec3 p=from+(s+zoffset)*dir;// + vec3(0.,0.,zoffset);
        p = abs(vec3(tile)-mod(p,vec3(tile*2.))); // tiling fold
        float pa,a=pa=0.;
        for (int i=0; i<iterations; i++) { 
            p=abs(p)/dot(p,p)-formuparam; // the magic formula
            //p=abs(p)/max(dot(p,p),0.005)-formuparam; // another interesting way to reduce noise
            float D = abs(length(p)-pa); // absolute sum of average change
            a += i > 7 ? min( 12., D) : D;
            pa=length(p);
        }
        //float dm=max(0.,darkmatter-a*a*.001); //dark matter
        a*=a*a; // add contrast
        //if (r>3) fade*=1.-dm; // dark matter, don't render near
        // brightens stuff up a bit
        float s1 = s+zoffset;
        // need closed form expression for this, now that we shift samples
        float fade = pow(distfading,max(0.,float(r)-sampleShift));
        v+=fade;
        
        // fade out samples as they approach the camera
        if( r == 0 )
            fade *= 1. - sampleShift;
        // fade in samples as they approach from the distance
        if( r == volsteps-1 )
            fade *= sampleShift;
        v+=vec3(2.*s1,4.*s1*s1,16.*s1*s1*s1*s1)*a*brightness*fade; // coloring based on distance
        s+=stepsize;
    }
    v=mix(vec3(length(v)),v,saturation); //color adjust

    v *= .01;

    #if defined( TONE_MAPPING ) 
    v = toneMapping( v ); 
    #endif

    gl_FragColor = vec4(v,1.); 
}
