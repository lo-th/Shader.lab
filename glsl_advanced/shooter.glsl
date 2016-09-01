
// ------------------ channel define
// 0_# bufferFULL_shooterA #_0
// 1_# bufferFULL_shooterB #_1
// 2_# tex10 #_2
// 3_# noise #_3
// ------------------

// https://www.shadertoy.com/view/XldGDN

// size between each transitions
#define TRANSITION 3000.0
// scroll speed of the player, in pixels per frames
#define SCROLL_SPEED 0.65
// duration between each transitions
#define TRANSITION_PERIOD (TRANSITION/SCROLL_SPEED)

#define PI 3.14159265359

const vec3 ENNEMY_COLOR = vec3(0.6, 0.2, 0.7);
const vec3 FRIEND_COLOR = vec3(0.4, 1.0, 0.3);
const vec3 BACKGROUND_COLOR = vec3(0.7, 0.8, 1.0);

// size of pixel on screen, resolution dependant
float pixelSize;
// time since the beginning
float gameplayGlobalTime;

float doDithering( in float value, in float noise, in float frac ) {
    value += (noise * 1.8 - 0.9) / frac;
    value = floor(value*frac) / (frac - 1.0);
    value = clamp(value, 0.0, 1.0);
    return value;
}

int imod( in int a, in int n ) {
    return a - (n * int(a/n));
}

// iq's 3D noise
float noise( in vec3 x ) {
    vec3 f = fract(x);
    vec3 p = x - f;
    f = f*f*(3.0 - 2.0*f);
    vec2 uv = (p.xy + vec2(37.0, 17.0) * p.z) + f.xy;
    vec2 rg = texture2D(iChannel3, (uv + 0.5)/256.0, -100.0).rg;
    return mix(rg.y, rg.x, f.z);
}

float hash1( in float n ) {
    return fract(sin(n)*138.5453123);
}

vec3 hash3( vec2 p ) {
    vec3 q = vec3( dot(p,vec2(127.1,311.7)), 
                   dot(p,vec2(269.5,183.3)), 
                   dot(p,vec2(419.2,371.9)) );
    return fract(sin(q)*438.5453);
}

mat2 rot( in float a ) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c,s,-s,c);  
}

float triangle( in vec2 uv, in vec2 n ) {
    vec2 uuv = vec2(abs(uv.x), uv.y);
    return max(-uv.y, dot(n, uuv));
}

float diamond( in vec2 uv, in float top, in float bottom ) {
    if (uv.y > 0.0) uv.y /= top;
    if (uv.y < 0.0) uv.y /= bottom;
    vec2 a = abs(uv);
    return a.x + a.y;
}

