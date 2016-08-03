
// https://www.shadertoy.com/view/ldsGRS

//Thank you iquilez for some of the primitive distance functions!

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform samplerCube envMap;
uniform vec3 resolution;
uniform vec4 mouse;
uniform float time;

varying vec2 vUv;
varying vec3 vEye;

const float PI = 3.14159265358979323846264;

const float GAMMA_CORRECTION_FACTOR = 2.6;

const int MAX_PRIMARY_RAY_STEPS = 64;
const int MAX_SECONDARY_RAY_STEPS = 12;

//General math functions    
float square(float x) {
    return x * x;
}

float round(float x) {
    return floor(x + 0.5);
}

float isNegative(float x) {
    //returns 0.0 if positive, 1.0 if negative
    //return (-abs(x) / x + 1.0) / 2.0;
    return 1.0 - step(0.0, x);
}

vec2 rectToPolar(vec2 v) {
    //result = vec2(length(v), atan(v.y / v.x));
    return vec2(length(v), atan(v.y / v.x) + isNegative(v.x) * PI);
}

vec2 polarToRect(vec2 v) {
    return v.x * vec2(cos(v.y), sin(v.y));
}

float polarDist(vec2 v1, vec2 v2) { 
    //Formula ripped from 
    //http://math.ucsd.edu/~wgarner/math4c/derivations/distance/distancepolar.htm
    return sqrt(v1.x * v1.x + v2.x * v2.x - 2.0 * v1.x * v2.x * cos(v1.y - v2.y));
}

vec2 rot2D(vec2 v, float angle) {
    float sinA = sin(angle);
    float cosA = cos(angle);
    return vec2(v.x * cosA - v.y * sinA, v.y * cosA + v.x * sinA);
}

float wireFunc(float x, float period) {
    //adjusts the position of the wires
    return cos(min(mod(x, period), PI) + floor(x / period) * PI);
}

float expFog(float d, float density) {
    return 1.0 / pow(d * density, 2.71828);
}

//better texture filtering - Thanks iquilez! - https://www.shadertoy.com/view/XsfGDn
vec3 betterTextureSample64(sampler2D texture, vec2 uv) {    
    float textureResolution = 64.0;
    uv = uv*textureResolution + 0.5;
    vec2 iuv = floor( uv );
    vec2 fuv = fract( uv );
    uv = iuv + fuv*fuv*(3.0-2.0*fuv); // fuv*fuv*fuv*(fuv*(fuv*6.0-15.0)+10.0);;
    uv = (uv - 0.5)/textureResolution;
    return texture2D(texture, uv).rgb;
}

vec3 betterTextureSample256(sampler2D texture, vec2 uv) {   
    float textureResolution = 256.0;
    uv = uv*textureResolution + 0.5;
    vec2 iuv = floor( uv );
    vec2 fuv = fract( uv );
    uv = iuv + fuv*fuv*(3.0-2.0*fuv); // fuv*fuv*fuv*(fuv*(fuv*6.0-15.0)+10.0);;
    uv = (uv - 0.5)/textureResolution;
    return texture2D(texture, uv).rgb;
}

//CSG operations
float join(float a, float b) { return min(a, b); }
float carve(float a, float b) { return max(a, -b); }
float intersect(float a, float b) { return max(a, b); }

//Distance field primitives
float sdPlane(vec3 p, vec4 n) {
    return dot(p, n.xyz) + n.w;
}

float sdInfCyl(vec2 p, float r) {
    return length(p.xy) - r;
}

float sdInfCylPolar(vec2 p, vec3 d) {
    //d.xy = polar coords of center of cylinder
    //d.z = radius of cylinder
    return polarDist(p, d.xy) - d.z;
}

float sd2Planes(vec3 p, vec4 n) {
    float plane1 = dot(p, n.xyz);
    float plane2 = dot(p, -n.xyz) - n.w;
    return max(plane1, plane2);
}

