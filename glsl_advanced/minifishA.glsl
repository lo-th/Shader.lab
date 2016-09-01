
// ------------------ channel define
// 0_# bufferFULL_minifishA #_0
// ------------------

// inspired by Flyguy shader [https://www.shadertoy.com/view/Ms3GDS]

#define NUM_BODIES 40.
#define BODY_MASS 0.2
#define MAX_ACCEL 3.
#define MAX_SPEED .5
#define RESISTANCE .18

float hash(float n) { return fract(sin(n)*43758.5453123); }

//--------------------------------------------------------------------
// from iq shader Brick [https://www.shadertoy.com/view/MddGzf]
//Get a body from the backbuffer with its ID (xy = Current pos, zw = velocity).
vec4 getBody(float id) { return texture2D(iChannel0, vec2(id+.5,.5)/iResolution.xy);}
//--------------------------------------------------------------------

//Integrate the body's position.
vec4 Integrate(vec4 body, vec2 sumF, float dt) {
    // compute new accel, including gravity and air resisitance/friction
    vec2 accel = -sumF - body.zw*RESISTANCE/dt;
    float acc = min(MAX_ACCEL, length(accel));
    accel = acc == 0. ? vec2(0) : acc * normalize(accel);
    // compute new velocity
    body.zw += accel*dt;
    float speed = min(MAX_SPEED, length(body.zw));
    body.zw = speed == 0. ? vec2(0) : speed * normalize(body.zw);    
    body.xy += body.zw*dt; 
    return body; 
}

vec2 CalculateForce(vec2 p1, vec2 p2, float id) {
    vec2 v = p1-p2;
    float d = length(v);
    if (d == 0.) return .01*vec2(hash(id),hash(id*7.)); 
    return (6.3+log(d*d*.02))/exp(d*d*2.4)*normalize(v);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {   
    if(fragCoord.y > 0.5 || fragCoord.x > NUM_BODIES) discard;
          
    vec2 v, rpos, sumF = vec2(0), res = iResolution.xy / iResolution.y;
    float id = floor(fragCoord.x);  
    
    if(iFrame < 30) {  
        //Initialization (iFrame == 0 doesn't seem to work when the page is initially loaded)
        rpos = vec2(id * 1.85, id * -0.03); 
        fragColor = vec4(.1+.8*vec2(hash(id),hash(id*7.))*res,0,0);
    } else {  
        // Normal animation step
        vec4 body = getBody(id);
        // Mouse
        if( iMouse.w>0.01 &&  iMouse.x>0.01) {
            v = body.xy - (iMouse.xy/iResolution.y);
            sumF -= .65/(dot(v,v))*normalize(v);
        }
        // Borders
        sumF += .8*(1./abs(res-body.xy) - 1./abs(body.xy));
        for(float i=0.;i<NUM_BODIES;i++)
            if(i != id) sumF += CalculateForce(body.xy, getBody(i).xy, id);
        fragColor = Integrate(body, sumF, .03);
    }
}
    