float box( in vec2 p, in vec2 b ) {
    vec2 d = abs(p) - b;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// Thanks P_Malin, see https://www.shadertoy.com/view/4sf3RN
const float kCharBlank = 12.0;
const float kCharMinus = 11.0;
const float kCharDecimalPoint = 10.0;
float InRect(const in vec2 vUV, const in vec4 vRect) {
    vec2 vTestMin = step(vRect.xy, vUV.xy);
    vec2 vTestMax = step(vUV.xy, vRect.zw); 
    vec2 vTest = vTestMin * vTestMax;
    return vTest.x * vTest.y;
}
float SampleDigit(const in float fDigit, const in vec2 vUV) {
    const float x0 = 0.0 / 4.0;
    const float x1 = 1.0 / 4.0;
    const float x2 = 2.0 / 4.0;
    const float x3 = 3.0 / 4.0;
    const float x4 = 4.0 / 4.0;
    const float y0 = 0.0 / 5.0;
    const float y1 = 1.0 / 5.0;
    const float y2 = 2.0 / 5.0;
    const float y3 = 3.0 / 5.0;
    const float y4 = 4.0 / 5.0;
    const float y5 = 5.0 / 5.0;
    vec4 vRect0 = vec4(0.0);
    vec4 vRect1 = vec4(0.0);
    vec4 vRect2 = vec4(0.0);
    if(fDigit < 0.5) {
        vRect0 = vec4(x0, y0, x3, y5); 
        vRect1 = vec4(x1, y1, x2, y4);
    } else if(fDigit < 1.5) {
        vRect0 = vec4(x1, y0, x2, y5); 
        vRect1 = vec4(x0, y0, x0, y0);
    } else if(fDigit < 2.5) {
        vRect0 = vec4(x0, y0, x3, y5); 
        vRect1 = vec4(x0, y3, x2, y4); 
        vRect2 = vec4(x1, y1, x3, y2);
    } else if(fDigit < 3.5) {
        vRect0 = vec4(x0, y0, x3, y5); 
        vRect1 = vec4(x0, y3, x2, y4); 
        vRect2 = vec4(x0, y1, x2, y2);
    } else if(fDigit < 4.5) {
        vRect0 = vec4(x0, y1, x2, y5); 
        vRect1 = vec4(x1, y2, x2, y5); 
        vRect2 = vec4(x2, y0, x3, y3);
    } else if(fDigit < 5.5) {
        vRect0 = vec4(x0, y0, x3, y5); 
        vRect1 = vec4(x1, y3, x3, y4); 
        vRect2 = vec4(x0, y1, x2, y2);
    } else if(fDigit < 6.5) {
        vRect0 = vec4(x0, y0, x3, y5); 
        vRect1 = vec4(x1, y3, x3, y4); 
        vRect2 = vec4(x1, y1, x2, y2);
    } else if(fDigit < 7.5) {
        vRect0 = vec4(x0, y0, x3, y5); 
        vRect1 = vec4(x0, y0, x2, y4);
    } else if(fDigit < 8.5) {
        vRect0 = vec4(x0, y0, x3, y5); 
        vRect1 = vec4(x1, y1, x2, y2); 
        vRect2 = vec4(x1, y3, x2, y4);
    } else if(fDigit < 9.5) {
        vRect0 = vec4(x0, y0, x3, y5); 
        vRect1 = vec4(x1, y3, x2, y4); 
        vRect2 = vec4(x0, y1, x2, y2);
    } else if(fDigit < 10.5) {
        vRect0 = vec4(x1, y0, x2, y1);
    } else if(fDigit < 11.5) {
        vRect0 = vec4(x0, y2, x3, y3);
    }   
    float fResult = InRect(vUV, vRect0) + InRect(vUV, vRect1) + InRect(vUV, vRect2);
    return mod(fResult, 2.0);
}

// STORAGE

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

// RENDERING

float explosion( in float seed, in vec2 uv, in float frac, in float radius ) {
    float len = length(uv);
    vec2 decal = vec2(hash1(seed*0.41355),
                      hash1(seed*9.00412))*2.0-1.0;
    decal *= radius*0.15;
    float len2 = length(uv+decal);
    float expl = frac * radius;
    float explosion = smoothstep(expl*0.75, expl+1.0, len);
    explosion *= 1.0 - smoothstep(expl+3.0, expl+4.0, len2);
    explosion *= frac;
    explosion *= 1.0 - smoothstep(0.6, 1.0, frac);
    return explosion;
}

// small ship, cannon fodder
vec4 getShipFighterColor( in int index, in vec2 uv, in float frac, in vec4 shipValue ) {
    frac = smoothstep(0.0, 0.2, frac);
    uv.y *= -1.0;
    uv.y += 2.0;
    
    float dither = texture2D( iChannel2, uv / 8.0 ).r;
    
    float tri = triangle(uv, normalize(vec2(3, 1))) - 5.0;
    float wings = triangle(uv + vec2(0, -4.5), normalize(vec2(1, 3))) - 1.5;
    wings = min(wings, box(uv, vec2(13, 2)));
    float cockpit = diamond(uv+vec2(0, 2), 3.0, 0.6) - 4.0;
    float mm = min(tri, wings);
    
    vec4 colorBase = vec4(ENNEMY_COLOR, 1.0);
    
    if (tri > 0.0) colorBase.rgb *= 0.5;
    else colorBase.rgb *= 1.0 + dither*(-tri*0.5);
    if (cockpit < 0.0) {
        if (cockpit < -1.5) colorBase.rgb = ENNEMY_COLOR * 4.0;
        else colorBase.rgb = vec3(0);
    }
    if (mm > 0.0) {
        if (mm > 1.0) colorBase.a = 0.0;
        else colorBase = vec4(0, 0, 0, 1);
    } else colorBase.a = 1.0;
    
    if (colorBase.a < 0.5) {
        float trail = 1.0;
        if (abs(uv.x) > 3.0) trail = 0.0;
        if (uv.y > 0.0) trail = 0.0;
        trail *= 1.0 - smoothstep(0.0, 20.0, -uv.y);
        colorBase = vec4(ENNEMY_COLOR*3.0, trail);
    }
    
    colorBase.a *= 1.0 - frac;
    
    float explo = explosion(float(index)+shipValue.z, uv, frac, 12.0);
    colorBase += vec4(ENNEMY_COLOR, 1)*explo;
    
    return colorBase;
}

// small ship but tankier than a fighter
vec4 getShipKnightColor( in int index, in vec2 uv, in float frac, in vec4 shipValue ) {
    frac = smoothstep(0.0, 0.2, frac);
    uv.y *= -1.0;
    uv.y += 6.0;
    
    float dither = texture2D( iChannel2, uv / 8.0 ).r;
    
    float tank = triangle(uv, normalize(vec2(6, 1)));
    tank = max(tank, uv.y-8.0) - 9.0;
    float cockpit = diamond(uv+vec2(0.0, -17.0), 0.7, 3.0) - 4.5;
    
    vec2 uuv = uv;
    uuv.x = abs(uuv.x);
    float guns = box(uuv-vec2(9, 12), vec2(2, 8)) - 0.0;
    
    vec4 colorBase = vec4(ENNEMY_COLOR, 1.0);
    
    if (tank > 0.0) {
        colorBase.rgb *= 0.5;
        colorBase.rgb *= 1.0 - dither*(-guns*0.5);
    } else {
        colorBase.rgb = mix(ENNEMY_COLOR, vec3(0.3), 0.7);
        colorBase.rgb *= 1.0 + dither*-tank*0.1;
        colorBase.rgb -= max(0.0, -cockpit+2.5)*dither*0.1;
        float xx = abs(uv.x);
        if (xx > 7.5) colorBase.rgb = ENNEMY_COLOR;
    }
    if (cockpit < 0.0) {
        float alea = sin(gameplayGlobalTime*8.0 + float(index)*5.0832)*0.5+0.5;
        if (cockpit < -1.5) colorBase.rgb = ENNEMY_COLOR * (1.0 + alea*3.0);
        else colorBase.rgb = vec3(0);
    }
    
    float mm = min(tank, guns);
    mm = min(mm, cockpit);
    if (mm > 0.0) {
        if (mm > 1.0) colorBase.a = 0.0;
        else colorBase = vec4(0, 0, 0, 1);
    } else colorBase.a = 1.0;

    colorBase.a *= 1.0 - frac;
    
    float explo = explosion(float(index)+shipValue.z, uv, frac, 20.0);
    colorBase += vec4(ENNEMY_COLOR, 1)*explo;
    
    return colorBase;
}

// small, fast, low health, dangerous
vec4 getShipNinjaColor( in int index, in vec2 uv, in float frac, in vec4 shipValue ) {
    frac = smoothstep(0.0, 0.2, frac);
    uv.y *= -1.0;
    uv.y += 2.0;
    uv *= 1.2;
    
    vec2 uuv = vec2(abs(uv.x), uv.y);
    uuv *= rot(-0.5);
    
    float dither = texture2D( iChannel2, uv / 8.0 ).r;
    
    float tri = triangle(uv+vec2(0, -4), normalize(vec2(5, 2))) - 5.0;
    float wings = length(uv+vec2(0, -18)) - 18.0;
    wings = max(-wings, length(uv+vec2(0, -8)) - 15.0);
    float cockpit = diamond(uv, 3.0, 3.0) - 4.0;
    
    float blades = triangle(uuv+vec2(0, 0), normalize(vec2(7, 2))) - 4.0;
    
    vec4 colorBase = vec4(ENNEMY_COLOR, 1.0);
    
    if (wings < 0.0) {
        if (wings > -0.5) colorBase.rgb = vec3(0);
        else {
            colorBase.rgb = mix(colorBase.rgb, vec3(0.6), 0.5);
            colorBase.rgb *= 1.0 + dither*-wings*0.2;
        }
    } else {
        colorBase.rgb *= 0.5;
        colorBase.rgb *= 1.0 + dither*(-tri*0.5);
        if (cockpit < 0.0) {
            if (cockpit < -1.5) colorBase.rgb = ENNEMY_COLOR * 4.0;
            else colorBase.rgb = vec3(0);
        }
    }
    
    float mm = min(wings, tri);
    mm = min(blades, mm);
    
    if (mm > 0.0) {
        if (mm > 1.0) colorBase.a = 0.0;
        else colorBase = vec4(0, 0, 0, 1);
    } else colorBase.a = 1.0;
    
    colorBase.a *= 1.0 - frac;
    
    float explo = explosion(float(index)+shipValue.z, uv, frac, 16.0);
    colorBase += vec4(ENNEMY_COLOR, 1)*explo;
    
    return colorBase;
}

// fire horizontally
vec4 getShipPillarColor( in int index, in vec2 uv, in float frac, in vec4 shipValue ) {
    frac = smoothstep(0.0, 0.2, frac);
    vec2 uuv = uv;
    uv = abs(uv);
    
    float dither = texture2D( iChannel2, uv / 8.0 ).r;
    
    float tank = triangle(uv + vec2(0, -7), normalize(vec2(2, 1))) - 4.5;
    float middle = box(uv, vec2(4, 5));
    
    vec4 colorBase = vec4(ENNEMY_COLOR, 1.0);
    
    if (tank < 0.0) {
        colorBase.rgb = mix(ENNEMY_COLOR, vec3(0.1), 0.7);
        colorBase.rgb *= 1.0 + dither*-tank*0.3;
        colorBase.rgb *= 1.0 - dither*-middle*0.2;
        float xx = abs(uv.x);
        if (xx > 7.5) colorBase.rgb = ENNEMY_COLOR;
    } else if (middle < 0.0) {
        float alea = sin(gameplayGlobalTime*7.0 + float(index)*5.0832)*0.5+0.5;
        float bar = fract(gameplayGlobalTime*1.0 + float(index)*5.0832);
        bar = cos(bar*PI)*5.0;
        colorBase.rgb = ENNEMY_COLOR*(2.0+3.0*alea);
        colorBase.rgb *= 1.0 + dither*-middle*0.5;
        if (abs(uuv.x-bar) < 1.0) colorBase.rgb = vec3(0);
    }
    
    float mm = min(tank, middle);
    if (mm > 0.0) {
        if (mm > 1.0) colorBase.a = 0.0;
        else colorBase = vec4(0, 0, 0, 1);
    } else colorBase.a = 1.0;
    
    colorBase.a *= 1.0 - frac;
    
    float explo = explosion(float(index)+shipValue.z, uv, frac, 20.0);
    colorBase += vec4(ENNEMY_COLOR, 1)*explo;
        
    return colorBase;
}

// big ship, moderate HP, lots of bullets
vec4 getShipFregateColor( in int index, in vec2 uv, in float frac, in vec4 shipValue ) {
    frac = smoothstep(0.0, 0.3, frac);
    uv.y *= -1.0;
    uv.y += 10.0;
    
    float dither = texture2D( iChannel2, uv / 8.0 ).r;
    
    float tri = triangle(uv, normalize(vec2(4, 1))) - 14.0;
    tri = max(tri, uv.y-40.0);
    
    float wings = triangle(uv + vec2(0, -6), normalize(vec2(1, 3))) - 5.0;
    wings = min(wings, box(uv + vec2(0.0, 4.0), vec2(35.0, 4.0)));
    wings = min(wings, triangle(uv + vec2(0, -32), normalize(vec2(1, 3))) - 3.0);
    wings = min(wings, box(uv + vec2(0, -25), vec2(23.0, 3.0)));
    float control = box(uv + vec2(0, 9), vec2(31.0, 5.0));
    float cockpit = diamond(uv+vec2(0.0, 2.0), 2.5, 0.9) - 8.0;
    
    vec2 uuv = uv;
    uuv.x = abs(uuv.x);
    float guns = box(uuv-vec2(17, 28), vec2(2, 8)) - 0.0;
    
    vec4 colorBase = vec4(ENNEMY_COLOR, 1.0);
    
    if (tri > 0.0) {
        colorBase.rgb *= 0.5;
        if (abs(control) < 1.0) colorBase.rgb *= 0.4;
        else if (control < 0.0) colorBase.rgb *= 1.5;
        else if (guns < 0.0 && wings > 0.0) colorBase.rgb *= 0.4;
    } else {
        colorBase.rgb = mix(colorBase.rgb, vec3(0.6), 0.5);
        colorBase -= smoothstep(-6.0, 0.0, tri)*0.5*dither;
    }
    
    if (cockpit < 0.0) {
        if (cockpit < -1.5) {
            colorBase.rgb = ENNEMY_COLOR * 2.0;
            colorBase.rgb += (1.0-smoothstep(-8.0, 0.0, cockpit)) * dither;
        } else colorBase.rgb = vec3(0);
    }
    
    float mm = min(tri, wings);
    mm = min(guns, mm);
    
    if (mm > 0.0) {
        if (mm > 1.0) colorBase.a = 0.0;
        else colorBase = vec4(0, 0, 0, 1);
    } else colorBase.a = 1.0;
    
    if (colorBase.a < 0.5) {
        float trail = 1.0;
        if (abs(uv.x) > 10.0) trail = 0.0;
        if (uv.y > 0.0) trail = 0.0;
        trail *= 1.0 - smoothstep(10.0, 22.0, -uv.y);
        colorBase = vec4(ENNEMY_COLOR*3.0, trail);
    }
    
    colorBase.a *= 1.0 - frac;
    
    float explo = explosion(float(index)+shipValue.z, uv, frac, 48.0);
    colorBase += vec4(ENNEMY_COLOR, 1)*explo;
    
    return colorBase;
}

// huge ship, lots of HP, maze attack
vec4 getShipMotherColor( in int index, in vec2 uv, in float frac, in vec4 shipValue ) {
    
    float dither = texture2D( iChannel2, uv / 8.0 ).r;
    float len = length(uv);
    float theta = atan(uv.y, uv.x)*0.5 + 0.5*PI;
    
    float radius = len - 40.0;
    float x = len / 40.0;
    vec3 norm = normalize(vec3(uv, sqrt(1.0-x*x)*40.0));
    
    float rot = gameplayGlobalTime*0.25;
    float blades = smoothstep(0.6, 0.65, abs(fract((theta+rot)/PI*5.0)*2.0-1.0));
    blades = max(radius-6.0, blades);
    
    float grebble = cos((theta+rot)*100.0)*0.5+0.5;
    float grebble2 = cos(theta*50.0)*0.5+0.5;
    
    vec4 colorBase = vec4(ENNEMY_COLOR, 1.0);
    
    if (radius < -23.0) {
        
        float alea = sin(gameplayGlobalTime*1.0);
        colorBase += doDithering(1.0-smoothstep(0.0, 20.0, len), dither, 4.0)*(1.7+alea);
    } else if (radius < -15.0) {
        colorBase *= 0.4;
        colorBase -= doDithering(grebble2, dither, 4.0)*0.2;
        float spin = abs(radius+19.0);
        float spinAngle = max(0.0, shipValue.w) / 130.0 * PI;
        if (spin < 4.0) {
            if (spin < 2.0) {
                if (spinAngle >= theta) {
                    colorBase.rgb = ENNEMY_COLOR*2.0;
                }
            } else {
                colorBase.rgb = vec3(0);
            }
        }
    } else if (radius < 0.0) {
        colorBase.rgb = mix(colorBase.rgb, vec3(0.4), 0.4);
        float d = max(0.0, dot(norm, normalize(vec3(10, 8, 13))));
        colorBase += doDithering(d, dither, 4.0)*0.4;
    } else {
        colorBase *= 0.4;
        colorBase -= doDithering(grebble, dither, 4.0)*0.2;
    }
    
    float mm = min(blades, radius);
    
    if (mm > 0.0) {
        if (mm >= 1.0) colorBase.a = 0.0;
        else colorBase = vec4(0, 0, 0, 1);
    } else colorBase.a = 1.0;
    
    if (colorBase.a < 0.5) {
        colorBase.rgb = ENNEMY_COLOR;
    }
    
    colorBase.a *= 1.0 - frac;
    
    // add 4 explosions
    for (int i = 0 ; i < 4 ; i++) {
        vec2 decal = vec2(hash1(float(i)*0.41355+shipValue.z),
                          hash1(float(i)*9.00412+shipValue.z*8.223))*2.0-1.0;
        decal *= 30.0;
        float rad = hash1(float(i)*431.412+shipValue.z*752.35)*50.0;
        float start = float(i)*0.2;
        float explofrac = smoothstep(start, start+0.3, frac);
        float explo = explosion(float(i)+shipValue.z, uv+decal, explofrac, 20.0 + rad);
        colorBase += vec4(ENNEMY_COLOR, 1)*explo;
    }
    
    return colorBase;
}

// bonus ship (not a ship, duh)
vec4 getShipBonusColor( in int index, in vec2 uv, in float frac, in vec4 shipValue ) {
    frac = smoothstep(0.0, 0.2, frac);
    vec2 uuuv = abs(uv);
    uv *= rot(gameplayGlobalTime*1.75);
    vec2 uuv = uv;
    uv = abs(uv);
    
    float dither = texture2D( iChannel2, uv / 8.0 ).r;
    
    float tank = box(uv, vec2(2, 8)) - 2.5;
    tank = max(tank, 5.0-uv.y);
    float middle = box(uv, vec2(3, 5));
    
    vec4 colorBase = vec4(FRIEND_COLOR, 1.0);
    
    if (tank > middle) {
        float dd = dot(uuv, vec2(1, 1)) + gameplayGlobalTime*15.0;
        dd = fract(dd*0.2);
        colorBase.rgb *= step(0.5, dd);
    } else {
        colorBase.rgb = mix(colorBase.rgb, vec3(0.6), 0.8);
        colorBase.rgb *= 1.0 + dither*-tank*0.5;
    }
    
    float mm = min(tank, middle);
    if (mm > 0.0) {
        if (mm > 1.5) colorBase.a = 0.0;
        else colorBase = vec4(0, 0, 0, 1);
    } else colorBase.a = 1.0;
    
    if (colorBase.a < 0.5) {
        float explo = explosion(float(index)+shipValue.z, uv,
                                fract(gameplayGlobalTime*0.5), 14.0);
        colorBase = vec4(FRIEND_COLOR, explo*0.5);
    }
    
    colorBase.a *= 1.0 - frac;
    
    uuuv.x *= 0.5;
    float radius = min(abs(uuuv.x), abs(uuuv.y));
    float explo = explosion(float(index)+shipValue.z, uuuv, frac, 48.0-radius);
    colorBase += vec4(FRIEND_COLOR, 1)*explo;
    
    return colorBase;
}
    
// texture for the player ship
vec4 getPlayerShipColor( in vec2 uv, in float frac, in float seed ) {
    
    float dither = texture2D( iChannel2, uv / 8.0 ).r;
    float len = length(uv);
    float theta = atan(uv.y, uv.x)*0.5 + 0.5*PI;
    
    float radius = len - 5.5;
    float x = len / 5.5;
    vec3 norm = normalize(vec3(uv, sqrt(1.0-x*x)*5.5));
    
    vec2 uuv = uv;
    uuv.x = abs(uuv.x);
    float guns = box(uuv-vec2(6, 2), vec2(0, 5)) - 0.0;
    float reguns = box(uuv-vec2(6, -3), vec2(0.5, 1.0)) - 1.0;
    guns = min(guns, reguns);
    
    float cockpit = dot(norm, normalize(vec3(0, 10, 7)));
    cockpit = smoothstep(0.4, 0.5, cockpit);
    
    vec4 colorBase = vec4(mix(FRIEND_COLOR.rgb, vec3(0.8), 0.9), 1.0);
    
    colorBase.rgb = mix(colorBase.rgb, FRIEND_COLOR*0.05, cockpit);
    
    if (radius < 0.0) {
        float d = max(0.0, dot(norm, normalize(vec3(10, 8, 13))));
        colorBase += doDithering(d, dither, 4.0)*0.4;
    } else if (guns < 0.5) {
        colorBase.rgb = FRIEND_COLOR;
        if (reguns < 0.5) colorBase.rgb = mix(colorBase.rgb, vec3(0.3), 0.8);
        if (radius < 1.0) colorBase.rgb = vec3(0);
        if (uv.y > 5.5 && uv.y < 6.5) colorBase.rgb = vec3(0);
    }
        
    float mm = min(radius, guns);
    if (mm > 0.0) {
        if (mm > 1.0) colorBase.a = 0.0;
        else colorBase = vec4(0, 0, 0, 1);
    } else colorBase.a = 1.0;
    
    colorBase.a *= 1.0 - frac;
    
    colorBase.rgb = mix(colorBase.rgb, vec3(1), frac);
    
    // add explosions
    for (int i = 0 ; i < 8 ; i++) {
        vec2 decal = vec2(hash1(float(i)*0.41355+seed),
                          hash1(float(i)*9.00412+seed*9.3153))*2.0-1.0;
        decal *= 10.0;
        float rad = hash1(float(i)*431.412+seed*124.312)*20.0;
        float start = float(i)*0.1;
        float explofrac = smoothstep(start, start+0.1, frac);
        float explo = explosion(float(i)*seed, uv+decal, explofrac, 16.0 + rad);
        colorBase += vec4(FRIEND_COLOR, 1)*explo;
    }
    
    return colorBase;
}

// bbox for the ennemies
vec2 getShipBBox( in int index ) {
    if (index < 28) return vec2(50);
    if (index < 30) return vec2(150);
    if (index < 31) return vec2(200);
    return vec2(200, 100);
}

// sprite sheet for the ennemies
vec4 getShipColor( in int index, in vec2 uv, in float frac, in vec4 shipValue ) {
    if (index < 8) return getShipFighterColor(index, uv, frac, shipValue);
    if (index < 16) return getShipKnightColor(index, uv, frac, shipValue);
    if (index < 24) return getShipNinjaColor(index, uv, frac, shipValue);
    if (index < 28) return getShipPillarColor(index, uv, frac, shipValue);
    if (index < 30) return getShipFregateColor(index, uv, frac, shipValue);
    if (index < 31) return getShipMotherColor(index, uv, frac, shipValue);
    return getShipBonusColor(index, uv, frac, shipValue);
}

// round to nearest pixel
vec2 roundToWorld( in vec2 pixel ) {
    pixel = floor(pixel / pixelSize);
    pixel *= pixelSize;
    pixel += pixelSize * 0.5;
    return pixel;
}

// planets palette
vec3 pal( in float t ) {
    const vec3 a = vec3(0.4,0.7,0.8);
    const vec3 b = vec3(0.3,0.3,0.3);
    const vec3 c = vec3(1.0,1.3,2.2);
    const vec3 d = vec3(0.5,0.20,0.25);
    return a + b*cos( 6.28318*(c*t+d) );
}

// planets background
vec4 getPlanets( in vec2 uv ) {
    uv *= rot(5.58231);
    const vec2 grid = vec2(900.0);
    
    vec2 planet = floor(uv / grid) + 0.5;
    planet *= grid;
    // randomize the planet
    vec3 seed = hash3( planet );
    float radius = 50.0 + seed.z * 150.0;
    planet += (seed.xy * 2.0 - 1.0) * (grid * 0.5 - radius - 100.0);
    vec2 delta = (uv - planet) / radius;
    float x = length(delta);
    
    vec3 randColor = pal(seed.z);
    vec4 baseColor = vec4(randColor, 1.0-smoothstep(0.95, 1.0, x));
    
    if (x < 1.0) {
        vec3 norm = normalize(vec3(delta, sqrt(1.0-x*x)));
        vec3 nnorm = norm;

        // rotate the normal randomly
        vec3 seed2 = hash3( planet + 12.0032 );
        norm.yz *= rot((seed2.y*2.0-1.0)*PI*0.5);
        norm.xy *= rot(seed2.x*2.0*PI+gameplayGlobalTime*0.1);

        // convert to spherical coordinates
        vec2 sphere = vec2(atan(norm.y/norm.x), acos(norm.z));

        float n = noise((norm + seed)*3.0)*0.7;
        n += noise((norm + seed*12.43)*5.0)*0.4;
        n += noise((norm + seed*242.47)*12.0)*0.2;
        n = clamp(n, 0.0, 1.0);
        baseColor.rgb = mix(baseColor.rgb, randColor-0.3, n);

        // add spiralling clouds
        float clouds = sin(sphere.y*10.0+sphere.x*2.0-gameplayGlobalTime)*0.5+0.5;
        clouds *= smoothstep(0.0, 0.2, sphere.y);
        clouds *= 1.0-smoothstep(PI-0.2, PI, sphere.y);
        clouds *= noise((norm + seed*15.43)*4.0);
        clouds *= noise((norm + seed*154.2)*2.0);
        baseColor.rgb = mix(baseColor.rgb, vec3(1.0), clouds);
        
        // add light
        float light = max(0.0, dot(nnorm, normalize(vec3(-1, 3, 6))));
        baseColor.rgb *= light;
    }

    // add the atmosphere
    float atmos = smoothstep(radius-50.0, radius, x*radius);
    atmos *= 1.0 - smoothstep(radius, radius+40.0, x*radius);
    baseColor = mix(baseColor, vec4(randColor*0.75, 1.0), atmos*0.9);
    
    return baseColor;
}

// sci-fi background
vec4 getGrebble( in vec2 uv, in float alpha, in float baseDither ) {
    float totalAlpha = 0.0;
    float top = 0.0;
    float ao = 1.0;
    float detail = 0.0;
    
    for (int i = 0 ; i < 3 ; i++) {
        // size of the frame
        vec2 scale = vec2(150.0+float(i)*60.0, 80.0+float(i)*30.0);
        if (imod(i, 3) == 0) scale.xy = scale.yx;
        
        // random offset
        vec2 uuv = uv;
        uuv += vec2(hash1(float(i)*12.442),
                    hash1(float(i)*72.247))*scale;
        // animate the offset
        float ani = imod(i, 2) == 0 ? -1.0:+1.0;
        uuv.x += gameplayGlobalTime*sign(ani)/scale.x*600.0;
        // snap to the grid
        uuv = floor(uuv+0.5);
        
        // get the center of the box
        vec2 center = floor(uuv/scale)+0.5;
        center *= scale;
        
        // 1 seed per box, get the dimensions of the box
        float seed = dot(center, vec2(0.4125, 0.90512));
        vec2 boxDim = vec2(hash1(seed),
                           hash1(seed*52.552))*0.2+0.3;
        boxDim *= scale;
        float height = hash1(seed+float(i)*0.5125);
        height *= height;
        
        // dither value
        float dither = texture2D(iChannel3, uuv/256.0, -100.0).g;
        float tt = 0.5 + (dither*2.0-1.0)*0.5*(1.0-height);
        
        // offset the box itself
        vec2 decal = vec2(hash1(seed*12.441),
                          hash1(seed*312.77))*2.0-1.0;
        decal *= (scale*0.5)-boxDim;
        center += decal*0.9;
        center = floor(center+0.5);
        
        // distance to the box
        vec2 inBox = uuv-center;
        float dist = box(inBox, boxDim);
        // rivets center
        vec2 rivets = center + sign(inBox)*(boxDim-8.0);
        float distRivets = length(uuv-rivets)-3.0;
            
        float noiseFactor = 1.0 - abs(2.0*(alpha-0.5));
        float noiseTot = noise(vec3(inBox*0.5, 6.0))*0.2;
        noiseTot += noise(vec3(inBox*0.2, 7.0))*0.2;
        noiseTot += noise(vec3(inBox*0.05, 8.0))*0.6;
        float thisAlpha = alpha + noiseFactor*noiseTot;
        
        // draw on top
        if (dist < 0.0 && thisAlpha > tt && height > top) {
            totalAlpha = 1.0;
            top = height;
            ao = smoothstep(1.0, 3.0, -dist);
            ao *= smoothstep(0.2,0.5, distRivets);
            detail = texture2D(iChannel2, inBox / scale / 3.0).r;
            detail += texture2D(iChannel3, inBox / 17.4457, -100.0).r*2.0;
        }
    }
    
    top = sqrt(top);
    float value = 0.1 + top*0.3 + detail*0.05;
    value -= (1.0-ao)*0.15;
    
    return vec4(BACKGROUND_COLOR*value, totalAlpha);
}

// transition indicator
vec4 getTransitionPanel( in vec2 uv, in float index ) {
    float dither = texture2D(iChannel2, uv/8.0).r;
    
    // get some light
    const vec2 lightSize = vec2(100.0, 100.0);
    float lightIndex = floor(uv.y / lightSize.y);
    float ss = sign(uv.x);
    ss = ss == 0.0 ? 1.0: ss;
    vec2 uvLight = vec2(ss, lightIndex + 0.5);
    uvLight.y = clamp(uvLight.y, -2.5, 3.5);
    uvLight *= lightSize;
    float lightValue = fract(lightIndex*0.1-gameplayGlobalTime*0.25);
    lightValue *= lightValue; lightValue *= lightValue;
    lightValue *= lightValue; lightValue *= lightValue;
    float distToLight = length(uv-uvLight);
    
    vec4 baseColor = vec4(BACKGROUND_COLOR, 0.0);
    
    // set light pole
    if (distToLight < 6.0) {
        baseColor.a = 1.0;
        if (distToLight > 5.0) baseColor.rgb = vec3(0.0);
        else {
            baseColor.rgb *= 0.2;
            float lens = 1.0-smoothstep(0.0, 6.0, distToLight);
            lens = doDithering(lens, dither, 4.0);
            baseColor.rgb += BACKGROUND_COLOR*lens*0.45*(lightValue*0.5+0.5);
        }
    }
    
    // box center
    const vec2 boxCenter = vec2(0.0, 350.0);
    const vec2 boxDim = vec2(60.0, 40.0);
    vec2 uvBox = uv-boxCenter;
    
    float boxDist = box(uvBox, boxDim)-5.0;
    if (boxDist < 0.0) {
        baseColor.a = 1.0;
        if (boxDist > -1.5) baseColor.rgb = vec3(0.0);
        else {
            float noise = texture2D(iChannel3, uvBox/256.0, -100.0).r;
            vec3 color = mix(BACKGROUND_COLOR, vec3(0.2), 0.6);
            baseColor.rgb = color+noise*0.1;
            baseColor -= smoothstep(-5.0, 0.0, boxDist)*0.3;
            float inBoxDist = box(uvBox, boxDim-5.0)-5.0;
            if (inBoxDist < 0.0) {
                if (inBoxDist > -2.5) baseColor.rgb = vec3(0.0);
                else {
                    float d = dot(uvBox, vec2(3, 1)*0.1);
                    d = sin(d)*0.5+0.5;
                    d = smoothstep(0.7, 1.0, d);
                    float dd = dot(uvBox, vec2(-5, 3)*0.3);
                    dd = sin(dd)*0.5+0.5;
                    vec3 grey = mix(baseColor.rgb, vec3(0.4), 0.7);
                    baseColor.rgb = mix(grey, vec3(0.3), d);
                    baseColor.rgb -= dd*noise*0.5;
                    baseColor -= smoothstep(-15.0, 0.0, inBoxDist)*0.2;
                    index = min(index, 99.0);
                    float a = mod(index, 10.0);
                    float b = floor(index / 10.0);
                    float digit = 0.0;
                    digit = max(digit, SampleDigit(a, uvBox*0.02 + vec2(-0.15, 0.5)));
                    digit = max(digit, SampleDigit(b, uvBox*0.02 + vec2(0.9, 0.5)));
                    baseColor.rgb += digit*BACKGROUND_COLOR*1.1;
                }
            }
        }
    }
    
    // light glow
    float lightRadius = (1.0-smoothstep(0.0, 45.0, distToLight))*lightValue;
    lightRadius *= 0.5;
    
    baseColor = mix(baseColor, vec4(BACKGROUND_COLOR*2.0, 1.0), lightRadius);
    
    return baseColor;
}

// background color
vec3 getBackground( in vec2 uv ) {
    float dither = texture2D(iChannel2, uv / 8.0).r;
    vec2 center = vec2(0, (gameplayGlobalTime*60.0)*SCROLL_SPEED + 175.0);
    center = floor(center+0.5);
    
    vec3 baseColor = BACKGROUND_COLOR*0.1;
    
    // stars 1
    float stars1 = 0.0;
    vec2 uvStars1 = (uv * 5.0 + center) * 0.04;
    uvStars1 *= rot(2.1258);
    stars1 += noise(vec3(uvStars1, 0.0))*0.38;
    uvStars1 *= rot(2.338);
    stars1 += noise(vec3(uvStars1, 1.0))*0.38;
    uvStars1 *= rot(1.1412);
    stars1 += noise(vec3(uvStars1, 2.0))*0.38;
    //stars1 = pow(abs(stars1), 120.0);
    stars1 = smoothstep(0.96, 1.0, stars1);
    baseColor = mix(baseColor, BACKGROUND_COLOR*1.5, stars1*0.75);
    
    // stars 2
    float stars2 = 0.0;
    vec2 uvStars2 = (uv * 2.5 + center) * 0.06;
    uvStars2 *= rot(2.1258);
    stars2 += noise(vec3(uvStars2, 3.0))*0.38;
    uvStars2 *= rot(2.338);
    stars2 += noise(vec3(uvStars2, 4.0))*0.38;
    uvStars2 *= rot(1.1412);
    stars2 += noise(vec3(uvStars2, 5.0))*0.38;
    //stars2 = pow(abs(stars2), 120.0);
    stars2 = smoothstep(0.98, 1.0, stars2);
    baseColor = mix(baseColor, BACKGROUND_COLOR*2.0, stars2*0.75);
    
    // add planets
    //vec4 getPlanets( in vec2 uv ) {
    vec2 uvPlanets = (uv * 2.0 + center);
    uvPlanets = floor(uvPlanets/2.0+0.5);
    vec4 planets = getPlanets(uvPlanets*2.0);
    float planetsDither = texture2D(iChannel2, uvPlanets/8.0).r;
    planets.a = doDithering(planets.a, planetsDither, 8.0);
    planets.r = doDithering(planets.r, planetsDither, 8.0);
    planets.g = doDithering(planets.g, planetsDither, 8.0);
    planets.b = doDithering(planets.b, planetsDither, 8.0);
    baseColor = mix(baseColor, planets.rgb, planets.a);
    
    // add more shit under the scifi stuff
    vec2 uvRuins = uv * 1.5 + center;
    float ruinsFact = fract(uvRuins.y/TRANSITION);
    uvRuins /= 1.5;
    uvRuins.x -= gameplayGlobalTime*8.0;
    uvRuins = floor(uvRuins+0.5);
    float alphaRuins = smoothstep(0.2, 0.4, ruinsFact);
    alphaRuins *= 1.0 - smoothstep(0.5, 0.7, ruinsFact);
    alphaRuins *= noise(vec3(uvRuins*0.01, 6.0));
    alphaRuins *= noise(vec3(uvRuins*0.05, 7.0));
    vec2 ruinsDistV = abs(mod(uvRuins, 40.0)*2.0 - 20.0);
    float ruinsDist = 40.0 - min(ruinsDistV.x, ruinsDistV.y);
    vec3 ruinsColor = BACKGROUND_COLOR*0.2;
    if (ruinsDist < 30.0) ruinsColor = vec3(0);
    if (ruinsDist < 27.5) alphaRuins = 0.0;
    float noise = texture2D(iChannel3, uvRuins / 256.0, -100.0).r;
    alphaRuins = step(0.25, alphaRuins+noise*0.2);
    baseColor = mix(baseColor, ruinsColor, alphaRuins);
    
    // set grebbles
    float greb = fract((uv.y + center.y)/TRANSITION);
    float alpha = smoothstep(0.3, 0.4, greb);
    alpha *= 1.0 - smoothstep(0.5, 0.6, greb);
    if (alpha > 0.0) {
        vec2 uvGreb = (uv + center);
        vec4 grebble = getGrebble(uvGreb, alpha, dither*0.998+0.001);
        baseColor = mix(baseColor, grebble.rgb, grebble.a);
    }
    
    // add the transition panel
    vec2 thingUV = uv * 0.7 + center;
    thingUV.y += TRANSITION*0.75; // offset into the grebble part
    vec2 thingPos = vec2(0.0, floor(thingUV.y/TRANSITION+0.5));
    float index = thingPos.y;
    thingPos *= TRANSITION;
    
    thingUV /= 0.7;
    thingPos /= 0.7;
    thingUV = floor(thingUV+0.5);
    thingPos = floor(thingPos+0.5);
    
    vec4 thing = getTransitionPanel((thingUV-thingPos), index);
    thing.a = doDithering(thing.a, dither, 16.0);
    baseColor = mix(baseColor, thing.rgb, thing.a);
    
    
    return baseColor;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    // the size of a pixel depends on the resolution
    pixelSize = floor(iResolution.y / 350.0); // 1 pixel in windowed
    pixelSize = max(pixelSize, 1.0);
    // the size of the playing field is a multiple of pixelsize
    vec2 play = vec2(pixelSize * 160.0);
    
    // get game stats
    vec4 game = loadValue(ADR_GAME);
    vec4 scoreState = loadValue(ADR_SCORE);
    float gameOver = game.x;
    float gameTimestamp = game.y;
    float gameOverTimestamp = game.z;
    float score = scoreState.x;
    float highscore = scoreState.y;
    
    gameplayGlobalTime = float(iFrame) - gameTimestamp;
    gameplayGlobalTime /= 60.0; // 60 FPS (hopefully)

    // round uv to pixelSize for big pixels
    vec2 uv = fragCoord.xy - iResolution.xy * 0.5;
    vec2 uvFine = uv;
    uv = roundToWorld(uv);
    
    bool outside = (uv.x>play.x)||(uv.x<-play.x)||(uv.y>play.y)||(uv.y<-play.y);
    
    // do the background color
    if (!outside) {
        fragColor.rgb = getBackground(uv/pixelSize);
    }
        
    // display collision mesh with pixel perfect accuracy
    vec2 colUV = (uvFine / play) * 0.5 + 0.5;
    colUV *= 128.0 / iResolution.xy;
    vec4 particles = texture2D( iChannel1, colUV );
    if (particles.r < 0.0) {
        fragColor.rgb = ENNEMY_COLOR;
        fragColor.rgb += (1.0-smoothstep(-0.03, 0.0, particles.r))*1.5;
    }
    if (particles.g < 0.0) {
        fragColor.rgb = FRIEND_COLOR;
        fragColor.rgb += (1.0-smoothstep(-0.03, 0.0, particles.g))*2.0;
    }
    
    // dithered for added retroness
    float dither = texture2D( iChannel2, uv / pixelSize / 8.0 ).r;
    
    // for each ennemies
    if (!outside) { // don't draw outside the playing zone
        for (int i = 0 ; i < 32 ; i++) {
            vec2 adr = ADR_ALIEN_SHIP_FIRST + vec2(float(i), 0.0);
            vec4 other = loadValue(adr);
            vec2 shipPos = roundToWorld(other.xy*play);
            vec2 displayPos = (uv-shipPos)/pixelSize;
            vec4 color = vec4(0);

            float delta = float(iFrame) - other.z;
            float white = 1.0;
            float frac = 0.0;

            float inBB = box(displayPos, getShipBBox(i));

            if (other.w < 0.5) {
                frac = smoothstep(0.0, 150.0, delta);
            } else {
                white = 1.0-smoothstep(0.0, 10.0, delta);
            }

            if (frac < 1.0 && inBB < 0.0) {
                color = getShipColor( i, displayPos, frac, other );
            }

            color.a = doDithering(color.a, dither, 4.0);

            color.rgb = mix(color.rgb, vec3(1), white);
            fragColor.rgb = mix(fragColor.rgb, color.rgb, color.a);
        }
    }
    
    // player
    vec2 playerPos = roundToWorld(loadValue(ADR_PLAYER).xy*play);
    vec4 playerColor = vec4(0);
    if (gameOver > 0.5) {
        float delta = float(iFrame) - gameOverTimestamp;
        float frac = smoothstep(0.0, 150.0, delta);
        playerColor = getPlayerShipColor( (uv-playerPos)/pixelSize, frac, gameTimestamp );
    } else {
        playerColor = getPlayerShipColor( (uv-playerPos)/pixelSize, 0.0, 0.0 );
    }
    playerColor.a = doDithering(playerColor.a, dither, 4.0);
    fragColor.rgb = mix(fragColor.rgb, playerColor.rgb, playerColor.a);
    
    // add a border around the game zone
    if (outside) {
        
        float distToPlay = box(uv, play)/pixelSize;
        
        if (distToPlay < 2.0) {
            fragColor.rgb = vec3(0);
        } else if (distToPlay < 5.0) {
            fragColor.rgb = BACKGROUND_COLOR*1.2;
        } else if (distToPlay < 7.0) {
            fragColor.rgb = vec3(0);
        } else {
            
            vec3 noise = texture2D(iChannel3, uv/128.0, -100.0).rgb;
            float dither = texture2D(iChannel2, uv/8.0).r;
            
            float d = dot(uv/pixelSize, vec2(-0.831, 0.313));
            float dd = dot(uv/pixelSize, vec2(10.4412, 10.9803));
            
            d = sin(d*0.1)*0.5+0.5;
            d = smoothstep(0.2, 0.5, d);
            dd = sin(dd*0.05)*0.5+0.5;
            dd = smoothstep(0.0, 1.0, dd);
            
            vec3 baseColor = BACKGROUND_COLOR*0.2+d*0.05;
            baseColor -= dd*0.4*noise.r;
            baseColor += noise.g*0.1;
            float shadow = 1.0-smoothstep(0.0, 30.0, distToPlay);
            vec2 vign = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
            shadow += dot(vign, vign)*0.7;

            // now display the score in the top left corner
            vec2 uvScore = uv + iResolution.xy*0.5;
            uvScore.x -= iResolution.x * 0.5;
            uvScore.x += (iResolution.x*0.5+play.x)*0.5;
            uvScore.y -= iResolution.y;
            uvScore /= pixelSize;
            uvScore -= vec2(0, -50);
            const vec2 scoreBox = vec2(42, 20);
            float distScore = box(uvScore, scoreBox);
            
            // add a shadow around the score box
            shadow += 1.0-smoothstep(6.0, 20.0, distScore);
            shadow = doDithering(shadow, dither, 4.0);
            baseColor -= shadow*0.2;
            fragColor.rgb = baseColor;
            
            if (distScore < 7.0) {
                if (distScore > 6.0) {
                    fragColor.rgb = vec3(0);
                } else if (distScore > 3.0) {
                    fragColor.rgb = BACKGROUND_COLOR*1.2;
                } else if (distScore > 1.0) {
                    fragColor.rgb = vec3(0);
                } else {
                    fragColor.rgb = vec3(0);

                    // display game stats
                    float scoreAcc = min(999999.0, score);
                    float colorAcc = 0.0;

                    // score
                    vec2 startScore = uvScore*0.09;
                    startScore += vec2(-2.5, -0.5);
                    for (int i = 0 ; i < 6 ; i++) {
                        float digit = mod(scoreAcc, 10.0);
                        scoreAcc -= digit;
                        scoreAcc *= 0.1;
                        colorAcc = max(colorAcc, SampleDigit(digit, startScore));
                        startScore.x += 1.0;
                        if (imod(i-2, 3) == 0) startScore.x += 0.7;
                    }

                    // highscore
                    scoreAcc = min(999999.0, highscore);
                    vec2 startHigh = uvScore*0.09;
                    startHigh += vec2(-2.5, +1.4);
                    for (int i = 0 ; i < 6 ; i++) {
                        float digit = mod(scoreAcc, 10.0);
                        scoreAcc -= digit;
                        scoreAcc *= 0.1;
                        colorAcc = max(colorAcc, SampleDigit(digit, startHigh));
                        startHigh.x += 1.0;
                        if (imod(i-2, 3) == 0) startHigh.x += 0.7;
                    }

                    fragColor.rgb += colorAcc;
                }
            }
        }
    }
    
    fragColor.a = 1.0;
}