float sdWedge(vec2 p, float d) { 
    //p is a polar coordinate!  
    return p.x * sin(abs(p.y) - d);
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdInfBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float distanceField(vec3 p) {
    float result;
    vec2 polarXY = rectToPolar(vec2(abs(p.x), p.y));
    
    //float heightOffset = 0.05 * texture2D(iChannel0, 0.06 * p.xz).r + 0.03 * square(p.x);
    float heightOffset = -0.02 * betterTextureSample256(iChannel0, 0.09 * p.xz).r + 0.06 * betterTextureSample256(iChannel0, 0.015 * p.xz).g + 0.03 * square(p.x);
    float ground = sdPlane(vec3(p.x, p.y - heightOffset, p.z), vec4(0.0, 1.0, 0.0, 2.1))  / 1.05;
    float tunnel = -sdInfCyl(p.xy, 4.0);
    
    float ringSupport = sd2Planes(vec3(p.xy, mod(p.z, 0.5) - 0.25), vec4(0.0, 0.0, -1.0, 0.05));
    ringSupport = carve(ringSupport, sdInfCyl(p.xy, 3.85));
    
    float linearSupport = sdWedge(vec2(polarXY.x, mod(polarXY.y, PI / 10.0) - PI / 20.0), 0.015);
    linearSupport = carve(linearSupport, sdInfCyl(p.xy, 3.90));
    
    float railroadTie = sdBox(vec3(p.xy, mod(p.z, 0.5) - 0.25) - vec3(0.0, -2.1, 0.0), vec3(1.3, 0.1, 0.10));
    
    float rail = sdInfBox(vec2(abs(p.x), p.y) - vec2(0.812, -1.9), vec2(0.05, 0.1));
    
    float wireOffset = 0.1 * wireFunc(p.z + 4.0 * step(p.x, 0.0), 2.0 * PI);
    float wirePos = 0.0;
    wirePos = wireOffset + round((polarXY.y - wireOffset) / 0.05) * 0.05;
    wirePos = clamp(wirePos, 0.2 + wireOffset - 0.05, 0.2 + wireOffset + 0.05);
    
    float wire = sdInfCylPolar(vec2(polarXY.x, polarXY.y), vec3(3.75, wirePos, 0.05));
    wire /= 1.05;
    
    result = join(tunnel, ground);
    result = join(result, ringSupport);
    result = join(result, linearSupport);
    result = join(result, railroadTie);
    result = join(result, rail);
    result = join(result, wire);
    return result;
}

int getMaterial(vec3 p) {
    vec2 polarXY = rectToPolar(vec2(abs(p.x), p.y));
    
    float heightOffset = -0.01 * betterTextureSample256(iChannel0, 0.06 * p.xz).r + 0.06 * betterTextureSample256(iChannel0, 0.015 * p.xz).g + 0.03 * square(p.x);
    float ground = sdPlane(vec3(p.x, p.y - heightOffset, p.z), vec4(0.0, 1.0, 0.0, 2.1));
    
    float tunnel = -sdInfCyl(p.xy, 4.0);
    float ringSupport = sd2Planes(vec3(p.xy, mod(p.z, 0.5) - 0.25), vec4(0.0, 0.0, -1.0, 0.05));
    ringSupport = carve(ringSupport, sdInfCyl(p.xy, 3.85));
    float linearSupport = sdWedge(vec2(polarXY.x, mod(polarXY.y, PI / 10.0) - PI / 20.0), 0.015);
    linearSupport = carve(linearSupport, sdInfCyl(p.xy, 3.90));
    float wall = min(min(ringSupport, linearSupport), tunnel);
    
    float railroadTie = sdBox(vec3(p.xy, mod(p.z, 0.5) - 0.25) - vec3(0.0, -2.1, 0.0), vec3(1.3, 0.1, 0.10));
    
    float rail = sdInfBox(vec2(abs(p.x), p.y) - vec2(0.812, -1.9), vec2(0.05, 0.1));
    
    float wireOffset = 0.1 * wireFunc(p.z + 4.0 * step(p.x, 0.0), 2.0 * PI);
    float wirePos = 0.0;
    wirePos = wireOffset + round((polarXY.y - wireOffset) / 0.05) * 0.05;
    wirePos = clamp(wirePos, 0.2 + wireOffset - 0.05, 0.2 + wireOffset + 0.05);
    
    float wire = sdInfCylPolar(vec2(polarXY.x, polarXY.y), vec3(3.75, wirePos, 0.05));

    if (ground < min(min(wall, railroadTie), min(rail, wire))) return 1;
    else if (wall < min(railroadTie, min(rail, wire))) return 2;
    else if (railroadTie < min(rail, wire)) return 3;
    else if (rail < wire) return 4;
    else return 5;
}

//rendering functions
vec3 castRay(vec3 pos, vec3 dir, float treshold) {
    for (int i = 0; i < MAX_PRIMARY_RAY_STEPS; i++) {
            float dist = distanceField(pos);
            if (abs(dist) < treshold) break;
            pos += dist * dir;
    }
    return pos;
}

vec3 getNormal(vec3 pos, float derivDist) {
    vec3 surfaceNormal;
    surfaceNormal.x = distanceField(vec3(pos.x + derivDist, pos.y, pos.z)) 
                    - distanceField(vec3(pos.x - derivDist, pos.y, pos.z));
    surfaceNormal.y = distanceField(vec3(pos.x, pos.y + derivDist, pos.z)) 
                    - distanceField(vec3(pos.x, pos.y - derivDist, pos.z));
    surfaceNormal.z = distanceField(vec3(pos.x, pos.y, pos.z + derivDist)) 
                    - distanceField(vec3(pos.x, pos.y, pos.z - derivDist));
    return normalize(0.5 * surfaceNormal / derivDist);
}

float castShadowRay(vec3 pos, vec3 lightPos, float treshold) {
    vec3 dir = normalize(pos - lightPos);
    float maxDist = length(lightPos - pos);
    vec3 rayPos = lightPos;
    float distAccum = 0.0;
    for (int i = 0; i < MAX_SECONDARY_RAY_STEPS; i++) {
        float dist = distanceField(rayPos);
        rayPos += dist * dir;
        distAccum += dist;
    }
    if (distAccum > maxDist - treshold) return 1.0;
    else return 0.0;
}

float lightPointDiffuseShadow(vec3 pos, vec3 lightPos, vec3 normal) {
    vec3 lightDir = normalize(lightPos - pos);
    float lightDist = length(lightPos - pos);
    float color = square(dot(normal, lightDir)) / square(lightDist);
    if (color > 0.00) color *= castShadowRay(pos, lightPos, 0.05);
    return max(0.0, color);
}
float lightPointDiffuseSpecularShadow(vec3 pos, vec3 lightPos, vec3 cameraPos, vec3 normal) {
    vec3 lightDir = normalize(lightPos - pos);
    float lightDist = length(lightPos - pos);
    float color = dot(normal, lightDir) / square(lightDist);
    if (color > 0.01) {
        vec3 cameraDir = normalize(cameraPos - pos);
        color += dot(cameraDir, lightDir);
        color *= castShadowRay(pos, lightPos, 0.001);
    }
    return max(0.0, color);
}

void main() {

    vec4 mousePos = (mouse / resolution.xyxy) * 2.0 - 1.0;
    vec2 screenPos = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
    vec3 cameraPos = vec3(0.0, 0.0, time * 2.0);
    //vec3 cameraPos = vec3(0.0);
    
    float cameraRotAngle = -0.7 * mousePos.x;
    vec3 cameraDir = vec3(0.0, 0.0, 1.5);
    cameraDir.xz = rot2D(cameraDir.xz, cameraRotAngle);
    vec3 planeU = vec3(1.0, 0.0, 0.0);
    planeU.xz = rot2D(planeU.xz, cameraRotAngle);
    vec3 planeV = vec3(0.0, resolution.y / resolution.x * 1.0, 0.0);
    vec3 rayDir = normalize(cameraDir + screenPos.x * planeU + screenPos.y * planeV);
    
    vec3 rayPos = castRay(cameraPos, rayDir, 0.01);
    vec2 polarXY = rectToPolar(vec2(abs(rayPos.x), rayPos.y));
    vec3 surfaceNormal = getNormal(rayPos, 0.0008);
    
    int material = getMaterial(rayPos);
    vec3 materialDiffuse = vec3(1.0);
    if (material == 1) materialDiffuse = (texture2D(iChannel3, rayPos.zx).rgb / 2.0 + 0.5) * vec3(1.0, 0.75, 0.6) * 0.5;
    if (material == 2) materialDiffuse = vec3(1.0, 0.7, 0.6) * texture2D(iChannel1, vec2(polarXY.y * 2.0 / PI, rayPos.z + polarXY.x)).rgb;//vec3(0.0, 1.0, 0.0);
    if (material == 3) materialDiffuse = vec3(0.3, 0.5, 1.0) * texture2D(iChannel2, vec2(rayPos.x, rayPos.y + rayPos.z)).rgb;
    if (material == 4) materialDiffuse = vec3(0.6, 0.6, 0.6);
    if (material == 5) materialDiffuse = vec3(0.4, 0.4, 0.4);
    
    vec3 color = materialDiffuse * 0.4;
    
    vec3 light1Pos = vec3(0.0, 1.1, 7.5 * mousePos.y + 12.0 + cameraPos.z);
    //lightPos = vec3(0.0, 0.0, sin(time) * 4.0 + 6.0);
        
    //float isLit = castShadowRay(rayPos, lightPos, 0.02, 0.001);
    color += materialDiffuse * 18.0 * lightPointDiffuseShadow(rayPos, light1Pos, surfaceNormal);
    
    vec3 light2Pos = vec3(0.0, 1.1, 0.0);//vec3(0.0, 1.1, 15.0 * mousePos.w + 16.0 /*+ time * 2.0*/);
    light2Pos.z = round(rayPos.z / 16.0) * 16.0;
    
    color += materialDiffuse * 18.0 * lightPointDiffuseShadow(rayPos, light2Pos, surfaceNormal);
    
    color = pow( abs(color), vec3(GAMMA_CORRECTION_FACTOR));
    
    gl_FragColor = vec4(color, 1.0);
    //fragColor = vec4(isLit * pow(10.0 * vec3(dot(surfaceNormal, lightRayDir)) / square(lightDistTotal), vec3(2.2)), 1.0);
}