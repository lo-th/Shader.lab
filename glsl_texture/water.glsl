
#define TAU 6.28318530718
#define MAX_ITER 5

void main() {

    float iGlobalTime = iGlobalTime * .5 + 23.0;

    //vec2 uv = vUv.xy / iResolution.xy;

    //vec2 uv = gl_FragCoord.xy / iResolution.xy;
    //uv = 1.0 - uv * 2.0;
    //uv.x *= iResolution.x / iResolution.y;   
    //uv.y *= -1.;

    vec2 uv = ((vUv * 2.0) - 1.0) * vec2(iResolution.z, 1.0);

    //vec2 p = mod(uv*TAU*2.0, TAU)-250.0;//tilling
    vec2 p = mod(uv * TAU, TAU) - 250.0;
    vec2 i = vec2(p);
    float c = 1.0;
    float inten = .005;
    for (int n = 0; n < MAX_ITER; n++) 
    {
        float t = iGlobalTime * (1.0 - (3.5 / float(n + 1)));
        i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0 / length(vec2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
    }
    c /= float(MAX_ITER);
    c = 1.17 - pow(c, 1.4);
    vec3 colour = vec3(pow(abs(c), 8.0));
    colour = clamp(colour + vec3(0.0, 0.35, 0.5), 0.0, 1.0);
    gl_FragColor = vec4(colour, 1.0);
    
}