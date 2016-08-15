
// ------------------ channel define
// 0_# basic #_0
// ------------------

void main() {
    vec2 uv = ((vUv * 2.0) - 1.0) * vec2(iResolution.z, 1.0);
    vec3 color = texture2D(iChannel0, uv).rgb;

    //color = toneMap( color );
    #if defined( TONE_MAPPING ) 
    color = toneMapping( color ); 
    #endif

    gl_FragColor = vec4(color, 1.0);

}
