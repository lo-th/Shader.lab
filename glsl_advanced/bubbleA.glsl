// shared game state

const int ENTITIES_START_Y = 1;
const int MAX_ENTITIES = 64;
const int NUM_DYNAMIC_ROWS = 3;

const int LEVEL_WIDTH = 28;
const int LEVEL_HEIGHT = 25;
const int LEVEL_START_Y = 32;
const int NUM_LEVELS = 4;

const int FONT_START_Y = 8;
const int FONT_HEIGHT = 8;
const int FONT_WIDTH = 8;

const int SPRITE_WIDTH = 16;
const int SPRITE_HEIGHT = 16;
const int SPRITE_START_Y = 16;

const int STRINGS_START_Y = 60;
const int STR_GAME_OVER = 0;
const int STR_BEGINNING0 = 1;
const int STR_BEGINNING1 = 2;
const int STR_BEGINNING2 = 3;
const int STR_BEGINNING3 = 4;
const int STR_BEGINNING4 = 5;
const int STR_PUSH_START = 6;
const int STR_1UP = 7;
const int STR_HIGH_SCORE = 8;
const int STR_00 = 9;
const int STR_INSERT = 10;
const int STR_COIN = 11;
const int STR_TO = 12;
const int STR_CONTINUE = 13;
const int STR_COPYRIGHT = 14;
const int STR_ALL_RIGHTS = 15;
const int STR_INSERT_COIN = 16;    
const int NUM_STRINGS = 17;

const int LOGO_START_Y = 200;
const int LOGO_WIDTH = 300;
const int LOGO_HEIGHT = 150;

const float ENTITY_TYPE_BUBBLE = 1.0;
const float ENTITY_TYPE_MONSTER = 2.0;
const float ENTITY_TYPE_TUMBLING_MONSTER = 3.0;
const float ENTITY_TYPE_ITEM = 4.0;
const float ENTITY_TYPE_SCORE = 5.0;

const int MONSTER_SPRITE_START_IDX = 5;
const int ITEM_SPRITE_START_IDX = 9;

const int NUM_PLACE_PLAYER_FRAMES = 120;

const float BUBBLE_ATTACK_FRAMES = 20.0;
const float BUBBLE_DEATH_FRAMES = 30.0;
const float BUBBLE_LIFE_FRAMES = 1200.0;
const float BUBBLE_FLOW_POWER = 0.4;
const float BUBBLE_ATTACK_EXP_SCALE = .15;
const float BUBBLE_POP_THRESHOLD = 4.0;
const float BUBBLE_COOLDOWN = 15.0;
const float RESPAWN_FRAMES = 120.0;
const float MONSTER_FREE_FRAME = 120.0;
const float MONSTER_HIT_DIST_SQ = 60.0;

const float WIN_DELAY_FRAMES = 150.0;
const float INVULNERABLE_FRAMES = 90.0;

const float PI = 3.1415926535;
const float GRAVITY = 0.10;
const float TERMINAL_VELOCITY = 1.0;
const float MOVEMENT_SPEED = 1.5;
const float JUMP_VELOCITY = 3.0;
const float PUSH_VECTOR_SCALE = .3;
const vec2 txGameState =    vec2(0.0,0.0);
const vec2 txGameState2 =   vec2(1.0,0.0);
const vec2 txGameState3 =   vec2(2.0,0.0);
const vec2 txPlayerPos =    vec2(3.0,0.0);  
const vec2 txPlayerSprite = vec2(4.0,0.0);  //vec4(sprite_idx, mirrored, 0, 0)
const vec2 txPlayerFlags =  vec2(5.0,0.0);
// private game state
const vec2 txPlayerVel =    vec2(6.0,0.0);
const vec2 txKeyWasDown =   vec2(7.0,0.0);
const vec2 txCoolDown =     vec2(8.0,0.0);
const vec2 txStaticDataInited = vec2(9.0,0.0);

const int SKIP_INTRO = 0;
const int START_LEVEL = 1;

const float KEY_SPACE = 32.5/256.0;
const float KEY_LEFT  = 37.5/256.0;
const float KEY_UP    = 38.5/256.0;
const float KEY_RIGHT = 39.5/256.0;

const int _A = 10, _B = 11, _C = 12, _D = 13, _E = 14, _F = 15, _G = 16, _H = 17, _I = 18, _J = 19, _K = 20, _L = 21, _M = 22, _N = 23, _O = 24, _P = 25, _Q = 26, _R = 27, _S = 28, _T = 29, _U = 30, _V = 31, _W = 32, _X = 33, _Y = 34, _Z = 35, _COPYRIGHT = 36, _EXCLAMATION = 37, _SPACE = 38;

#define HASHSCALE1 .1031
float hash11(float p)
{
    vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 Logo(int x, int y)
{
    y += 50;
    vec2 coord = vec2(x, y);
    float radius = 5.0;
    float radiusSq = radius*radius;
    vec2 pos = vec2(0);
    
    const int NUM_STEPS = 50;
    const int NUM_OBJECTS = 13;
    const int NUM_PARTS = 3;
    const float STEP_SIZE = 1.5;
    
    #define P(_T) enabled = true; if(phase == ph++ && t >= (_T)) phase++, 
    #define E(_T) if(phase == ph++ && t >= (_T)) break;
    
    float value = 0.0;  //0.0: not drawn, 1.0: inner, 2.0: edge, 3.0: shadow
    
    vec2 shadowOffset = vec2(-3,-2);
    for(int object = 0; object < NUM_OBJECTS; object++)
    {
        for(int pass = 0; pass < 2; pass++)
        {
            for(int part = 0; part < NUM_PARTS; part++)
            {       
                int phase = 0;
                float shortestDistSq = 1e10;
                float hitT = 0.0;

                float angle = 0.0;
                float velocity = 0.0;
                float acceleration = 0.0;
                bool enabled = false;
                bool overrideInner = false;
                for(int i = 0; i < NUM_STEPS; i++)
                {
                    float t = float(i) / float(NUM_STEPS - 1);
                    int ph = 0;
                    
                    // E
                    if(object == 0)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(170,115), angle = -PI*.5;
                            P(0.4) angle += PI*.5;
                            E(0.6);
                        }
                        if(part == 1)
                        {
                            P(0.0) pos=vec2(170,115), angle = -PI*.5;
                            P(0.2) angle += PI*.5;
                            E(0.35);
                        }
                        if(part == 2)
                        {
                            P(0.0) pos=vec2(170,115), angle = 0.0;
                            E(0.2);
                        }
                    }
                    
                    // L
                    if(object == 1)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(155,115), angle = -PI*.5-.2;
                            P(0.4) angle += PI*.5;
                            E(0.6);
                        }
                    }
                    
                    // B
                    if(object == 2)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(130,95), angle = PI*.5;
                            P(0.35) angle -= PI*0.5, acceleration = -0.007;
                            P(0.70) acceleration = 0.004;
                            E(0.82);
                        }
                        if(part == 1)
                        {
                            P(0.0) pos=vec2(130,95), angle = -.3, acceleration = 0.007;
                            P(0.2) overrideInner = true;
                            E(0.35);
                        }
                    }
                    
                    // B
                    if(object == 3)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(108,90), angle = PI*.5-.2;
                            P(0.35) angle -= PI*0.5, acceleration = -0.007;
                            P(0.70) acceleration = 0.004;
                            E(0.82);
                        }
                        if(part == 1)
                        {
                            P(0.0) pos=vec2(108,90), angle = -.5, acceleration = 0.007;
                            P(0.2) overrideInner = true;
                            E(0.37);
                        }
                    }
                    
                    // O
                    if(object == 4)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(95,100), velocity = 0.13;
                            E(0.7);
                        }
                    }
                    
                    // B
                    if(object == 5)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(65,90), angle = PI*.5;
                            P(0.4) angle -= PI*0.5, acceleration = -0.007;
                            P(0.8) acceleration = 0.004;
                            E(0.87);
                        }
                        if(part == 1)
                        {
                            P(0.0) pos=vec2(65,90), angle = -0.2, acceleration = 0.0065;
                            P(0.2) overrideInner = true;
                            E(0.4);
                        }   
                    }
                    
                    // E
                    if(object == 6)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(190,165), angle = -PI*.5-.2;
                            P(0.4) angle += PI*.5;
                            E(0.6);
                        }
                        if(part == 1)
                        {
                            P(0.0) pos=vec2(190,165), angle = -PI*.5-.2;
                            P(0.2) angle += PI*.5;
                            E(0.35);
                        }
                        if(part == 2)
                        {
                            P(0.0) pos=vec2(190,165), angle = -.2;
                            E(0.2);
                        }
                    }
                    
                    // L
                    if(object == 7)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(173,165), angle = -PI*.5-.25;
                            P(0.4) angle += PI*.5;
                            E(0.6);
                        }
                    }
                    
                    // B
                    if(object == 8)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(140,135), angle = PI*.5-.1;
                            P(0.37) angle -= PI*0.5, acceleration = -0.007;
                            P(0.70) acceleration = 0.004;
                            E(0.82);
                        }
                        if(part == 1)
                        {
                            P(0.0) pos=vec2(140,135), angle = -.4, acceleration = 0.007;
                            P(0.2) overrideInner = true;
                            E(0.4);
                        }
                    }
                    
                    // B
                    if(object == 9)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(115,135), angle = PI*.5-.1;
                            P(0.35) angle -= PI*0.5, acceleration = -0.007;
                            P(0.70) acceleration = 0.004;
                            E(0.82);
                        }
                        if(part == 1)
                        {
                            P(0.0) pos=vec2(115,135), angle = -.4, acceleration = 0.007;
                            P(0.2) overrideInner = true;
                            E(0.37);
                        }
                    }
                    
                    // U
                    if(object == 10)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(95,155), angle =-PI*.5-.2;
                            P(0.2) velocity = 0.15;
                            P(0.489) velocity = 0.0;
                            E(0.68);
                        }
                    }
                    
                    // T
                    if(object == 11)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(80,160), angle = -PI*.5+.1;
                            E(0.35);
                        }
                        
                        if(part == 1)
                        {
                            P(0.0) pos=vec2(67,157), angle = .1;
                            E(0.30);
                        }
                    }
                    
                    // S
                    if(object == 12)
                    {
                        if(part == 0)
                        {
                            P(0.0) pos=vec2(60,167), angle = PI+.3;
                            P(0.1) velocity = 0.12;
                            P(0.35) velocity = 0.0;
                            P(0.6) velocity = -0.15;
                            P(0.85) velocity = 0.0;
                            E(0.95);
                        }
                        
                    }
                    
                    
                    if(!enabled) break;

                    velocity += acceleration * STEP_SIZE;
                    angle += velocity * STEP_SIZE;
                    pos += STEP_SIZE * vec2(cos(angle), sin(angle));

                    vec2 offset = (pass == 0) ? shadowOffset : vec2(0,0);
                    vec2 delta = (coord + offset) - pos;
                    float lenSq = dot(delta, delta);
                    if(lenSq < radiusSq)
                    {
                        if(lenSq < shortestDistSq)
                        {
                            shortestDistSq = lenSq;
                            hitT = t;

                            if(pass == 0)
                                value = 3.0;
                            else
                                if(lenSq < radiusSq * 0.4)
                                {
                                    value = 1.0;
                                }
                                else
                                {
                                    if(value != 1.0 || overrideInner)
                                        value = 2.0;
                                }
                        }
                    }
                }
            }
        }
    }
    
    vec3 color = vec3(0);
    float len = 1e10;
    for(int i = 0; i < 200; i++)
    {
        float t = float(i) + 1200.0;
        vec2 p = vec2((hash11(t)*2.0)*80.0-80.0,(hash11(t+1000.0)*2.0)*40.0-40.0) + vec2(128, 125);
        len = min(len, length(p - coord) - hash11(t + 2000.0)*25.+8.0);
    }
    if(len < 10.0)
    {
        color = mix(vec3(250,161,0)/255.0, color, smoothstep(9.5, 10.0, len));
        color = mix(vec3(0), color, smoothstep(6.5, 7.0, len));
        color = mix(vec3(255,240,32)/255.0, color, smoothstep(5.0, 5.5, len));
    }
    
    if(value == 1.0)
        color = vec3(-1);
    else if(value >= 2.0)
        color = vec3(0);
    
    return color;
}



