



const float dispValue = .7;
const float dispOffset = .5;
const float sphereBaseRadius = .6;
const vec3 ld = vec3(1, 1, .5);
float hash(vec3 p) 
{
    float h = dot(p, vec3(127.1, 311.7, 79.1));
    return fract(sin(h) * 43758.5453123);
}
vec3 rotateY(vec3 v, float t) 
{
    float cost = cos(t);
    float sint = sin(t);
    return vec3(v.x * cost + v.z * sint, v.y, -v.x * sint + v.z * cost);
}
vec3 rotateX(vec3 v, float t) 
{
    float cost = cos(t);
    float sint = sin(t);
    return vec3(v.x, v.y * cost - v.z * sint, v.y * sint + v.z * cost);
}
float noise(in vec3 p) 
{
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float v = mix(mix(mix(hash(i + vec3(0., 0., 0.)), hash(i + vec3(1., 0., 0.)), u.x), mix(hash(i + vec3(0., 1., 0.)), hash(i + vec3(1., 1., 0.)), u.x), u.y), mix(mix(hash(i + vec3(0., 0., 1.)), hash(i + vec3(1., 0., 1.)), u.x), mix(hash(i + vec3(0., 1., 1.)), hash(i + vec3(1., 1., 1.)), u.x), u.y), u.z);
    v = v * 2. - .5;
    float cv = abs(cos(v));
    float sv = abs(sin(v));
    v = mix(sv, cv, sv);
    return v;
}
float noiseLayer(vec3 p) 
{
    float freq = 1.2;
    const int iter = 11;
    float lacunarity = 1.;
    float v = 0.;
    float sum = 0.;
    for (int i = 0; i < iter; i++) 
    {
        float layerUp = 1. / pow(freq, lacunarity);
        v += noise(p * freq) * layerUp;
        sum += layerUp;
        freq *= 1.8;
    }
    v /= sum;
    return v;
}
float map(vec3 p) 
{
    p = rotateX(p, iMouse.y / 100. + iGlobalTime / 7.);
    p = rotateY(p, iMouse.x / 100. + iGlobalTime / 7.);
    float iGlobalTimeOffset = iGlobalTime / 70.;
    return noiseLayer(p + iGlobalTimeOffset) - dispOffset;
}
vec3 calcNormal(in vec3 pos, float t) 
{
    vec2 eps = vec2(0.005 * t, 0.0);
    return normalize(vec3(map(pos + eps.xyy) - map(pos - eps.xyy), map(pos + eps.yxy) - map(pos - eps.yxy), map(pos + eps.yyx) - map(pos - eps.yyx)));
}
float shadowRay(vec3 startP, vec3 lightDir) 
{
    float t = 0.0;
    float shadowHardness = 10.;
    float minD = 1.;
    for (int r = 0; r < 8; ++r) 
    {
        vec3 p = startP + vec3(t * lightDir.x, t * lightDir.y, t * lightDir.z) + normalize(startP) / shadowHardness;
        vec3 pp = normalize(p) * sphereBaseRadius;
        float sp = sphereBaseRadius + map(pp) * dispValue;
        float d = length(p) - sp;
        minD = min(minD, d);
        if (d < 0.0) 
        {
            break;
        }
         t += 0.08;
    }
    return smoothstep(0., 1.0, minD * shadowHardness);
}
vec3 skyColor(vec2 uv, float minD) 
{
    float stars = ((1. - noiseLayer(vec3(uv * 100. + iGlobalTime / 40., 0.))) * 10. - 8.);
    float stars2 = ((1. - noiseLayer(vec3(uv * 30. + iGlobalTime / 120., 3.))) * 10. - 8.8);
    vec3 sky = max(0., stars) * vec3(0.2, 0.5, .6);
    sky += max(0., stars2 * 10.) * vec3(1., .8, .5);
    float halo = (1. - length(uv * 0.7)) * 2.;
    sky *= halo;
    minD = 1. - minD;
    minD = pow(minD, 3.) * .3;
    sky += minD * vec3(1., .25, .2);
    return sky;
}
void main() 
{
    //vec2 uv = vUv.xy * 2.0 / iResolution.xy - 1.0;
    //uv.x *= iResolution.x / iResolution.y;

    //vec2 uv = gl_FragCoord.xy / iResolution.xy;
   // uv = 1.0 - uv * 2.0;
   // uv.x *= iResolution.x / iResolution.y;   
    //uv.y *= -1.;

    vec2 uv = ((vUv - 0.5) * 2.0) * vec2(iResolution.z, 1.0);


    vec3 color = vec3(skyColor(uv, 0.));
    float minD = 1.;
    float t = 0.0;
    for (int r = 0; r < 16; ++r) 
    {
        vec3 p = vec3(uv.x, uv.y, -2. + t);
        vec3 pp = normalize(p) * sphereBaseRadius;
        float sp = sphereBaseRadius + map(pp) * dispValue;
        float d = length(p) - sp;
        minD = min(minD, d);
        if (d < 0.01) 
        {
            float rayCount = float(r);
            rayCount /= 16.;
            vec3 n = mix(calcNormal(pp, 0.1), calcNormal(pp, 10.), .5);
            float light1 = max(dot(n, -ld), .0) * 1.2;
            if (light1 > 0.1) 
            {
                light1 *= shadowRay(p, ld);
            }
             light1 += pow(light1, 15.) / 500.;
            color = vec3(0.4, 0.5, 0.6) * light1;
            color += max(dot(n, vec3(0, .5, 1)), .0) * .15 * vec3(.4, .5, .7);
            color += vec3(2.0, .35, 0.15) * pow(max(.0, -map(pp) + .2), 3.) * 8. * max(.0, 1. - n.z);
            color += pow(rayCount, 3.) * vec3(1., .25, .2);
            break;
        }
 else if (t > 4.) 
        {
            color = skyColor(uv, minD);
            break;
        }
         t += d;
    }

    #if defined( TONE_MAPPING ) 
    color = toneMapping( color ); 
    #endif

    gl_FragColor = vec4(color, 1.);
}
