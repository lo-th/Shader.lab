
// ------------------ channel define
// 0_# bufferFULL_minifishA #_0
// ------------------


// Created by sebastien durand - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------
// inspired by Flyguy shader [https://www.shadertoy.com/view/Ms3GDS]
//-----------------------------------------------------

// https://www.shadertoy.com/view/ldd3DB

#define NUM_BODIES 40.
#define BODY_RADIUS 4.
#define MAX_SPEED .5

//--------------------------------------------------------------------
// from iq shader Brick [https://www.shadertoy.com/view/MddGzf]
//--------------------------------------------------------------------
vec4 getBody(float id) { return texture2D(iChannel0, vec2(id+.5,.5)/iResolution.xy); }
//--------------------------------------------------------------------

float sdFish(float i,vec2 p, float a, float scale) {
    float ca = cos(a), sa = sin(a);
    p *= scale*mat2(ca,sa,-sa,ca);
    p.x *= .97 + .2*p.y*cos(i+10.*iGlobalTime) + .03*cos(i-10.*iGlobalTime);
    float dsub = min(length(p-vec2(.8,0)) - .45, length(p-vec2(-.14,0)) - .12);  
    p.y = abs(p.y);
    float d = max(min(length(p-vec2(0,-.15)), length(p-vec2(.56,-.15)))-.3, -dsub);
    return d/scale;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float px = 1./iResolution.y, d2, d = 1e6;
    vec2  res = iResolution.xy * px,
          uv = fragCoord.xy * px;
    vec3  col, c;
    for(float i=0.;i<NUM_BODIES;i++) {      
        vec4 body = getBody(i);
        c = mix(vec3(0,0,1), vec3(1,0,0), length(body.zw)/MAX_SPEED);
        d2 = sdFish(i,body.xy-uv,body.w==0. && body.z ==0. ? 0. : atan(body.w, body.z), 20.);
        d = min(d, d2);
        col += 2.*c/(1.+3e3*d2*d2*d2) + .5*c/(1.+30.*d2*d2);
    }
    col /= NUM_BODIES;
    fragColor = mix(vec4(1),vec4(clamp(.6*sqrt(col),vec3(0),vec3(1)),1.), smoothstep(0.,px*1.5,d));
}
