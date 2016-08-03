#define CONTRAST 1.4
#define SATURATION 1.4
#define BRIGHTNESS 1.2

precision highp float;
varying vec2 vUv;
uniform float time;
uniform vec4 mouse;
uniform vec3 resolution;
vec3 sunLight = normalize(vec3(0.35, 0.1, 0.7));
vec3 cameraPos;
vec3 sunColour = vec3(1.0, .75, .4);
const mat2 rotate2D = mat2(1.732, 1.323, -1.523, 1.652);
float gTime = 0.0;
float Hash(float n) 
{
    return fract(sin(n) * 56753.545383);
}
float Hash(vec2 p) 
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 63758.5453);
}
vec3 NoiseD(in vec2 x) 
{
    vec2 p = floor(x);
    vec2 u = fract(x);
    float n = p.x + p.y * 57.0;
    float a = Hash(n + 0.0);
    float b = Hash(n + 1.0);
    float c = Hash(n + 57.0);
    float d = Hash(n + 58.0);
    return vec3(a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y, 30.0 * u * u * (u * (u - 2.0) + 1.0) * (vec2(b - a, c - a) + (a - b - c + d) * u.yx));
}
float Terrain(in vec2 p) 
{
    float type = 0.0;
    vec2 pos = p * 0.004;
    float w = 60.0;
    float f = .0;
    vec2 d = vec2(0.0);
    for (int i = 0; i < 5; i++) 
    {
        vec3 n = NoiseD(pos);
        d += n.yz;
        f += w * n.x / (1.0 + dot(d, d));
        w = w * 0.52;
        pos = rotate2D * pos;
    }
    return f;
}
float Terrain2(in vec2 p, in float sphereR) 
{
    float type = 0.0;
    vec2 pos = p * 0.004;
    float w = 60.0;
    float f = .0;
    vec2 d = vec2(0.0);
    int t = 10 - int(sphereR);
    if (t < 5) t = 5;
     for (int i = 0; i < 10; i++) 
    {
        if (i > t) continue;
         vec3 n = NoiseD(pos);
        d += n.yz;
        f += w * n.x / (1.0 + dot(d, d));
        w = w * 0.52;
        pos = rotate2D * pos;
    }
    return f;
}
float Map(in vec3 p) 
{
    float h = Terrain(p.xz);
    return p.y - h;
}
vec3 GetSky(in vec3 rd) 
{
    float sunAmount = max(dot(rd, sunLight), 0.0);
    float v = pow(1.0 - max(rd.y, 0.0), 6.);
    vec3 sky = mix(vec3(.2), vec3(.42, .2, .1), v);
    sky *= smoothstep(-0.3, .0, rd.y);
    sky = sky + sunColour * sunAmount * sunAmount * .25;
    sky = sky + sunColour * min(pow(sunAmount, 800.0) * 1.5, .3);
    return clamp(sky, 0.0, 1.0);
}
float SphereRadius(float t) 
{
    t = abs(t - 60.0);
    return max(t * t * 0.0002, 0.2);
}
float Linstep(float a, float b, float t) 
{
    return clamp((t - a) / (b - a), 0., 1.);
}
vec3 DoLighting(in vec3 mat, in vec3 normal, in vec3 eyeDir) 
{
    float h = dot(sunLight, normal);
    return mat * sunColour * (max(h, 0.0) + .1);
}
vec4 Scene(in vec3 rO, in vec3 rD) 
{
    float t = 0.0;
    float alpha;
    vec4 normal = vec4(0.0);
    vec3 p = vec3(0.0);
    for (int j = 0; j < 100; j++) 
    {
        if (normal.w > .8 || t > 600.0) break;
         p = rO + t * rD;
        float sphereR = SphereRadius(t);
        float h = Map(p);
        h += sphereR * .5;
        if (h < sphereR) 
        {
            vec2 j = vec2(sphereR * .5, 0.0);
            vec3 nor = vec3(0.0, Terrain2(p.xz, sphereR), 0.0);
            vec3 v2 = nor - vec3(j.x, Terrain2(p.xz + j, sphereR), 0.0);
            vec3 v3 = nor - vec3(0.0, Terrain2(p.xz - j.yx, sphereR), -j.x);
            nor = cross(v2, v3);
            nor = normalize(nor);
            alpha = (1.0 - normal.w) * Linstep(-sphereR, sphereR, -h);
            normal += vec4(nor * alpha, alpha);
        }
         t += h * .75 + .1;
    }
    normal.w = clamp(normal.w * 1.25, 0.0, 1.0);
    return normal;
}
vec3 CameraPath(float t) 
{
    vec2 p = vec2(200.0 * sin(3.54 * t), 200.0 * cos(2.0 * t));
    return vec3(p.x + 25.0, 0.0 + sin(t * .3) * 6.5, 0.0 + p.y);
}
vec3 PostEffects(vec3 rgb, vec2 xy) 
{
    rgb = pow(rgb, vec3(0.45));
    rgb = mix(vec3(.5), mix(vec3(dot(vec3(.2125, .7154, .0721), rgb * BRIGHTNESS)), rgb * BRIGHTNESS, SATURATION), CONTRAST);
    rgb *= .4 + 0.5 * pow(40.0 * xy.x * xy.y * (1.0 - xy.x) * (1.0 - xy.y), 0.2);
    return rgb;
}
void main(void) 
{
    float gTime = (time * 5.0 + 2352.0) * .006;
    float hTime = time;
    vec2 xy = vUv.xy / resolution.xy;

    //vec2 uv = gl_FragCoord.xy / resolution.xy;
    //uv = 1.0 - uv * 2.0;
   // uv.x *= resolution.x / resolution.y;   
    //uv.y *= -1.;

    //vec2 uv = (1.0 - vUv * 2.0) * vec2(resolution.x / resolution.y, -1.0);
    vec2 uv = ((vUv - 0.5) * 2.0) * vec2(resolution.z, 1.0);

    //vec2 uv = (-1.0 + 2.0 * xy) * vec2(resolution.x / resolution.y, 1.0);
    vec3 camTar;
    cameraPos = CameraPath(gTime + 0.0);
    float height = max(0.0, 9.0 - hTime) * 16.0;
    camTar = CameraPath(gTime + .3);
    cameraPos.y += height * 2.0 - 5.0;
    float t = Terrain(CameraPath(gTime + .009).xz) + 10.0;
    if (cameraPos.y < t) cameraPos.y = t;
     camTar.y = cameraPos.y - height * 1.0;
    float roll = .4 * sin(gTime + .5);
    vec3 cw = normalize(camTar - cameraPos);
    vec3 cp = vec3(sin(roll), cos(roll), 0.0);
    vec3 cu = cross(cw, cp);
    vec3 cv = cross(cu, cw);
    vec3 dir = normalize(uv.x * cu + uv.y * cv + 1.3 * cw);
    mat3 camMat = mat3(cu, cv, cw);
    vec3 col;
    float distance;
    vec4 normal;
    normal = Scene(cameraPos, dir);
    normal.xyz = normalize(normal.xyz);
    col = mix(vec3(.45, 0.4, 0.3), vec3(.2, 0.05, 0.0), smoothstep(0.5, 1.5, (normal.y)));
    col += vec3(0.3, 0.3, 0.3) * clamp(normal.z, 0.0, 1.0);
    if (normal.w > 0.0) col = DoLighting(col, normal.xyz, dir);
     col = mix(GetSky(dir), col, normal.w);
    float bri = dot(cw, sunLight) * .7;
    if (bri > 0.0) 
    {
        vec2 sunPos = (-camMat * sunLight).xy;
        bri = pow(bri, 7.0) * .8;
        float glare1 = max(dot(normalize(vec3(dir.x, dir.y + .3, dir.z)), sunLight), 0.0) * 1.4;
        float glare2 = max(1.0 - length(sunPos - uv * 2.1), 0.0);
        float glare3 = max(sin(smoothstep(-0.4, .7, length(sunPos + uv * 2.5)) * 3.0), 0.0);
        col += bri * vec3(1.0, .0, .0) * pow(glare1, 12.5) * .05;
        col += bri * vec3(1.0, 1.0, 0.0) * pow(glare2, 3.0) * 4.0;
        col += bri * vec3(1.0, 1.0, 1.0) * pow(glare3, 33.9) * .7;
    }
     col = PostEffects(col, xy);
    gl_FragColor = vec4(col, 1.0);
}