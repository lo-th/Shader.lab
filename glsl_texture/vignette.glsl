void main()
{
    //vec2 uv = vUv/iResolution.xy;
    vec2 uv = ((vUv * 2.0) - 1.0) * vec2(iResolution.z, 1.0);

    float radius = 0.125;
    float intensity = 0.25;
    float sx = iResolution.x > iResolution.y ? iResolution.x / iResolution.y : 1.;
    float sy = iResolution.y > iResolution.x ? iResolution.y / iResolution.x : 1.;

    vec2 normal = vec2( sy, sx );
    vec2 v1 = smoothstep( vec2( 0. ), vec2( radius ) * normal, uv );
    vec2 v2 = smoothstep( vec2( 0. ), vec2( radius ) * normal, 1. - uv );
    vec2 v = v1 * v2;

    float vignette = v.x * v.y;
    
    vec3 color = vec3( .056, .067, .078 );
    vec3 vignetteColor = vec3( 0., 1., 1. );
    color = mix( vignetteColor, color, pow( vignette, intensity ) );

    gl_FragColor = vec4( color, 1. );
}