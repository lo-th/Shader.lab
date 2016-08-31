// ------------------ channel define
// 0_# bufferFULL_raytraceA #_0
// ------------------

// https://www.shadertoy.com/view/lldGDj

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 color = texture2D(iChannel0, uv).rgb;
    
    fragColor = vec4(pow(clamp(color, 0., 1.), vec3(1./2.2)), 1.);
}
