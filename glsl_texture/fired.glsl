
vec3 firePalette(float i) 
{
    float T = 1400. + 1300. * i;
    vec3 L = vec3(7.4, 5.6, 4.4);
    L = pow(L, vec3(5.0)) * (exp(1.43876719683e5 / (T * L)) - 1.0);
    return 1.0 - exp(-5e8 / L);
}
vec3 hash33(vec3 p) 
{
    float n = sin(dot(p, vec3(7, 157, 113)));
    return fract(vec3(2097152, 262144, 32768) * n);
}
float voronoi(vec3 p) 
{
    vec3 b, r, g = floor(p);
    p = fract(p);
    float d = 1.;
    for (int j = -1; j <= 1; j++) 
    {
        for (int i = -1; i <= 1; i++) 
        {
            b = vec3(i, j, -1);
            r = b - p + hash33(g + b);
            d = min(d, dot(r, r));
            b.z = 0.0;
            r = b - p + hash33(g + b);
            d = min(d, dot(r, r));
            b.z = 1.;
            r = b - p + hash33(g + b);
            d = min(d, dot(r, r));
        }
    }
    return d;
}
float noiseLayers(in vec3 p) 
{
    vec3 t = vec3(0., 0., p.z + iGlobalTime * 1.5);
    const int iter = 5;
    float tot = 0., sum = 0., amp = 1.;
    for (int i = 0; i < iter; i++) 
    {
        tot += voronoi(p + t) * amp;
        p *= 2.0;
        t *= 1.5;
        sum += amp;
        amp *= 0.5;
    }
    return tot / sum;
}
void main() 
{
    //vec2 uv = (vUv.xy - iResolution.xy * 0.5) / iResolution.y;

    //vec2 uv = gl_FragCoord.xy / iResolution.xy;
    //uv = 1.0 - uv * 2.0;
    //uv.x *= iResolution.x / iResolution.y;   
    //uv.y *= -1.;

    //uv =  1.0 - vUv * 2.0;
    //uv.x *= iResolution.x / iResolution.y;

    vec2 uv = ((vUv * 2.0) - 1.0) * vec2(iResolution.z, 1.0);

    //uv += vec2(sin(iGlobalTime * 0.5) * 0.25, cos(iGlobalTime * 0.5) * 0.125);

    vec3 rd = normalize(vec3(uv.x, uv.y, 3.1415926535898 / 8.));
    float cs = cos(iGlobalTime * 0.25), si = sin(iGlobalTime * 0.25);
    rd.xy = rd.xy * mat2(cs, -si, si, cs);
    float c = noiseLayers(rd * 2.);
    c = max(c + dot(hash33(rd) * 2. - 1., vec3(0.015)), 0.);
    c *= sqrt(c) * 1.5;
    vec3 col = firePalette(c);
    col = mix(col, col.zyx * 0.1 + c * 0.9, (1. + rd.x + rd.y) * 0.45);
    gl_FragColor = vec4(clamp(col, 0., 1.), 1.);
}
