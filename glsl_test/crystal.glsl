precision highp float;
varying vec2 vUv;
uniform float time;
uniform vec2 resolution;
vec2 hash22(vec2 p) 
{
    float n = sin(dot(p, vec2(41, 289)));
    return fract(vec2(262144, 32768) * n);
}
float Voronoi(vec2 p) 
{
    vec2 ip = floor(p);
    p = fract(p);
    float d = 1.;
    for (float i = -1.; i < 1.1; i++) 
    {
        for (float j = -1.; j < 1.1; j++) 
        {
            vec2 cellRef = vec2(i, j);
            vec2 offset = hash22(ip + cellRef);
            vec2 r = cellRef + offset - p;
            float d2 = dot(r, r);
            d = min(d, d2);
        }
    }
    return sqrt(d);
}
void main(void) {
    
    //vec2 uv = (vUv.xy - resolution.xy * .5) / resolution.y;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = 1.0 - uv * 2.0;
    uv.x *= resolution.x / resolution.y;   
    uv.y *= -1.;

    uv =  1.0 - vUv * 2.0;

    float t = time, s, a, b, e;
    float th = sin(time * 0.1) * sin(time * 0.13) * 4.;
    float cs = cos(th), si = sin(th);
    uv *= mat2(cs, -si, si, cs);
    vec3 sp = vec3(uv, 0);
    vec3 ro = vec3(0, 0, -1);
    vec3 rd = normalize(ro - sp);
    vec3 lp = vec3(cos(time) * 0.375, fract(time) * 0.1, -1.);
    const float L = 8.;
    const float gFreq = 0.1;
    float sum = 0.;
    th = 3.14159265 * 0.7071 / L;
    cs = cos(th), si = sin(th);
    mat2 M = mat2(cs, -si, si, cs);
    vec3 col = vec3(0);
    float f = 0., fx = 0., fy = 0.;
    vec2 eps = vec2(6. / resolution.y, 0.);
    vec2 offs = vec2(0.9);
    for (float i = 0.; i < L; i++) 
    {
        s = fract((i - t * 2.) / L);
        e = exp2(s * L) * gFreq;
        a = (1. - cos(s * 7.283)) / e;
        f += Voronoi(M * sp.xy * e + offs) * a;
        fx += Voronoi(M * (sp.xy + eps.xy) * e + offs) * a;
        fy += Voronoi(M * (sp.xy + eps.yx) * e + offs) * a;
        sum += a;
        M *= M;
    }
    sum = max(sum, 0.001);
    f /= sum;
    fx /= sum;
    fy /= sum;
    float bumpFactor = 0.2;
    fx = (fx - f) / eps.x;
    fy = (fy - f) / eps.x;
    vec3 n = normalize(vec3(0, 0.0, -0.1) - vec3(fx, fy, 0) * bumpFactor);
    vec3 ld = lp - sp;
    float lDist = max(length(ld), 0.0003);
    ld /= lDist;
    float atten = min(1. / (lDist * 0.75 + lDist * lDist * 0.15), 1.);
    float diff = max(dot(n, ld), 0.);
    diff = pow(diff, 2.) * 0.66 + pow(diff, 4.) * 0.34;
    float spec = pow(max(dot(reflect(-ld, n), rd), 0.), 8.);
    vec3 objCol = vec3(f, f * f * sqrt(f) * 0.4, f * 0.6);
    col = (objCol * (diff + 0.5) + vec3(0.5, 0.85, 1.) * spec) * atten;
    gl_FragColor = vec4(min(col, 1.), 1.);
}