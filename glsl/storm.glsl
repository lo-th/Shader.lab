
// ------------------ channel define
// 0_# noise #_0
// ------------------

// https://www.shadertoy.com/view/Xd23zh

// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    vec2 uv = (p.xy) + f.xy;
    return texture2D( iChannel0, (uv+ 0.5)/256.0, -100.0 ).x;
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = texture2D( iChannel0, (uv+ 0.5)/256.0, -100.0 ).yx;
    return mix( rg.x, rg.y, f.z );
}

float hash( in float n )
{
    return fract(sin(n)*43758.5453);
}

// coulds
vec4 map( vec3 p, vec2 ani )
{
    vec3 r = p;
    
    float h = (0.7+0.3*ani.x) * noise( 0.76*r.xz );
    r.y -= h;
    
    float den = -(r.y + 2.5);
    r +=  0.2*vec3(0.0,0.0,1.0)*ani.y;
        
    vec3 q = 2.5*r*vec3(1.0,1.0,0.15)    + vec3(1.0,1.0,1.0)*ani.y*0.15;
    float f;
    f  = 0.50000*noise( q ); q = q*2.02 - vec3(-1.0,1.0,-1.0)*ani.y*0.15;
    f += 0.25000*noise( q ); q = q*2.03 + vec3(1.0,-1.0,1.0)*ani.y*0.15;
    f += 0.12500*noise( q ); q = q*2.01 - vec3(1.0,1.0,-1.0)*ani.y*0.15;
    q.z *= 4.0;
    f += 0.06250*noise( q ); q = q*2.02 + vec3(1.0,1.0,1.0)*ani.y*0.15;
    f += 0.03125*noise( q );
    
    float es =  1.0-clamp( (r.y+1.0)/0.26,0.0,1.0);
    f += f*(1.0-f)*0.6*sin(q.z)*es; 
    den = clamp( den + 4.4*f, 0.0, 1.0 );

    // color    
    vec3 col = mix( vec3(0.2,0.3,0.3), vec3(1.0,1.0,1.0), clamp( (r.y+2.5)/3.0,0.0,1.0) );
    col = mix( col, 3.0*vec3(1.0,1.1,1.20)*(0.2+0.8*ani.x), es );
    col *= mix( vec3(0.1,0.32,0.38), vec3(1.05,0.95,0.75), f*1.2 );
    col = col*(0.8-0.5*ani.x) + ani.x*2.0*smoothstep(0.75,0.86,sin(10.0*ani.y+2.0*r.z + r.x*10.0))*smoothstep(0.6,0.8,f)*vec3(1.0,0.8,0.5)*smoothstep( 0.7, 0.9, noise(q.yx) );
    
    return vec4( col, den );
}

// light direction
vec3 lig = normalize(vec3(-1.0,1.0,-1.0));
                     
vec3 raymarch( in vec3 ro, in vec3 rd, in vec2 ani, in vec2 pixel )
{
    // background color 
    vec3 bgc = vec3(0.6,0.7,0.7) + 0.3*rd.y;
    bgc *= 0.2;
    

    // dithering    
    float t = 0.03*texture2D( iChannel0, pixel.xy/iChannelResolution[0].x ).x;

    // raymarch 
    vec4 sum = vec4( 0.0 );
    for( int i=0; i<150; i++ )
    {
        if( sum.a > 0.99 ) continue;
        
        vec3 pos = ro + t*rd;
        vec4 col = map( pos, ani );

        // lighting     
        float dif = 0.1 + 0.4*(col.w - map( pos + lig*0.15, ani ).w);
        col.xyz += dif;

        // fog      
        col.xyz = mix( col.xyz, bgc, 1.0-exp(-0.005*t*t) );
        
        col.rgb *= col.a;
        sum = sum + col*(1.0 - sum.a);  

        // advance ray with LOD
        t += 0.03+t*0.012;
    }

    // blend with background    
    sum.xyz = mix( bgc, sum.xyz/(sum.w+0.0001), sum.w );
    
    return clamp( sum.xyz, 0.0, 1.0 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0*q;
    p.x *= iResolution.x/ iResolution.y;
    
    vec2 mo = iMouse.xy / iResolution.xy;
    if( iMouse.w<=0.00001 ) mo=vec2(0.0);
    
    float time = iGlobalTime;
    
    vec2 ani = vec2(1.0);
    float ati = time/17.0;
    float pt = mod( ati, 2.0 );
    ani.x = smoothstep( 0.3, 0.7, pt ) - smoothstep( 1.3, 1.7, pt );
    float it = floor( 0.75 + ati*0.5 + 0.1 );
    float ft = fract( 0.75 + ati*0.5 + 0.1 );
    ft = smoothstep( 0.0, 0.6, ft );
    ani.y = time*0.15 + 30.0*(it + ft); 
    
    // camera parameters
    vec4 camPars = texture2D( iChannel0, floor(1.0+iGlobalTime/5.5)*vec2(5.0,7.0)/iChannelResolution[0].xy );
    
    // camera position
    vec3 ro = 4.0*normalize(vec3(cos(30.0*camPars.x + 0.023*time), 0.3+0.2*sin(30.0*camPars.x + 0.08*time), sin(30.0*camPars.x + 0.023*iGlobalTime)));
    vec3 ta = vec3(0.0, 0.0, 0.0);
    float cr = 0.25*cos(30.0*camPars.y + 0.1*time);

    // shake        
    ro += ani.x*ani.x*0.05*(-1.0+2.0*texture2D( iChannel0, 1.035*time*vec2(0.010,0.014) ).xyz);
    ta += ani.x*ani.x*0.20*(-1.0+2.0*texture2D( iChannel0, 1.035*time*vec2(0.013,0.008) ).xyz);
    
    // build ray
    vec3 ww = normalize( ta - ro);
    vec3 uu = normalize(cross( vec3(sin(cr),cos(cr),0.0), ww ));
    vec3 vv = normalize(cross(ww,uu));
    vec3 rd = normalize( p.x*uu + p.y*vv + (2.5 + 3.5*pow(camPars.z,2.0))*ww );
    
    // raymarch 
    vec3 col = raymarch( ro, rd, ani, fragCoord );
    
    // contrast, saturation and vignetting  
    col = col*col*(3.0-2.0*col);
    col = mix( col, vec3(dot(col,vec3(0.33))), -0.5 );
    col *= 0.25 + 0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
    
    col *= 1.0-smoothstep( 0.4, 0.5, abs(fract(iGlobalTime/5.5)-0.5) )*(1.0-sqrt(ani.x));
    fragColor = vec4( col, 1.0 );
}



//---------------------------

// THREE JS TRANSPHERE

void main(){

    vec4 color = vec4(0.0);

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

//---------------------------