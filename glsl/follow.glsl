#define PI 3.1415926

precision highp float;
precision highp int;
uniform vec3 resolution;
uniform vec4 mouse;
varying vec2 vUv;

#define border 0.01
#define radius 0.03
//#define PI 3.1415926
//#define PI 3.1415926





struct Rect {
    float width;
    float height;
    float x;
    float y;
    vec3 color;
    float rotation;
    vec2 csys;
};
Rect CreateRect(float width, float height, float x, float y, vec3 color) 
{
    Rect rect;
    rect.width = width;
    rect.height = height;
    rect.x = x;
    rect.y = y;
    rect.color = color;
    return rect;
}
void DrawRect(inout Rect rect, vec2 p, inout vec3 pix) 
{
    float dx = p.x - rect.x;
    float dy = p.y - rect.y;
    dx = cos(rect.rotation) * (p.x - rect.x) + sin(rect.rotation) * (p.y - rect.y);
    dy = -sin(rect.rotation) * (p.x - rect.x) + cos(rect.rotation) * (p.y - rect.y);
    float fL = -rect.width / 2.;
    float fR = +rect.width / 2.;
    float fT = +rect.height / 2.;
    float fB = -rect.height / 2.;
    float del;
    del = smoothstep(fL - 0.005, fL + 0.005, dx);
    del *= 1. - smoothstep(fR - 0.005, fR + 0.005, dx);
    del *= smoothstep(fB - 0.005, fB + 0.005, dy);
    del *= 1. - smoothstep(fT - 0.005, fT + 0.005, dy);
    float d = 0.005;
    if (dx > fL - d && dx < fR + d && dy < fT + d && dy > fB - d) 
    {
        pix = mix(pix, rect.color, del);
    }
     rect.csys = vec2(dx, dy);
}
void AddRectTo(Rect rect, Rect target, inout vec3 pix) 
{
    vec2 p = target.csys;
    float fL = rect.x - rect.width / 2.;
    float fR = rect.x + rect.width / 2.;
    float fT = rect.y + rect.height / 2.;
    float fB = rect.y - rect.height / 2.;
    float del;
    del = smoothstep(fL - 0.005, fL + 0.005, p.x);
    del *= 1. - smoothstep(fR - 0.005, fR + 0.005, p.x);
    del *= smoothstep(fB - 0.005, fB + 0.005, p.y);
    del *= 1. - smoothstep(fT - 0.005, fT + 0.005, p.y);
    float d = 0.005;
    if (p.x > fL - d && p.x < fR + d && p.y < fT + d && p.y > fB - d) 
    {
        pix = mix(pix, rect.color, del);
    } 
 }

float GetMouseFollowRotationAngle(Rect r1, vec2 m) 
{
    float cx = r1.x;
    float cy = r1.y;
    float tx = m.x;
    float ty = m.y;
    float nx = tx - cx;
    float ny = ty - cy;
    float distance = sqrt(pow(nx, 2.) + pow(ny, 2.));
    float new_angle = atan(ny, nx);
    return new_angle;
}

void main() 
{



    vec2 r = ((vUv - 0.5) * 2.0) * vec2(resolution.z, 1.0);
    //vec2 r = 2. * vec2(vUv.xy - .5 * resolution.xy) / resolution.y;
    vec2 m = 2. * vec2(mouse.xy - .5 * resolution.xy) / resolution.y;
    Rect r1 = CreateRect(0.5, 0.5, 0., .0, vec3(0. ,1., 1.));
    r1.rotation = GetMouseFollowRotationAngle(r1, m);
    vec3 bg = vec3(0.);
    vec3 pixel = bg;
    DrawRect(r1, r, pixel);
    Rect r1_sub = CreateRect(.1, .1, 0.2, 0., vec3(0., 0., 1.));
    AddRectTo(r1_sub, r1, pixel);
    //gl_FragColor = vec4(pixel, 1.);

    vec4 cc = vec4(1.0);
    cc.z = 0.0;
    //vec2 center = vec2(1./mouse.x, 1./mouse.y);
    vec2 center = 2.0 * vec2(mouse.xy - (resolution.xy*0.5)) / resolution.y;

    vec2 uvx = r - center;

    float dist =  sqrt(dot(uvx, uvx));

    if ( (dist > ( radius+border)) || (dist < ( radius-border )) ) gl_FragColor = vec4(pixel, pixel.b);
    else gl_FragColor = cc;

}
