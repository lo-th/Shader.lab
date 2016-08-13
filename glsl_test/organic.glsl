precision highp float;
precision highp int;
uniform sampler2D iChannel0;
uniform vec2 resolution;
uniform float time;
varying vec2 vUv;
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n) 
{
    n = max(n * n, 0.001);
    n /= (n.x + n.y + n.z);
    return (texture2D(tex, p.yz) * n.x + texture2D(tex, p.zx) * n.y + texture2D(tex, p.xy) * n.z).xyz;
}
float map(vec3 p) 
{
    p.xy += sin(p.xy * 7. + cos(p.yx * 13. + time)) * .01;
    return 1. - p.z - texture2D(iChannel0, p.xy).x * .1;
}
vec3 getNormal(in vec3 pos) 
{
    vec2 e = vec2(0.002, -0.002);
    return normalize(e.xyy * map(pos + e.xyy) + e.yyx * map(pos + e.yyx) + e.yxy * map(pos + e.yxy) + e.xxx * map(pos + e.xxx));
}
float calculateAO(vec3 p, vec3 n) 
{
    const float AO_SAMPLES = 5.0;
    float r = 1.0, w = 1.0, d0;
    for (float i = 1.0; i <= AO_SAMPLES; i++) 
    {
        d0 = i / AO_SAMPLES;
        r += w * (map(p + n * d0) - d0);
        w *= 0.5;
    }
    return clamp(r, 0.0, 1.0);
}
float curve(in vec3 p) 
{
    const float eps = 0.02, amp = 7., ampInit = 0.5;
    vec2 e = vec2(-1., 1.) * eps;
    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);
    return clamp((t1 + t2 + t3 + t4 - 4. * map(p)) * amp + ampInit, 0., 1.);
}
void main() 
{
    vec3 rd = normalize(vec3(vUv - resolution.xy * .5, resolution.y * 1.5));
    vec2 a = sin(vec2(1.5707963, 0) + sin(time / 4.) * .3);
    rd.xy = mat2(a, -a.y, a.x) * rd.xy;
    vec3 ro = vec3(time * .25, 0., 0.);
    vec3 lp = ro + vec3(cos(time / 2.) * .5, sin(time / 2.) * .5, 0.);
    float d, t = 0.;
    for (int j = 0; j < 16; j++) 
    {
        d = map(ro + rd * t);
        t += d * .7;
        if (d < 0.001) break;
     }
    vec3 sp = ro + rd * t;
    vec3 sn = getNormal(sp);
    vec3 ld = lp - sp;
    float c = 1. - tex3D(iChannel0, sp * 8. - vec3(sp.x, sp.y, time / 4. + sp.x + sp.y), sn).x;
    vec3 orange = vec3(min(c * 1.5, 1.), pow(c, 2.), pow(c, 8.));
    vec3 oC = orange;
    oC = mix(oC, oC.zxy, cos(rd.zxy * 6.283 + sin(sp.yzx * 6.283)) * .25 + .75);
    oC = mix(oC.yxz, oC, (sn) * .5 + .5);
    oC = mix(orange, oC, (sn) * .25 + .75);
    oC *= oC * 1.5;
    float lDist = max(length(ld), 0.001);
    float atten = 1. / (1. + lDist * .125);
    ld /= lDist;
    float diff = max(dot(ld, sn), 0.);
    float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.0), 32.);
    float fre = clamp(dot(sn, rd) + 1., .0, 1.);
    float crv = curve(sp);
    float ao = calculateAO(sp, sn);
    vec3 crvC = vec3(crv, crv * 1.3, crv * .7) * .25 + crv * .75;
    crvC *= crvC;
    vec3 col = (oC * (diff + .5) + vec3(.5, .75, 1.) * spec * 2.) + vec3(.3, .7, 1.) * pow(fre, 3.) * 5.;
    col *= (atten * crvC * ao);
    gl_FragColor = vec4(sqrt(max(col, 0.)), 1.);
}
