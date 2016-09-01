

// ------------------ channel define
// 0_# bufferFULL_shooterA #_0
// 1_# bufferFULL_shooterB #_1
// 3_# tex12 #_3
// ------------------

// #define GODMODE
// #define THUMBNAIL
// #define HELL // uncomment if you want the real bullet hell experience ;)
// #define BOT  // uncomment so the game can play itself, code by Imp5

// size between each transitions
#define TRANSITION 3000.0
// scroll speed of the player, in pixels per frames
#define SCROLL_SPEED 0.65
// duration between each transitions
#define TRANSITION_PERIOD (TRANSITION/SCROLL_SPEED)

#define PI 3.14159265359

int imod(in int a, in int n) {
    return a - (n * int(a/n));
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

const vec2 ADR_MAX = ADR_ALIEN_SHIP_PROJ_LAST;

float isInside( vec2 p, vec2 c ) {
    vec2 d = abs(p-0.5-c) - 0.5001;
    return -max(d.x,d.y);
}
float isInside( vec2 p, vec2 c, vec2 cc ) {
    vec2 delt = (cc-c)*0.5;
    vec2 d = abs(p-0.5-(c+delt)) - delt - 0.5001;
    return -max(d.x,d.y);
}
vec4 loadValue( in vec2 re ) {
    return texture2D( iChannel0, (0.5+re) / iChannelResolution[0].xy, -100.0 );
}
void storeValue( in vec2 re, in vec4 va, inout vec4 fragColor, in vec2 fragCoord ) {
    fragColor = ( isInside(fragCoord,re) > 0.0 ) ? va : fragColor;
}

// INPUT

const float KEY_SPACE = 32.5/256.0;
const float KEY_LEFT  = 37.5/256.0;
const float KEY_UP    = 38.5/256.0;
const float KEY_RIGHT = 39.5/256.0;
const float KEY_DOWN  = 40.5/256.0;
float keyDown( in float key ) {
    return texture2D( iChannel2, vec2(key, 0.25) ).r;
}

// GAME LOGIC

// date of the game over
int gameoverFrame = 0;

// frame since the beginning
// used to determine ennemies spawn/behavior
int gameplayFrame = 0;

// collision mesh sample in the game world
vec4 getCollisionMesh( in vec2 uv ) {
    if (uv.x < -1.0 || uv.x >= 1.0) return vec4(999.9);
    if (uv.y < -1.0 || uv.y >= 1.0) return vec4(999.9);
    uv = uv * 0.5 + 0.5;
    uv *= 128.0 / iResolution.xy;
    return texture2D( iChannel1, uv );
}

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

// score for each ennemy type
float getScore( in int index ) {
    if (index < 8) return 1.0;
    if (index < 16) return 5.0;
    if (index < 24) return 10.0;
    if (index < 28) return 5.0;
    if (index < 30) return 50.0;
    if (index < 31) return 150.0;
    return 500.0;
}

// create a new ennemy ship
void BirthEnnemy( in int index, inout vec4 value ) {
    // FIGHTER
    if (index < 8) {
        int i = imod(index+gameplayFrame, 8);
        int j = imod(index*3+gameplayFrame*7, 16);
        value.x = (float(i - 4) + 0.5) / 4.0 * 0.95;
        value.y = 1.75 - (float(j) / 16.0)*0.65;
        value.w = 1.0;
    }
    
    // KNIGHT
    else if (index < 16) {
        int i = imod(index, 8);
        int j = imod(index*9+gameplayFrame*12, 16);
        value.x = (float(i - 4) + 0.5) / 4.0 * 0.95;
        value.y = 1.75 - (float(j) / 16.0)*0.65;
        value.w = 9.0;
    }
    
    // NINJA
    else if (index < 24) {
        value.xy = vec2(0.0, 1.2);
        value.w = 2.0;
    }
    
    // PILLAR
    else if (index < 28) {
        int i = imod(index, 4);
        int j = imod(index*2+gameplayFrame*7, 8);
        value.x = (float(i - 2) + 0.5) / 2.0 * 1.2;
        value.y = 1.75 - (float(j) / 8.0)*0.65;
        value.w = 9.0;
    }
    
    // FREGATE
    else if (index < 30) {
        int i = imod(index, 2);
        int j = imod(index+gameplayFrame*19, 16);
        value.x = (float(i - 1) + 0.5) * 1.2;
        value.y = 2.0 - (float(j) / 16.0)*0.75;
        value.w = 30.0;
    }
    
    // MOTHERSHIP
    else if (index < 31) {
        value.xy = vec2(0.0, 1.3);
        value.w = 130.0;
    }
    
    // BONUS
    else {
        value.xy = vec2(-1.1, 0.5);
        value.w = 3.0;
    }
}

// create a new ennemy projectile
void BirthEnnemyProj( in int index, inout vec4 value, in vec4 shipValue ) {
    // FIGHTER
    if (index < 8) {

    }
    
    // KNIGHT
    else if (index < 16) {

    }
    
    // NINJA
    else if (index < 24) {
        vec2 playerPos = loadValue(ADR_PLAYER).xy;
        vec2 delt = playerPos - shipValue.xy;
        float theta = atan(delt.y, delt.x);
        value.w = theta;
    }
    
    // PILLAR
    else if (index < 28) {
        value.w = 0.0;
    }
    
    // FREGATE
    else if (index < 30) {
        value.w = 0.03;
        value.y -= 0.1;
    }
    
    // MOTHERSHIP
    else if (index < 31) {
        // mothership projectiles are always in the center
        // so xy is used as polar coordinates
        value.x = 0.2;
        int i = imod(gameplayFrame, 32);
        value.y = float(i) / 16.0 * PI * 5.0;
    }
}

// move ennemy ship
void ThinkEnnemy( in int index, inout vec4 value ) {
    // FIGHTER
    if (index < 8) {
        // go straight down
        value.y -= 0.007;
        if (value.y < -1.1) {
            value.w = 0.0;
        }
    }
    
    // KNIGHT
    else if (index < 16) {
        // move slowly toward the center of the screen
        value.y -= max(0.0, log(value.y+1.0 - 0.25)*0.005);
        value.y -= 0.0015;
        if (value.y < -1.1) {
            value.w = 0.0;
        }
    }
    
    // NINJA
    else if (index < 24) {
        // find a position somewhere
        vec2 pos = vec2(0.0, 0.3);
        float param = float(index)*1.0+float(gameplayFrame)*0.03;
        pos.x += sin(param*0.3312)*2.0;
        pos.y += sin(param*0.5368)*1.5;
        vec2 delt = pos-value.xy;
        delt *= max(0.0, log(length(delt)+1.0));
        value.xy += delt*0.005;
    }
    
    // PILLAR
    else if (index < 28) {
        // go straight down
        value.y -= 0.002;
        if (value.y < -1.1) {
            value.w = 0.0;
        }
    }
    
    // FREGATE
    else if (index < 30) {
        // check the state of the other fregate
        float otherIndex = 28.0;
        if (index == 28) otherIndex += 1.0;
        vec4 otherFregate = loadValue(vec2(otherIndex, ADR_ALIEN_SHIP_FIRST.y));
        
        // when the other fregate is dead go to the center of the screen
        vec2 wishPos = vec2(0.0, 0.7);
        float ecart = 0.6;
        if (otherFregate.w > 0.5) {
            ecart = 0.4;
            // otherwise go to its own side
            if (index == 28) wishPos.x = -0.5;
            else wishPos.x = 0.5;
        }
        
        // move the position around
        float v = float(index-28);
        wishPos.x += sin(float(gameplayFrame)*0.02 + v*PI)*ecart;
        
        // then go toward it
        vec2 delt = wishPos-value.xy;
        delt *= max(0.0, sqrt(length(delt)+1.0));
        value.xy += delt*0.005;
    }
    
    // MOTHERSHIP
    else if (index < 31) {
        // move slowly toward the center of the screen
        value.y -= max(0.0, log(value.y+1.5)*0.003);
        value.y = max(0.0, value.y);
    }
    
    // BONUS
    else {
        // move to the right
        value.x += 0.006;
        value.y += sin(float(gameplayFrame)*0.05)*0.01;
        if (value.x > 1.1) {
            value.w = 0.0;
        }
    }
}

// move ennemy projectile
void ThinkEnnemyProj( in int index, inout vec4 value ) {
    // FIGHTER
    if (index < 8) {
        value.y -= 0.015;
        if (value.y < -1.1) {
            value.z = 0.0;
        }
    }
    
    // KNIGHT
    else if (index < 16) {
        value.y -= 0.008;
        if (value.y < -1.1) {
            value.z = 0.0;
        }
    }
    
    // NINJA
    else if (index < 24) {
        vec2 vec = vec2(cos(value.w), sin(value.w));
        value.xy += vec * 0.01;
        if (value.x < -1.1 || value.x > +1.1 || 
            value.y < -1.1 || value.y > +1.1) {
            value.z = 0.0;
        }
    }
    
    // PILLAR
    else if (index < 28) {
        value.w += 0.003;
        value.y -= 0.002;
        if (value.w > 2.5 || value.y < -1.1) {
            value.z = 0.0;
        }
    }
    
    // FREGATE
    else if (index < 30) {
        value.w += 0.003;
        value.y -= 0.009;
        if (value.y < -1.1) {
            value.z = 0.0;
        }
    }
    
    // MOTHERSHIP
    else if (index < 31) {
        value.x += 0.002;
        value.y -= 0.004;
        if (value.x > 1.5) {
            value.z = 0.0;
        }
    }
}

// should the ennemy spawn at this frame ? basically difficulty setting
bool ShouldSpawnEnnemy( in int index ) {
    
    // this is the duration between each transitions
    int period = int(TRANSITION_PERIOD+0.5);
    // this is the offset from the start the the point of transition
    int offset = int(780.0/SCROLL_SPEED+0.5);
    // position in the transition
    int inTransition = imod(gameplayFrame, period);
    // has the player just entered a transition?
    bool enteringTransition = inTransition == offset;
    // which transition we are in
    int periodIndex = gameplayFrame / period;
    
    // get a random value per transitions
    vec2 inDither = vec2(float(periodIndex), float(periodIndex/64)) + 0.5;
    inDither /= 64.0;
    float noise = texture2D(iChannel3, inDither, -100.0).r;
    
    // do a boss fight starting with 2, then 4, etc
    bool doBossFight = imod(periodIndex, 2) == 1 && periodIndex > 0;
    // type of boss is random
    bool doMothership = noise < 0.4;
    
    // difficulty moves with transition index, cap at level 20
    int baseIndex = imod(index, 8);
    int diff = 20-periodIndex;
    if (diff < 0) diff = 0;
    
    // during a boss fight ? is used to inhibe spawn rates
    bool duringBossFight = doBossFight && inTransition > offset-300 &&
        inTransition < offset+1000+diff*20;
    
    #ifdef HELL
    duringBossFight = false;
    diff = diff - 15;
    if (diff < 0) diff = 0;
    #endif
    
    // FIGHTER
    if (index < 8) {
        if (duringBossFight) return false;
        if (imod(gameplayFrame+baseIndex*1483, 353+diff*97) == 0) return true;
    }
    
    // KNIGHT
    else if (index < 16) {
        if (duringBossFight) return false;
        if (imod(gameplayFrame+baseIndex*1979, 1019+diff*131) == 0) return true;
    }
    
    // NINJA
    else if (index < 24) {
        if (duringBossFight) return false;
        if (imod(gameplayFrame+baseIndex*1871, 797+diff*139) == 0) return true;
    }
    
    // PILLAR
    else if (index < 28) {
        if (duringBossFight) return false;
        if (imod(gameplayFrame+baseIndex*1259, 1201+diff*103) == 0) return true;
    }
    
    // FREGATE
    else if (index < 30) {
        if (enteringTransition && doBossFight && !doMothership) return true;
        if (duringBossFight) return false;
        if (diff > 16) return false;
        if (imod(gameplayFrame+baseIndex*4783, 2857+diff*449) == 0) return true;
    }
    
    // MOTHERSHIP
    else if (index < 31) {
        if (enteringTransition && doBossFight && doMothership) return true;
        if (duringBossFight) return false;
        if (diff > 3) return false;
        if (imod(gameplayFrame, 4937+diff*977) == 0) return true;
    }
    
    // BONUS
    else {
        // 1 bonus per transitions, with a random offset
        return inTransition == int(noise*float(period)+0.5);
    }
    
    return false;
}

// should the projectile spawn at this frame ?
bool ShouldSpawnEnnemyProj( in int index, in vec4 shipValue ) {
    // FIGHTER
    if (index < 8) {
        return imod(gameplayFrame+index*37, 130) == 0;
    }
    
    // KNIGHT
    else if (index < 16) {
        if (shipValue.y > 0.7) return false;
        return imod(gameplayFrame+index*30, 60) == 0;
    }
    
    // NINJA
    else if (index < 24) {
        if (shipValue.x < -1.1 || shipValue.x > +1.1 || 
            shipValue.y < -1.1 || shipValue.y > +1.1) {
            return false;
        }
        return imod(gameplayFrame+index*31, 130) == 0;
    }
    
    // PILLAR
    else if (index < 28) {
        return imod(gameplayFrame+index*27, 200) == 0;
    }
    
    // FREGATE
    else if (index < 30) {
        if (shipValue.y > 0.8) return false;
        return imod(gameplayFrame+index*20, 40) == 0;
    }
    
    // MOTHERSHIP
    else if (index < 31) {
        if (dot(shipValue.xy, shipValue.xy) > 0.0 ) return false;
        return imod(gameplayFrame, 127) == 0;
    }
    
    // BONUS
    return false;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    // outside the limits of the gameplay buffer, discard the fragment
    if ( !(isInside(fragCoord, vec2(0), ADR_MAX) > 0.0) ) {
        discard;
        return;
    }
    
    ivec2 iFragCoord = ivec2(fragCoord);
    vec2 floorFragCoord = vec2(iFragCoord);
    
    // load game state
    vec4 game = loadValue(ADR_GAME);
    vec4 score = loadValue(ADR_SCORE);
    float gameOver = game.x;
    float gameTimestamp = game.y;
    float gameOverTimestamp = game.z;
    float highscore = max(2000.0, score.y);
    float bonus = score.z;
    bool doBonus = float(iFrame)-bonus < 300.0;
    
    gameplayFrame = iFrame - int(gameTimestamp);
    gameoverFrame = iFrame - int(gameOverTimestamp);
    
    // this means theres isn't enough place to play the game properly
    // the game area is 320 pixels large
    bool thumb = iResolution.x < 280.0 || iResolution.y < 280.0;
    #ifdef THUMBNAIL
    thumb = true;
    #endif
    
    // initialize the first frame
    bool initialize = gameOver > 0.5 && (gameoverFrame > 300);
    if ( iFrame == 0 || initialize ) {
        fragColor = vec4(0.0);
        
        // initialize player
        if ( isInside(fragCoord, ADR_PLAYER) > 0.0 ) {
            storeValue(ADR_PLAYER, vec4(0.0, thumb?0.0:-0.6, 0.0, 0.0),
                       fragColor, fragCoord);
        }
        
        // initialize game
        if ( isInside(fragCoord, ADR_GAME) > 0.0 ) {
            storeValue(ADR_GAME, vec4(0.0, float(iFrame), 0.0, 0.0),
                       fragColor, fragCoord);
        }
        
        // initialize score
        if ( isInside(fragCoord, ADR_SCORE) > 0.0 ) {
            storeValue(ADR_SCORE, vec4(0.0, highscore, -999.9, 0.0),
                       fragColor, fragCoord);
        }
        
        // initialize ennemies
        if ( isInside(fragCoord, ADR_ALIEN_SHIP_FIRST, ADR_ALIEN_SHIP_LAST) > 0.0 ) {
            storeValue(floorFragCoord, vec4(999.9, 999.9, -999.0, 0.0),
                       fragColor, fragCoord);
        }
        
        return;
    }
    
    // run the player loop
    if ( isInside(fragCoord, ADR_PLAYER) > 0.0 ) {
        vec4 value = loadValue(ADR_PLAYER);
        vec2 pos = value.xy;
        vec2 ppos = pos;
        
        bool left = keyDown(KEY_LEFT) > 0.5;
        bool up = keyDown(KEY_UP) > 0.5;
        bool right = keyDown(KEY_RIGHT) > 0.5;
        bool down = keyDown(KEY_DOWN) > 0.5;
        
        vec2 delta = vec2(0);
        float speed = 0.015;
        
        #ifndef BOT
        if (iMouse.z > 0.5) {
            // same computation than in the image buffer
            vec2 uv = iMouse.xy - iResolution.xy * 0.5;
            float pixelSize = floor(iResolution.y / 350.0);
            pixelSize = max(pixelSize, 1.0);
            vec2 play = vec2(pixelSize * 160.0);
            vec2 pointer = uv / play;
            delta = pointer-pos;
            float len = length(delta);
            if (len > speed) {
                delta /= len;
                delta *= speed;
            }
        } else {
            // otherwise, use the keyboard
            delta = vec2(
                keyDown(KEY_RIGHT)-keyDown(KEY_LEFT),
                keyDown(KEY_UP)-keyDown(KEY_DOWN));
            if (dot(delta, delta) > 1.44) delta /= 1.41421;
            delta *= speed;
        }
        #endif
        
        // code by Imp5
        #ifdef BOT 
        {
            vec2 playerPos = ppos;
            vec2 limit = vec2(0.09, 0.15);
            vec2 v00 = min(getCollisionMesh(playerPos).rb, limit);
            vec2 v10 = min(getCollisionMesh(playerPos + vec2(0.01, 0.0)).rb, limit);
            vec2 v01 = min(getCollisionMesh(playerPos + vec2(0.0, 0.01)).rb, limit);

            vec2 wishPos = vec2(0.0, -0.5);
            wishPos.x = getCollisionMesh(vec2(playerPos.x + 0.01, 0.8)).b <
                getCollisionMesh(vec2(playerPos.x, 0.8)).b ?
                playerPos.x + 0.1 : playerPos.x - 0.1;

            vec2 gradient = vec2(v10.x - v00.x, v01.x - v00.x)
                + vec2(v10.y - v00.y, v01.y - v00.y)
                + ((wishPos - playerPos) * 0.001);
            gradient.x *= 5.0;                    
            delta = normalize(gradient);
            delta *= speed;            
        }
        #endif
        
        delta *= 1.0 - gameOver;
        pos += delta;
        pos = clamp(pos, -0.99, +0.99);
        if ( thumb ) pos = vec2(0.0);
        
        value.xy = pos;
        storeValue(ADR_PLAYER, value, fragColor, fragCoord);
    }
    
    
    // game logic loop (game over)
    if ( isInside(fragCoord, ADR_GAME) > 0.0 ) {
        vec4 value = loadValue(ADR_GAME);
        
        float gameOver = value.x;
        float gameOverTimestamp = value.z;
        
        // while the game is running, check collision model for gameover state
        if (gameOver < 0.5 && !thumb) {
            vec2 playerPos = loadValue(ADR_PLAYER).xy;
            vec2 something = getCollisionMesh(loadValue(ADR_PLAYER).xy).rb;
            #ifndef GODMODE
            if ( something.x < 0.0 || something.y < 0.0 ) {
                gameOver = 1.0;
                gameOverTimestamp = float(iFrame);
            }
            #endif
        }
        
        value.x = gameOver;
        value.z = gameOverTimestamp;
        storeValue(ADR_GAME, value, fragColor, fragCoord);
    }
    
    // compute score
    if ( isInside(fragCoord, ADR_SCORE) > 0.0 ) {
        vec4 value = loadValue(ADR_SCORE);
        
        float score = value.x;
        float highscore = value.y;
        float bonusFrame = value.z;
        
        // for each kind of ennemies
        for (int i = 0 ; i < 32 ; i++) {
            vec2 adr = ADR_ALIEN_SHIP_FIRST + vec2(float(i), 0.0);
            vec4 other = loadValue(adr);
            if (other.w < -0.5) {
                score += getScore(i);
                if (i == 31) {
                    bonusFrame = float(iFrame);
                }
            }
        }
        
        // set the highscore
        highscore = max(score, highscore);
        
        if (thumb) {
            score = 999999.0;
            highscore = 999999.0;
        }
        
        value.x = score;
        value.y = highscore;
        value.z = bonusFrame;
        storeValue(ADR_SCORE, value, fragColor, fragCoord);
    }
    
    
    // for each player owned projectiles
    if ( isInside(fragCoord, ADR_PLAYER_PROJ_FIRST, ADR_PLAYER_PROJ_LAST) > 0.0 ) {
        vec4 value = loadValue(floorFragCoord);
        vec2 pos = value.xy;
        float alive = value.z;
        float type = value.w;
        
        if ( alive > 0.5 ) {
            // when alive, move the projectile to the top
            pos.y += 0.04;
            // remove the thing when it goes offscreen
            if (pos.y > 1.1) {
                alive = 0.0;
                pos = vec2(0);
            }
        } else {
            // we might be trying to shoot?
            if (imod(gameplayFrame, 12) == 0 && gameOver < 0.5) {
                // are we the first dead projectile?
                bool firstDead = true;
                for (int i = 0 ; i < 8 ; i++) {
                    const int offset = int(ADR_PLAYER_PROJ_FIRST.x+0.5);
                    if (i+offset < iFragCoord.x && firstDead) {
                        vec2 adr = ADR_PLAYER_PROJ_FIRST + vec2(float(i), 0.0);
                        vec4 other = loadValue(adr);
                        if (other.z < 0.5) {
                            firstDead = false;
                        }
                    }
                    
                }
                // then if this is the case, put it back in the world
                if (firstDead) {
                    alive = 1.0;
                    pos = loadValue(ADR_PLAYER).xy;
                    
                    if (imod(gameplayFrame/12, 2) > 0) {
                        pos.x += 0.02;
                    } else {
                        pos.x -= 0.02;
                    }
                    
                    if (doBonus) {
                        type = 1.0;
                    } else {
                        type = 0.0;
                    }
                }
            }
        }
        
        if ( thumb ) alive = 0.0;
        value.xy = pos;
        value.z = alive;
        value.w = type;
        storeValue(floorFragCoord, value, fragColor, fragCoord);
    }
    
    // for each ennemies
    if ( isInside(fragCoord, ADR_ALIEN_SHIP_FIRST, ADR_ALIEN_SHIP_LAST) > 0.0 ) {
        int index = iFragCoord.x;
        vec4 value = loadValue(floorFragCoord);
        
        if ( value.w > 0.5 ) {
            
            // move the ennemy
            ThinkEnnemy(index, value);
            
            // remove health when touching a collision mesh
            bool score = false;
            float lastHitDelta = float(iFrame) - value.z;
            if (lastHitDelta > 8.0 && getCollisionMesh(value.xy).g < getRadius(index)) {
                value.z = float(iFrame);
                value.w = value.w - 1.0;
                score = value.w < 0.5;
            }
            
            // remove the projectile when the health is 0
            if (value.w < 0.5) {
                if (score) {
                    // ennemy was killed, store timestamp
                    value.z = float(iFrame); // also used to animate death
                    // set health to -1 to award score
                    value.w = -1.0;
                } else {
                    // ennemy suicided, drop it
                    value.xy = vec2(999.9);
                    value.z = 0.0;
                    value.w = 0.0;
                }
            }

        } else {
            
            float timeSinceDeath = float(iFrame) - value.z;
            
            // the ennemy is dead, should we spawn?
            // don't spawn too son after death, this will ruin death animations
            if (timeSinceDeath > 200.0 && ShouldSpawnEnnemy(iFragCoord.x)) {
                BirthEnnemy(iFragCoord.x, value);
            } else {
                // the health might be at -1, which means the player killed it
                value.w = 0.0;
            }
            
        }
        
        if ( thumb ) value.w = 0.0;
        storeValue(floorFragCoord, value, fragColor, fragCoord);
    }
    
    
    // for each ennemies projectiles
    if ( isInside(fragCoord, ADR_ALIEN_SHIP_PROJ_FIRST, ADR_ALIEN_SHIP_PROJ_LAST) > 0.0 ) {
        vec4 value = loadValue(floorFragCoord);
        
        if ( value.z > 0.5 ) {
            // move the projectile
            ThinkEnnemyProj(iFragCoord.x, value);
        } else {
            // look at the friend ship
            vec2 shipAdr = vec2(floorFragCoord.x, ADR_ALIEN_SHIP_FIRST.y);
            vec4 shipValue = loadValue(shipAdr);
            int delta = int(float(iFrame) - shipValue.z + 0.5);
            
            // is the ship trying to shoot?
            if (shipValue.w > 0.5 && ShouldSpawnEnnemyProj(iFragCoord.x, shipValue)) {
                // are we the first dead projectile?
                bool firstDead = true;
                for (int i = 0 ; i < 8 ; i++) {
                    const int offset = int(ADR_ALIEN_SHIP_PROJ_FIRST.y+0.5);
                    if (i+offset < iFragCoord.y && firstDead) {
                        vec2 adr = vec2(floorFragCoord.x, 
                                        ADR_ALIEN_SHIP_PROJ_FIRST.y + float(i));
                        vec4 other = loadValue(adr);
                        if (other.z < 0.5) {
                            firstDead = false;
                        }
                    }
                    
                }
                
                // then if this is the case, put it back in the world
                if (firstDead) {
                    value.z = 1.0;
                    value.xy = shipValue.xy;
                    BirthEnnemyProj(iFragCoord.x, value, shipValue);
                }
            }
        }

        if ( thumb ) value.z = 0.0;
        storeValue(floorFragCoord, value, fragColor, fragCoord);
    }
    
}