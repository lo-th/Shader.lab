// ------------------ channel define
// 0_# buffer256_bubbleA #_0
// ------------------

// shared game state
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

const int ENTITIES_START_Y = 1;
const int MAX_ENTITIES = 64;

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

const int LOGO_START_Y = 200;
const int LOGO_WIDTH = 300;
const int LOGO_HEIGHT = 150;


const float ENTITY_TYPE_BUBBLE = 1.0;
const float ENTITY_TYPE_MONSTER = 2.0;
const float ENTITY_TYPE_TUMBLING_MONSTER = 3.0;
const float ENTITY_TYPE_ITEM = 4.0;

const int MONSTER_SPRITE_START_IDX = 5;
const int ITEM_SPRITE_START_IDX = 9;

const int NUM_PLACE_PLAYER_FRAMES = 120;
const float INVULNERABLE_FRAMES = 90.0;

const float BUBBLE_ATTACK_FRAMES = 20.0;
const float BUBBLE_DEATH_FRAMES = 30.0;
const float BUBBLE_LIFE_FRAMES = 1200.0;
const vec3 BUBBLE_COLOR = vec3(0.25, 1.0, 0.25);

const float TILE_SIZE = 8.;
const float SHADOW_WIDTH = 3.0;
const int LEVEL_HEIGHT_MARGIN = 4;
const int LEVEL_HEIGHT_IN_PIXELS = int(TILE_SIZE) * (LEVEL_HEIGHT + LEVEL_HEIGHT_MARGIN);
const vec2 txGameState =    vec2(0.0,0.0);
const vec2 txGameState2 =   vec2(1.0,0.0);
const vec2 txGameState3 =   vec2(2.0,0.0);
const vec2 txPlayerPos =    vec2(3.0,0.0);
const vec2 txPlayerSprite = vec2(4.0,0.0);
const vec2 txPlayerFlags =  vec2(5.0,0.0);

const float PI = 3.1415926535;



