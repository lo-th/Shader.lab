#define GAMMA (2.2)

//precision highp float;
//precision highp int;

uniform sampler2D iChannel3;
uniform sampler2D iChannel0;
uniform vec3 resolution;
uniform vec4 mouse;
uniform float time;
varying vec2 vUv;


const int Key_M = 77;
const int Key_E = 69;
const int Key_P = 80;
const int Key_L = 76;
const int Key_S = 83;
const int Key_A = 65;
const int Key_R = 82;
const int Key_O = 79;
const int Key_C = 67;
const int Key_N = 78;
const vec3 lightDir = vec3(-2, 2, .5);
const vec3 lightColour = vec3(1.0);
const vec3 fillLightDir = vec3(0, 1, 0);
const vec3 fillLightColour = vec3(.65, .7, .8) * .7;
const float tau = 6.28318530717958647692;

float Noise( in vec3 x );
vec2 Noise2( in vec3 x );

//float Noise(in vec3 x) vec2 Noise2(in vec3 x)
//{
 //   return pow(col, vec3(GAMMA));
//}

vec3 ToLinear( in vec3 col )
{
    // simulate a monitor, converting colour values into light values
    return pow( col, vec3(GAMMA) );
}

vec3 ToGamma(in vec3 col) 
{
    return pow(col, vec3(1.0 / GAMMA));
}

