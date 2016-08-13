precision highp float;
varying vec2 vUv;
uniform vec2 resolution;
uniform vec2 mouse;
void main() 
{
    vec3 p = vec3((vUv.xy) / (resolution.y), mouse.x);
    for (int i = 0; i < 100; i++) 
    {
        p.xzy = vec3(1.3, 0.999, 0.7) * abs((abs(p) / dot(p, p) - vec3(1.0, 1.0, mouse.y * 0.5)));
    }
    gl_FragColor.rgb = p;
    gl_FragColor.a = 5.0;
}