//hack hack: encode bits into floating point mantissa. much faster to compile than any of the alternatives
#define D24(_y, _d0, _d1, _d2, _d3, _d4, _d5, _d6, _d7, _d8, _d9, _d10, _d11, _d12, _d13, _d14, _d15, _d16, _d17, _d18, _d19, _d20, _d21, _d22, _d23) v = (y == (_y)) ? (float(_d0)*0.5 + float(_d1)*1.0 + float(_d2)*2.0 + float(_d3)*4.0 + float(_d4)*8.0 + float(_d5)*16.0 + float(_d6)*32.0 + float(_d7)*64.0 + float(_d8)*128.0 + float(_d9)*256.0 + float(_d10)*512.0 + float(_d11)*1024.0 + float(_d12)*2048.0 + float(_d13)*4096.0 + float(_d14)*8192.0 + float(_d15)*16384.0 + float(_d16)*32768.0 + float(_d17)*65536.0 + float(_d18)*131072.0 + float(_d19)*262144.0 + float(_d20)*524288.0 + float(_d21)*1048576.0 + float(_d22)*2097152.0 + float(_d23)*4194304.0) : v;

bool Font(int x, int y, int n)
{
    if(x < 0 || x >= FONT_WIDTH || y < 0 || y >= FONT_HEIGHT) return false;
    float v = 0.0;
    y = (FONT_HEIGHT - 1) - y;
    
    int b = n / 3;
    
    
    if(b == 0)
    {
        // 0, 1, 2
        D24(0, 0,0,0,1,1,1,0,0, 0,0,0,0,1,1,0,0, 0,0,1,1,1,1,1,0)
        D24(1, 0,0,1,0,0,1,1,0, 0,0,0,1,1,1,0,0, 0,1,1,0,0,0,1,1)
        D24(2, 0,1,1,0,0,0,1,1, 0,0,0,0,1,1,0,0, 0,0,0,0,0,1,1,1)
        D24(3, 0,1,1,0,0,0,1,1, 0,0,0,0,1,1,0,0, 0,0,0,1,1,1,1,0)
        D24(4, 0,1,1,0,0,0,1,1, 0,0,0,0,1,1,0,0, 0,0,1,1,1,1,0,0)
        D24(5, 0,0,1,1,0,0,1,0, 0,0,0,0,1,1,0,0, 0,1,1,1,0,0,0,0)
        D24(6, 0,0,0,1,1,1,0,0, 0,0,1,1,1,1,1,1, 0,1,1,1,1,1,1,1) 
    }
    else if(b == 1)
    {
        // 3, 4, 5
        D24(0, 0,0,1,1,1,1,1,1, 0,0,0,0,1,1,1,0, 0,1,1,1,1,1,1,0)
        D24(1, 0,0,0,0,0,1,1,0, 0,0,0,1,1,1,1,0, 0,1,1,0,0,0,0,0)
        D24(2, 0,0,0,0,1,1,0,0, 0,0,1,1,0,1,1,0, 0,1,1,1,1,1,1,0)
        D24(3, 0,0,0,1,1,1,1,0, 0,1,1,0,0,1,1,0, 0,0,0,0,0,0,1,1)
        D24(4, 0,0,0,0,0,0,1,1, 0,1,1,1,1,1,1,1, 0,0,0,0,0,0,1,1)
        D24(5, 0,1,1,0,0,0,1,1, 0,0,0,0,0,1,1,0, 0,1,1,0,0,0,1,1)
        D24(6, 0,0,1,1,1,1,1,0, 0,0,0,0,0,1,1,0, 0,0,1,1,1,1,1,0)        
    }
    else if(b == 2)
    {
        // 6, 7, 8
        D24(0, 0,0,0,1,1,1,1,0, 0,1,1,1,1,1,1,1, 0,0,1,1,1,1,0,0)
        D24(1, 0,0,1,1,0,0,0,0, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,0)
        D24(2, 0,1,1,0,0,0,0,0, 0,0,0,0,0,1,1,0, 0,1,1,1,0,0,1,0)
        D24(3, 0,1,1,1,1,1,1,0, 0,0,0,0,1,1,0,0, 0,0,1,1,1,1,0,0)
        D24(4, 0,1,1,0,0,0,1,1, 0,0,0,1,1,0,0,0, 0,1,0,0,1,1,1,1)
        D24(5, 0,1,1,0,0,0,1,1, 0,0,0,1,1,0,0,0, 0,1,0,0,0,0,1,1)
        D24(6, 0,0,1,1,1,1,1,0, 0,0,0,1,1,0,0,0, 0,0,1,1,1,1,1,0)
    }
    else if(b == 3)
    {
        // 9, A, B
        D24(0, 0,0,1,1,1,1,1,0, 0,0,0,1,1,1,0,0, 0,1,1,1,1,1,1,0)
        D24(1, 0,1,1,0,0,0,1,1, 0,0,1,1,0,1,1,0, 0,1,1,0,0,0,1,1)
        D24(2, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1)
        D24(3, 0,0,1,1,1,1,1,1, 0,1,1,0,0,0,1,1, 0,1,1,1,1,1,1,0)
        D24(4, 0,0,0,0,0,0,1,1, 0,1,1,1,1,1,1,1, 0,1,1,0,0,0,1,1)
        D24(5, 0,0,0,0,0,1,1,0, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1)
        D24(6, 0,0,1,1,1,1,0,0, 0,1,1,0,0,0,1,1, 0,1,1,1,1,1,1,0)
    }
    else if(b == 4)
    {
        // C, D, E
        D24(0, 0,0,0,1,1,1,1,0, 0,1,1,1,1,1,0,0, 0,1,1,1,1,1,1,1)
        D24(1, 0,0,1,1,0,0,1,1, 0,1,1,0,0,1,1,0, 0,1,1,0,0,0,0,0)
        D24(2, 0,1,1,0,0,0,0,0, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,0,0)
        D24(3, 0,1,1,0,0,0,0,0, 0,1,1,0,0,0,1,1, 0,1,1,1,1,1,1,0)
        D24(4, 0,1,1,0,0,0,0,0, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,0,0)
        D24(5, 0,0,1,1,0,0,1,1, 0,1,1,0,0,1,1,0, 0,1,1,0,0,0,0,0)
        D24(6, 0,0,0,1,1,1,1,0, 0,1,1,1,1,1,0,0, 0,1,1,1,1,1,1,1)
    }
    else if(b == 5)
    {
        // F, G, H
        D24(0, 0,1,1,1,1,1,1,1, 0,0,0,1,1,1,1,1, 0,1,1,0,0,0,1,1)
        D24(1, 0,1,1,0,0,0,0,0, 0,0,1,1,0,0,0,0, 0,1,1,0,0,0,1,1)
        D24(2, 0,1,1,0,0,0,0,0, 0,1,1,0,0,0,0,0, 0,1,1,0,0,0,1,1)
        D24(3, 0,1,1,1,1,1,1,0, 0,1,1,0,0,1,1,1, 0,1,1,1,1,1,1,1)
        D24(4, 0,1,1,0,0,0,0,0, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1)
        D24(5, 0,1,1,0,0,0,0,0, 0,0,1,1,0,0,1,1, 0,1,1,0,0,0,1,1)
        D24(6, 0,1,1,0,0,0,0,0, 0,0,0,1,1,1,1,1, 0,1,1,0,0,0,1,1)
    }
    else if(b == 6)
    {
        // I, J, K
        D24(0, 0,0,1,1,1,1,1,1, 0,0,0,0,0,0,1,1, 0,1,1,0,0,0,1,1)
        D24(1, 0,0,0,0,1,1,0,0, 0,0,0,0,0,0,1,1, 0,1,1,0,0,1,1,0)
        D24(2, 0,0,0,0,1,1,0,0, 0,0,0,0,0,0,1,1, 0,1,1,0,1,1,0,0)
        D24(3, 0,0,0,0,1,1,0,0, 0,0,0,0,0,0,1,1, 0,1,1,1,1,0,0,0)
        D24(4, 0,0,0,0,1,1,0,0, 0,0,0,0,0,0,1,1, 0,1,1,1,1,1,0,0)
        D24(5, 0,0,0,0,1,1,0,0, 0,1,1,0,0,0,1,1, 0,1,1,0,1,1,1,0)
        D24(6, 0,0,1,1,1,1,1,1, 0,0,1,1,1,1,1,0, 0,1,1,0,0,1,1,1)
    }
    else if(b == 7)
    {
        // L, M, N
        D24(0, 0,1,1,0,0,0,0,0, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1)
        D24(1, 0,1,1,0,0,0,0,0, 0,1,1,1,0,1,1,1, 0,1,1,1,0,0,1,1)
        D24(2, 0,1,1,0,0,0,0,0, 0,1,1,1,1,1,1,1, 0,1,1,1,1,0,1,1)
        D24(3, 0,1,1,0,0,0,0,0, 0,1,1,1,1,1,1,1, 0,1,1,1,1,1,1,1)
        D24(4, 0,1,1,0,0,0,0,0, 0,1,1,0,1,0,1,1, 0,1,1,0,1,1,1,1)
        D24(5, 0,1,1,0,0,0,0,0, 0,1,1,0,0,0,1,1, 0,1,1,0,0,1,1,1)
        D24(6, 0,1,1,1,1,1,1,1, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1)
    }
    else if(b == 8)
    {
        // O, P, Q
        D24(0, 0,0,1,1,1,1,1,0, 0,1,1,1,1,1,1,0, 0,0,1,1,1,1,1,0)
        D24(1, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1)
        D24(2, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1)
        D24(3, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1)
        D24(4, 0,1,1,0,0,0,1,1, 0,1,1,1,1,1,1,0, 0,1,1,0,1,1,1,1)
        D24(5, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,0,0, 0,1,1,0,0,1,1,0)
        D24(6, 0,0,1,1,1,1,1,0, 0,1,1,0,0,0,0,0, 0,0,1,1,1,1,0,1)
    }
    else if(b == 9)
    {
        // R, S, T
        D24(0, 0,1,1,1,1,1,1,0, 0,0,1,1,1,1,0,0, 0,0,1,1,1,1,1,1)
        D24(1, 0,1,1,0,0,0,1,1, 0,1,1,0,0,1,1,0, 0,0,0,0,1,1,0,0)
        D24(2, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,0,0, 0,0,0,0,1,1,0,0)
        D24(3, 0,1,1,0,0,1,1,1, 0,0,1,1,1,1,1,0, 0,0,0,0,1,1,0,0)
        D24(4, 0,1,1,1,1,1,0,0, 0,0,0,0,0,0,1,1, 0,0,0,0,1,1,0,0)
        D24(5, 0,1,1,0,1,1,1,0, 0,1,1,0,0,0,1,1, 0,0,0,0,1,1,0,0)
        D24(6, 0,1,1,0,0,1,1,1, 0,0,1,1,1,1,1,0, 0,0,0,0,1,1,0,0)
    }
    else if(b == 10)
    {
        // U, V, W
        D24(0, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1)
        D24(1, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1)
        D24(2, 0,1,1,0,0,0,1,1, 0,1,1,0,0,0,1,1, 0,1,1,0,1,0,1,1)
        D24(3, 0,1,1,0,0,0,1,1, 0,1,1,1,0,1,1,1, 0,1,1,1,1,1,1,1)
        D24(4, 0,1,1,0,0,0,1,1, 0,0,1,1,1,1,1,0, 0,1,1,1,1,1,1,1)
        D24(5, 0,1,1,0,0,0,1,1, 0,0,0,1,1,1,0,0, 0,1,1,1,0,1,1,1)
        D24(6, 0,0,1,1,1,1,1,0, 0,0,0,0,1,0,0,0, 0,1,1,0,0,0,1,1)
    }
    else if(b == 11)
    {
        // X, Y, Z
        D24(0, 0,1,1,0,0,0,1,1, 0,0,1,1,0,0,1,1, 0,1,1,1,1,1,1,1)
        D24(1, 0,1,1,1,0,1,1,1, 0,0,1,1,0,0,1,1, 0,0,0,0,0,1,1,1)
        D24(2, 0,0,1,1,1,1,1,0, 0,0,1,1,0,0,1,1, 0,0,0,0,1,1,1,0)
        D24(3, 0,0,0,1,1,1,0,0, 0,0,0,1,1,1,1,0, 0,0,0,1,1,1,0,0)
        D24(4, 0,0,1,1,1,1,1,0, 0,0,0,0,1,1,0,0, 0,0,1,1,1,0,0,0)
        D24(5, 0,1,1,1,0,1,1,1, 0,0,0,0,1,1,0,0, 0,1,1,1,0,0,0,0)
        D24(6, 0,1,1,0,0,0,1,1, 0,0,0,0,1,1,0,0, 0,1,1,1,1,1,1,1)
    }
    else if(b == 12)
    {
        // copyright, exclamation, space
        D24(0, 0,0,1,1,1,1,0,0, 0,0,0,1,1,1,0,0, 0,0,0,0,0,0,0,0)
        D24(1, 0,1,0,0,0,0,1,0, 0,0,0,1,1,1,0,0, 0,0,0,0,0,0,0,0)
        D24(2, 1,0,0,1,1,0,0,1, 0,0,0,1,1,1,0,0, 0,0,0,0,0,0,0,0)
        D24(3, 1,0,1,0,0,0,0,1, 0,0,0,1,1,0,0,0, 0,0,0,0,0,0,0,0)
        D24(4, 1,0,1,0,0,0,0,1, 0,0,0,1,1,0,0,0, 0,0,0,0,0,0,0,0)
        D24(5, 1,0,0,1,1,0,0,1, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0)
        D24(6, 0,1,0,0,0,0,1,0, 0,0,0,1,1,0,0,0, 0,0,0,0,0,0,0,0)
        D24(7, 0,0,1,1,1,1,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0)
    }
    
    int bi = n - b*3;
    return fract(v*exp2(float(-(bi*8 + x)))) >= 0.5;
}

