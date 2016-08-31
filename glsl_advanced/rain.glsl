
// ------------------ channel define
// 0_# bufferFULL_rainB #_0
// 1_# cube_grey1 #_1
// ------------------

//OMGS
///proudly presents zguerrero`s slowmo fluid as rain on camera/window
/// work based on sauce: https://www.shadertoy.com/view/ltdGDn
// License: MINE, MY OWN! I knows you wants it precious

// https://www.shadertoy.com/view/4l3Gz2

void main(){

    vec2 uv = gl_FragCoord.xy / iResolution.xy;
 
    vec3 bufB = texture2D(iChannel0,uv).xyz;
   
    vec3 rain = textureCube(iChannel1,reflect(bufB,vec3(uv,1.)) ).xyz;
    
    gl_FragColor = vec4(rain, 1.0 );
}