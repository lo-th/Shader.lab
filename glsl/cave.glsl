
// https://www.shadertoy.com/view/MsX3RH

//precision highp float;
//precision highp int;

uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform sampler2D iChannel4;
uniform vec3 iResolution;
uniform float iGlobalTime;
varying vec2 vUv;

const vec2 cama = vec2(-2.6943, 3.0483);
const vec2 camb = vec2(0.2516, 0.1749);
const vec2 camc = vec2(-3.7902, 2.4478);
const vec2 camd = vec2(0.0865, -0.1664);
const vec2 lighta = vec2(1.4301, 4.0985);
const vec2 lightb = vec2(-0.1276, 0.2347);
const vec2 lightc = vec2(-2.2655, 1.5066);
const vec2 lightd = vec2(-0.1284, 0.0731);
vec2 Position(float z, vec2 a, vec2 b, vec2 c, vec2 d) 
{
    return sin(z * a) * b + cos(z * c) * d;
}
vec3 Position3D(float iGlobalTime, vec2 a, vec2 b, vec2 c, vec2 d) 
{
    return vec3(Position(iGlobalTime, a, b, c, d), iGlobalTime);
}
float Distance(vec3 p, vec2 a, vec2 b, vec2 c, vec2 d, vec2 e, float r) 
{
    vec2 pos = Position(p.z, a, b, c, d);
    float radius = max(5.0, r + sin(p.z * e.x) * e.y) / 10000.0;
    return radius / dot(p.xy - pos, p.xy - pos);
}
float Dist2D(vec3 pos) 
{
    float d = 0.0;
    d += Distance(pos, cama, camb, camc, camd, vec2(2.1913, 15.4634), 70.0000);
    d += Distance(pos, lighta, lightb, lightc, lightd, vec2(0.3814, 12.7206), 17.0590);
    d += Distance(pos, vec2(2.7377, -1.2462), vec2(-0.1914, -0.2339), vec2(-1.3698, -0.6855), vec2(0.1049, -0.1347), vec2(-1.1157, 13.6200), 27.3718);
    d += Distance(pos, vec2(-2.3815, 0.2382), vec2(-0.1528, -0.1475), vec2(0.9996, -2.1459), vec2(-0.0566, -0.0854), vec2(0.3287, 12.1713), 21.8130);
    d += Distance(pos, vec2(-2.7424, 4.8901), vec2(-0.1257, 0.2561), vec2(-0.4138, 2.6706), vec2(-0.1355, 0.1648), vec2(2.8162, 14.8847), 32.2235);
    d += Distance(pos, vec2(-2.2158, 4.5260), vec2(0.2834, 0.2319), vec2(4.2578, -2.5997), vec2(-0.0391, -0.2070), vec2(2.2086, 13.0546), 30.9920);
    d += Distance(pos, vec2(0.9824, 4.4131), vec2(0.2281, -0.2955), vec2(-0.6033, 0.4780), vec2(-0.1544, 0.1360), vec2(3.2020, 12.2138), 29.1169);
    d += Distance(pos, vec2(1.2733, -2.4752), vec2(-0.2821, -0.1180), vec2(3.4862, -0.7046), vec2(0.0224, 0.2024), vec2(-2.2714, 9.7317), 6.3008);
    d += Distance(pos, vec2(2.6860, 2.3608), vec2(-0.1486, 0.2376), vec2(2.0568, 1.5440), vec2(0.0367, 0.1594), vec2(-2.0396, 10.2225), 25.5348);
    d += Distance(pos, vec2(0.5009, 0.9612), vec2(0.1818, -0.1669), vec2(0.0698, -2.0880), vec2(0.1424, 0.1063), vec2(1.7980, 11.2733), 35.7880);
    return d;
}
vec3 nmap(vec2 t, sampler2D tx, float str) 
{
    float d = 1.0 / 1024.0;
    float xy = texture2D(tx, t).x;
    float x2 = texture2D(tx, t + vec2(d, 0)).x;
    float y2 = texture2D(tx, t + vec2(0, d)).x;
    float s = (1.0 - str) * 1.2;
    s *= s;
    s *= s;
    return normalize(vec3(x2 - xy, y2 - xy, s / 8.0));
}
void main() 
{
    float iGlobalTime = iGlobalTime / 3.0 + 291.0;
    vec2 p1 = Position(iGlobalTime + 0.05, cama, camb, camc, camd);
    vec3 Pos = Position3D(iGlobalTime, cama, camb, camc, camd);
    vec3 oPos = Pos;
    vec3 CamDir = normalize(vec3(p1.x - Pos.x, -p1.y + Pos.y, 0.1));
    vec3 CamRight = normalize(cross(CamDir, vec3(0, 1, 0)));
    vec3 CamUp = normalize(cross(CamRight, CamDir));
    mat3 cam = mat3(CamRight, CamUp, CamDir);
    //vec2 uv = 2.0 * vUv.xy / iResolution.xy - 1.0;

    vec2 uv = ((vUv - 0.5) * 2.0) * vec2(iResolution.z, 1.0);


    //vec2 uv = gl_FragCoord.xy / iResolution.xy;
    //uv = 1.0 - uv * 2.0;
    //uv.x *= iResolution.x / iResolution.y;   
    //uv.y *= -1.;

    float aspect = iResolution.z;
    vec3 Dir = normalize(vec3(uv * vec2(aspect, 1.0), 1.0)) * cam;
    float fade = 0.0;
    const float numit = 75.0;
    const float threshold = 1.20;
    const float scale = 1.5;
    vec3 Posm1 = Pos;
    for (float x = 0.0; x < numit; x++) 
    {
        if (Dist2D(Pos) < threshold) 
        {
            fade = 1.0 - x / numit;
            break;
        }
         Posm1 = Pos;
        Pos += Dir / numit * scale;
    }
    for (int x = 0; x < 6; x++) 
    {
        vec3 p2 = (Posm1 + Pos) / 2.0;
        if (Dist2D(p2) < threshold) Pos = p2;
 else Posm1 = p2;
    }
    vec3 n = normalize(vec3(Dist2D(Pos + vec3(0.01, 0, 0)) - Dist2D(Pos + vec3(-0.01, 0, 0)), Dist2D(Pos + vec3(0, 0.01, 0)) - Dist2D(Pos + vec3(0, -0.01, 0)), Dist2D(Pos + vec3(0, 0, 0.01)) - Dist2D(Pos + vec3(0, 0, -0.01))));
    vec3 tpn = normalize(max(vec3(0.0), (abs(n.xyz) - vec3(0.2)) * 7.0)) * 0.5;
    vec3 lp = Position3D(iGlobalTime + 0.5, cama, camb, camc, camd);
    vec3 ld = lp - Pos;
    float lv = 1.0;
    const float ShadowIT = 15.0;
    for (float x = 1.0; x < ShadowIT; x++) if (Dist2D(Pos + ld * (x / ShadowIT)) < threshold) 
    {
        lv = 0.0;
        break;
    }
     vec3 tuv = Pos * vec3(3.0, 3.0, 1.5);
    float nms = 0.19;
    vec3 nmx = nmap(tuv.yz, iChannel2, nms) + nmap(-tuv.yz, iChannel2, nms);
    vec3 nmy = nmap(tuv.xz, iChannel3, nms) + nmap(-tuv.xz, iChannel3, nms);
    vec3 nmz = nmap(tuv.xy, iChannel4, nms) + nmap(-tuv.xy, iChannel4, nms);
    vec3 nn = normalize(nmx * tpn.x + nmy * tpn.y + nmz * tpn.z);
    float dd;
    dd = max(0.0, dot(nn, normalize(ld * mat3(vec3(1, 0, 0), vec3(0, 0, 1), n))));
    vec4 diff = vec4(dd * 1.2 * lv) + vec4(0.2);
    float w = pow(dot(normalize(Pos - oPos), normalize(lp - oPos)), 5000.0);
    if (length(Pos - oPos) < length(lp - oPos)) w = 0.0;
     vec4 tx = texture2D(iChannel2, tuv.yz) + texture2D(iChannel2, -tuv.yz);
    vec4 ty = texture2D(iChannel3, tuv.xz) + texture2D(iChannel3, -tuv.xz);
    vec4 tz = texture2D(iChannel4, tuv.xy) + texture2D(iChannel4, -tuv.xy);
    vec4 col = tx * tpn.x + ty * tpn.y + tz * tpn.z;
    gl_FragColor = col * diff * min(1.0, fade * 10.0) + w;
}
