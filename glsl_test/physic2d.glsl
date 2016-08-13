precision highp float;
precision highp int;
uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;
varying vec2 vUv;
const int LineCount = 6;

int showSolution = 0;
float solution;
int MotionBlur = 1;
float bounceRatio = 0.5;
float gravity = -0.5;
float ti;
vec2 sp;
float aspect = 16.0 / 9.0;
vec3 color = vec3(0.0);
float timeleft;
float ballsize = 0.007;
float newBallTiming = 10.0;
float pixelsize = 1.0 / resolution.x;
float linethickness = pixelsize * 2.0 * aspect;

void drawline(vec2 a, vec2 b, vec3 linecolor) 
{
    vec2 s = sp;
    if (dot(b - a, s - a) < 0.0 || dot(b - a, s - a) > dot(b - a, b - a)) return;
     float aaval = (1.0 - (abs((a.x - b.x) * (s.y - a.y) - (a.y - b.y) * (s.x - a.x)) / linethickness / length(a - b) * 2.0));
    color = max(color, linecolor * aaval);
}

vec3 diskWithMotionBlur(vec3 col, in vec2 uv, in vec3 sph, in vec2 cd, in vec3 sphcol, in float alpha) 
{
    vec2 xc = uv - sph.xy;
    float a = dot(cd, cd);
    float b = dot(cd, xc);
    float c = dot(xc, xc) - sph.z * sph.z;
    float h = b * b - a * c;
    if (h > 0.0) 
    {
        h = sqrt(h);
        float ta = max(0.0, (-b - h) / a);
        float tb = min(1.0, (-b + h) / a);
        if (ta < tb) col = mix(col, sphcol, alpha * clamp(2.0 * (tb - ta), 0.0, 1.0));
     }
     return col;
}

void drawdisk(vec2 center, vec2 vel, float radius) 
{
    if (showSolution != 0) return;
     if (MotionBlur != 0) 
    {
        color = diskWithMotionBlur(color, sp, vec3(center, radius), vel / 24.0, vec3(1.0, 1.0, 1.0), 1.0);
    }
 else 
    {
        float val = clamp(-(length(center - sp) - radius) / pixelsize, -0.5, 0.5) + 0.5;
        color = max(color, vec3(1.0, 1.0, 1.0) * val);
    }
}
vec2 ballpos, ballvel;
vec2 lines[LineCount * 2];
vec2 getBallPosFly(float t) 
{
    vec2 np = ballpos + ballvel * t;
    np.y += gravity * t * t * 0.5;
    return np;
}
float bounceTime;
float time0;
float bounceTan;
float bounceLineAX, bounceLineBX;
void lineFlyIntersection(vec2 la, vec2 lb) 
{
    float k = (lb.y - la.y) / (lb.x - la.x);
    float topT = -ballvel.y / gravity;
    float topX = ballpos.x + ballvel.x * topT;
    float topY = ballpos.y - 0.5 * gravity * topT * topT;
    float topLineY = k * (topX - la.x) + la.y;
    float b = -(topY - topLineY);
    float a = -k * ballvel.x;
    float t0 = -a / gravity + topT;
    if (2.0 * b * gravity + a * a <= 0.0) return;
     float td = -sqrt(2.0 * b * gravity + a * a) / gravity;
    float t = t0 - td;
    if (t < 0.001 || ballpos.x + ballvel.x * t < la.x || ballpos.x + ballvel.x * t > lb.x) t = t0 + td;
     if (bounceTime > t && t > 0.001 && ballpos.x + ballvel.x * t >= la.x && ballpos.x + ballvel.x * t <= lb.x) 
    {
        bounceTime = t;
        bounceTan = k;
        bounceLineAX = la.x;
        bounceLineBX = lb.x;
        if (lb.y < 0.1) solution = 1.0;
     }
 }
void showPathFly(float t) 
{
    if (showSolution != 0) return;
     float xt = (sp.x - ballpos.x) / ballvel.x;
    if (xt > 0.0 && xt < t) 
    {
        float py = ballpos.y + ballvel.y * xt + xt * xt * gravity * 0.5;
        vec2 vel = ballvel;
        vel.y += xt * gravity;
        float aa = 1.0 - abs(sp.y - py) / pixelsize / 1.5 / length(vec2(1.0, vel.y / vel.x));
        color = max(color, aa * vec3(0.1, 0.4, 0.9));
    }
 }
