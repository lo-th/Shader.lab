const float KEY_1 = 49.5/256.0;
const float KEY_2 = 50.5/256.0;
const float KEY_3 = 51.5/256.0;
const float KEY_4 = 52.5/256.0;

const float KEY_Q = 81.5/256.0;
const float KEY_W = 87.5/256.0;
const float KEY_E = 69.5/256.0;
const float KEY_R = 82.5/256.0;

vec3 HSVtoRGB(vec3 hsv);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 pointer = iMouse.xy / iResolution.xy;
    
    
    float Q = texture2D( iChannel3, vec2( KEY_Q, 0.75 )).r;
    float W = texture2D( iChannel3, vec2( KEY_W, 0.75 )).r;
    
    vec2 brush = vec2(1.) * iResolution.xy / iResolution.xx;
    if( Q > .5 )
        brush.x *= 8.;
    if( W > .5 )
        brush.y *= 8.;
    
    if( (length( (uv - pointer) * brush ) > 0.1 || iMouse.z < 0.) && (uv.x < 0.95 && uv.y < 0.95) )
        discard;
    pointer.x = dFdx( fragColor.x ) *1000.;
    float pallette = mod( iGlobalTime, 8. );
    vec2 localuv = uv - pointer + .1;
    
    float tex1 = texture2D( iChannel3, vec2( KEY_1, 0.75 )).r;
    float tex2 = texture2D( iChannel3, vec2( KEY_2, 0.75 )).r;
    float tex3 = texture2D( iChannel3, vec2( KEY_3, 0.75 )).r;
    float tex4 = texture2D( iChannel3, vec2( KEY_4, 0.75 )).r;
    
    if( tex2 > .5 )
        fragColor.rgb += texture2D( iChannel0, localuv ).rgb;
    if( tex3 > .5 )
        fragColor.rgb += texture2D( iChannel1, localuv ).rgb;
    if( tex4 > .5 )
        fragColor.rgb += texture2D( iChannel2, localuv ).rgb;
    
    if( !(tex1 > .5) )
    {
        vec3 hsv = vec3(mod(iGlobalTime, 10.) / 10., 0.5, 0.5 );
        fragColor.rgb += HSVtoRGB( hsv ) / 255.;
    }
    fragColor.rgb *= abs(2.0 - mod( iGlobalTime, 4. ));
    fragColor.a = 1.;
}



vec3 HSVtoRGB(vec3 hsv)
{
    float R, G, B;
    float H = hsv.x;
    float S = hsv.y;
    float V = hsv.z;
    if( S == 0.0 )
    {
        R = G = B = floor(V * 255.0);
    }
    else
    {
        float vH = H * 6.0;
        float vI = floor( vH );
        float   v = floor(V * 255.0);
        float  v1 = floor(V * (1.0 - S) * 255.0);
        float  v2 = floor(V * (1.0 - S * (vH - vI)) * 255.0);
        float  v3 = floor(V * (1.0 - S * (1.0 - (vH - vI))) * 255.0);

        if     ( vI == 0.0 ) { R =  v; G = v3; B = v1; }
        else if( vI == 1.0 ) { R = v2; G =  v; B = v1; }
        else if( vI == 2.0 ) { R = v1; G =  v; B = v3; }
        else if( vI == 3.0 ) { R = v1; G = v2; B =  v; }
        else if( vI == 4.0 ) { R = v3; G = v1; B =  v; }
        else               { R =  v; G = v1; B = v2; }
    }
    return vec3(R,G,B);
}