int ModLevel(int level)
{
    if(level == 0) return 0;
    return level - (level - 1)/NUM_LEVELS*NUM_LEVELS;
}

bool Level(int x, int y, int level)
{
    if(x < 0 || x >= LEVEL_WIDTH) return true;
    if(y < 0 || y >= LEVEL_HEIGHT) return false;
    
    int abs_x = x <= (LEVEL_WIDTH - 1) - x ? x : (LEVEL_WIDTH - 1) - x;
    
    level = ModLevel(level);
    
    if(level == 1)
    {
        if(y == 0 || y == LEVEL_HEIGHT - 1)
            return true;
        else if((y == 5 || y == 10 || y == 15) && (abs_x <= 1 || abs_x >= 5))
            return true;
    }
    else if(level == 2)
    {
        if(y == 0)
            return true;
        else if(y == 5 && ((abs_x >= 2 && abs_x <= 8) || (abs_x >= 11)))
            return true;
        else if(y == 10 && abs_x >= 5)
            return true;
        else if(y == 15 && abs_x >= 9 && abs_x <= 12)
            return true;
        else if(y == 20 && abs_x >= 11)
            return true;
    }
    else if(level == 3)
    {
        if((y == 0 || y == 24) && (abs_x <= 6 || abs_x >= 11))
            return true;
        else if(y == 5 && (abs_x <= 4 || (abs_x >= 7 && abs_x <= 9)))
            return true;
        else if(abs_x == 3 && y >= 10 && y <= 19)
            return true;
        else if(y == 10 && abs_x >= 3 && abs_x <= 12)
            return true;
        else if(y == 15 && abs_x >= 3 && abs_x <= 11)
            return true;
        else if(y == 20 && abs_x >= 3 && abs_x <= 10)
            return true;
    }
    else if(level == 4)
    {
        if((y == 0 || y == 24) && (abs_x <= 6 || abs_x >= 11))
            return true;
        if(y == 5 && (abs_x >= 3 && abs_x <= 9 || abs_x == 13))
            return true;
        if((y == 10 || y == 15) && (abs_x >= 3 && abs_x <= 6))
            return true;
        if(y == 19 && (abs_x >= 3 && abs_x <= 11))
           return true;
        if(y == 22 && (abs_x >= 6 && abs_x <= 8))
           return true;
        if(y == 23 && abs_x == 6)
           return true;
        if(abs_x == 3 && (y >= 5 && y <= 10 || y >= 15 && y <= 19))
            return true;
        if((abs_x >= 10 && abs_x <= 11) && (y >= 11 && y <= 19))
            return true;
    }
    
    return false;
}

bool Collision(int x, int y, int level)
{
    if(level == 0) return false;
    
    if(y < 0 || y >= LEVEL_HEIGHT-1) return false;
    if(x < 0 || x >= LEVEL_WIDTH) return true;
    
    level = ModLevel(level);
    
    return texture2D(iChannel0, (vec2(x + level*LEVEL_WIDTH, y+LEVEL_START_Y) + 0.5) / iChannelResolution[0].xy).x > 0.5;
}

