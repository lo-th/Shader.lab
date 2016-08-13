
// https://www.shadertoy.com/view/XstXRj


const int MAX_INNER_REFLECTIONS = 8; // Kill framerate here
const float GLASS_IOR = 1.7;
const float GLASS_REFLECTION = 0.15;
const float GLASS_FRESNEL_POWER = 2.5;
const vec3 GLASS_ABSORPTION = vec3(0.08, 0.02, 0.01);
const float DISPERSION = 0.05;
const float EXPOSURE = 1.5;

vec3 BOARD_SIZE = vec3(4.5, 0.1, 4.5);
float BOARD_TOP = -3.0;
float BOARD_REFLECTION = 0.2;
vec3 LIGHT_DIR = normalize(vec3(-1.0, 3.0, -1.5));
vec3 SHADOW_COLOR = vec3(0.45, 0.45, 0.55);
vec3 SKY_COLOR = vec3(0.3, 0.4, 0.6);
vec3 GROUND_COLOR = vec3(0.2, 0.2, 0.1);

const vec3 RGB_IOR_MULTIPLIER = exp(DISPERSION * vec3(647.0, 510.0, 440.0) / 589.0);

const float PI = 3.1415926535897932384626433832795;
const float TAU = 2.0 * PI;
const float BIG = 1e15;
const float EPSILON = 1e-10;
const float THETA = 1.61803398875;
const float INV_THETA = 0.61803398875;

struct Ray
{
    vec3 o;
    vec3 d;
};
    
struct Intersection
{
    float dist;
    vec3 normal;
};

struct Result
{
    Intersection start;
    Intersection end;
};
    
mat4 rotateX(float v)
{
    float c = cos(v);
    float s = sin(v);
    
    return mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0,   c,   s, 0.0,
        0.0,  -s,   c, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 rotateY(float v)
{
    float c = cos(v);
    float s = sin(v);
    
    return mat4(
          c, 0.0,  -s, 0.0,
        0.0, 1.0, 0.0, 0.0,
          s, 0.0,   c, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 rotateZ(float v)
{
    float c = cos(v);
    float s = sin(v);
    
    return mat4(
          c,   s, 0.0, 0.0,
         -s,   c, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 translate(vec3 v)
{
    return mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        v.x, v.y, v.z, 1.0
    );
}

mat4 translate(float x, float y, float z)
{
    return translate(vec3(x, y, z));
}

mat4 scale(vec3 v)
{
    return mat4(
        v.x, 0.0, 0.0, 0.0,
        0.0, v.y, 0.0, 0.0,
        0.0, 0.0, v.z, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 scale(float x, float y, float z)
{
    return scale(vec3(x, y, z));
}

mat4 transpose(mat4 m)
{
    return mat4(
        m[0].x, m[1].x, m[2].x, m[3].x,
        m[0].y, m[1].y, m[2].y, m[3].y,
        m[0].z, m[1].z, m[2].z, m[3].z,
        m[0].w, m[1].w, m[2].w, m[3].w
    );
}

Ray transform(mat4 m, Ray ray)
{
    ray.o = (m * vec4(ray.o, 1.0)).xyz;
    ray.d = normalize((m * vec4(ray.d, 0.0)).xyz);
    
    return ray;
}

Intersection transform(mat4 m, mat4 itm, Ray ray, Intersection is)
{
    vec3 pos = ray.o + ray.d * is.dist;
    ray = transform(m, ray);
    pos = (m * vec4(pos, 1.0)).xyz;
    
    is.dist = dot(pos - ray.o, ray.d); 
    is.normal = normalize((itm * vec4(is.normal, 0.0)).xyz);
    
    return is;
}

Result transform(mat4 m, mat4 itm, Ray ray, Result r)
{
    r.start = transform(m, itm, ray, r.start);
    r.end = transform(m, itm, ray, r.end);
    return r;
}

Result intersect(Result a, Result b)
{
    Result result;
    result.start = a.start;
    result.end = a.end;
    
    if (b.start.dist > a.start.dist)
    {
        result.start = b.start;
    }
    
    if (b.end.dist < a.end.dist)
    {
        result.end = b.end;
    }
    
    return result;
}
    
Result sphere(vec3 center, float radius, Ray ray)
{
    ray.o -= center;
    
    float p = 2.0 * dot(ray.o, ray.d);
    float q = dot(ray.o, ray.o) - radius * radius;
    float r = p * p / 4.0 - q;
    
    Result result;
    result.start.dist = BIG;
    result.end.dist = -BIG;
    
    if (r >= 0.0)
    {
        float m = -p / 2.0;
        float sr = sqrt(r);
        result.start.dist = m - sr;
        result.start.normal = (ray.o + ray.d * result.start.dist) / radius;
        result.end.dist = m + sr;
        result.end.normal = (ray.o + ray.d * result.end.dist) / radius;
    }
    
    return result;
}

Result plane(vec3 pos, vec3 normal, Ray ray)
{
    ray.o -= pos;
    
    float rdn = dot(ray.d, normal);
    float ron = dot(ray.o, normal);
    
    Result result;
    result.start.normal = normal;
    result.end.normal = normal;
    
    if (ron > 0.0)
    {
        // Outside
        result.start.dist = BIG;
        result.end.dist = -BIG;
        
        if (abs(rdn) > EPSILON)
        {
            float d = -ron / rdn;
            
            if (d > 0.0)
            {
                result.start.dist = d;
                result.end.dist = BIG;
            }
            else
            {
                result.start.dist = -BIG;
                result.end.dist = d;
            }
        }
    }
    else
    {
        // Inside
        result.start.dist = -BIG;
        result.end.dist = BIG;
        
        if (abs(rdn) > EPSILON)
        {
            float d = -ron / rdn;
            
            if (d > 0.0)
            {
                result.start.dist = -BIG;
                result.end.dist = d;
            }
            else
            {
                result.start.dist = d;
                result.end.dist = BIG;
            }
        }
    }
    return result;
}

Result cube(vec3 center, vec3 size, Ray ray)
{
    Result r;
    r.start.dist = -BIG;
    r.end.dist = BIG;
    
    r = intersect(r, plane(center + size * vec3(1.0, 0.0, 0.0),  vec3(1.0, 0.0, 0.0),  ray));
    r = intersect(r, plane(center + size * vec3(0.0, 1.0, 0.0),  vec3(0.0, 1.0, 0.0),  ray));
    r = intersect(r, plane(center + size * vec3(0.0, 0.0, 1.0),  vec3(0.0, 0.0, 1.0),  ray));
    r = intersect(r, plane(center + size * vec3(-1.0, 0.0, 0.0), vec3(-1.0, 0.0, 0.0), ray));
    r = intersect(r, plane(center + size * vec3(0.0, -1.0, 0.0), vec3(0.0, -1.0, 0.0), ray));
    r = intersect(r, plane(center + size * vec3(0.0, 0.0, -1.0), vec3(0.0, 0.0, -1.0), ray));
    
    return r;
}

Result icosahedron(Ray ray)
{
    Result r;
    r.start.dist = -BIG;
    r.end.dist = BIG;
    
    vec3 n;
    
    // What's a for loop?
    n = normalize(vec3(1, 1, 1));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(1, 1, -1));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(1, -1, 1));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(1, -1, -1));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(-1, 1, 1));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(-1, 1, -1));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(-1, -1, 1));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(-1, -1, -1));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(0, INV_THETA, THETA));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(0, INV_THETA, -THETA));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(0, -INV_THETA, THETA));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(0, -INV_THETA, -THETA));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(INV_THETA, THETA, 0));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(INV_THETA, -THETA, 0));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(-INV_THETA, THETA, 0));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(-INV_THETA, -THETA, 0));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(THETA, 0, INV_THETA));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(-THETA, 0, INV_THETA));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(THETA, 0, -INV_THETA));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    n = normalize(vec3(-THETA, 0, -INV_THETA));
    r = intersect(r, plane(n, n, ray));
    if (r.start.dist > r.end.dist) return r;
    
    return r;
}