bool ReadKey(int key, bool toggle) 
{
    float keyVal = 0.0;//texture2D(iChannel3, vec2((float(key) + .5) / 256.0, toggle ? .75 : .25)).x;
    return (keyVal > .5) ? true : false;
}
const vec3 CamPos = vec3(0, 0.0, -250.0);
const vec3 CamLook = vec3(0, 0, 0);
const float CamZoom = 10.0;
const float NearPlane = 0.0;
const float drawDistance = 1000.0;
const vec3 SkyColour = vec3(.4, .25, .2);
vec3 SkyDome(vec3 rd) 
{
    vec3 result = ToLinear(SkyColour) * 2.0 * Noise(rd);
    result = mix(result, vec3(8), smoothstep(.8, 1.0, rd.y / max((rd.x + 1.0), abs(rd.z))));
    return result;
}
const float IrisAng = tau / 12.0;
const float PupilAng = (1.6 * IrisAng / 5.0);
const float EyeRadius = 10.0;
const float BulgeRadius = 6.0;
vec4 ComputeEyeRotation() 
{
    vec2 rot;
    if (!ReadKey(Key_M, true) && mouse.w > .00001) rot = .25 * vec2(1.0, 1.0) * tau * (mouse.xy - resolution.xy * .5) / resolution.x;
 else 
    {
        float time = time / 2.0;
        time += Noise(vec3(0, time, 0));
        float flick = floor(time) + smoothstep(0.0, 0.05, fract(time));
        rot = vec2(.2, .1) * tau * (texture2D(iChannel0, vec2((flick + .5) / 256.0, .5), -100.0).rb - .5);
    }
    return vec4(cos(rot.x), sin(rot.x), cos(rot.y), sin(rot.y));
}
vec3 ApplyEyeRotation(vec3 pos, vec4 rotation) 
{
    pos.yz = rotation.z * pos.yz + rotation.w * pos.zy * vec2(1, -1);
    pos.xz = rotation.x * pos.xz + rotation.y * pos.zx * vec2(1, -1);
    return pos;
}
float Isosurface(vec3 pos, vec4 eyeRotation) 
{
    pos = ApplyEyeRotation(pos, eyeRotation);
    vec2 slice = vec2(length(pos.xy), pos.z);
    float aa = atan(slice.x, -slice.y);
    float bulge = cos(tau * .2 * aa / IrisAng);
    bulge = bulge * .8 - .8;
    bulge *= smoothstep(tau * .25, 0.0, aa);
    bulge += cos(tau * .25 * aa / IrisAng) * .5 * smoothstep(-.02, .1, IrisAng - aa);
    return length(slice) - EyeRadius - bulge;
}
float GetEyelidMask(vec3 pos, vec4 eyeRotation) 
{
    vec3 eyelidPos = pos;
    float eyelidTilt = -.05;
    eyelidPos.xy = cos(eyelidTilt) * pos.xy + sin(eyelidTilt) * pos.yx * vec2(1, -1);
    float highLid = tan(max(tau * .05, asin(eyeRotation.w) + IrisAng + .05));
    float lowLid = tan(tau * .1);
    float blink = smoothstep(.0, .02, abs(Noise(vec3(time * .2, 0, 0)) - .5));
    highLid *= blink;
    lowLid *= blink;
    return min((-eyelidPos.z - 2.0) - (-eyelidPos.y / lowLid), (-eyelidPos.z - 2.0) - (eyelidPos.y / highLid));
}
float GetIrisPattern(vec2 uv) 
{
    return Noise(vec3(10.0 * uv / pow(length(uv), .7), 0));
}
vec3 Shading(vec3 worldPos, vec3 norm, float shadow, vec3 rd, vec4 eyeRotation) 
{
    vec3 view = normalize(-rd);
    float eyelidMask = GetEyelidMask(worldPos, eyeRotation);
    if (eyelidMask < 0.0 || (-worldPos.z - 3.0) < (worldPos.x / tan(tau * .23))) 
    {
        return ToLinear(SkyColour);
    }
     vec3 pos = ApplyEyeRotation(worldPos, eyeRotation);
    float lenposxy = length(pos.xy);
    float ang = atan(lenposxy / (-pos.z));
    if (ang < 0.0) ang += tau / 2.0;
     vec3 irisRay = ApplyEyeRotation(-view, eyeRotation);
    vec3 localNorm = ApplyEyeRotation(norm, eyeRotation);
    float a = dot(irisRay, localNorm);
    float b = cos(acos(a) * 1.33);
    if (!ReadKey(Key_E, true)) irisRay += localNorm * (b - a);
     irisRay = normalize(irisRay);
    float planeDist = -cos(IrisAng) * EyeRadius;
    float t = (planeDist - pos.z) / irisRay.z;
    vec3 ppos = t * irisRay + pos;
    float rad = length(ppos.xy);
    float pupilr = EyeRadius * sin(PupilAng);
    float irisr = EyeRadius * sin(IrisAng);
    float irisPattern = GetIrisPattern(ppos.xy);
    vec3 iris = ToLinear(mix(pow(vec3(.65, .82, .85), 2.0 * vec3(1.2 - sqrt(irisPattern))), vec3(1, .5, .2), .7 * pow(mix(smoothstep(pupilr, irisr, rad), Noise(ppos), .7), 2.0)));
    if (ReadKey(Key_C, true)) iris = vec3(1);
     iris *= pow(smoothstep(irisr + 1.0, irisr - 1.5, rad), GAMMA);
    vec3 irisNorm;
    irisNorm.x = GetIrisPattern(ppos.xy + vec2(-.001, 0)) - GetIrisPattern(ppos.xy + vec2(.001, 0));
    irisNorm.y = GetIrisPattern(ppos.xy + vec2(0, -.001)) - GetIrisPattern(ppos.xy + vec2(0, .001));
    irisNorm.xy += -.01 * normalize(ppos.xy) * sin(1. * tau * rad / irisr);
    irisNorm.z = -.15;
    irisNorm = normalize(irisNorm);
    if (ReadKey(Key_N, true)) irisNorm = vec3(0, 0, -1);
     vec3 lightDirN = normalize(lightDir);
    vec3 localLightDir = ApplyEyeRotation(lightDirN, eyeRotation);
    vec3 fillLightDirN = normalize(fillLightDir);
    vec3 localFillLightDir = ApplyEyeRotation(fillLightDirN, eyeRotation);
    float photonsL, photonsFL;
    if (!ReadKey(Key_P, true)) 
    {
        if (!ReadKey(Key_L, true)) 
        {
            vec3 nn = normalize(vec3(ppos.xy, -sqrt(max(0.0, BulgeRadius * BulgeRadius - rad * rad))));
            vec3 irisLDir = localLightDir;
            vec3 irisFLDir = localFillLightDir;
            float d = dot(nn, irisLDir);
            irisLDir += nn * (cos(acos(d) / 1.33) - d);
            d = dot(nn, irisFLDir);
            irisFLDir += nn * (cos(acos(d) / 1.33) - d);
            irisLDir = normalize(irisLDir);
            irisFLDir = normalize(irisFLDir);
            photonsL = smoothstep(0.0, 1.0, dot(irisNorm, irisLDir));
            photonsFL = (dot(irisNorm, irisFLDir) * .5 + .5);
        }
 else 
        {
            vec3 irisLDir = localLightDir;
            vec3 irisFLDir = localFillLightDir;
            irisLDir.z = -cos(acos(-irisLDir.z) / 1.5);
            irisFLDir.z = -cos(acos(-irisFLDir.z) / 1.5);
            irisLDir = normalize(irisLDir);
            irisFLDir = normalize(irisFLDir);
            photonsL = smoothstep(0.0, 1.0, dot(irisNorm, irisLDir));
            photonsFL = (dot(irisNorm, irisFLDir) * .5 + .5);
            photonsL *= .3 + .7 * smoothstep(1.2, .9, length(ppos.xy / irisr + .2 * irisLDir.xy / (irisLDir.z - .05)));
        }
    }
 else 
    {
        photonsL = max(0.0, dot(irisNorm, localLightDir));
        photonsFL = .5 + .5 * dot(irisNorm, localLightDir);
    }
    vec3 l = ToLinear(lightColour) * photonsL;
    vec3 fl = ToLinear(fillLightColour) * photonsFL;
    vec3 ambientOcclusion = vec3(1);
    vec3 eyelidShadow = vec3(1);
    if (!ReadKey(Key_A, true)) 
    {
        ambientOcclusion = mix(vec3(1), ToLinear(vec3(.8, .7, .68)), pow(smoothstep(5.0, 0.0, eyelidMask), 1.0));
        eyelidShadow = mix(vec3(1), ToLinear(vec3(.8, .7, .68)), smoothstep(2.0, -2.0, GetEyelidMask(worldPos + lightDir * 1.0, eyeRotation)));
    }
     fl *= ambientOcclusion;
    l *= eyelidShadow;
    iris *= l + fl;
    iris *= smoothstep(pupilr - .01, pupilr + .5, rad);
    float theta = atan(pos.x, pos.y);
    theta += Noise(pos * 1.0) * tau * .03;
    float veins = (sin(theta * 60.0) * .5 + .5);
    veins *= veins;
    veins *= (sin(theta * 13.0) * .5 + .5);
    veins *= smoothstep(IrisAng, tau * .2, ang);
    veins *= veins;
    veins *= .5;
    vec3 sclera = mix(ToLinear(vec3(1, .98, .96)), ToLinear(vec3(.9, .1, 0)), veins);
    float ndotl = dot(norm, lightDirN);
    l = pow(ToLinear(vec3(.5, .3, .25)), vec3(mix(3.0, 0.0, smoothstep(-1.0, .2, ndotl))));
    if (ReadKey(Key_S, true)) l = vec3(max(0.0, ndotl));
     l *= ToLinear(lightColour);
    fl = ToLinear(fillLightColour) * (dot(norm, fillLightDirN) * .5 + .5);
    fl *= ambientOcclusion;
    l *= eyelidShadow;
    sclera *= l + fl;
    float blend = smoothstep(-.1, .1, ang - IrisAng);
    vec3 result = mix(iris, sclera, blend);
    vec3 bumps;
    bumps.xy = .7 * Noise2(pos * 3.0);
    bumps.z = sqrt(1.0 - dot(bumps.xy, bumps.xy));
    bumps = mix(vec3(0, 0, 1), bumps, blend);
    norm.xy += bumps.xy * .1;
    norm = normalize(norm);
    float glossiness = mix(.7, 1.0, bumps.z);
    float ndoti = dot(view, norm);
    vec3 rr = -view + 2.0 * ndoti * norm;
    vec3 reflection = SkyDome(rr);
    vec3 h = normalize(view + lightDir);
    float specular = pow(max(0.0, dot(h, norm)), 2000.0);
    reflection += specular * 32.0 * glossiness * ToLinear(lightColour);
    float eyelidReflection = smoothstep(.8, 1.0, GetEyelidMask(normalize(worldPos + rd * 2.0) * EyeRadius, eyeRotation));
    if (!ReadKey(Key_O, true)) reflection *= eyelidReflection;
     float fresnel = mix(.04 * glossiness, 1.0, pow(1.0 - ndoti, 5.0));
    if (!ReadKey(Key_R, true)) result = mix(result, reflection, fresnel);
     float mask2 = min(eyelidMask, (-worldPos.z - 3.0) - (worldPos.x / tan(tau * .23)));
    result = mix(ToLinear(SkyColour), result, smoothstep(.0, .3, mask2));
    return result;
}
const float epsilon = .003;
const float normalPrecision = .1;
const float shadowOffset = .1;
const int traceDepth = 100;
vec2 Noise2(in vec3 x) 
{
    vec3 p = floor(x.xzy);
    vec3 f = fract(x.xzy);
    f = f * f * (3.0 - 2.0 * f);
    vec2 uv = (p.xy + vec2(37.0, 17.0) * p.z) + f.xy;
    vec4 rg = texture2D(iChannel0, (uv + 0.5) / 256.0, -100.0);
    return mix(rg.yw, rg.xz, f.z);
}
float Noise(in vec3 x) 
{
    return Noise2(x).x;
}
float Trace(vec3 ro, vec3 rd, vec4 eyeRotation) 
{
    float t = 0.0;
    float dist = 1.0;
    for (int i = 0; i < traceDepth; i++) 
    {
        if (abs(dist) < epsilon || t > drawDistance || t < 0.0) continue;
         dist = Isosurface(ro + rd * t, eyeRotation);
        t = t + dist;
    }
    return t;
}
vec3 GetNormal(vec3 pos, vec4 eyeRotation) 
{
    const vec2 delta = vec2(normalPrecision, 0);
    vec3 n;
    n.x = Isosurface(pos + delta.xyy, eyeRotation) - Isosurface(pos - delta.xyy, eyeRotation);
    n.y = Isosurface(pos + delta.yxy, eyeRotation) - Isosurface(pos - delta.yxy, eyeRotation);
    n.z = Isosurface(pos + delta.yyx, eyeRotation) - Isosurface(pos - delta.yyx, eyeRotation);
    return normalize(n);
}
vec3 GetRay(vec3 dir, float zoom, vec2 uv) 
{
    uv = uv - .5;
    uv.x *= resolution.x / resolution.y;
    dir = zoom * normalize(dir);
    vec3 right = normalize(cross(vec3(0, 1, 0), dir));
    vec3 up = normalize(cross(dir, right));
    return dir + right * uv.x + up * uv.y;
}
void main() {

    //vec2 uv = vUv.xy / resolution.xy;
    vec2 uv = ((vUv - 0.5) * 2.0) * vec2(resolution.z, 1.0);
    vec3 camPos = CamPos;
    vec3 camLook = CamLook;
    vec2 camRot = .5 * tau * (mouse.xy - resolution.xy * .5) / resolution.x;
    if (!ReadKey(Key_M, true)) camRot = vec2(0, 0);
     camPos.yz = cos(camRot.y) * camPos.yz + sin(camRot.y) * camPos.zy * vec2(1, -1);
    camPos.xz = cos(camRot.x) * camPos.xz + sin(camRot.x) * camPos.zx * vec2(1, -1);
    vec4 eyeRotation = ComputeEyeRotation();
    if (Isosurface(camPos, eyeRotation) <= 0.0) 
    {
        gl_FragColor = vec4(0, 0, 0, 0);
        return;
    }
     vec3 ro = camPos;
    vec3 rd;
    rd = GetRay(camLook - camPos, CamZoom, uv);
    ro += rd * (NearPlane / CamZoom);
    rd = normalize(rd);
    float t = Trace(ro, rd, eyeRotation);
    vec3 result = ToLinear(SkyColour);
    if (t > 0.0 && t < drawDistance) 
    {
        vec3 pos = ro + t * rd;
        vec3 norm = GetNormal(pos, eyeRotation);
        float shadow = 1.0;
        if (Trace(pos + lightDir * shadowOffset, lightDir, eyeRotation) < drawDistance) shadow = 0.0;
         result = Shading(pos, norm, shadow, rd, eyeRotation);
    }
     gl_FragColor = vec4(ToGamma(result), 1.0);
}