vec2 displayBallPos, displayBallVel;
void main() 
{

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = 1.0 - uv * 2.0;
    uv.x *= resolution.x / resolution.y;   
    uv.y *= -1.;

    lines[0] = vec2(0.1, 0.4);
    lines[1] = vec2(0.35, 0.25);
    lines[2] = vec2(0.35, 0.22);
    lines[3] = vec2(0.5, 0.21);
    lines[4] = vec2(0.5, 0.16);
    lines[5] = vec2(0.7, 0.3);
    lines[6] = vec2(0.84, 0.19);
    lines[7] = vec2(0.90, 0.34);
    lines[8] = vec2(0.4, 0.06);
    lines[9] = vec2(1.0, 0.2);
    lines[10] = vec2(0.2, 0.08);
    lines[11] = vec2(0.5, 0.01);
    ti = mod(time, newBallTiming);
    //sp = vUv.xy / resolution.xy;
    //sp.y /= aspect;
    sp = uv;

    timeleft = ti;
    time0 = 0.0;
    ballpos = mouse.xy / resolution.xy / vec2(1.0, aspect);
    if (length(ballpos) == 0.0) ballpos = vec2(0.19 - mod(floor(time / newBallTiming) * 0.02211, 0.12), 0.57);
     if (showSolution != 0) ballpos = sp;
     ballvel = vec2(0.08, -0.08);
    for (int i = 0; i < LineCount; i++) 
    {
        vec2 fakeshift = normalize(lines[i * 2 + 1].yx - lines[i * 2].yx) * vec2(ballsize, -ballsize);
        drawline(lines[i * 2] + fakeshift, lines[i * 2 + 1] + fakeshift, vec3(1.0, 0.8, 0.1));
    }
    for (int pass = 0; pass < 50; pass++) 
    {
        bounceTime = 1e35;
        for (int i = 0; i < LineCount; i++) 
        {
            lineFlyIntersection(lines[i * 2], lines[i * 2 + 1]);
        }
        float timeToGo = bounceTime;
        showPathFly(timeToGo);
        if (bounceTime > timeleft && timeleft > 0.0) 
        {
            displayBallPos = getBallPosFly(timeleft);
            displayBallVel = ballvel;
            displayBallVel.y += timeleft * gravity;
        }
         ballpos = getBallPosFly(timeToGo);
        ballvel.y += timeToGo * gravity;
        timeleft -= timeToGo;
        time0 += timeToGo;
        if (timeleft == 0.0 || bounceTime == 1e35) break;
         vec2 norm = normalize(vec2(-bounceTan, 1.0));
        if (abs(dot(norm, ballvel)) < 0.02) 
        {
            ballvel -= norm * dot(norm, ballvel);
            vec2 slope = vec2(1.0, bounceTan);
            vec2 gravslope = gravity * slope * bounceTan / dot(slope, slope);
            float A = 0.5 * gravslope.x;
            float B = ballvel.x;
            float C1 = ballpos.x - bounceLineAX;
            float C2 = ballpos.x - bounceLineBX;
            float tm = B / -2.0 / A;
            float rollendt = 99.0;
            if (B * B - 4.0 * A * C1 > 0.0) 
            {
                float td = abs(sqrt(B * B - 4.0 * A * C1) / 2.0 / A);
                float t = tm - td;
                if (t <= 0.0) t = tm + td;
                 if (t > 0.0) rollendt = t;
             }
             if (B * B - 4.0 * A * C2 > 0.0) 
            {
                float td = abs(sqrt(B * B - 4.0 * A * C2) / 2.0 / A);
                float t = tm - td;
                if (t <= 0.0) t = tm + td;
                 if (t > 0.0) rollendt = min(rollendt, t);
             }
             float turnT = max(tm, 0.0);
            if (turnT > rollendt) turnT = 0.0;
             vec2 turnBallPos = ballpos + ballvel * turnT + turnT * turnT * 0.5 * gravslope;
            if (rollendt > timeleft && timeleft > 0.0) 
            {
                displayBallPos = ballpos + ballvel * timeleft + timeleft * timeleft * 0.5 * gravslope;
                displayBallVel = ballvel;
            }
             timeToGo = rollendt;
            ballpos += ballvel * timeToGo + timeToGo * timeToGo * 0.5 * gravslope;
            ballvel += gravslope * timeToGo;
            if (showSolution == 0) drawline(ballpos, turnBallPos, vec3(0.1, 0.4, 0.9));
             time0 += timeToGo;
            timeleft -= timeToGo;
        }
 else 
        {
            ballvel -= norm * dot(norm, ballvel) * (1.0 + bounceRatio);
        }
        if (ballpos.y < 0.0) break;
     }
    drawdisk(displayBallPos, displayBallVel, ballsize);
    if (showSolution != 0) 
    {
        color = max(color, vec3(-ballvel.x * 3.0, ballvel.x * 3.0, 0.0));
    }
     gl_FragColor = vec4(color, 1.0);
}