vec3 renderBackground(Ray ray)
{
    float tolight = pow(dot(ray.d, LIGHT_DIR) * 0.5 + 0.5, 6.0) * 5.0;
    vec3 color = vec3(tolight) + mix(GROUND_COLOR, SKY_COLOR, ray.d.y * 0.5 + 0.5);
    return mix(color, textureCube(iChannel0, ray.d).xyz, 0.2);
}

vec3 boardTexture(vec3 pos)
{
    float square = (fract(pos.x * 2.1) < 0.5 == fract(pos.z * 2.1) < 0.5) ? 0.0 : 1.0;
    if (abs(pos.x* 2.1) >= 2.0 || abs(pos.z * 2.1) >= 2.0)
    {
        square = 0.5;
    }
    
    vec3 base = mix(vec3(0.345, 0.245, 0.329), vec3(0.231, 0.176, 0.231), square);
    float scratches = texture2D(iChannel1, (scale(0.05, 0.05, 0.7) * rotateY(1.0) * vec4(pos, 1.0)).xz).x;
    scratches = smoothstep(0.6, 1.0, scratches) * 0.4;
    
    return mix(base * 1.3, vec3(0.9, 0.9, 0.9), scratches);
}

vec3 renderBoard(Ray ray, mat4 m, mat4 im, mat4 tm, mat4 itm)
{
    Result result = cube(vec3(0.0, BOARD_TOP - BOARD_SIZE.y, 0.0), BOARD_SIZE, ray);
    
    if (result.start.dist < 0.0 || result.start.dist >= result.end.dist)
    {
        return renderBackground(ray);
    }
    
    vec3 pos = ray.o + ray.d * result.start.dist;
    vec3 color = boardTexture(pos / BOARD_SIZE);
    
    Ray shadowRay;
    shadowRay.o = pos;
    shadowRay.d = -LIGHT_DIR;
    
    Ray shadowRayt = transform(m, shadowRay);
    Result shadowResult = icosahedron(shadowRayt);
    shadowResult = transform(im, tm, shadowRayt, shadowResult);
    
    float shadow = clamp(shadowResult.end.dist - shadowResult.start.dist, 0.0, 1.0);
    float spotlight1 = smoothstep(5.0, 0.0, length(pos.xz));
    float spotlight2 = smoothstep(10.0, 0.0, length(pos.xz));
    
    Ray reflectedRay;
    reflectedRay.o = pos;
    reflectedRay.d = reflect(ray.d, result.start.normal);
    
    vec3 reflection = renderBackground(reflectedRay);
    
    vec3 c = color * (dot(result.start.normal, LIGHT_DIR) + 1.0) * 0.5 * mix(vec3(spotlight2), SHADOW_COLOR, shadow * spotlight1);
    return mix(c, reflection, BOARD_REFLECTION);
}

