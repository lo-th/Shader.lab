// ------------------ channel define
// 0_# stone #_0
// ------------------



#define FAR 30.
#define PI 3.14159265
#define PRECISION 0.001

float getGrey(vec3 p) 
{
    return p.x * 0.299 + p.y * 0.587 + p.z * 0.114;
}
mat2 rot(float th) 
{
    float cs = cos(th), sn = sin(th);
    return mat2(cs, -sn, sn, cs);
}
vec3 firePalette(float i) 
{
    float T = 1400. + 1300. * i;
    vec3 L = vec3(7.4, 5.6, 4.4);
    L = pow(L, vec3(5.0)) * (exp(1.43876719683e5 / (T * L)) - 1.0);
    return 1.0 - exp(-5e8 / L);
}
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n) 
{
    n = max((abs(n) - 0.2) * 7., 0.001);
    n /= (n.x + n.y + n.z);
    return (texture2D(tex, p.yz) * n.x + texture2D(tex, p.zx) * n.y + texture2D(tex, p.xy) * n.z).xyz;
}
float hash31(vec3 p) 
{
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}
vec3 hash33(vec3 p) 
{
    float n = sin(dot(p, vec3(7, 157, 113)));
    return fract(vec3(2097152, 262144, 32768) * n) * 2. - 1.;
}
vec3 doBumpMap(sampler2D tex, in vec3 p, in vec3 nor, float bumpfactor) 
{
    const float eps = 0.001;
    vec3 grad = vec3(getGrey(tex3D(tex, vec3(p.x - eps, p.y, p.z), nor)), getGrey(tex3D(tex, vec3(p.x, p.y - eps, p.z), nor)), getGrey(tex3D(tex, vec3(p.x, p.y, p.z - eps), nor)));
    grad = (grad - getGrey(tex3D(tex, p, nor))) / eps;
    grad -= nor * dot(nor, grad);
    return normalize(nor + grad * bumpfactor);
}
float sminP(in float a, in float b) 
{
    float h = clamp(2. * (b - a) + 0.5, 0.0, 1.0);
    return (b - 0.25 * h) * (1. - h) + a * h;
}
float map(vec3 p) 
{
    vec2 perturb = vec2(sin((p.z * 2.15 + p.x * 2.35)), cos((p.z * 1.15 + p.x * 1.25)));
    vec2 perturb2 = vec2(cos((p.z * 1.65 + p.y * 1.75)), sin((p.z * 1.4 + p.y * 1.6)));
    vec2 q1 = mod(p.xy + vec2(0.25, -0.5), 2.) - 1.0 + perturb * vec2(0.25, 0.5);
    vec2 q2 = mod(p.yz + vec2(0.25, 0.25), 2.) - 1.0 - perturb * vec2(0.25, 0.3);
    vec2 q3 = mod(p.xz + vec2(-0.25, -0.5), 2.) - 1.0 - perturb2 * vec2(0.25, 0.4);
    p = sin(p * 8. + cos(p.yzx * 8.));
    float s1 = length(q1) - 0.24;
    float s2 = length(q2) - 0.24;
    float s3 = length(q3) - 0.24;
    return sminP(sminP(s1, s3), s2) - p.x * p.y * p.z * 0.05;
}
float softShadow(in vec3 ro, in vec3 rd, in float start, in float end, in float k) 
{
    float shade = 1.0;
    const int maxIterationsShad = 12;
    float dist = start;
    float stepDist = end / float(maxIterationsShad);
    for (int i = 0; i < maxIterationsShad; i++) 
    {
        float h = map(ro + rd * dist);
        shade = min(shade, k * h / dist);
        dist += clamp(h, 0.0001, .2);
        if (abs(h) < 0.001 || dist > end) break;
     }
    return min(max(shade, 0.) + 0.4, 1.0);
}
float calculateAO(vec3 p, vec3 n) 
{
    const float AO_SAMPLES = 5.0;
    float r = 0.0, w = 1.0, d;
    for (float i = 1.0; i < AO_SAMPLES + 1.1; i++) 
    {
        d = i / AO_SAMPLES;
        r += w * (d - map(p + n * d));
        w *= 0.5;
    }
    return 1.0 - clamp(r, 0.0, 1.0);
}
vec3 getNormal(in vec3 p) 
{
    vec2 e = vec2(0.5773, -0.5773) * 0.001;
    return normalize(e.xyy * map(p + e.xyy) + e.yyx * map(p + e.yyx) + e.yxy * map(p + e.yxy) + e.xxx * map(p + e.xxx));
}
float logBisectTrace(in vec3 ro, in vec3 rd) 
{
    float t = 0., told = 0., mid, dn;
    float d = map(rd * t + ro);
    float sgn = sign(d);
    for (int i = 0; i < 80; i++) 
    {
        if (sign(d) != sgn || d < PRECISION || t > FAR) break;
         told = t;
        t += step(-1., -d) * (log(abs(d) + 1.1) * .7 - d * .7) + d * .7;
        d = map(rd * t + ro);
    }
    if (sign(d) != sgn) 
    {
        dn = sign(map(rd * told + ro));
        vec2 iv = vec2(told, t);
        for (int ii = 0; ii < 8; ii++) 
        {
            mid = dot(iv, vec2(.5));
            float d = map(rd * mid + ro);
            if (abs(d) < PRECISION) break;
             iv = mix(vec2(iv.x, mid), vec2(mid, iv.y), step(0.0, d * dn));
        }
        t = mid;
    }
     return t;
}
float trig3(in vec3 p) 
{
    p = cos(p * 2. + (cos(p.yzx) + 1. + iGlobalTime * 4.) * 1.57);
    return dot(p, vec3(0.1666)) + 0.5;
}
float trigNoise3D(in vec3 p) 
{
    const mat3 m3RotTheta = mat3(0.25, -0.866, 0.433, 0.9665, 0.25, -0.2455127, -0.058, 0.433, 0.899519) * 1.5;
    float res = 0.;
    float t = trig3(p * PI);
    p += (t - iGlobalTime * 0.25);
    p = m3RotTheta * p;
    res += t;
    t = trig3(p * PI);
    p += (t - iGlobalTime * 0.25) * 0.7071;
    p = m3RotTheta * p;
    res += t * 0.7071;
    t = trig3(p * PI);
    res += t * 0.5;
    return res / 2.2071;
}
float getMist(in vec3 ro, in vec3 rd, in vec3 lp, in float t) 
{
    float mist = 0.;
    ro += rd * t / 8.;
    for (int i = 0; i < 4; i++) 
    {
        float sDi = length(lp - ro) / FAR;
        float sAtt = min(1. / (1. + sDi * 0.25 + sDi * sDi * 0.05), 1.);
        mist += trigNoise3D(ro * 2.) * sAtt;
        ro += rd * t / 4.;
    }
    return clamp(mist / 2. + hash31(ro) * 0.1 - 0.05, 0., 1.);
}
void main() {

    vec2 uv = ((vUv - 0.5) * 2.0) * vec2(iResolution.z, 1.0);

    vec3 ro = vec3(0., 0., iGlobalTime * 2.);
    vec3 rd = normalize(vec3(uv, 0.5));
    mat2 m2 = rot(iGlobalTime * 0.25);
    rd.xz *= m2;
    rd.xy *= m2;
    rd.yz *= m2;
    vec3 lp = vec3(0., 0., FAR) + ro + rd * 10.;
    float bgShade = pow(max(dot(rd, normalize(lp - ro)), 0.) * 0.5 + 0.5, 4.);
    vec3 bc = mix(vec3(.0, .0, .05), vec3(1.), bgShade);
    vec3 sc = bc;
    float t = logBisectTrace(ro, rd);
    if (t < FAR) 
    {
        vec3 sp = ro + rd * t;
        vec3 sn = getNormal(sp);
        const float texSize0 = 1. / 2.;
        sn = doBumpMap(iChannel0, sp * texSize0, sn, 0.025);
        vec3 objCol = tex3D(iChannel0, sp * texSize0, sn);
        vec3 ld = lp - sp;
        float lDist = max(length(ld), 0.001);
        ld /= lDist;
        lDist /= FAR;
        float sAtten = min(1. / (1. + lDist * 0.125 + lDist * lDist * 0.05), 1.);
        float shad = softShadow(sp, ld, 0.05, FAR, 8.);
        float ao = calculateAO(sp, sn);
        float diff = max(dot(sn, ld), 0.);
        float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.0), 8.);
        sc = (objCol * (diff + 0.5) + spec) * sAtten;
        sc = min(sc, 1.) * shad * ao;
    }
     float fog = min(1.0 / (1. + t * 0.25 + t * t * 0.025), 1.);
    sc = mix(bc, sc, fog);
    vec3 sc2 = firePalette(getGrey(sc));
    float fadeFactor = min(1.0 / (1. + t), 1.);
    sc = mix(sc, sc2, fadeFactor * 0.34 + 0.66);
    float mist = getMist(ro, rd, lp, t);
    vec3 fogCol = mix(vec3(bgShade * 0.8 + 0.2) * vec3(1., 0.85, 0.6), sc, mist * fog);
    sc = sc * 0.65 + fogCol * 0.35;
    gl_FragColor = vec4(clamp(sc, 0., 1.), 1.0);
}