#define HASHSCALE1 .1031
float hash11(float p)
{
    vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

bool Letter(int x, int y, int n)
{
    if(x < 0 || x >= FONT_WIDTH || y < 0 || y >= FONT_HEIGHT) return false;
    return texture2D(iChannel0, (vec2(x + n*FONT_WIDTH, y+FONT_START_Y) + 0.5) / iChannelResolution[0].xy).x > 0.5;
}

int ModLevel(int level)
{
    if(level == 0) return 0;
    return level - (level - 1) / NUM_LEVELS * NUM_LEVELS;
}

#define D16(_y, _d0, _d1, _d2, _d3, _d4, _d5, _d6, _d7, _d8, _d9, _d10, _d11, _d12, _d13, _d14, _d15) if(y == (_y)) v0 = float(_d0) * 0.125 + float(_d1) * 1.0 + float(_d2) * 8.0 + float(_d3) * 64.0 + float(_d4) * 512.0 + float(_d5) * 4096.0 + float(_d6) * 32768.0 + float(_d7) * 262144.0, v1 = float(_d8) * 0.125 + float(_d9) * 1.0 + float(_d10) * 8.0 + float(_d11) * 64.0 + float(_d12) * 512.0 + float(_d13) * 4096.0 + float(_d14) * 32768.0 + float(_d15) * 262144.0;    
vec3 Sprite(vec2 coord, int n, vec3 color, bool mirror, int rotate, vec3 colorMultiply)
{
    int x = int(coord.x);
    int y = int(coord.y);
    if(mirror) x = (SPRITE_WIDTH - 1) - x;
    int old_x = x;
    int old_y = y;
    if(rotate == 1) { x = 15-old_y; y = old_x; }
    else if(rotate == 2) { x = 15-old_x; y = 15-old_y; }
    else if(rotate == 3) { x = old_y; y = 15-old_x; }

    if(x < 0 || x >= SPRITE_WIDTH || y < 0 || y >= SPRITE_HEIGHT) return color;
    
    vec3 c = texture2D(iChannel0, (vec2(x + n*SPRITE_WIDTH, y + SPRITE_START_Y) + 0.5) / iChannelResolution[0].xy).xyz;
    return c.x >= 0.0 ? (c * colorMultiply) : color;
}


vec3 PrintStr(vec2 fragCoord, int x, int y, int str, vec3 color, vec3 inputColor)
{
    int lx = int(fragCoord.x) - x;  
    int ly = int(fragCoord.y) - y;
    if(lx < 0 || ly < 0 || ly >= FONT_HEIGHT) return inputColor;
    
    return texture2D(iChannel0, (vec2(lx, STRINGS_START_Y + str * FONT_HEIGHT + ly) + 0.5) / iChannelResolution[0].xy).x > 0.5 ? color : inputColor;
}


float Number(vec2 coord, int n, int numDigits)
{
    int x = int(coord.x);
    int y = int(coord.y);
    if(x < 0 || y < 0 || x >= FONT_WIDTH*numDigits || y >= FONT_HEIGHT)
    {
        return 0.0;
    }
    
    int d = x / FONT_WIDTH;
    x = x - d * FONT_WIDTH;
    int tmp = int((float(n) + 0.5) / pow(10.,float((numDigits - 1) - d)));
    if(tmp == 0 && d < numDigits - 2)
        return 0.0;

    tmp = tmp - tmp/10*10;
    return Letter(x, y, tmp) ? 1.0 : 0.0;
}

bool Map(vec2 coord, int level)
{
    int x = int(coord.x);
    int y = int(coord.y);
    
    if(level == 0) return false;
    
    if(y < 0 || y >= LEVEL_HEIGHT) return false;
    if(x < 0 || x >= LEVEL_WIDTH) return true;
    
    level = ModLevel(level);
    
    
    return texture2D(iChannel0, (vec2(x + level*LEVEL_WIDTH, y+LEVEL_START_Y) + 0.5) / iChannelResolution[0].xy).x > 0.5;
}

vec3 Tile(vec2 coord, int tile)
{
    //coord = floor(coord); //pixelate
    if(tile == 1)
    {
        float s = sin((coord.x + coord.y)/8.0*PI*2.0+1.);
        return (s >= 0.0 ? vec3(244,106,252) : vec3(252, 194, 252)) / 255.0;
    }
    else if(tile == 2)
    {
        float s = sin((coord.x + coord.y)/8.0*PI*2.0+1.);
        return (s >= 0.0 ? vec3(106,244,252) : vec3(194, 252, 252)) / 255.0;
    }
    else if(tile == 3)
    {
        float s = sin((coord.x + coord.y)/8.0*PI*2.0+1.);
        return (s >= 0.0 ? vec3(244,252,106) : vec3(252, 252, 194)) / 255.0;
    }
    else if(tile == 4)
    {
        float s = sin((coord.x + coord.y)/8.0*PI*2.0+1.);
        return (s >= 0.0 ? vec3(244,252,106) : vec3(252, 252, 194)) / 255.0;
    }
    
    return vec3(0.0);
}

void TileShadowColors(int tile, out vec3 color0, out vec3 color1)
{
    color0 = color1 = vec3(0);
    if(tile == 1)
    {
        color0 = vec3(244,106,252)/255.0*.6;
        color1 = vec3(244,106,252)/255.0*.4;
    } else if(tile == 2)
    {
        color0 = vec3(106,244,252)/255.0*.6;
        color1 = vec3(106,244,252)/255.0*.4;
    }
    else if(tile == 3)
    {
        color0 = vec3(244,252,106)/255.0*.6;
        color1 = vec3(244,252,106)/255.0*.4;
    }
    else if(tile == 4)
    {
        color0 = vec3(244,252,106)/255.0*.6;
        color1 = vec3(244,252,106)/255.0*.4;
    }
}



vec3 LargeBubble(vec2 coord, float time, vec3 color)
{
    float radius = 12.0 + sin(time*3.0);
    float aspect = 1.0 + sin(time*7.5)*.1;
    float len = abs(length(coord*vec2(aspect, 2.0 - aspect)) - radius);
    float alpha = max(0.0, 1.0 - len);
    return mix(color, vec3(1), alpha);
}

vec3 DrawMap(vec2 pixelCoord, float offset, vec3 color)
{
    if(offset < float(LEVEL_HEIGHT_IN_PIXELS)*.5)
    {
        int ioffset = int(offset);
        
        // vec3 PrintStr(vec2 fragCoord, int x, int y, int str, vec3 color, vec3 inputColor)
        color = PrintStr(pixelCoord, 1*8, 25*8+ioffset, STR_BEGINNING0, vec3(1), color);
        color = PrintStr(pixelCoord, 2*8, 23*8+ioffset, STR_BEGINNING1, vec3(1), color);
        color = PrintStr(pixelCoord, 6*8, 21*8+ioffset, STR_BEGINNING2, vec3(1), color);
        color = PrintStr(pixelCoord, 4*8, 19*8+ioffset, STR_BEGINNING3, vec3(1), color);
        color = PrintStr(pixelCoord, 9*8, 16*8+ioffset, STR_BEGINNING4, vec3(1), color);
    }
    
    int level = int(offset - pixelCoord.y + float(LEVEL_HEIGHT_IN_PIXELS)) / LEVEL_HEIGHT_IN_PIXELS;
    level = ModLevel(level);
    pixelCoord.y = mod(pixelCoord.y - offset, float(LEVEL_HEIGHT_IN_PIXELS));
                    
    vec2 tileCoord = floor((pixelCoord + 0.5) / TILE_SIZE);
    vec2 tileOffset = (pixelCoord - tileCoord*TILE_SIZE);
    tileOffset.y = (TILE_SIZE - 1.0) - tileOffset.y;
    
    
    
    
    int tile = level;
    if(Map(tileCoord, level))
    {
        color = Tile(tileOffset, tile);
    }
    else
    {
        //TODO: optimize this!
        vec3 color0, color1;
        TileShadowColors(tile, color0, color1);
        bool left = Map(tileCoord+vec2(-1,0), level);
        bool up = Map(tileCoord+vec2(0,1), level);
        bool upleft = Map(tileCoord+vec2(-1,1), level);
        if(upleft && left && up && tileOffset.x < SHADOW_WIDTH && tileOffset.y < SHADOW_WIDTH)
            color = (tileOffset.x < tileOffset.y)?color0:color1;
        else if(upleft && left && tileOffset.x < SHADOW_WIDTH)
            color = color0;// now is the beginning...
        else if(upleft && up && tileOffset.y < SHADOW_WIDTH)
            color = color1;
        else if(upleft && tileOffset.x < SHADOW_WIDTH && tileOffset.y < SHADOW_WIDTH)
            color = (tileOffset.x < tileOffset.y)?color1:color0;
        else if(left && tileOffset.x < SHADOW_WIDTH)
            color = (tileOffset.x < tileOffset.y)?color0:vec3(0);
        else if(up && tileOffset.y < SHADOW_WIDTH)
            color = (tileOffset.x < tileOffset.y)?vec3(0):color1;
    }
    return color;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 targetSize = vec2(32.,27.)*TILE_SIZE;
    if(fragCoord.x > targetSize.x || fragCoord.y > targetSize.y) discard;
    fragColor = vec4(0);
    
    // load state
    vec4 gameState =    texture2D(iChannel0, (txGameState + 0.5) / iChannelResolution[0].xy);
    vec4 gameState2=    texture2D(iChannel0, (txGameState2+ 0.5) / iChannelResolution[0].xy);
    vec2 playerPos =    texture2D(iChannel0, (txPlayerPos + 0.5) / iChannelResolution[0].xy).xy;
    vec4 playerSprite = texture2D(iChannel0, (txPlayerSprite + 0.5) / iChannelResolution[0].xy);
    vec4 playerFlags =  texture2D(iChannel0, (txPlayerFlags + 0.5) / iChannelResolution[0].xy);
    
    vec2 playFieldCoord = fragCoord - vec2(TILE_SIZE*2.0,0);
    vec2 tileCoord = floor((playFieldCoord + 0.5) / TILE_SIZE);
    vec2 tileOffset = (playFieldCoord - tileCoord*TILE_SIZE);
    tileOffset.y = (TILE_SIZE - 1.0) - tileOffset.y;
    
    float time = iGlobalTime;
    
    int level = int(gameState.y);
    /*
    if(gameState.x == 3.0)
    {
        // now is the beginning...
        
        fragColor.xyz = Sprite(playFieldCoord - playerPos.xy, 4, fragColor.xyz, fract(time*2.0) > 0.5, 0);
        fragColor.xyz = LargeBubble(playFieldCoord - playerPos.xy - vec2(8.0, 8.0), time, fragColor.xyz);
        
        
        
        return;
    }
    */
    
    if(gameState.x == 3.0 || gameState.x == 4.0)
    {
        // transition to level
        float s = min(1.0, gameState2.z * .01);
        vec2 pos = mix(gameState2.xy, playerPos.xy, s);
        float offset = (float(level-1)+s) * float(LEVEL_HEIGHT_IN_PIXELS);
        if(gameState.x == 3.0)
        {
            pos = playerPos;
            offset = 0.0;
        }
    
        fragColor.xyz = DrawMap(playFieldCoord, offset, fragColor.xyz);
        
        fragColor.xyz = Sprite(playFieldCoord - pos.xy, 4, fragColor.xyz, fract(time*2.0) > 0.5, 0, vec3(1));
        fragColor.xyz = LargeBubble(playFieldCoord - pos.xy - vec2(8.0, 8.0), time, fragColor.xyz);
        
        return;
    }
    
    // header
    if(tileCoord.y > 24.0)
    {
        int score = int(gameState.z);
        fragColor.xyz = vec3( Number(fragCoord - vec2(0,25.*8.), score, 8) +
                              Number(fragCoord - vec2(10*8,25.*8.), 30000, 8));
    
        fragColor.xyz = PrintStr(fragCoord, 4*8, 26*8, STR_1UP, vec3(0,210,0)/255., fragColor.xyz);
        fragColor.xyz = PrintStr(fragCoord, 11*8, 26*8, STR_HIGH_SCORE, vec3(210,0,0)/255., fragColor.xyz);
        
        float playTime = iGlobalTime;   //TODO: fix this
        if(gameState.x < 4.0)
        {
            fragColor.xyz = PrintStr(fragCoord, 25*8, 26*8, STR_1UP, vec3(0,190,255)/255., fragColor.xyz);
            fragColor.xyz = PrintStr(fragCoord, 27*8, 25*8, STR_00, vec3(0,190,255)/255., fragColor.xyz);
        }
        else
        {
            if(mod(iGlobalTime,3.0) < 1.5)
            {
                fragColor.xyz = PrintStr(fragCoord, 24*8, 26*8, STR_INSERT, vec3(0,190,255)/255., fragColor.xyz);
                fragColor.xyz = PrintStr(fragCoord, 25*8, 25*8, STR_COIN, vec3(0,190,255)/255., fragColor.xyz);
            }
            else
            {
                fragColor.xyz = PrintStr(fragCoord, 26*8, 26*8, STR_TO, vec3(0,190,255)/255., fragColor.xyz);
                fragColor.xyz = PrintStr(fragCoord, 23*8, 25*8, STR_CONTINUE, vec3(0,190,255)/255., fragColor.xyz);
            }
        }
        
        return;
    }


    
    if(gameState.x == 1.0)
    {
        // bubble bobble splash
        
        fragColor.xyz = PrintStr(fragCoord, 3*8, 5*8, STR_COPYRIGHT, vec3(1), fragColor.xyz);
        fragColor.xyz = PrintStr(fragCoord, 7*8, 3*8, STR_ALL_RIGHTS, vec3(1), fragColor.xyz);
        
        float c = sin(iGlobalTime*24.5)*.5+0.5;
        
        /*
        vec2 coord = fragCoord + vec2(0, min(0.0,-160.0+floor(iGlobalTime*120.0)));
        float len = 1e10;
        for(int i = 0; i < 200; i++)
        {
            float t = float(i) + 1200.0;
            vec2 p = vec2((hash11(t)*2.0)*80.0-80.0,(hash11(t+1000.0)*2.0)*40.0-40.0) + vec2(128, 125);
            len = min(len, length(p - coord) - hash11(t + 2000.0)*25.+8.0);
        }
        if(len < 10.0)
        {
            vec3 color = vec3(0);
            color = mix(vec3(250,161,0)/255.0, color, smoothstep(9.5, 10.0, len));
            color = mix(vec3(0), color, smoothstep(6.5, 7.0, len));
            color = mix(vec3(255,240,32)/255.0, color, smoothstep(5.0, 5.5, len));
            fragColor.xyz = color;
        }
        
        fragColor.xyz = Logo(int(coord.x), int(coord.y), vec3(1), fragColor.xyz);
        */
        
        vec2 coord = fragCoord - vec2(0, 50) + vec2(0, min(0.0,-160.0+floor(iGlobalTime*120.0)));
        int x = int(coord.x);
        int y = int(coord.y);
        
        
        if(x >= 0 && x < LOGO_WIDTH && y >= 0 && y < LOGO_HEIGHT)
        {
            vec3 tmp = texture2D(iChannel0, (vec2(x, y+LOGO_START_Y) + 0.5) / iChannelResolution[0].xy).xyz;
            float s = sin(iGlobalTime*50.0)*.5+.5;
            
            if(iGlobalTime >= 0.12*20.0) s = 0.0;
            vec3 drawColor = mix(vec3(255, 88, 152), vec3(255, 255, 100), s)/255.0;
            
    
            fragColor.xyz = tmp.x < 0.0 ? drawColor : tmp;
        }
        
        return;
    }
    
    if(gameState.x == 2.0)
    {
        // insert coin
        fragColor.xyz = PrintStr(fragCoord, 10*8, 13*8, STR_INSERT_COIN, vec3(1), fragColor.xyz);
        return;
    }
    
    if(gameState.x == 6.0)
    {
        // game over        
        fragColor.xyz = PrintStr(fragCoord, 12*8, 13*8, STR_GAME_OVER, vec3(1), fragColor.xyz);
        fragColor.xyz = PrintStr(fragCoord, 11*8, 7*8, STR_PUSH_START, vec3(1), fragColor.xyz);
        return;
    }
    
    fragColor.xyz = DrawMap(playFieldCoord, float(level * LEVEL_HEIGHT_IN_PIXELS), fragColor.xyz);
    
    int lives = int(gameState.w);
    
    // bubbles    
    for(int i = 0; i < MAX_ENTITIES; i++)
    {
        vec4 entity0 = texture2D(iChannel0, (vec2(i, ENTITIES_START_Y + 0) + 0.5) / iChannelResolution[0].xy);
        vec4 entity1 = texture2D(iChannel0, (vec2(i, ENTITIES_START_Y + 1) + 0.5) / iChannelResolution[0].xy);
        if(entity0.w == ENTITY_TYPE_BUBBLE && entity0.z >= -BUBBLE_DEATH_FRAMES)
        {
            float radius =  min(8.,1.0 + entity0.z*.5);
            if(entity0.z < 0.0) radius = 8.0;
            vec2 delta = playFieldCoord - entity0.xy;
            float aspect = 1.0 + sin(entity0.z*.1 )*.1;
            float l = length(delta*vec2(aspect,2.0-aspect));
            if(l < radius + 1.)
            {
                float l2 = length(delta + vec2(2,-2));
                float c = max(0.0, 1.0 - entity0.z / BUBBLE_ATTACK_FRAMES);
                
                if(entity0.z >= 0.0)
                {    
                    if(entity1.y >= 0.0)
                    {
                        // draw monster inside
                        fragColor.xyz = Sprite(delta*1.25 + vec2(8.,8.), MONSTER_SPRITE_START_IDX, fragColor.xyz, false, 0, vec3(1));
                    }
                    
                    // bubble
                    float shake = max(0., entity0.z - (BUBBLE_LIFE_FRAMES - 120.0));
                    shake = sin(shake)*.3 + 1.0;
                    float alpha = max(0., 1.0 - abs(l - 7.5)*.75);
                    fragColor.xyz = ((fragColor.xyz + c) * (mix(vec3(1), BUBBLE_COLOR, c)) + (alpha*.75*BUBBLE_COLOR + exp(-l2)))*shake;
                }
                else
                {
                    // bursting animation
                    float angle = fract(atan(delta.y, delta.x)/(2.0*PI));
                    float band = min(.4 - entity0.z*.05, 1.3);
                    float q = abs(0.5 - 2.0*fract(angle*16.0))*5.0/l * float(l > radius*(band-.1) && l < radius*band);
                    q = clamp(q, 0.0, 1.0);
                    fragColor.xyz = mix(fragColor.xyz, vec3(1), vec3(q));
                }
            }
        }
    }
    
    // draw monsters/tumblers/items
    for(int i = 0; i < MAX_ENTITIES; i++)
    {
        vec4 entity0 = texture2D(iChannel0, (vec2(i, ENTITIES_START_Y + 0) + 0.5) / iChannelResolution[0].xy);
        vec4 entity1 = texture2D(iChannel0, (vec2(i, ENTITIES_START_Y + 1) + 0.5) / iChannelResolution[0].xy);
        if(entity0.w == ENTITY_TYPE_MONSTER)
        {
            int frame = int(mod(entity0.z*.1, 4.0));
            fragColor.xyz = Sprite(playFieldCoord - entity0.xy, MONSTER_SPRITE_START_IDX+frame, fragColor.xyz, entity1.x > 0.0, 0, vec3(1));
        }
        else if(entity0.w == ENTITY_TYPE_TUMBLING_MONSTER)
        {
            int rot = int(mod(entity0.z*.1, 4.0));
            int frame = int(mod(entity0.z*.2, 4.0));
            fragColor.xyz = Sprite(playFieldCoord - entity0.xy, MONSTER_SPRITE_START_IDX+frame, fragColor.xyz, entity1.x > 0.0, rot, vec3(0.5,0.7,1));
        }
        else if(entity0.w == ENTITY_TYPE_ITEM)
        {
            int frame = int(entity0.z);
            fragColor.xyz = Sprite(playFieldCoord - entity0.xy, ITEM_SPRITE_START_IDX+frame, fragColor.xyz, false, 0, vec3(1));
        }
    }

    if(playerFlags.y >= 0.0)
    {
        float intensity = 1.0 + 0.1*sin(playerFlags.y)*float(playerFlags.y < INVULNERABLE_FRAMES);
        // alive
        fragColor.xyz = Sprite(playFieldCoord - playerPos, int(playerSprite.x), fragColor.xyz, playerSprite.y != 0.0, 0, vec3(intensity));
    }
    else
    {
        // dead
        int rot = int(-playerFlags.y)/16;
        rot = rot - rot/4*4;
        fragColor.xyz = Sprite(playFieldCoord - playerPos, int(playerSprite.x), fragColor.xyz, playerSprite.y != 0.0, rot, vec3(1));
    }
    
    
    
    if(fragCoord.x < 2.0*8.0)
    {
        // level
        if(fragCoord.y > 23.5*8.0)
        {
            fragColor.xyz -= Number(fragCoord - vec2(-1,24.*8.-1.) + vec2(-1,1), level, 2);
            fragColor.xyz = clamp(fragColor.xyz, 0.0, 1.0);
            fragColor.xyz += Number(fragCoord - vec2(-1,24.*8.-1.), level, 2);
        }
        // lives
        if(fragCoord.y < 8.0)
        {
            fragColor.xyz -= Number(fragCoord - vec2(-1,0.*8.-1.) + vec2(-1,1), lives, 2);
            fragColor.xyz = clamp(fragColor.xyz, 0.0, 1.0);
            fragColor.xyz += Number(fragCoord - vec2(-1,0.*8.-1.), lives, 2);
        }
    }
}