

#define PI 3.14159

uniform vec3 resolution;
uniform float time;
varying vec3 vEye;
varying vec2 vUv;

mat3 xrot(float t) {

    return mat3(1.0, 0.0, 0.0, 0.0, cos(t), -sin(t), 0.0, sin(t), cos(t));
}

mat3 yrot(float t) {

    return mat3(cos(t), 0.0, -sin(t), 0.0, 1.0, 0.0, sin(t), 0.0, cos(t));
}

mat3 zrot(float t) {

    return mat3(cos(t), -sin(t), 0.0, sin(t), cos(t), 0.0, 0.0, 0.0, 1.0);
}

float sdBox(vec3 p, vec3 b) {

    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float map(vec3 pos) {

    float speed = 1.0;
    vec3 grid = floor(pos);
    vec3 gmod = mod(grid, 2.0);
    vec3 rmod = mod(grid, 4.0) - 2.0;
    float tm = fract(time * speed);
    rmod *= (cos(tm * PI) - 1.0);
    float g = floor(mod(time * speed, 3.0));
    if (g == 0.0) 
    {
        if (gmod.y * gmod.x == 1.0) 
        {
            pos.z += rmod.x * rmod.y * 0.5;
        }
     }
 else if (g == 1.0) 
    {
        if (gmod.y * gmod.z == 1.0) 
        {
            pos.x += rmod.y;
        }
     }
 else if (g == 2.0) 
    {
        if (gmod.z == 0.0) 
        {
            pos.y += rmod.z * rmod.x * 0.5;
        }
     }
     grid = floor(pos);
    pos = pos - grid;
    pos = pos * 2.0 - 1.0;
    float len = 0.9;
    float d = sdBox(pos, vec3(len));
    bool skip = false;
    if (mod(grid.x, 2.0) == 0.0 && mod(grid.y, 2.0) == 0.0) 
    {
        skip = true;
    }
     if (mod(grid.x, 2.0) == 0.0 && mod(grid.z, 2.0) == 0.0) 
    {
        skip = true;
    }
     if (mod(grid.y, 2.0) == 0.0 && mod(grid.z, 2.0) == 1.0) 
    {
        skip = true;
    }
     if (skip) 
    {
        d = 100.0;
        vec3 off = vec3(2.0, 0.0, 0.0);
        for (int i = 0; i < 3; ++i) 
        {
            float a = sdBox(pos + off, vec3(len));
            float b = sdBox(pos - off, vec3(len));
            d = min(d, min(a, b));
            off = off.zxy;
        }
        d *= 0.5;
    }
 else 
    {
        d *= 0.8;
    }
    return d;
}

vec3 surfaceNormal(vec3 pos) {

    vec3 delta = vec3(0.01, 0.0, 0.0);
    vec3 normal;
    normal.x = map(pos + delta.xyz) - map(pos - delta.xyz);
    normal.y = map(pos + delta.yxz) - map(pos - delta.yxz);
    normal.z = map(pos + delta.zyx) - map(pos - delta.zyx);
    return normalize(normal);
}

float aoc(vec3 origin, vec3 ray) {

    float delta = 0.05;
    const int samples = 8;
    float r = 0.0;
    for (int i = 1; i <= samples; ++i) 
    {
        float t = delta * float(i);
        vec3 pos = origin + ray * t;
        float dist = map(pos);
        float len = abs(t - dist);
        r += len * pow(2.0, -float(i));
    }
    return r;

}

void main() {

    vec2 uv = ((vUv - 0.5) * 2.0) * vec2(resolution.z, 1.0);

    vec3 eye = normalize(vec3(uv, 1.0 - dot(uv, uv) * 0.33));
    vec3 origin = vec3(0.0);
    eye = eye * yrot(time) * xrot(time);
    float speed = 0.5;
    float j = time * speed;
    float f = fract(j);
    float g = 1.0 - f;
    f = f * f * g + (1.0 - g * g) * f;
    f = f * 2.0 - 1.0;
    float a = floor(j) + f * floor(mod(j, 2.0));
    float b = floor(j) + f * floor(mod(j + 1.0, 2.0));
    origin.x += 0.5 + a;
    origin.y += 0.5;
    origin.z += 0.5 + b;
    float t = 0.0;
    float d = 0.0;
    for (int i = 0; i < 32; ++i) 
    {
        vec3 pos = origin + eye * t;
        d = map(pos);
        t += d;
    }
    vec3 worldPos = origin + eye * t;
    vec3 norm = surfaceNormal(worldPos);
    float prod = max(0.0, dot(norm, -eye));
    float amb = 0.0;
    vec3 ref = reflect(eye, norm);
    vec3 spec = vec3(0.0);
    prod = pow(1.0 - prod, 2.0);
    vec3 col = vec3(0.1, 0.3, 0.5);
    spec *= col;
    col = mix(col, spec, prod);
    float shade = pow(max(1.0 - amb, 0.0), 4.0);
    float fog = 1.0 / (1.0 + t * t * 0.2) * shade;
    vec3 final = col;
    final = mix(final, vec3(1.0), fog);
    fog = 1.0 / (1.0 + t * t * 0.1);
    gl_FragColor = vec4(final * fog, fog );

}