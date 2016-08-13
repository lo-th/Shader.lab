
// https://www.shadertoy.com/view/Mlc3Rl

#define PI 3.14159265359

void main(){

    vec2 uv = (gl_FragCoord.xy) / iResolution.xy;
    
    vec4 data = vec4(texture2D(iChannel0, uv));
    
    vec2 vel = data.zw;
    
    float angle = atan(vel.y, vel.x) + PI;
    
    vec4 color = vec4(0,0,0,0);
    
    vec4 red = vec4(1.0, 0.0, 0.0, 1.0);
    vec4 yel = vec4(1.0, 1.0, 0.0, 1.0);
    vec4 gre = vec4(0.0, 1.0, 0.0, 1.0);
    vec4 cya = vec4(0.0, 1.0, 1.0, 1.0);
    vec4 blu = vec4(0.0, 0.0, 1.0, 1.0);
    vec4 mag = vec4(1.0, 0.0, 1.0, 1.0);
    
    if(angle < PI / 3.0)
    {
        color = mix(red, yel, angle / (PI / 3.0));
    }
    else if(angle < 2.0 * PI / 3.0)
    {
        color = mix(yel, gre, (angle - PI / 3.0) / (PI / 3.0));
    }
    else if(angle < PI)
    {
        color = mix(gre, cya, (angle - 2.0 * PI / 3.0) / (PI / 3.0));
    }
    else if(angle < 4.0 * PI / 3.0)
    {
        color = mix(cya, blu, (angle -  PI) / (PI / 3.0));
    }
    else if(angle < 5.0 * PI / 3.0)
    {
        color = mix(blu, mag, (angle - 4.0 * PI / 3.0) / (PI / 3.0));
    }
    else
    {
        color = mix(mag, red, (angle - 5.0 * PI / 3.0) / (PI / 3.0));
    }
    
    if(data.x > 0.001)
        gl_FragColor = color;
    else
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
}