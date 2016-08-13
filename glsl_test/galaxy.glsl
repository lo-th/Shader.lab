precision highp float;
precision highp int;
uniform vec2 resolution;
uniform float time;
varying vec2 vUv;
void main() 
{
    //vec2 uv = (vUv.xy / resolution.xy) - .5;

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = 1.0 - uv * 2.0;
    uv.x *= resolution.x / resolution.y;   
    uv.y *= -1.;

    uv =  1.0 - vUv * 2.0;
    uv.x *= resolution.x / resolution.y;


    float t = time * .1 + ((.25 + .05 * sin(time * .1)) / (length(uv.xy) + .07)) * 2.2;
    float si = sin(t);
    float co = cos(t);
    mat2 ma = mat2(co, si, -si, co);
    float v1, v2, v3;
    v1 = v2 = v3 = 0.0;
    float s = 0.0;
    for (int i = 0; i < 90; i++) 
    {
        vec3 p = s * vec3(uv, 0.0);
        p.xy *= ma;
        p += vec3(.22, .3, s - 1.5 - sin(time * .13) * .1);
        for (int i = 0; i < 8; i++) p = abs(p) / dot(p, p) - 0.659;
        v1 += dot(p, p) * .0015 * (1.8 + sin(length(uv.xy * 13.0) + .5 - time * .2));
        v2 += dot(p, p) * .0013 * (1.5 + sin(length(uv.xy * 14.5) + 1.2 - time * .3));
        v3 += length(p.xy * 10.) * .0003;
        s += .035;
    }
    float len = length(uv);
    v1 *= smoothstep(.7, .0, len);
    v2 *= smoothstep(.5, .0, len);
    v3 *= smoothstep(.9, .0, len);
    vec3 col = vec3(v3 * (1.5 + sin(time * .2) * .4), (v1 + v3) * .3, v2) + smoothstep(0.2, .0, len) * .85 + smoothstep(.0, .6, v3) * .3;
    gl_FragColor = vec4(min(pow(abs(col), vec3(1.2)), 1.0), 1.0);
    
}