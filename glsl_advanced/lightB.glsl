
// ------------------ channel define
// 0_# bufferFULL_lightB #_0
// ------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    fragColor.a = texture2D(iChannel0,uv).a;
    float b = 0.0;
    if (iMouse.z>0.0) {
        b=1.0;
        if (iMouse.y<20.0) {
            fragColor.a = min(1.0,max(1.02*iMouse.x/iResolution.x-0.1,0.0));
            b=0.0;
        }
    }
    
    fragColor.rgb = vec3(iMouse.x/iResolution.x,iMouse.y/iResolution.y,b);
    if (fragCoord.x>=1.0) {
        uv.x -= 1.0/iResolution.x;
        fragColor.rgb = texture2D(iChannel0, uv).rgb;
    }
    
}