#define D16(_y, _d0, _d1, _d2, _d3, _d4, _d5, _d6, _d7, _d8, _d9, _d10, _d11, _d12, _d13, _d14, _d15) if(y == (_y)) v0 = float(_d0) * 0.125 + float(_d1) * 1.0 + float(_d2) * 8.0 + float(_d3) * 64.0 + float(_d4) * 512.0 + float(_d5) * 4096.0 + float(_d6) * 32768.0 + float(_d7) * 262144.0, v1 = float(_d8) * 0.125 + float(_d9) * 1.0 + float(_d10) * 8.0 + float(_d11) * 64.0 + float(_d12) * 512.0 + float(_d13) * 4096.0 + float(_d14) * 32768.0 + float(_d15) * 262144.0;    
vec3 Sprite(int x, int y, int n)
{
    vec3 color = vec3(-1);
    if(x < 0 || x >= SPRITE_WIDTH || y < 0 || y >= SPRITE_HEIGHT) return color;
    y = (SPRITE_HEIGHT - 1) - y;
 
    int palette = 0;
    
    float v0 = 0.0;
    float v1 = 0.0;
    if(n == 1)
    {
        palette = 0;
        D16( 0, 0,0,0,0,0,0,0,0, 1,0,0,0,0,0,0,0)
        D16( 1, 0,0,0,0,0,0,0,1, 1,1,0,0,0,0,0,0)
        D16( 2, 0,0,0,1,1,1,1,2, 2,2,2,2,0,0,0,0)
        D16( 3, 0,0,0,0,1,1,2,2, 2,2,2,2,2,0,0,0)
        D16( 4, 0,0,0,0,0,2,2,2, 2,3,3,2,3,2,0,0)
        D16( 5, 0,0,1,1,1,2,2,2, 3,3,4,2,4,3,0,0)
        D16( 6, 0,0,0,1,2,2,2,2, 3,3,4,2,4,3,0,0)
        D16( 7, 0,0,0,0,2,2,2,2, 3,3,4,2,4,3,2,0)
        D16( 8, 0,0,1,1,2,2,2,2, 3,3,4,2,4,3,2,0)
        D16( 9, 0,0,0,1,2,2,2,2, 2,3,3,2,3,3,2,0)
        D16(10, 0,0,0,0,2,1,2,2, 0,0,0,3,0,0,0,0)
        D16(11, 0,0,0,2,1,1,1,2, 2,2,2,2,2,2,0,0)
        D16(12, 0,0,0,2,1,1,1,2, 2,3,3,3,3,0,0,0)
        D16(13, 0,0,1,2,1,1,2,2, 3,3,3,3,3,3,0,0)
        D16(14, 0,1,2,2,2,2,2,1, 1,3,3,3,3,3,0,0)
        D16(15, 2,2,2,2,2,2,1,1, 1,1,3,3,3,1,1,1)
    }
    else if(n == 2)
    {
        // shoot
        palette = 0;
        D16( 0, 0,0,0,0,0,0,0,1, 0,0,0,0,0,0,0,0)
        D16( 1, 0,0,0,0,0,0,1,1, 1,3,3,0,0,0,0,0)
        D16( 2, 0,0,0,1,1,1,1,2, 2,4,3,3,2,0,0,0)
        D16( 3, 0,0,0,0,1,1,2,3, 4,2,4,3,3,2,0,0)
        D16( 4, 0,0,0,0,0,2,3,3, 4,4,2,3,2,2,0,0)
        D16( 5, 0,0,1,1,1,2,3,3, 3,4,3,2,2,0,0,0)
        D16( 6, 0,0,0,1,2,2,2,3, 3,3,3,2,3,0,0,0)
        D16( 7, 0,0,0,0,2,2,2,2, 3,3,2,0,0,0,0,0)
        D16( 8, 0,0,1,1,2,2,2,2, 2,2,0,0,0,0,0,0)
        D16( 9, 0,0,0,0,0,2,2,2, 2,0,0,0,0,0,0,0)
        D16(10, 0,0,0,1,1,1,2,2, 0,0,0,0,0,0,0,0)
        D16(11, 0,0,0,1,1,1,1,2, 2,2,2,2,2,2,0,0)
        D16(12, 2,0,0,0,1,1,2,2, 2,3,3,3,3,0,0,0)
        D16(13, 2,1,1,2,2,2,2,2, 3,3,3,3,3,3,0,0)
        D16(14, 0,2,2,2,2,2,2,1, 1,1,3,3,3,3,0,0)
        D16(15, 0,0,2,2,2,2,1,1, 1,1,1,3,3,1,1,1)
    }
    else if(n == 3)
    {
        // dead!
        palette = 0;
        D16( 0, 0,0,0,3,0,0,0,0, 1,0,0,0,0,0,0,0)
        D16( 1, 0,3,0,0,0,0,0,1, 1,1,0,0,0,0,0,0)
        D16( 2, 0,0,0,1,1,1,1,2, 2,2,2,2,0,0,0,0)
        D16( 3, 0,0,0,0,1,1,2,2 ,2,2,2,2,2,0,0,0)
        D16( 4, 0,0,0,0,0,2,2,2 ,2,3,3,2,3,2,0,0)
        D16( 5, 0,0,1,1,1,2,2,2 ,3,3,4,3,4,3,0,0)
        D16( 6, 0,0,0,1,2,2,2,2 ,3,3,4,3,4,3,0,0)
        D16( 7, 2,0,0,1,2,2,2,2 ,4,4,4,4,4,4,2,0)
        D16( 8, 2,1,1,0,2,2,2,2 ,3,3,4,3,4,3,2,0)
        D16( 9, 2,1,1,1,1,2,2,2 ,2,3,3,2,3,2,2,0)
        D16(10, 0,1,1,1,1,1,2,0 ,0,0,0,0,0,0,0,0)
        D16(11, 0,2,1,1,1,2,2,2 ,0,0,0,0,0,0,0,0)
        D16(12, 0,0,2,2,2,2,2,2 ,0,0,0,0,0,0,0,0)
        D16(13, 0,0,2,1,1,1,1,3 ,3,0,0,0,0,0,0,0)
        D16(14, 0,0,2,2,1,1,1,1 ,3,3,3,3,1,1,1,0)
        D16(15, 0,0,0,2,3,1,1,1 ,3,3,3,1,1,1,0,0)
    }
    else if(n == 4)
    {
        // in bubble
        D16( 0, 0,0,0,0,0,0,0,1, 1,0,0,0,0,0,0,0)
        D16( 1, 0,0,0,0,0,0,2,2, 2,2,0,0,0,0,0,0)
        D16( 2, 0,0,0,0,2,2,2,2, 2,2,2,2,0,0,0,0)
        D16( 3, 0,0,0,0,2,2,3,3, 2,3,3,2,0,0,0,0)
        D16( 4, 0,0,0,2,2,3,3,4, 2,4,3,3,2,0,0,0)
        D16( 5, 0,0,0,2,2,3,3,4, 2,4,3,3,2,0,0,0)
        D16( 6, 0,0,2,2,2,3,3,4, 2,4,3,3,2,0,0,0)
        D16( 7, 0,0,2,4,2,3,3,3, 2,3,3,3,2,2,0,0)
        D16( 8, 0,0,2,4,2,2,3,3, 2,3,3,2,2,2,0,0)
        D16( 9, 0,0,0,2,4,4,4,4, 4,4,4,4,4,0,0,0)
        D16(10, 0,0,1,1,1,2,2,2, 2,2,2,2,2,0,1,0)
        D16(11, 0,1,1,1,1,2,3,3, 3,3,3,2,1,1,1,0)
        D16(12, 0,0,1,1,2,3,3,3, 3,3,3,3,2,1,0,0)
        D16(13, 0,0,2,2,1,1,1,3, 3,3,1,1,1,0,0,0)
        D16(14, 0,0,0,1,1,1,1,1, 3,1,1,1,1,0,0,0)
        D16(15, 0,0,0,0,0,0,0,0, 0,1,1,1,0,0,0,0)
    }
    else if(n == 5)
    {
        // monster 0
        palette = 1;
        D16( 0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0)
        D16( 1, 0,0,0,1,1,1,1,1, 1,1,1,1,1,0,0,0)
        D16( 2, 0,0,1,1,3,1,1,1, 1,1,1,1,1,1,0,0)
        D16( 3, 0,0,1,3,1,1,1,1, 1,1,1,1,1,1,0,0)
        D16( 4, 0,0,1,3,1,1,1,1, 1,1,1,1,1,1,0,0)
        D16( 5, 0,0,1,1,1,1,1,1, 1,1,1,1,2,5,5,0)
        D16( 6, 0,0,1,1,1,1,1,1, 1,1,1,1,5,6,6,5)
        D16( 7, 0,0,1,4,1,4,1,1, 1,1,1,1,5,6,6,5)
        D16( 8, 0,0,1,4,1,4,1,1, 1,1,5,5,5,5,5,0)
        D16( 9, 0,0,1,4,1,4,1,1, 1,2,6,6,5,6,0,0)
        D16(10, 0,0,1,1,1,1,1,2, 2,2,6,6,5,6,0,0)
        D16(11, 0,2,2,2,2,2,2,2, 2,6,5,5,6,2,0,0)
        D16(12, 0,2,2,2,2,2,2,2, 2,2,6,6,2,2,0,0)
        D16(13, 0,0,2,2,2,2,2,2, 2,2,2,2,2,0,0,0)
        D16(14, 0,0,0,0,7,7,7,0, 0,7,7,7,7,0,0,0)
        D16(15, 0,0,7,7,7,7,7,7, 0,0,0,0,0,0,0,0)
    }
    else if(n == 6)
    {
        // monster 1
        palette = 1;
        D16( 0, 0,0,0,0,0,1,1,1, 1,1,1,0,0,0,0,0)
        D16( 1, 0,0,0,0,1,1,3,1, 1,1,1,1,1,1,0,0)
        D16( 2, 0,0,0,1,1,3,1,1, 1,1,1,1,1,1,1,0)
        D16( 3, 0,0,0,1,1,1,1,1, 1,1,1,1,1,1,1,0)
        D16( 4, 0,0,0,1,4,1,4,1, 1,1,1,1,1,1,1,0)
        D16( 5, 0,0,0,1,4,1,4,1, 1,1,1,1,6,5,5,0)
        D16( 6, 0,0,0,1,4,1,4,1, 1,1,1,6,5,6,6,5)
        D16( 7, 0,0,0,1,1,1,1,1, 1,1,1,6,5,6,6,5)
        D16( 8, 0,0,0,4,4,4,4,4, 4,1,1,1,6,5,5,0)
        D16( 9, 0,0,0,0,4,4,4,4, 4,4,4,4,5,5,5,0)
        D16(10, 0,0,2,2,2,2,2,2, 2,2,2,6,5,6,6,5)
        D16(11, 0,0,2,2,2,2,2,2, 2,2,2,6,5,6,6,5)
        D16(12, 0,0,2,2,2,2,2,2, 2,2,2,2,6,5,5,0)
        D16(13, 0,7,7,2,2,2,2,2, 2,2,2,2,2,6,0,0)
        D16(14, 0,0,0,7,7,7,7,0, 0,7,7,7,0,0,0,0)
        D16(15, 0,0,0,0,0,0,0,7, 7,7,7,7,7,0,0,0)
    }
    else if(n == 7)
    {
        // monster 2
        palette = 1;
        D16( 0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0)
        D16( 1, 0,0,0,1,1,1,1,1, 1,1,1,1,1,0,0,0)
        D16( 2, 0,0,1,1,3,1,1,1, 1,1,1,1,1,1,0,0)
        D16( 3, 0,0,1,3,1,1,1,1, 1,1,1,1,1,1,0,0)
        D16( 4, 0,0,1,3,1,1,1,1, 1,1,1,1,1,1,0,0)
        D16( 5, 0,0,1,1,1,1,1,1, 1,1,5,5,1,1,0,0)
        D16( 6, 0,0,1,1,1,1,1,1, 1,5,6,6,5,0,0,0)
        D16( 7, 0,0,1,4,1,4,1,1, 1,5,6,6,5,0,0,0)
        D16( 8, 0,0,1,4,1,4,1,1, 1,6,5,5,5,5,5,0)
        D16( 9, 0,0,1,4,1,4,1,1, 1,1,1,1,5,6,6,5)
        D16(10, 0,0,1,1,1,1,1,2, 2,2,2,2,5,6,6,5)
        D16(11, 0,2,2,2,2,2,2,2, 2,2,2,2,6,5,5,6)
        D16(12, 0,2,2,2,2,2,2,2, 2,2,2,7,7,6,6,0)
        D16(13, 0,0,2,2,2,2,2,2, 2,7,7,7,7,7,0,0)
        D16(14, 0,0,0,0,7,7,7,0, 0,7,7,7,0,0,0,0)
        D16(15, 0,0,7,7,7,7,7,7, 0,0,0,0,0,0,0,0)   
    }
    else if(n == 8)
    {
        // monster 3
        palette = 1;
        D16( 0, 0,0,0,0,1,1,1,1, 1,1,0,0,0,0,0,0)
        D16( 1, 0,0,0,1,1,3,1,1, 1,1,1,1,1,0,0,0)
        D16( 2, 0,0,1,1,3,1,1,1, 1,1,1,1,1,1,0,0)
        D16( 3, 0,0,1,1,1,1,1,1, 1,1,1,1,1,1,0,0)
        D16( 4, 0,0,1,4,1,4,1,1, 1,1,1,1,1,1,0,0)
        D16( 5, 0,0,1,4,1,4,1,1, 1,1,1,1,1,1,0,0)
        D16( 6, 0,0,1,4,1,4,1,1, 1,1,5,5,1,5,5,0)
        D16( 7, 0,0,1,1,1,1,1,1, 1,5,6,6,5,6,6,5)
        D16( 8, 0,0,4,4,4,4,4,4, 1,5,6,6,5,6,6,5)
        D16( 9, 0,0,0,4,4,4,4,4, 4,4,5,5,6,5,5,0)
        D16(10, 0,2,2,2,2,2,2,2, 2,2,6,6,2,6,0,0)
        D16(11, 0,2,2,2,2,2,2,2, 2,2,2,2,2,2,0,0)
        D16(12, 7,7,7,7,2,2,2,2, 2,2,2,2,2,2,0,0)
        D16(13, 0,7,7,7,7,2,2,2, 2,2,2,2,2,0,0,0)
        D16(14, 0,0,7,7,7,7,0,0, 7,7,7,0,0,0,0,0)
        D16(15, 0,0,0,0,0,0,7,7, 7,7,7,7,0,0,0,0)        
    }
    else if(n == 9)
    {
        // banana?
        palette = 2;
        D16( 0, 0,0,0,0,0,0,0,0, 0,0,0,3,3,0,0,0)
        D16( 1, 0,0,0,0,0,0,0,0, 0,0,0,1,2,3,0,0)
        D16( 2, 0,0,0,0,0,0,0,0, 0,0,0,1,1,1,3,0)
        D16( 3, 0,0,0,0,0,0,0,0, 0,5,3,1,1,1,1,1)
        D16( 4, 0,0,0,0,0,0,0,5, 5,3,3,3,1,1,0,0)
        D16( 5, 5,5,5,5,5,5,5,3, 3,2,3,3,1,1,1,0)
        D16( 6, 5,3,3,3,3,3,2,2, 2,3,3,1,3,1,1,0)
        D16( 7, 0,2,2,2,2,2,2,3, 3,3,1,3,3,2,1,0)
        D16( 8, 0,0,0,2,2,3,3,3, 3,1,3,3,3,2,1,0)
        D16( 9, 5,5,5,5,5,3,3,2, 1,3,3,3,2,2,1,0)
        D16(10, 1,5,5,3,2,2,1,1, 3,3,3,2,2,1,0,0)
        D16(11, 0,1,1,1,1,2,3,3, 3,3,2,2,1,1,0,0)
        D16(12, 0,0,5,5,5,5,3,3, 2,2,2,1,1,0,0,0)
        D16(13, 0,5,5,5,5,3,2,2, 2,1,1,1,0,0,0,0)
        D16(14, 0,0,1,1,1,1,1,1, 1,1,1,0,0,0,0,0)
        D16(15, 0,0,0,0,1,1,1,1, 1,0,0,0,0,0,0,0)
    }
    else if(n == 10)
    {
        palette = 2;
        D16( 0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0)
        D16( 1, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0)
        D16( 2, 0,0,0,0,0,0,0,0, 0,0,0,3,2,0,0,0)
        D16( 3, 0,0,0,0,0,0,1,2, 2,2,2,3,4,2,0,0)
        D16( 4, 0,0,0,0,1,2,2,3, 3,3,3,3,3,2,0,0)
        D16( 5, 0,0,0,1,2,3,3,6, 6,3,3,2,2,2,0,0)
        D16( 6, 0,0,0,2,3,3,3,6, 6,3,3,3,2,2,0,0)
        D16( 7, 0,0,1,3,3,6,3,3, 3,3,3,3,3,2,0,0)
        D16( 8, 0,0,2,3,3,3,3,3, 3,3,3,3,3,2,0,0)
        D16( 9, 0,0,2,3,3,3,3,3, 3,3,3,3,3,2,0,0)
        D16(10, 0,0,2,3,3,3,3,3, 3,3,3,3,2,2,0,0)
        D16(11, 0,0,3,3,3,3,3,3, 3,3,3,3,2,2,0,0)
        D16(12, 0,2,3,3,3,3,3,3, 3,3,3,2,2,0,0,0)
        D16(13, 0,2,3,2,3,3,3,3, 3,3,2,2,2,0,0,0)
        D16(14, 0,0,2,2,2,2,2,2, 2,2,2,2,0,0,0,0)
        D16(15, 0,0,0,0,2,2,2,2, 2,2,0,0,0,0,0,0)
    }
    else if(n == 11)
    {
        palette = 2;
        D16( 0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,4,4)
        D16( 1, 0,0,0,0,0,0,0,0, 0,0,5,5,5,0,4,0)
        D16( 2, 0,0,0,0,0,0,0,0, 0,5,5,5,4,4,0,0)
        D16( 3, 0,0,0,0,0,0,0,0, 4,5,6,5,5,4,4,0)
        D16( 4, 0,0,0,0,0,0,4,4, 4,5,5,5,5,4,4,0)
        D16( 5, 0,0,0,4,4,4,4,4, 5,5,5,5,5,4,4,0)
        D16( 6, 0,0,4,4,4,5,5,5, 5,5,5,5,5,4,4,0)
        D16( 7, 0,4,4,4,4,6,6,4, 5,5,5,5,4,4,4,0)
        D16( 8, 0,4,4,5,5,6,6,5, 5,4,5,5,4,4,0,0)
        D16( 9, 4,4,4,5,5,4,5,5, 5,5,5,4,4,4,0,0)
        D16(10, 4,4,5,4,5,5,5,4, 5,5,5,4,4,4,0,0)
        D16(11, 4,4,5,5,5,5,5,5, 5,5,4,4,4,0,0,0)
        D16(12, 4,4,4,5,4,5,5,5, 4,5,4,4,4,0,0,0)
        D16(13, 0,4,4,4,5,5,4,5, 0,4,4,4,4,0,0,0)
        D16(14, 0,4,4,4,4,4,4,4, 4,4,4,4,0,0,0,0)
        D16(15, 0,0,4,4,4,4,4,4, 4,4,4,0,0,0,0,0)
    }
    
    int shift = x < 8 ? 3*x : 3*x-24;
    float v = x < 8 ? v0 : v1;
    float idx = floor(fract(v*exp2(float(-shift))) * 8.0);
    if(palette == 0)
    {
        color = (idx == 1.0) ? vec3(224,128, 64)/255.0 : color;
        color = (idx == 2.0) ? vec3( 96,224, 64)/255.0 : color;
        color = (idx == 3.0) ? vec3(255,255,255)/255.0 : color;
        color = (idx == 4.0) ? vec3(  0,  0,  0)/255.0 : color;
    }
    else if(palette == 1)
    {
        color = (idx == 1.0) ? vec3(170,170,221)/255.0 : color;
        color = (idx == 2.0) ? vec3(136,136,187)/255.0 : color;
        color = (idx == 3.0) ? vec3(255,255,255)/255.0 : color;
        color = (idx == 4.0) ? vec3(  0,  0,  0)/255.0 : color;
        color = (idx == 5.0) ? vec3(  0,153,255)/255.0 : color;
        color = (idx == 6.0) ? vec3(136,  0,255)/255.0 : color;
        color = (idx == 7.0) ? vec3(255,  0,119)/255.0 : color;
    }
    else if(palette == 2)
    {
        color = (idx == 1.0) ? vec3(255,136,  0)/255.0 : color;
        color = (idx == 2.0) ? vec3(255,187,  0)/255.0 : color;
        color = (idx == 3.0) ? vec3(204,255,  0)/255.0 : color;
        color = (idx == 4.0) ? vec3(  0,187,  0)/255.0 : color;
        color = (idx == 5.0) ? vec3(  0,255,  0)/255.0 : color;
        color = (idx == 6.0) ? vec3(255,255,255)/255.0 : color;

    }
    
    return color;
}

