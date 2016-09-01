
// ------------------ channel define
// 0_# bufferFULL_shooterA #_0
// ------------------

#define PI 3.14159265359

mat2 rot( in float a ) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c,s,-s,c);  
}

float box( in vec2 p, in vec2 b ) {
    vec2 d = abs(p) - b;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float capsule( vec2 p, vec2 a, vec2 b ) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

// STORAGE (use multiple of 8 for efficient SIMD usage)

const vec2 ADR_PLAYER = vec2(0, 0);
const vec2 ADR_GAME = vec2(8, 0);
const vec2 ADR_SCORE = vec2(16, 0);
const vec2 ADR_PLAYER_PROJ_FIRST = vec2(24, 0);
const vec2 ADR_PLAYER_PROJ_LAST = vec2(31, 0);
const vec2 ADR_ALIEN_SHIP_FIRST = vec2(0, 8);
const vec2 ADR_ALIEN_SHIP_LAST = vec2(31, 8);
const vec2 ADR_ALIEN_SHIP_PROJ_FIRST = vec2(0, 16);
const vec2 ADR_ALIEN_SHIP_PROJ_LAST = vec2(31, 23);

vec4 loadValue( in vec2 re ) {
    return texture2D( iChannel0, (0.5+re) / iChannelResolution[0].xy, -100.0 );
}

// RASTERIZE COLLISION MESH INTO A SMALL 128 BUFFER
// collision mesh is a regular distance field, negative value is inside a projectile
// distance fields works nicely with linear interpolation, see
// http://www.valvesoftware.com/publications/2007/SIGGRAPH2007_AlphaTestedMagnification.pdf

// radius function for the ennemy
float getRadius( in int index ) {
    if (index < 8) return 0.06;
    if (index < 16) return 0.07;
    if (index < 24) return 0.05;
    if (index < 28) return 0.05;
    if (index < 30) return 0.14;
    if (index < 31) return 0.26;
    return 0.04;
}

// distance function for a given projectile
float getDistance( in int index, in vec2 coord, in vec4 value ) {
    
    vec2 uv = coord - value.xy;
    
    // FIGHTER
    if (index < 8) {
        return length(uv) - 0.06;
    }
    
    // KNIGHT
    else if (index < 16) {
        vec2 center = vec2(sign(uv.x), 0.0);
        if (center.x == 0.0) center.x = 1.0;
        center.x *= 0.05;
        return length(uv-center)-0.03;
    }
    
    // NINJA
    else if (index < 24) {
        return length(uv) - 0.06;
    }
    
    // PILLAR
    else if (index < 28) {
        vec2 center = vec2(sign(uv.x), 0.0);
        if (center.x == 0.0) center.x = 1.0;
        center.x *= value.w;
        vec2 secondCenter = center;
        if (secondCenter.x > 0.0) {
            secondCenter.x = max(0.0, secondCenter.x - 0.3);
        } else {
            secondCenter.x = min(0.0, secondCenter.x + 0.3);
        }
        return capsule(uv, center, secondCenter)-0.03;
    }
    
    // FREGATE
    else if (index < 30) {
        float radius = value.w;
        uv.x += radius*0.5;
        float x = floor((uv.x)/radius)+0.5;
        x = clamp(x, -0.5, 1.5);
        x *= radius;
        vec2 center = vec2(x, 0.0);
        return length(uv-center)-0.06;
    }
    
    // MOTHERSHIP
    else if (index < 31) {
        float len = length(coord)-value.x;
        float dist = abs(len)-0.04;
        const vec2 inBox = vec2(0.5, 0.06);
        for (int i = 0 ; i < 5 ; i++) {
            vec2 uuv = coord*rot(value.y+(PI*2.0 / 5.0) * float(i));
            uuv.x += value.x;
            float inner = box(uuv, inBox);
            dist = max(dist, -inner);
        }
        return dist;
    }
    
    return 999.9;
}
    

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    vec2 uv = fragCoord.xy / 128.0;
    // outside the limits of the collision mesh, discard the fragment
    if (uv.x > 1.0 || uv.y > 1.0) {
        discard;
        return;
    }
    
    uv = uv * 2.0 - 1.0;
    
    // for each projectiles
    float minProj = 999.9;
    for (int i = 0 ; i < 8 ; i++) {
        vec2 adr = ADR_PLAYER_PROJ_FIRST + vec2(float(i), 0.0);
        vec4 other = loadValue(adr);
        if (other.z > 0.5) {
            float len = 0.0;
            if (other.w > 0.5) len = abs(uv.y-other.y);
            else len = length(uv-other.xy);
            minProj = min(minProj, len-0.03);
        }
    }
    
    // for each ennemies
    float minEnnemy = 999.9;
    float minProjEnn = 999.9;
    // skip the last one (bonus don't hurt player)
    for (int i = 0 ; i < 31 ; i++) {
        vec2 adr = ADR_ALIEN_SHIP_FIRST + vec2(float(i), 0.0);
        vec4 other = loadValue(adr);
        if (other.w > 0.5) {
            minEnnemy = min(minEnnemy, length(uv-other.xy)-getRadius(i));
        }
        
        // for each ennemies projectiles
        for (int j = 0 ; j < 8 ; j++) {
            vec2 aadr = adr + vec2(0, 8+j);
            vec4 projO = loadValue(aadr);
            if (projO.z > 0.5) {
                minProjEnn = min(minProjEnn, getDistance(i, uv, projO));
            }
        }
    }
    
    fragColor.r = minProjEnn;   // r = ENNEMIES PROJECTILES
    fragColor.g = minProj;      // g = PLAYER PROJECTILES
    fragColor.b = minEnnemy;    // b = ENNEMIES
    fragColor.a = 999.9;
    
}