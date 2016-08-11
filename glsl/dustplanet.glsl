

#define ITR 90
#define FAR 60.
#define MOD3 vec3(.16532,.17369,.15787)
#define SKY1_COLOR vec3(0.0, 0.10, 0.20)
#define SKY2_COLOR vec3(0.2, 0.05, 0.08)
#define SUN_COLOR vec3(1.0, 0.45, 0.35)
#define CLOUD_COLOR vec3(0.2, 0.10, 0.08)
#define moveSpeed 2.5

float height(in vec2 p) 
{
    float h = sin(p.x * .1 + p.y * .2) + sin(p.y * .1 - p.x * .2) * .5;
    h += sin(p.x * .04 + p.y * .01 + 3.0) * 4.;
    h -= sin(h * 10.0) * .1;
    return h;
}
float camHeight(in vec2 p) 
{
    float h = sin(p.x * .1 + p.y * .2) + sin(p.y * .1 - p.x * .2) * .5;
    h += sin(p.x * .04 + p.y * .01 + 3.0) * 4.;
    return h;
}
float smin(float a, float b) 
{
    const float k = 2.7;
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
float hash12(vec2 p) 
{
    p = fract(p * vec2(5.3983, 5.4427));
    p += dot(p.yx, p.xy + vec2(21.5351, 14.3137));
    return fract(p.x * p.y * 95.4337);
}
float vine(vec3 p, in float c, in float h) 
{
    p.y += sin(p.z * .5625 + 1.3) * 3.5 - .5;
    p.x += cos(p.z * .4575) * 1.;
    vec2 q = vec2(mod(p.x, c) - c / 2., p.y);
    return length(q) - h * 1.4 - sin(p.z * 3. + sin(p.x * 7.) * 0.5) * 0.1;
}
float tri(in float x) 
{
    return abs(fract(x) - .5);
}
vec3 tri3(in vec3 p) 
{
    return vec3(tri(p.z + tri(p.y * 1.)), tri(p.z + tri(p.x * 1.)), tri(p.y + tri(p.x * 1.)));
}
mat2 m2 = mat2(0.970, 0.242, -0.242, 0.970);
float triNoise3d(in vec3 p) 
{
    float z = 1.4;
    float rz = 0.;
    vec3 bp = p;
    for (float i = 0.; i <= 2.; i++) 
    {
        vec3 dg = tri3(bp);
        p += (dg);
        bp *= 2.;
        z *= 1.5;
        p *= 1.3;
        rz += tri(p.z + tri(p.x + tri(p.y))) / z;
        bp += 0.14;
    }
    return rz;
}
float map(vec3 p) 
{
    p.y += height(p.zx);
    float d = p.y + .5;
    d = smin(d, vine(p + vec3(.8, 0., 0), 30., 3.3));
    d = smin(d, vine(p.zyx + vec3(0., 0, 17.), 33., 1.4));
    d += triNoise3d(p * .05) * (p.y * 1.2);
    p.xz *= .2;
    d += triNoise3d(p * .3);
    return d;
}
float fogmap(in vec3 p, in float d) 
{
    p.xz -= iGlobalTime * 7.;
    p.y -= iGlobalTime * .5;
    return (max(triNoise3d(p * .008 + .1) - .1, 0.0) * triNoise3d(p * .1)) * .7;
}
float march(in vec3 ro, in vec3 rd, out float f, in vec2 scUV) 
{
    float precis = 0.01;
    float h = precis * 2.0;
    float d = hash12(scUV);
    f = 0.0;
    float fd = hash12(scUV * 1.3);
    for (int i = 0; i < ITR; i++) 
    {
        vec3 p = ro + rd * d;
        if (h < precis || d > FAR) break;
         h = map(p);
        if (d > fd) f += (1.0 - f) * fogmap(p, fd);
         d += h * .65 + d * .002;
        fd += .1;
    }
    return d;
}
vec3 normal(in vec3 pos, in float d) 
{
    vec2 eps = vec2(d * d * .003 + .01, 0.0);
    vec3 nor = vec3(map(pos + eps.xyy) - map(pos - eps.xyy), map(pos + eps.yxy) - map(pos - eps.yxy), map(pos + eps.yyx) - map(pos - eps.yyx));
    return normalize(nor);
}
float bnoise(in vec3 p) 
{
    p.xz *= .4;
    float n = triNoise3d(p * 3.) * 0.4;
    n += triNoise3d(p * 1.5) * 0.2;
    return n * n * .2;
}
vec3 bump(in vec3 p, in vec3 n, in float ds) 
{
    p.xz *= .4;
    vec2 e = vec2(.01, 0);
    float n0 = bnoise(p);
    vec3 d = vec3(bnoise(p + e.xyy) - n0, bnoise(p + e.yxy) - n0, bnoise(p + e.yyx) - n0) / e.x;
    n = normalize(n - d * 10. / (ds));
    return n;
}
float shadow(in vec3 ro, in vec3 rd, in float mint) 
{
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 12; i++) 
    {
        float h = map(ro + rd * t);
        res = min(res, 4. * h / t);
        t += clamp(h, 0.1, 1.5);
    }
    return clamp(res, 0.2, 1.0);
}
vec3 Clouds(vec3 sky, vec3 rd) 
{
    float v = (200.0) / rd.y;
    rd.y = v;
    rd.xz = rd.xz * v - iGlobalTime * 24.0;
    rd.xz *= .0004;
    float f = triNoise3d(rd.xzz * .5) + triNoise3d(rd.zzx * 3.) * .5;
    return mix(sky, CLOUD_COLOR, max(f - .3, 0.0));
}
vec3 Sky(vec3 rd, vec3 ligt) 
{
    vec3 sky = mix(SKY1_COLOR, SKY2_COLOR, pow(abs(rd.y + .04), .5));
    return mix(sky, SUN_COLOR, min(pow(max(dot(rd, ligt), 0.0), 4.5), 1.0));
}
void main() 
{
    //vec2 uv = gl_FragCoord.xy / iResolution.xy;
    //uv = 1.0 - uv * 2.0;
    //uv.x *= iResolution.x / iResolution.y;   
    //uv.y *= -1.;

    vec2 q = vUv;
    vec2 p = ((vUv * 2.0) - 1.0) * vec2(iResolution.z, 1.0);
    //p.x *= iResolution.x / iResolution.y;
    vec2 mo = iMouse.xy / iResolution.xy-.5;
    mo.x *= 6.28;
    vec3 ro = vec3(0. + smoothstep(0., 1., tri(iGlobalTime * .6) * 2.) * 0.1, smoothstep(0., 1., tri(iGlobalTime * 3.) * 3.) * 0.08, -iGlobalTime * moveSpeed - 140.0);
    ro.y -= camHeight(ro.zx) - .4;
    mo.x += smoothstep(0.7, 1., sin(iGlobalTime * .35)) * .5 - 1.5 - smoothstep(-.7, -1., sin(iGlobalTime * .35)) * .5;
    vec3 eyedir = normalize(vec3(cos(mo.x), mo.y * 2. + sin(iGlobalTime * .5) * 0.1, sin(mo.x)));
    vec3 rightdir = normalize(vec3(cos(mo.x + 1.5708), 0., sin(mo.x + 1.5708)));
    vec3 updir = normalize(cross(rightdir, eyedir));
    vec3 rd = normalize((p.x * rightdir + p.y * updir) * 1. + eyedir);
    vec3 ligt = normalize(vec3(0.5, 0.1, -0.1));
    float fg;
    float rz = march( ro, rd, fg, q );
    vec3 sky = Sky(rd, ligt);
    vec3 col = sky;
    if (rz < FAR) 
    {
        vec3 pos = ro + rz * rd;
        vec3 nor = normal(pos, rz);
        float d = distance(pos, ro);
        nor = bump(pos, nor, d);
        float shd = shadow(pos, ligt, .04);
        float dif = clamp(dot(nor, ligt), 0.0, 1.0);
        float spe = pow(clamp(dot(reflect(rd, nor), ligt), 0.0, 1.0), 8.) * 2.5;
        float fre = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.);
        col = vec3(.38);
        col = col * dif * shd + spe * fre * shd * SUN_COLOR + abs(nor.y) * vec3(.1, .1, .12);
        col = mix(col, sky, smoothstep(FAR - 10., FAR, rz));
    }
 else col = Clouds(col, rd);

 
    col = mix(col, vec3(0.6, .62, .7), fg);
    col = min(pow(col * 1.1, vec3(1.6)), 1.0);

    // tone mapping
    col = toneMap( col );

    // Borders...
    float f = smoothstep(0.0, 3.0, iGlobalTime) * .5;
    col *= f + f * pow(70. * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), .2);

    
    
    gl_FragColor = vec4(col, 1.0);
}