vec2 Flow(int x, int y, int level)
{
    if(x < 0) return vec2(1,0);
    if(x >= LEVEL_WIDTH) return vec2(-1,0);
    if(y < 0) return vec2(0,1);
    if(y >= LEVEL_HEIGHT - 2) return vec2(0,-1);
    
    level = ModLevel(level);
    
    float xsign = sign(float(14 - x));
    
    //if(level == 1 || level == 2)
    {
        if(y > 21) return vec2(xsign, 0);
    }
    
    return vec2(0,1);
}

#define S4(_c0, _c1, _c2, _c3) { v = (current++ == b) ? (float(_c0)*0.015625 + float(_c1)*1.0 + float(_c2)*64.0 + float(_c3)*4096.0) : v; }
int String(int str, int x)
{
    int b = x / 4;
    int bi = x - b*4;
    int current = 0;
    float v = float(_SPACE)*4161.015625;
    if(str == STR_GAME_OVER)
    {
        S4(_G, _A, _M, _E)
        S4(_SPACE, _O, _V, _E)
        S4(_R, _SPACE, _SPACE, _SPACE)
    }
    else if(str == STR_BEGINNING0)
    {
        S4(_N, _O, _W, _SPACE)
        S4(_I, _T, _SPACE, _I)
        S4(_S, _SPACE, _T, _H)
        S4(_E, _SPACE, _B, _E)
        S4(_G, _I, _N, _N)
        S4(_I, _N, _G, _SPACE)
        S4(_O, _F, _SPACE, _SPACE)
    } else if(str == STR_BEGINNING1)
    {
        S4(_A, _SPACE, _F, _A)
        S4(_N, _T, _A, _S)
        S4(_T, _I, _C, _SPACE)
        S4(_S, _T, _O, _R)
        S4(_Y, _EXCLAMATION, _SPACE, _L)
        S4(_E, _T, _SPACE, _U)
        S4(_S, _SPACE, _SPACE, _SPACE)
    }
    else if(str == STR_BEGINNING2)
    {
        S4(_M, _A, _K, _E)
        S4(_SPACE, _A, _SPACE, _J)
        S4(_O, _U, _R, _N)
        S4(_E, _Y, _SPACE, _T)
        S4(_O, _SPACE, _SPACE, _SPACE)
    }
    else if(str == STR_BEGINNING3)
    {
        S4(_T, _H, _E, _SPACE)
        S4(_C, _A, _V, _E)
        S4(_SPACE, _O, _F, _SPACE)
        S4(_M, _O, _N, _S)
        S4(_T, _E, _R, _S)
        S4(_EXCLAMATION, _SPACE, _SPACE, _SPACE)
    }
    else if(str == STR_BEGINNING4)
    {
        S4(_G, _O, _O, _D)
        S4(_SPACE, _L, _U, _C)
        S4(_K, _EXCLAMATION, _SPACE, _SPACE)
    }
    else if(str == STR_PUSH_START)
    {
        S4(_P, _U, _S, _H)
        S4(_SPACE, _S, _T, _A)
        S4(_R, _T, _SPACE, _SPACE)
    }
    else if(str == STR_1UP)
    {
        S4(1, _U, _P, _SPACE)
    }
    else if(str == STR_HIGH_SCORE)
    {
        S4(_H, _I, _G, _H)
        S4(_SPACE, _S, _C, _O)
        S4(_R, _E, _SPACE, _SPACE)
    }
    else if(str == STR_00)
    {
        S4(0, 0, _SPACE, _SPACE)
    }
    else if(str == STR_INSERT)
    {
        S4(_I, _N, _S, _E)
        S4(_R, _T, _SPACE, _SPACE)
    }
    else if(str == STR_COIN)
    {
        S4(_C, _O, _I, _N)
    }
    else if(str == STR_TO)
    {
        S4(_T, _O, _SPACE, _SPACE)
    }
    else if(str == STR_CONTINUE)
    {
        S4(_C, _O, _N, _T)
        S4(_I, _N, _U, _E)
    }
    else if(str == STR_COPYRIGHT)
    {
        S4(_COPYRIGHT, _SPACE, _M, _E)
        S4(_N,_T,_O,_R)
        S4(_SPACE,_C,_O,_R)
        S4(_P,_O,_R,_A)
        S4(_T,_I,_O,_N)
        S4(_SPACE,1,9,8)
        S4(6,_SPACE,_SPACE,_SPACE)
    }
    else if(str == STR_ALL_RIGHTS)
    {
        S4(_A,_L,_L,_SPACE)
        S4(_R,_I,_G,_H)
        S4(_T,_S,_SPACE,_R)
        S4(_E,_S,_E,_R)
        S4(_V,_E,_D,_SPACE)
    }
    else if(str == STR_INSERT_COIN)
    {
        S4(_I, _N, _S, _E)
        S4(_R, _T, _SPACE, _C)
        S4(_O, _I, _N, _SPACE)
    }
       
    return int(fract(v * exp2(-float(bi*6)))*64.0);
}

