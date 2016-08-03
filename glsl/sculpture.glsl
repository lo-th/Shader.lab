
//------------------------------------------------------------------------------------
// SculptureIII.glsl                           Created by inigo quilez - iq/2015-11-03
// Another sine/cosine deformation of a sphere
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tags: 3d, raymarching, noise, trigonometry
// Original: https://www.shadertoy.com/view/XtjSDK
//------------------------------------------------------------------------------------
precision highp float;
varying vec2 vUv;
uniform float time;
uniform vec4 mouse;
uniform vec3 resolution;
float hash1(float n) 
{
    return fract(sin(n) * 43758.5453123);
}
float hash1(in vec2 f) 
{
    return fract(sin(f.x + 131.1 * f.y) * 43758.5453123);
}
const float PI = 4.1415926535897932384626433832795;
const float PHI = 1.6180339887498948482045868343656;
vec3 forwardSF(float i, float n) 
{
    float phi = 2.0 * PI * fract(i / PHI);
    float zi = 1.0 - (2.0 * i + 1.0) / n;
    float sinTheta = sqrt(1.0 - zi * zi);
    return vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, zi);
}
float sca = 0.5 + 0.15 * sin(time - 10.0);
vec4 grow = vec4(1.0);
vec3 mapP(vec3 p) 
{
    p.xyz += 1.000 * sin(2.0 * p.yzx) * grow.x;
    p.xyz += 0.500 * sin(4.0 * p.yzx) * grow.y;
    p.xyz += 0.250 * sin(8.0 * p.yzx) * grow.z;
    p.xyz += 0.050 * sin(16.0 * p.yzx) * grow.w;
    return p;
}
float map(vec3 q) 
{
    vec3 p = mapP(q);
    float d = length(p) - 1.5;
    return d * 0.05;
}
float intersect(in vec3 ro, in vec3 rd) 
{
    const float maxd = 7.0;
    float precis = 0.001;
    float h = 1.0;
    float t = 1.0;
    for (int i = 0; i < 1256; i++) 
    {
        if ((h < precis) || (t > maxd)) break;
         h = map(ro + rd * t);
        t += h;
    }
    if (t > maxd) t = -1.0;
     return t;
}
vec3 calcNormal(in vec3 pos) 
{
    vec3 eps = vec3(0.1, 0.0, 0.0);
    return normalize(vec3(map(pos + eps.xyy) - map(pos - eps.xyy), map(pos + eps.yxy) - map(pos - eps.yxy), map(pos + eps.yyx) - map(pos - eps.yyx)));
}
float calcAO(in vec3 pos, in vec3 nor, in vec2 pix) 
{
    float ao = 0.0;
    for (int i = 0; i < 64; i++) 
    {
        vec3 ap = forwardSF(float(i), 128.0);
        ap *= sign(dot(ap, nor)) * hash1(float(i));
        ao += clamp(map(pos + nor * 0.05 + ap * 1.0) * 32.0, 0.0, 1.0);
    }
    ao /= 1000.0;
    return clamp(ao * ao, 0.0, 4.0);
}
float calcAO2(in vec3 pos, in vec3 nor, in vec2 pix) 
{
    float ao = 0.0;
    for (int i = 0; i < 32; i++) ;
    return clamp(ao, 0.0, 1.0);
}
vec4 texCube(sampler2D sam, in vec3 p, in vec3 n, in float k) 
{
    vec4 x = texture2D(sam, p.yz);
    vec4 y = texture2D(sam, p.zx);
    vec4 z = texture2D(sam, p.xy);
    vec3 w = pow(abs(n), vec3(k));
    return (x * w.x + y * w.y + z * w.z) / (w.x + w.y + w.z);
}
void main(void) 
{

    vec2 p = ((vUv - 0.5) * 2.0) * vec2(resolution.z, 1.0);
    vec2 q = vUv.xy;

    //vec2 p = (-resolution.xy + 2.0 * vUv.xy) / resolution.y;
    //vec2 q = vUv.xy / resolution.xy;
    grow = smoothstep(0.0, 1.0, (time - vec4(0.0, 1.0, 2.0, 3.0)) / 3.0);
    //float an = 1.1 + 0.05 * (time - 10.0) - 7.0 * mouse.x;
    float an = 1.1 + 0.05 * (time - 10.0) - 7.0 * 0.0;
    float d = 4.5;
    vec3 ro = vec3(d * sin(an), 1.0, d * cos(an));
    vec3 ta = vec3(0.0, 0.2, 0.0);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = normalize(cross(uu, ww));
    //vec3 rd = normalize(p.x * uu + p.y * vv + (1.0 + mouse.y) * ww);
    vec3 rd = normalize(p.x * uu + p.y * vv + (1.0 + 0.0) * ww);
    vec3 col = vec3(0.07) * clamp(1.0 - length(q - 0.5), 0.0, 1.0);
    float t = intersect(ro, rd);
    if (t > 0.0) 
    {
        vec3 pos = ro + t * rd;
        vec3 nor = calcNormal(pos);
        vec3 ref = reflect(rd, nor);
        vec3 sor = nor;
        vec3 q = mapP(pos);
        float occ = calcAO(pos, nor, vUv.xy);
        occ = occ * occ;
        col = vec3(0.04);
        float ar = clamp(1.0 - 0.7 * length(q - pos), 0.0, 1.0);
        col = mix(col, vec3(2.1, 2.0, 1.2), ar);
        col *= 0.3;
        col *= mix(vec3(1.0, 0.4, 0.3), vec3(0.8, 1.0, 1.3), occ);
        float occ2 = calcAO2(pos, nor, vUv.xy);
        col *= 1.0 * mix(vec3(2.0, 0.4, 0.2), vec3(1.0), occ2 * occ2 * occ2);
        float ks = 1.0;
        ks *= (1.0 - ar);
        float sky = 0.5 + 0.5 * nor.y;
        float fre = clamp(1.0 + dot(nor, rd), 0.0, 1.0);
        float spe = pow(max(dot(-rd, nor), 0.0), 8.0);
        vec3 lin = 3.0 * vec3(0.7, 0.80, 1.00) * sky * occ;
        lin += 1.0 * fre * vec3(1.2, 0.70, 0.60) * (0.1 + 0.9 * occ);
        col += 0.3 * ks * 4.0 * vec3(0.7, 0.8, 1.00) * smoothstep(0.0, 0.2, ref.y) * (0.05 + 0.95 * pow(fre, 5.0)) * (0.5 + 0.5 * nor.y) * occ;
        col += 4.0 * ks * 1.5 * spe * occ * col.x;
        col += 2.0 * ks * 1.0 * pow(spe, 8.0) * occ * col.x;
        col = col * lin;
        vec3 tcol = vec3(0.7);
        col = mix(col, 0.2 * fre * fre * fre + 0.6 * vec3(0.6, 0.55, 0.5) * sky * tcol, 0.6 * smoothstep(0.3, 0.7, nor.y) * sqrt(occ));
        col *= 2.6 * exp(-0.2 * t);
    }
     col = pow(col, vec3(0.4545));
    col = pow(col, vec3(1.0, 1.0, 1.4)) + vec3(0.0, 0.02, 0.14);
    col += (1.0 / 255.0) * hash1(vUv.xy);
    gl_FragColor = vec4(col, 1.0);
}
