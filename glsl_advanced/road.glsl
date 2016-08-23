// ------------------ channel define
// 0_# noise #_0
// 2_# bufferFULL_roadA #_2
// ------------------
// https://www.shadertoy.com/view/4lcGWr

//Motion blur from mu6k: https://www.shadertoy.com/view/lsyXRK

vec2 totex(vec2 p)
{
    p.x=p.x*iResolution.y/iResolution.x+0.5;
    p.y+=0.5;
    return p; 
}

vec3 sample_color(vec2 p)
{
    return texture2D(iChannel2, totex(p)).xyz;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 p = (fragCoord.xy - iResolution.xy*.5) / iResolution.yy;
    
    if (abs(p.y)>.41) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    
    vec4 fb = texture2D(iChannel2, uv);
    
    float amp =1./fb.w*0.1;
    vec4 noise = texture2D(iChannel0, (fragCoord+floor(iGlobalTime*vec2(12.0,56.0)))/64.0);
    
    vec3 col = vec3(0.0);
    col += sample_color(p*((noise.x+2.0)*amp+1.0));
    col += sample_color(p*((noise.y+1.0)*amp+1.0));
    col += sample_color(p*((noise.z+0.0)*amp+1.0));
    col += sample_color(p*((noise.w-1.0)*amp+1.0));
    col += sample_color( p*((noise.x-2.0)*amp+1.0));
    col *= 0.2;
    col.y*=1.2;
    col=pow(clamp(col,0.0,1.0),vec3(0.45)); 
    col=mix(col, vec3(dot(col, vec3(0.33))), -0.5);
    
    fragColor = vec4(col, 1.0);
}

void main(){

    vec4 color = vec4(1.0);

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