float isInside( vec2 p, vec2 c ) { vec2 d = abs(p-0.5-c) - 0.5; return -max(d.x,d.y); }

vec4 loadValue(vec2 re)
{
    return texture2D( iChannel0, (0.5 + re) / iChannelResolution[0].xy, -100.0 );
}

void storeValue(vec2 re, vec4 va, inout vec4 gl_FragColor, vec2 gl_FragCoord)
{
    gl_FragColor = (isInside(gl_FragCoord, re) > 0.0) ? va : gl_FragColor;
}

void main(){

    int x = int(gl_FragCoord.x);
    int y = int(gl_FragCoord.y);

    gl_FragColor = texture2D( iChannel0, gl_FragCoord / iChannelResolution[0].xy, -100.0 );
    vec4 staticDataInited = loadValue(txStaticDataInited);
    if(staticDataInited.x == 0.0)
    {
        gl_FragColor = vec4(0);
        if(y >= FONT_START_Y && y < FONT_START_Y + FONT_HEIGHT)
        {
            gl_FragColor = Font(x - x/FONT_WIDTH*FONT_WIDTH, y - FONT_START_Y, x/FONT_WIDTH) ? vec4(1) : vec4(0);
        }
        
        if(y >= LEVEL_START_Y && y < LEVEL_START_Y + LEVEL_HEIGHT)
        {
            gl_FragColor = Level(x - x/LEVEL_WIDTH*LEVEL_WIDTH, y - LEVEL_START_Y, x/LEVEL_WIDTH) ? vec4(1) : vec4(0);
        }
        
        if(y >= SPRITE_START_Y && y < SPRITE_START_Y + SPRITE_HEIGHT)
        {
            gl_FragColor = vec4(Sprite(x - x/SPRITE_WIDTH*SPRITE_WIDTH, y - SPRITE_START_Y, x/SPRITE_WIDTH), 1.0);
        }
        if(y >= STRINGS_START_Y && y < STRINGS_START_Y + NUM_STRINGS*FONT_HEIGHT)
        {
            int str = (y - STRINGS_START_Y) / FONT_HEIGHT;
            int c = String(str, x / FONT_WIDTH);
            int lx = x - x/FONT_WIDTH*FONT_WIDTH;
            int ly = (y - STRINGS_START_Y) - str*FONT_HEIGHT;
            gl_FragColor = Font(lx, ly, c) ? vec4(1) : vec4(0);
        }
        if(y >= LOGO_START_Y && y < LOGO_START_Y + LOGO_HEIGHT)
        {
            gl_FragColor.xyz = Logo(x, y - LOGO_START_Y);
        }
        
        staticDataInited.x = 1.0;
    }
    else
    {
        if(y >= NUM_DYNAMIC_ROWS)
        {
            return;
        }
    }

    if(y == 0 && x >= 16) discard;
    if(((y == ENTITIES_START_Y) || (y == ENTITIES_START_Y + 1)) && x >= MAX_ENTITIES) discard;
    
    // load state
    vec4 gameState = loadValue(txGameState);
    vec4 gameState2 = loadValue(txGameState2);
    vec4 gameState3 = loadValue(txGameState3);
    vec4 playerPos = loadValue(txPlayerPos);
    vec4 playerSprite = loadValue(txPlayerSprite);
    
    vec4 playerVel = loadValue(txPlayerVel);
    vec4 playerFlags = loadValue(txPlayerFlags);
    vec4 keyWasDown = loadValue(txKeyWasDown);
    vec4 cooldown = loadValue(txCoolDown);
    
    float moveRight = texture2D( iChannel1, vec2(KEY_RIGHT, 0.25) ).x;
    float moveLeft  = texture2D( iChannel1, vec2(KEY_LEFT,  0.25) ).x;
    float moveUp    = texture2D( iChannel1, vec2(KEY_UP,    0.25) ).x;
    float keySpace  = texture2D( iChannel1, vec2(KEY_SPACE, 0.0) ).x;
    
    float time = iGlobalTime - gameState2.w;
    
    
    if(gameState.x == 0.0)
    {
        // init
        playerPos = vec4(0,8,0,0);
        playerSprite = vec4(1,0,0,0);
        playerVel = vec4(0);
        playerFlags = vec4(0);
        gameState = vec4((SKIP_INTRO == 0) ? 1.0 : 5.0, float(0.0), 0.0, 2.0);   //state, level, score, lives
        //gameState2 = vec4(0,0,0,0);       //old_player_x, old_player_x, frame_counter, globaltime offset
        gameState2.xyz = vec3(0,0,0);
        gameState3 = vec4(0);   //win_counter
        
        if(y == ENTITIES_START_Y || y == ENTITIES_START_Y + 1)
        {
            gl_FragColor = vec4(-1);       //(x, y, time, type)
            //monster:
            //(x, y, time, type), (direction, target_height, y_velocity, had_floor_contact)
            //bubble:
            //(x, y, time, type), (direction, monster, pop_from_timeout, ?)
        }
        
    }
    else if(gameState.x == 1.0)
    {
        if(time > 7.0)
            gameState.x = 2.0;
    }
    else if(gameState.x == 2.0)
    {
        if(time > 9.6)
        {
            gameState.x = 3.0;
            gameState2.z = 0.0;
            
            float angle = time*2.5;
            playerPos.xy = vec2(40,120) + vec2(cos(angle)*30.0,sin(angle)*20.0);    //hack: avoid pop
        }
    }
    else if(gameState.x == 3.0)
    {
        // now is the beginning...
        float angle = time*2.5;
        playerPos.xy = vec2(40,120) + vec2(cos(angle)*30.0,sin(angle)*20.0);
        
        if(time > 18.36)
        {
            gameState.x = 4.0;
            
            gameState.y += 1.0; //hack: avoid pop
            gameState2.xy = playerPos.xy;
            playerPos = vec4(0,8,0,0);
            playerSprite = vec4(1,0,0,0);
            playerVel = vec4(0);
            playerFlags = vec4(0);
        }
    }
    else if(gameState.x == 4.0)
    {
        if(gameState2.z == 0.0)
        {
            if(y == ENTITIES_START_Y || y == ENTITIES_START_Y + 1)
            {
                gl_FragColor = vec4(-100,-100,-1,-1e5);
            }
            
            // init level
            /*
            gameState2.xy = playerPos.xy;
            playerPos = vec4(0,8,0,0);
            playerSprite = vec4(1,0,0,0);
            playerVel = vec4(0);
            playerFlags = vec4(0);
            */
            int modLevel = ModLevel(int(gameState.y));
         
            if(modLevel == 1)
            {
                if(y == ENTITIES_START_Y)
                {
                    if(x == 0) gl_FragColor = vec4(14*8, LEVEL_HEIGHT*8, 0, ENTITY_TYPE_MONSTER);
                    if(x == 1) gl_FragColor = vec4(14*8, LEVEL_HEIGHT*8+16, 0, ENTITY_TYPE_MONSTER);
                    if(x == 2) gl_FragColor = vec4(14*8, LEVEL_HEIGHT*8+32, 0, ENTITY_TYPE_MONSTER);
                }
                
                if(y == ENTITIES_START_Y + 1)
                {
                    if(x == 0) gl_FragColor = vec4(-1, 16*8, -1, -1);
                    if(x == 1) gl_FragColor = vec4(-1, 18*8, -1, -1);
                    if(x == 2) gl_FragColor = vec4(-1, 20*8, -1, -1);
                }
            }
            else if(modLevel == 2)
            {
                if(y == ENTITIES_START_Y)
                {
                    if(x == 0) gl_FragColor = vec4(10*8, LEVEL_HEIGHT*8, 0, ENTITY_TYPE_MONSTER);
                    if(x == 1) gl_FragColor = vec4(12*8, LEVEL_HEIGHT*8, 0, ENTITY_TYPE_MONSTER);
                    if(x == 2) gl_FragColor = vec4(14*8, LEVEL_HEIGHT*8, 0, ENTITY_TYPE_MONSTER);
                    if(x == 3) gl_FragColor = vec4(16*8, LEVEL_HEIGHT*8, 0, ENTITY_TYPE_MONSTER);
                }
                
                if(y == ENTITIES_START_Y + 1)
                {
                    if(x == 0) gl_FragColor = vec4(-1, 16*8, -1, -1);
                    if(x == 1) gl_FragColor = vec4(-1, 21*8, -1, -1);
                    if(x == 2) gl_FragColor = vec4( 1, 21*8, -1, -1);
                    if(x == 3) gl_FragColor = vec4( 1, 16*8, -1, -1);
                }
            }
            else if(modLevel == 3)
            {
                if(y == ENTITIES_START_Y)
                {
                    if(x == 0) gl_FragColor = vec4(4*8, LEVEL_HEIGHT*8,  0, ENTITY_TYPE_MONSTER);
                    if(x == 1) gl_FragColor = vec4(8*8, LEVEL_HEIGHT*8,  0, ENTITY_TYPE_MONSTER);
                    if(x == 2) gl_FragColor = vec4(18*8, LEVEL_HEIGHT*8, 0, ENTITY_TYPE_MONSTER);
                    if(x == 3) gl_FragColor = vec4(22*8, LEVEL_HEIGHT*8, 0, ENTITY_TYPE_MONSTER);
                }
                
                if(y == ENTITIES_START_Y + 1)
                {
                    if(x == 0) gl_FragColor = vec4( 1, 16*8, -1, -1);
                    if(x == 1) gl_FragColor = vec4( 1, 21*8, -1, -1);
                    if(x == 2) gl_FragColor = vec4(-1, 21*8, -1, -1);
                    if(x == 3) gl_FragColor = vec4(-1, 16*8, -1, -1);
                }
            }
            else if(modLevel == 4)
            {
                if(y == ENTITIES_START_Y)
                {
                    if(x == 0) gl_FragColor = vec4(4*8, LEVEL_HEIGHT*8,  0, ENTITY_TYPE_MONSTER);
                    if(x == 1) gl_FragColor = vec4(6*8, LEVEL_HEIGHT*8,  0, ENTITY_TYPE_MONSTER);
                    if(x == 2) gl_FragColor = vec4(8*8, LEVEL_HEIGHT*8,  0, ENTITY_TYPE_MONSTER);
                    if(x == 3) gl_FragColor = vec4(18*8, LEVEL_HEIGHT*8, 0, ENTITY_TYPE_MONSTER);
                    if(x == 4) gl_FragColor = vec4(20*8, LEVEL_HEIGHT*8, 0, ENTITY_TYPE_MONSTER);
                    if(x == 5) gl_FragColor = vec4(22*8, LEVEL_HEIGHT*8, 0, ENTITY_TYPE_MONSTER);
                }
                
                if(y == ENTITIES_START_Y + 1)
                {
                    if(x == 0) gl_FragColor = vec4( 1, 20*8, -1, -1);
                    if(x == 1) gl_FragColor = vec4( 1, 16*8, -1, -1);
                    if(x == 2) gl_FragColor = vec4( 1,  8*8, -1, -1);
                    if(x == 3) gl_FragColor = vec4(-1,  8*8, -1, -1);
                    if(x == 4) gl_FragColor = vec4(-1, 16*8, -1, -1);
                    if(x == 5) gl_FragColor = vec4(-1, 20*8, -1, -1);
                }
            }

        }
        
        gameState2.z++;
        if(gameState2.z > float(NUM_PLACE_PLAYER_FRAMES))
        {
            gameState.x = 5.0;
            gameState2.z = 0.0;
        }
    }
    else if(gameState.x == 5.0)
    {
        gameState2.z++;

        
        // player
        playerVel.y = max(playerVel.y - GRAVITY, -TERMINAL_VELOCITY);

        float oldPlayerPosX = playerPos.x;
        if(playerFlags.y >= 0.0)
        {
            // alive
            
            if(moveUp > 0.0 && playerFlags.x == 1.0)    //only allow jump if we had ground collision last frame
            {
                //playerFlags.x = 1.0;
                playerVel.y += JUMP_VELOCITY;
            }

            playerPos.x += MOVEMENT_SPEED * (moveRight - moveLeft);
            playerSprite.y = (moveRight > 0.0 ^^ moveLeft > 0.0) ? float(moveLeft) : playerSprite.y;
            
            playerFlags.y += 1.0;
        }
        else
        {
            playerFlags.y -= 1.0;
        }
        
        playerPos.xy += playerVel.xy;
        
        {
            float deltaX = playerPos.x - oldPlayerPosX;
            if(deltaX > 0.0)
            {
                int bx = int(playerPos.x/8.0+2.0);
                bool wallCollision = Collision(bx, int(playerPos.y/8.0+0.5), int(gameState.y)) &&
                                    Collision(bx, int(playerPos.y/8.0+1.5), int(gameState.y));
                if(wallCollision) playerPos.x = float(bx)*8.0-16.0;
            }
            else
            {
                int bx = int(floor(playerPos.x/8.0));
                bool wallCollision = Collision(bx, int(playerPos.y/8.0+0.5), int(gameState.y)) &&
                                    Collision(bx, int(playerPos.y/8.0+1.5), int(gameState.y));
                if(wallCollision) playerPos.x = float(bx)*8.0+8.0;
            }            
        }
        
        
        if(playerPos.y < -16.0) playerPos.y = float(LEVEL_HEIGHT)*8.0;  // wrap around y-axis
        
        
        // did I walk into a monster?
        int firstFreeEntity = 0;
        for(int i = 0; i < MAX_ENTITIES; i++)
        {
            vec4 entity0 = texture2D( iChannel0, (vec2(i, ENTITIES_START_Y) + 0.5) / iChannelResolution[0].xy, -100.0 );
            
            if(entity0.w == ENTITY_TYPE_MONSTER && playerFlags.y >= INVULNERABLE_FRAMES && length(entity0.xy - playerPos.xy) < 10.0)
            {
                // death
                playerFlags.y = -1.0;
                gameState.w -= 1.0;
            }
            
            if(entity0.w < 0.0 && firstFreeEntity == 0)
            {
                firstFreeEntity = i;
            }
        }
        
        // respawn?
        if(playerFlags.y < -RESPAWN_FRAMES)
        {
            if(gameState.w >= 0.0)
            {
                playerFlags.y = 0.0;
                playerPos = vec4(0,8,0,0);
                playerSprite = vec4(1,0,0,0);
                playerVel = vec4(0);
            }
            else
            {
                gameState.x = 6.0;  //game over!
            }
        }
        
        
        bool didFire = (keySpace != 0.0 && keyWasDown.x == 0.0 && cooldown.x <= 0.0 && playerFlags.y >= 0.0);
        if(didFire)
        {
            cooldown.x = BUBBLE_COOLDOWN;
        }
        
        if(playerFlags.y >= 0.0)
            playerSprite.x = float(cooldown.x > 5.0) + 1.0;
        else
            playerSprite.x = 3.0; 
        
        bool floorCollision = Collision(int(playerPos.x/8.0+.5), int(playerPos.y/8.0), int(gameState.y)) || Collision(int(playerPos.x/8.0+.5)+1, int(playerPos.y/8.0), int(gameState.y));
        playerFlags.x = 0.0;
        if(playerVel.y <= 0.0 && floorCollision)
        {
            float new_y = (floor(playerPos.y/8.0)+1.0)*8.0;
            if(new_y <= playerPos.y + 2.0)  //ignore if it moves us up too much
            {
                playerPos.y = new_y;
                playerVel.y = 0.0;
                playerFlags.x = 1.0;
            }
        }

        
        // entity update
        if((y == ENTITIES_START_Y || y == ENTITIES_START_Y + 1) && x < MAX_ENTITIES)
        {
            vec4 entity0 = texture2D( iChannel0, (vec2(x, ENTITIES_START_Y + 0) + 0.5) / iChannelResolution[0].xy, -100.0 );
            vec4 entity1 = texture2D( iChannel0, (vec2(x, ENTITIES_START_Y + 1) + 0.5) / iChannelResolution[0].xy, -100.0 );
            
            
            if(entity0.w == ENTITY_TYPE_BUBBLE) // bubble update
            {
                entity1.w = 0.0;    // clear points
                
                bool turnToMonster = false;
                bool turnToTumbling = false;
                
                vec2 pushVector = vec2(0);
                for(int i = 0; i < MAX_ENTITIES; i++)
                {
                    vec4 otherEntity0 = texture2D( iChannel0, (vec2(i, ENTITIES_START_Y + 0) + 0.5) / iChannelResolution[0].xy, -100.0 );
                    vec4 otherEntity1 = texture2D( iChannel0, (vec2(i, ENTITIES_START_Y + 1) + 0.5) / iChannelResolution[0].xy, -100.0 );
                
                    if(entity0.z >= 0.0 && otherEntity0.w == ENTITY_TYPE_BUBBLE)
                    {
                        vec2 delta = entity0.xy - otherEntity0.xy;
                        float dist = length(delta);
                        if(otherEntity0.z >= 0.0)
                        {
                            if(length(delta) > 0.01) pushVector += normalize(delta) * max(0., 13.0 - dist);
                        }
                        else if(otherEntity0.z >= -2.0 && otherEntity1.z == 0.0 && dist < 15.0) //neighbor died very recently
                        {
                            entity0.z = -1.0;
                            entity1.z =  0.0;   // not timeout
                            entity1.w = (entity1.y > 0.0) ? 1000.0 : 10.0;  // points
                            turnToTumbling = (entity1.y > 0.0);
                        }
                    }
                }
                
                if(entity0.z >= 0.0)
                {
                    if(entity0.z < BUBBLE_ATTACK_FRAMES && entity1.y <= 0.0 && gameState2.z >= MONSTER_FREE_FRAME)
                    {
                        for(int j = 0; j < MAX_ENTITIES; j++)
                        {
                            vec4 otherEntity0 = texture2D( iChannel0, (vec2(j, ENTITIES_START_Y + 0) + 0.5) / iChannelResolution[0].xy, -100.0 );
                            if(otherEntity0.w == ENTITY_TYPE_MONSTER)
                            {
                                vec2 delta = entity0.xy - (otherEntity0.xy + vec2(8,8));
                                if(dot(delta, delta) < MONSTER_HIT_DIST_SQ)
                                {
                                    entity1.y = 1.0;    // caught a monster!
                                }
                            }
                        }
                    }
                    
                    vec2 delta = entity0.xy - (playerPos.xy + vec2(8,8));
                    float penetration = max(0.,16. - length(delta));
                    if(length(delta) > .01) pushVector += normalize(delta) * penetration;

                    if(entity0.z < BUBBLE_ATTACK_FRAMES)
                        entity0.x += entity1.x * exp2(-BUBBLE_ATTACK_EXP_SCALE * entity0.z) / BUBBLE_ATTACK_EXP_SCALE;
                    else
                        entity0.xy += Flow(int(entity0.x/8.0), int(entity0.y/8.0), int(gameState.y)) * BUBBLE_FLOW_POWER;
                    entity0.xy += pushVector*PUSH_VECTOR_SCALE;
                    entity0.x = clamp(entity0.x, 8., float(LEVEL_WIDTH)*8.-8.);
                    entity0.z += 1.0;
                    if(entity0.z >= BUBBLE_LIFE_FRAMES)
                    {
                        entity0.z = -1.0;
                        entity1.z =  1.0;   // timeout
                        entity1.w =  0.0;   // 0 points
                        turnToMonster = (entity1.y > 0.0);
                    }
                    else if(entity0.z > 10.0 && penetration > BUBBLE_POP_THRESHOLD)
                    {
                        entity0.z = -1.0;   // popped by player
                        entity1.z =  0.0;   // not timeout
                        entity1.w = (entity1.y > 0.0) ? 1000.0 : 10.0;  // points
                        turnToTumbling = (entity1.y > 0.0);
                    }   
                }
                else
                {
                    entity0.z -= 1.0;
                }
              
                if(entity0.z < -BUBBLE_DEATH_FRAMES)
                {
                    entity0.w = -1.0;
                }
                
                if(turnToMonster)
                {
                    entity0.z = 0.0;
                    entity0.w = ENTITY_TYPE_MONSTER;
                    entity1 = vec4(1, 0, -1, -1);
                }
                
                if(turnToTumbling)
                {
                    entity0.z = 0.0;
                    entity0.w = ENTITY_TYPE_TUMBLING_MONSTER;
                    entity1 = vec4(-1, -1, -1, 1000.0);
                    entity1.x = (hash11(iGlobalTime + float(x)*100.0)*2.0-1.0)*3.0;
                    entity1.y = 3.5;
                }
                
            }
            else if(entity0.w == ENTITY_TYPE_MONSTER)   // monster update
            {
                // alive                
                if(gameState2.z < MONSTER_FREE_FRAME)
                {
                    //move monsters down to starting location
                    if(entity0.y > entity1.y)
                    {
                        entity0.y = max(entity0.y - 1.5, entity1.y);
                    }
                }
                else
                {
                    // was monster hit by bubble?
                    for(int i = 0; i < MAX_ENTITIES; i++)
                    {
                        vec4 otherEntity0 = texture2D( iChannel0, (vec2(i, ENTITIES_START_Y + 0) + 0.5) / iChannelResolution[0].xy, -100.0 );
                        vec4 otherEntity1 = texture2D( iChannel0, (vec2(i, ENTITIES_START_Y + 1) + 0.5) / iChannelResolution[0].xy, -100.0 );
                        if(otherEntity0.w == ENTITY_TYPE_BUBBLE && otherEntity0.z >= 0.0 && otherEntity0.z < BUBBLE_ATTACK_FRAMES && otherEntity1.y <= 0.0)
                        {
                            vec2 delta = otherEntity0.xy - (entity0.xy + vec2(8,8));
                            if(dot(delta, delta) < MONSTER_HIT_DIST_SQ)
                            {
                                entity0.w = -1.0;
                            }
                        }
                    }
                    
                    entity1.z = max(entity1.z - GRAVITY, -TERMINAL_VELOCITY);
                    
                    
                    entity0.y += entity1.z;
                    bool floorCollision = Collision(int(entity0.x/8.0+.5), int(entity0.y/8.0), int(gameState.y)) || Collision(int(entity0.x/8.0+.5)+1, int(entity0.y/8.0), int(gameState.y));
                    
                    bool ceilingCollision = false;
                    for(int i = 2; i <= 5; i++)
                    {
                        ceilingCollision = ceilingCollision || Collision(int(entity0.x/8.0+1.0), int(entity0.y/8.0+float(i)), int(gameState.y));
                    }
                    
                    if(entity1.w > 0.0)
                    {
                        //we can jump, but should we?
                        if(playerPos.y > entity0.y + 8.0 && ceilingCollision && hash11(time+float(x)*200.0)>0.98)
                        {
                             // yes!
                            entity1.z += JUMP_VELOCITY;
                            entity1.w = 0.0;
                        }
                    }
                    
                    entity1.w = 0.0;
                    if(entity1.z <= 0.0 && floorCollision)
                    {
                        float new_y = (floor(entity0.y/8.0)+1.0)*8.0;
                        if(new_y <= entity0.y + 2.0)    //ignore if it moves us up too much
                        {
                            entity0.y = new_y;
                            entity1.z = 0.0;
                            entity1.w = 1.0;
                        }
                        entity0.x += entity1.x;
                        
                        float xpos = entity0.x/8.0 + ((entity1.x < 0.0) ? -1.0 : 2.0);
                        bool wallCollision = Collision(int(xpos), int(entity0.y/8.0+.5), int(gameState.y));
                        if(wallCollision)
                        {
                            entity0.x -= entity1.x;
                            entity1.x *= -1.0;
                        }
                    }
                    if(entity0.y < -16.0) entity0.y = float(LEVEL_HEIGHT)*8.0;  // wrap around y-axis
                    
                }
                entity0.z += 1.0;
            }
            else if(entity0.w == ENTITY_TYPE_TUMBLING_MONSTER)
            {
                entity1.w = 0.0;    //clear points
                
                entity0.z += 1.0;
                entity0.xy += entity1.xy;
                if(entity0.y < -16.0) entity0.y = float(LEVEL_HEIGHT)*8.0;  // wrap around y-axis
                
                entity1.y = max(entity1.y - GRAVITY, -TERMINAL_VELOCITY);
                
                if(entity0.x < 0.0)
                {
                    entity0.x = 0.0;
                    entity1.x *= -1.0;
                }
                else if(entity0.x >= float(LEVEL_WIDTH-4)*8.0)
                {
                    entity0.x = float(LEVEL_WIDTH-4)*8.0;
                    entity1.x *= -1.0;
                }
                entity1.x *= 0.98;
                
                if(entity0.z > 180.0)
                {
                    bool floorCollision = Collision(int(entity0.x/8.0+.5), int(entity0.y/8.0), int(gameState.y)) || Collision(int(entity0.x/8.0+.5)+1, int(entity0.y/8.0), int(gameState.y));
                    if(floorCollision)
                    {
                        entity0.y = (floor(entity0.y/8.0)+1.0)*8.0;
                        entity0.z = floor(hash11(iGlobalTime + float(x)*100.0)*2.99);   // icon
                        entity0.w = ENTITY_TYPE_ITEM;
                        entity1.w = 1000.0; // points
                    }
                }   
            }
            else if(entity0.w == ENTITY_TYPE_ITEM)
            {
                if(length(playerPos.xy - entity0.xy) < 10.0)
                {
                    entity0.w = ENTITY_TYPE_SCORE;
                    entity1.w = 1000.0;
                }
            }
            else if(entity0.w == ENTITY_TYPE_SCORE)
            {
                entity1.w = 0.0;
            }
            
            // fire new bubble?
            if(didFire && x == firstFreeEntity)
            {
                if(playerSprite.y > 0.0)
                {
                    entity0 = vec4(playerPos.x +  6.0, playerPos.y + 8., 0, ENTITY_TYPE_BUBBLE);
                    entity1 = vec4(-1, -1, -1, 0);
                }
                else
                {
                    entity0 = vec4(playerPos.x + 10.0, playerPos.y + 8., 0, ENTITY_TYPE_BUBBLE);
                    entity1 = vec4( 1, -1, -1, 0);
                }
            }
            
            gl_FragColor = (y == ENTITIES_START_Y) ? entity0 : entity1;
        }
        
        
        
        keyWasDown.x = keySpace;
        cooldown -= 1.0;
        
        bool winCondition = true;//gameState.y > 0.0;
        if(y == 0)
        {
            for(int i = 0; i < MAX_ENTITIES; i++)
            {
                vec4 entity0 = texture2D( iChannel0, (vec2(i, ENTITIES_START_Y + 0) + 0.5) / iChannelResolution[0].xy, -100.0 );
                vec4 entity1 = texture2D( iChannel0, (vec2(i, ENTITIES_START_Y + 1) + 0.5) / iChannelResolution[0].xy, -100.0 );
                if(entity0.w == ENTITY_TYPE_MONSTER || (entity0.w == ENTITY_TYPE_BUBBLE && entity1.y > 0.0))
                {
                    winCondition = false;
                }
                if(entity0.w == ENTITY_TYPE_BUBBLE || entity0.w == ENTITY_TYPE_SCORE)
                {
                    gameState.z += entity1.w;
                }
                if(entity0.w == ENTITY_TYPE_TUMBLING_MONSTER)
                {
                    gameState.z += entity1.w;
                    winCondition = false;
                }
            }
        }
        
        if(winCondition)
        {
            gameState3.x += 1.0;
            
            if(gameState3.x >= WIN_DELAY_FRAMES)
            {
                gameState.x = 4.0;  //next level
                gameState2.z = 0.0;
                gameState3.x = 0.0;
                
                //hack hack to avoid pop when changing level
                gameState.y++;
                gameState2.xy = playerPos.xy;
                playerPos = vec4(0,8,0,0);
                playerSprite = vec4(1,0,0,0);
                playerVel = vec4(0);
                playerFlags = vec4(0);
            }
        }
        
    } else if(gameState.x == 6.0)
    {
        if(keySpace != 0.0)
        {
            gameState.x = 0.0;
            gameState2.w = iGlobalTime;
        }
    }
    
    // store state
    storeValue(txGameState,     vec4(gameState),    gl_FragColor, gl_FragCoord);
    storeValue(txGameState2,    vec4(gameState2),   gl_FragColor, gl_FragCoord);
    storeValue(txGameState3,    vec4(gameState3),   gl_FragColor, gl_FragCoord);
    storeValue(txPlayerPos,     vec4(playerPos),    gl_FragColor, gl_FragCoord);
    storeValue(txPlayerSprite,  vec4(playerSprite), gl_FragColor, gl_FragCoord);
    storeValue(txPlayerVel,     vec4(playerVel),    gl_FragColor, gl_FragCoord);
    storeValue(txPlayerFlags,   vec4(playerFlags),  gl_FragColor, gl_FragCoord);
    storeValue(txKeyWasDown,    vec4(keyWasDown),   gl_FragColor, gl_FragCoord);
    storeValue(txCoolDown,      vec4(cooldown),     gl_FragColor, gl_FragCoord);
    storeValue(txStaticDataInited, vec4(staticDataInited),  gl_FragColor, gl_FragCoord);
    
}