vec3 renderIcosahedronInside(Ray ray, mat4 m, mat4 im, mat4 tm, mat4 itm, float wl)
{
    float dist = 0.0;
    Ray refractedRay;
    Result result;
    
    for (int i = 0; i < MAX_INNER_REFLECTIONS; i++)
    {
        Ray rayt = transform(m, ray);
        result = icosahedron(rayt);
        result = transform(im, tm, rayt, result);
        
        dist += result.end.dist - result.start.dist;

        vec3 pos = ray.o + ray.d * result.end.dist;
        
        refractedRay.o = pos;
        refractedRay.d = refract(ray.d, -result.end.normal, wl * GLASS_IOR);
        ray.o = pos;
        ray.d = reflect(ray.d, -result.end.normal);
        
        if (length(refractedRay.d) > EPSILON)
        {
            break;
        }
    }
    
    if (length(refractedRay.d) < EPSILON)
    {
        refractedRay.d = ray.d;
    }
    
    float fresnel = pow(1.0 - abs(dot(refractedRay.d, result.end.normal)), GLASS_FRESNEL_POWER);
    float reflectiveness = mix(fresnel, 1.0, GLASS_REFLECTION);
    
    return renderBoard(refractedRay, m, im, tm, itm) * exp(-dist * GLASS_ABSORPTION) * (1.0 - reflectiveness);
}

vec3 renderScene(Ray ray)
{
    float phase = fract(iGlobalTime * 0.5);
    float height = (phase - phase * phase) * 4.0 * 5.0;
    phase = fract(phase + 0.025);
    float squish = exp(-phase * 1.5) * sin(phase * 12.0) * 0.5;
    float s = exp(squish);
    float is = 1.0 / s;
    
    mat4 m = 
        rotateX(iGlobalTime * 0.6) * 
        rotateY(iGlobalTime * 0.4) *
        scale(is, s, is) *
        translate(0.0, -height - BOARD_TOP - 0.75, 0.0);
    mat4 im = 
        translate(0.0, height + BOARD_TOP + 0.75, 0.0)*
        scale(1.0 / is, 1.0 / s, 1.0 / is) *
        rotateY(-iGlobalTime * 0.4) * 
        rotateX(-iGlobalTime * 0.6);
    mat4 tm = transpose(m);
    mat4 itm = transpose(im);
    
    Ray rayt = transform(m, ray);
    Result result = icosahedron(rayt);
    result = transform(im, tm, rayt, result);
    
    if (result.start.dist > 0.0 && result.start.dist < result.end.dist)
    {   
        vec3 pos = ray.o + ray.d * result.start.dist;
        
        Ray reflectedRay;
        reflectedRay.o = pos;
        reflectedRay.d = reflect(ray.d, result.start.normal);
        float fresnel = pow(1.0 - abs(dot(ray.d, result.start.normal)), GLASS_FRESNEL_POWER);
        float reflectiveness = mix(fresnel, 1.0, GLASS_REFLECTION);
        
        vec3 fromInside;
        
        for (int i = 0; i < 3; i++)
        {
            float wl = RGB_IOR_MULTIPLIER[i];
            
            Ray refractedRay;
            refractedRay.o = pos;
            refractedRay.d = normalize(refract(ray.d, result.start.normal, 1.0 / (wl * GLASS_IOR)));
            
            
            vec3 c = renderIcosahedronInside(refractedRay, m, im, tm, itm, wl);
            fromInside[i] = c[i];
        }
        
        return fromInside + renderBoard(reflectedRay, m, im, tm, itm) * reflectiveness;
    }
    else
    {
        return renderBoard(ray, m, im, tm, itm);
    }
}

vec3 toneMap(vec3 color)
{
    return 1.0 - exp(-color * EXPOSURE);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    Ray ray;
    ray.o = vec3(0.0, 0.0, 0.0);
    ray.d = normalize(vec3((fragCoord.xy - iResolution.xy * 0.5) / iResolution.y, 1.0));
    
    ray = transform(
        rotateY(iGlobalTime * 0.05) * translate(0.0, 0.0, -9.0)
        /* * rotateY(-iMouse.x / iResolution.x + 0.5)  * rotateX(iMouse.y / iResolution.y - 0.5)*/,
        ray);
    
    vec3 color = renderScene(ray);
    color = toneMap(color);
    fragColor = vec4(color, 1.0);
}