// https://www.shadertoy.com/view/4sdXz8


// ------------------ channel define
// 0_# bufferFULL_lightA #_0
// ------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = sqrt( texture2D(iChannel0, uv));
}