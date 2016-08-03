uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
    
varying vec2 vUv;
varying vec3 vEye;

struct Ray {
    vec3 origin;
    vec3 direction;
};
    
struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shine;
    float reflectivity;
};
    
struct Sphere {
    vec3 origin;
    float radius;
};

struct Plane {
    vec3 direction;
    float dis;
};
    
struct PointLight {
    vec3 origin;
    vec3 color;
};

struct Output {
    vec3 origin;
    vec3 normal;
    float dis;
    Material material;
};

const float PI = 3.1415926536;

#define planeCount 1
Plane plane[planeCount];

#define sphereCount 5
Sphere sphere[sphereCount];

#define lightCount 6
PointLight light[lightCount];

vec3 eye;

const int materialCount = 2;
Material material[2];

Sphere makeSphere(float offset) {
    float t = time + PI * 2.0 * offset;
    float x = cos(t) * 3.0;
    float z = sin(t * 2.0) * 1.5;
    return Sphere(vec3(x, 0.8, z), 0.8);
}

void makeScene() {
    {
        material[0] = Material(
            vec3(0.0, 0.0, 0.0),
            vec3(0.3, 0.3, 0.3),
            vec3(1.0, 1.0, 1.0),
            80.0,
            0.4
        );
        
        material[1] = Material(
            vec3(0.0, 0.0, 0.0),
            vec3(0.5, 0.5, 0.5),
            vec3(1.0, 1.0, 1.0),
            40.0,
            0.6
        );
    }
    
    {
        plane[0].direction = vec3(0.0, 1.0, 0.0);
        plane[0].dis = 0.0;

        sphere[0] = makeSphere(0.0 / 5.0);
        sphere[1] = makeSphere(1.0 / 5.0);
        sphere[2] = makeSphere(2.0 / 5.0);
        sphere[3] = makeSphere(3.0 / 5.0);
        sphere[4] = makeSphere(4.0 / 5.0);
    }

    {
        float r = 4.0;
        float y = 4.0;
        
        float t0 = -time + PI * 0.0;
        light[0].origin = vec3(cos(t0) * r, y, sin(t0) * r);
        light[0].color = vec3(0.5, 0.0, 0.0);

        float t1 = -time + PI * 0.333333;
        light[1].origin = vec3(cos(t1) * r, y, sin(t1) * r);
        light[1].color = vec3(0.4, 0.4, 0.0);

        float t2 = -time + PI * 0.666666;
        light[2].origin = vec3(cos(t2) * r, y, sin(t2) * r);
        light[2].color = vec3(0.0, 0.5, 0.0);

        float t3 = -time + PI * 1.0;
        light[3].origin = vec3(cos(t3) * r, y, sin(t3) * r);
        light[3].color = vec3(0.0, 0.4, 0.4);

        float t4 = -time + PI * 1.333333;
        light[4].origin = vec3(cos(t4) * r, y, sin(t4) * r);
        light[4].color = vec3(0.0, 0.0, 0.5);

        float t5 = -time + PI * 1.666666;
        light[5].origin = vec3(cos(t5) * r, y, sin(t5) * r);
        light[5].color = vec3(0.4, 0.0, 0.4);
    }
}

void intersectSphere(const Sphere sphere, const Ray ray, Material material, inout Output o) {
    vec3 d = ray.origin - sphere.origin;
    
    float a = dot(ray.direction, ray.direction);
    float b = dot(ray.direction, d);
    float c = dot(d, d) - sphere.radius * sphere.radius;
    
    float g = b*b - a*c;
    
    if(g > 0.0) {
        float dis = (-sqrt(g) - b) / a;
        if(dis > 0.0 && dis < o.dis) {
            o.dis = dis;
            o.origin = ray.origin + ray.direction * dis;
            o.normal = (o.origin - sphere.origin) / sphere.radius;
            o.material = material;
        }
    }
}

