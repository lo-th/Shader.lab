precision highp float;
varying vec2 vUv;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
float length2(vec2 p) 
{
    return dot(p, p);
}
float noise(vec2 p) 
{
    return fract(sin(fract(sin(p.x) * (43.13311)) + p.y) * 31.0011);
}
float worley(vec2 p) 
{
    float d = 1e30;
    for (int xo = -1; xo <= 1; ++xo) 
    {
        for (int yo = -1; yo <= 1; ++yo) 
        {
            vec2 tp = floor(p) + vec2(xo, yo);
            d = min(d, length2(p - tp - vec2(noise(tp))));
        }
    }
    return 3.0 * exp(-4.0 * abs(2.0 * d - 1.0));
}
float fworley(vec2 p) 
{
    return sqrt(sqrt(sqrt(2.1 * worley(p * 5. + .3 + time * .0525) * sqrt(worley(p * 50. + 0.9 + time * -0.15)) * sqrt(sqrt(worley(p * -10. + 9.3))))));
}
void main() 
{
    vec2 uv = vUv.xy / resolution.xy;
    float t = fworley(uv * resolution.xy / 1100.0);
    t *= exp(-length2(abs(0.66 * uv - 1.0)));
    gl_FragColor = vec4(t * vec3(0.8, 2.2 * t, .4 * t + pow(t, 0.1 - t)), 1.0);
}