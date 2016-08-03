#define iterations 4
#define formuparam2 0.89
#define volsteps 10
#define stepsize 0.190
#define zoom 3.900
#define tile 0.450
#define speed2 0.010
#define brightness 0.2
#define darkmatter 0.400
#define distfading 0.560
#define saturation 0.400
#define transverseSpeed 1.1
#define cloud 0.2

precision highp float;
varying vec2 vUv;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float triangle(float x, float a) 
{
    float output2 = 2.0 * abs(2.0 * ((x / a) - floor((x / a) + 0.5))) - 1.0;
    return output2;
}
float field(in vec3 p) 
{
    float strength = 7. + .03 * log(1.e-6 + fract(sin(time) * 4373.11));
    float accum = 0.;
    float prev = 0.;
    float tw = 0.;
    for (int i = 0; i < 6; ++i) 
    {
        float mag = dot(p, p);
        p = abs(p) / mag + vec3(-.5, -.8 + 0.1 * sin(time * 0.2 + 2.0), -1.1 + 0.3 * cos(time * 0.15));
        float w = exp(-float(i) / 7.);
        accum += w * exp(-strength * pow(abs(mag - prev), 2.3));
        tw += w;
        prev = mag;
    }
    return max(0., 5. * accum / tw - .7);
}
void main() 
{

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = 1.0 - uv * 2.0;
    uv.x *= resolution.x / resolution.y;   
    uv.y *= -1.;

    //vec2 uv2 = 2. * vUv.xy / resolution.xy - 1.;
    //vec2 uvs = uv2 * resolution.xy / max(resolution.x, resolution.y);
    float time2 = time;
    float speed = speed2;
    //vec2 uv = uvs;
    float a_xz = 0.9;
    float a_yz = -.6;
    float a_xy = 0.9 + time * 0.04;
    mat2 rot_xz = mat2(cos(a_xz), sin(a_xz), -sin(a_xz), cos(a_xz));
    mat2 rot_yz = mat2(cos(a_yz), sin(a_yz), -sin(a_yz), cos(a_yz));
    mat2 rot_xy = mat2(cos(a_xy), sin(a_xy), -sin(a_xy), cos(a_xy));
    vec3 dir = vec3(uv * zoom, 1.);
    vec3 from = vec3(0.0, 0.0, 0.0);
    from.x -= 5.0 * (mouse.x - 0.5);
    from.y -= 5.0 * (mouse.y - 0.5);
    vec3 forward = vec3(0., 0., 1.);
    from.z += 0.003 * time;
    dir.xy *= rot_xy;
    forward.xy *= rot_xy;
    dir.xz *= rot_xz;
    forward.xz *= rot_xz;
    dir.yz *= rot_yz;
    forward.yz *= rot_yz;
    from.xy *= -rot_xy;
    from.xz *= rot_xz;
    from.yz *= rot_yz;
    float zooom = (time2 - 3311.) * speed;
    from += forward * zooom;
    float sampleShift = mod(zooom, stepsize);
    float zoffset = -sampleShift;
    sampleShift /= stepsize;
    float s = 0.24;
    float s3 = s + stepsize / 2.0;
    vec3 v = vec3(0.);
    float t3 = 0.0;
    vec3 backCol2 = vec3(0.);
    for (int r = 0; r < volsteps; r++) 
    {
        vec3 p3 = (from + (s3 + zoffset) * dir) * (1.9 / zoom);
        p3 = abs(vec3(tile) - mod(p3, vec3(tile * 2.)));
        t3 = field(p3);
        float fade = pow(distfading, max(0., float(r) - sampleShift));
        backCol2 += 0.75 * vec3(t3) * fade;
        s += stepsize;
        s3 += stepsize;
    }
    v = mix(vec3(length(v)), v, saturation);
    backCol2 *= cloud;
    gl_FragColor = vec4(backCol2, 1.0);
}
