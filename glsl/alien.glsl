precision highp float;
varying vec2 vUv;
uniform float iGlobalTime;
uniform vec3 iResolution;
uniform vec4 iMouse;

vec3 roty(vec3 p, float a) {
    return p * mat3(cos(a), 0, -sin(a), 0, 1, 0, sin(a), 0, cos(a));
}

float map(in vec3 p) {

    float res = 0.;
    vec3 c = p;
    for (int i = 0; i < 4; i++) 
    {
        p = 0.9 * abs(p) / dot(p, p) - .7;
        p.yz = vec2(p.y * p.y - p.z * p.z, 2. * p.y * p.z);
        res += exp(-20. * abs(dot(p, c)));
    }
    return res / 2.0;

}

vec3 raymarch(vec3 ro, vec3 rd) {

    float t = 4.0;
    vec3 col = vec3(0);
    float c = 0.;
    for (int i = 0; i < 64; i++) 
    {
        t += 0.02 * exp(-2.0 * c);
        c = map(ro + t * rd);
        col = 0.98 * col + 0.08 * vec3(c * c, c, c * c * c);
        col = 0.98 * col + 0.08 * vec3(c * c * c, c * c, c);
        col = 0.98 * col + 0.08 * vec3(c, c * c * c, c * c);
    }
    return col;

}

void main() {

    vec2 uv = ((vUv - 0.5) * 2.0) * vec2(iResolution.z, 1.0);

    vec2 p = uv;//(vUv.xy - iResolution / 2.0) / (iResolution.y);
    vec3 ro = roty(vec3(3.), iGlobalTime * 0.3 + iMouse.x);
    vec3 uu = normalize(cross(ro, vec3(0.0, 1.0, 0.0)));
    vec3 vv = normalize(cross(uu, ro));
    vec3 rd = normalize(p.x * uu + p.y * vv - ro * 0.3);
    gl_FragColor.rgb = 0.5 * log(1.0 + raymarch(ro, rd));
    gl_FragColor.a = 1.0;

}