//TODO:
//*d24 font
//**baseline: ~2s
//**now: ~1s
//*move sprites to Buf A
//**baseline: ~5s
//**now: ~3s
//**float hacking for sprites
//*monster sprite + movement
//*sprite rotation
//*life counter
//*fix pattern 0 length
//*intro animation: "now it is the beginning of a fantastic story.."
//*hero in bubble
//*change level animation
//*game over
//*game restart
//-fix state transition glitches!
//**remove bubbles
//**clear jump state
//-monster in bubble: begin: 9:17
//**monster disappears when hit by attack bubble: 9:26
//**monster trapped in bubble: 10:55
//**monsters/items/bubbles are entities! 11:12
//**release monster
//**win condition
//*bug: hit multiple monsters with one bubble!
//**multipop doesn't work anymore
//**fall out the bottom...
//**bug: can walk on top of level
//**draw monster in bubble
//*support for multiple tiles
//*shake bubble when about to pop
//*bubbles shouldn't pop neighbors when popped by timeout
//*points for bubbles
//*monsters use collision
//**wall collision
//*collision issues
//**jump after fall
//**glide into wall
//**walk through wall
//*monster fall
//*monster jump
//*better AI
//*repeat levels!
//*invulnerable
//*item pickup
//**sync music with logo
//**optimize: performance is crappy now
//*resolution scaling
//*more fruit
//*faster compile
//*only update 'dynamic' part of texture
//*level 4
//*fix transitions
//*logo
//*copyright message?
//-long compile time because of logo
//-real tiles
//-bubble effect in intro
//-dead monster sprite
//-bug no wall colision on top row
//-logo AA?
//-jump animation
//-fall animation
//-walk animation
//-bubbles collide with level?
//-monster leaping
//-death animation
//-player 2
//-TODO: retrigger notes
//-note slide

