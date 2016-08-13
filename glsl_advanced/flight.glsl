

// https://www.shadertoy.com/view/XldGR7
// Here is my raymarching debut. Developed on GTX 960. Thanks for watching!

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(){
    
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    
    vec2 uv2 = gl_FragCoord.xy / iResolution.xy * 2.0 - 1.0;
    float asp = iResolution.x / iResolution.y;
    uv2.x *= asp;
    
    float dist = pow(max(1. - texture2D(iChannel0,uv).a * 0.04,0.),3.5);
    
    vec3 origin = vec3(0.0, 2.2 + 2. * sin(iGlobalTime), -1000.0 + iGlobalTime * 15.);
    
   vec3 direction;// = vec3(0.0, 0, 1.0);
    vec2 ml;
    if (iMouse.x>10.)
    {
        ml.x = 2.5 - iMouse.x/iResolution.x * 5.;
        ml.y = -2.5 + iMouse.y/iResolution.y * 5.;
    }
    // camera   
    vec3 ro = origin;
    vec3 ta = origin + vec3( sin(iGlobalTime * 0.2)+ml.x,ml.y , 2. );
    
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );
    
    // ray direction
    direction = ca * normalize( vec3(uv2.xy,2.0) );
    
    //inverse(ca);
    vec3 dir = direction;
    vec2 bdir = vec2(-dir.x,dir.y);//vec2(0.75-uv.x + dir.x,uv.y*asp + dir.y);//-vec2(0.5)+uv;
    bdir += vec2(-direction.x, direction.y);
    bdir.x /= asp;
    float dither = texture2D(iChannel1,gl_FragCoord.xy/4.).r;
    
    //bdir.y *= 1./asp;
    vec3 color=vec3(0.);
    const int BLUR_STEPS = 8;
    float bs = float(BLUR_STEPS);
    for ( int i=0; i<BLUR_STEPS; i++ )
    {
        color += texture2D(iChannel0,uv - bdir * (float(i)+2.*dither) / bs * 0.16 * dist).xyz/bs;
    }
    
   // color = vec3(dist);// direction;// vec3(bdir,0.);
    
    
   
    //const int RAY_STEPS = 128;
    //const float NEAR_CLIP = .5;
    //const float FAR_CLIP = 100.0;
    
   // vec3 normal;
   // vec3 intersection; 
    
    
    // Reinhard tonemapping
    float white = 8.;
    float L = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.g;
    float nL = (1.0 + L / white) / (1.0 + L);;
    //float scale = nL / L;
    color *= nL;
    color = pow(color,vec3( 1./2.2 ));
    
    gl_FragColor = vec4(color,0);
}