void intersectPlane(const Plane plane, const Ray ray, Material material, inout Output o) {
    float dis = plane.dis - dot(plane.direction, ray.origin) / dot(plane.direction, ray.direction);
    
    bool hit = false;
    if(dis > 0.0 && dis < o.dis) {
        o.dis = dis;
        o.origin = ray.origin + ray.direction * dis;
        o.normal = faceforward(plane.direction, plane.direction, ray.direction);
        o.material = material;
        
        // checkerboard hack
        vec2 cb = floor(o.origin.xz);
        float cb2 = mod(cb.x + cb.y, 2.0);
        o.material.ambient *= cb2 + 1.2;
        o.material.diffuse *= cb2 + 1.2;
        o.material.specular *= cb2 + 1.2;
    }
}


vec3 illuminatePointLight(PointLight light, Output o) {
    vec3 v = normalize(light.origin - o.origin);
    
    float d = clamp(dot(o.normal, v), 0.0, 1.0);
    float s = 0.0;
    if(d > 0.0) {
        vec3 eyeV = normalize(eye - o.origin);
        vec3 h = normalize(v + eyeV);
        s = pow(clamp(dot(o.normal, h), 0.0, 1.0), o.material.shine);
    }
    
    vec3 diffuse  = o.material.diffuse  * light.color * d;
    vec3 specular = o.material.specular * light.color * s;
    return diffuse + specular;
}

vec3 illumiate(Output o) {
    vec3 color = o.material.ambient;
    
    for(int i = 0; i < lightCount; ++i) {
        color += illuminatePointLight(light[i], o);
    }
    
    float dis = length(eye - o.origin);
    
    dis -= 4.0;
    dis *= 0.07;
    dis = clamp(dis, 0.0, 1.0);
    
    return color * (1.0 - dis);
}

Output raytraceIteration(Ray ray) {
    Output o;
    o.origin = vec3(0.0, 0.0, 0.0);
    o.normal = vec3(0.0, 0.0, 1.0); 
    o.dis = 1.0e4;
    o.material = Material(
        vec3(0.0, 0.0, 0.0),
        vec3(0.0, 0.0, 0.0),
        vec3(0.0, 0.0, 0.0),
        0.0,
        0.0
    );

    for(int i = 0; i < planeCount; ++i) {
        intersectPlane(plane[i], ray, material[0], o);
    }
    for(int i = 0; i < sphereCount; ++i) {
        intersectSphere(sphere[i], ray, material[1], o);
    }

    return o;
}

vec3 raytrace(Ray ray) {
    vec3 color = vec3(0.0, 0.0, 0.0);
    
    float reflectivity = 1.0;
    
    for(int i = 0; i < 4; ++i) {
        Output o = raytraceIteration(ray);
        
        if(o.dis >= 1.0e3) {
            break;
        }
        
        color += illumiate(o) * reflectivity;
        
        float l = length(ray.origin - o.origin) + 0.0001;
        color -= 0.02 / l;

        reflectivity *= o.material.reflectivity;
        if(reflectivity < 0.05) {
            break;
        }
        
        ray = Ray(o.origin + o.normal * 0.0001, reflect(normalize(o.origin - ray.origin), o.normal));
    }
    
    return color;
}

Ray getPrimaryRay(vec3 origin, vec3 lookat) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.xx;

    vec3 forward = normalize(lookat - origin);
    vec3 up = vec3(0.0, 1.0, 0.0);
    
    vec3 right = cross(up, forward);
    up = cross(forward, right);
    
    Ray ray;
    
    ray.origin = origin;
    ray.direction = normalize(right * uv.x + up * uv.y + forward);
    
    eye = ray.origin;
    
    return ray;
}

void main() {
    makeScene();
    
    float xo = (mouse.x * 2.0 / resolution.x - 1.0) * PI;
    float yo = (0.5 - (mouse.y / resolution.y)) * 4.0 + 2.01;
    
    eye = vEye;//vec3(cos(time * 0.1 + xo) * 5.0, yo, sin(time * 0.1 + xo) * 5.0);
    
    vec3 lookat = vec3(0.0, 0.0, 0.0);
    
    Ray ray = getPrimaryRay(eye, lookat);
    
    vec3 color = raytrace(ray);
    
    gl_FragColor = vec4(color, 1.0);
}
