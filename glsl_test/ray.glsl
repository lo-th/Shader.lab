precision highp float;
precision highp int;

uniform samplerCube envMap;
uniform vec2 resolution;
uniform float time;
varying vec2 vUv;

vec4 ray(mat4 transformation, mat4 inv) 
{
    vec4 p = transformation * vec4(0, 0, 0, 1);
    float distance_squared = dot(p.xy, p.xy);
    if (distance_squared < 1.0) 
    {
        vec3 norm = vec3(-p.x, -p.y, -sqrt(1.0 - distance_squared));
        vec3 spec = reflect(vec3(0, 0, 1), norm);
        return textureCube(envMap, (inv * vec4(spec, 0)).xyz) * 0.8 + vec4(0.1);
    }
     return textureCube(envMap, (inv * vec4(0, 0, 1, 0)).xyz);
}

mat4 transpose(mat4 v) {
    return mat4(v[0].x, v[1].x, v[2].x, v[3].x, v[0].y, v[1].y, v[2].y, v[3].y, v[0].z, v[1].z, v[2].z, v[3].z, v[0].w, v[1].w, v[2].w, v[3].w);
}

void main() {

    //vec2 uv = (vUv.xy - resolution.xy / 2.0) / resolution.x;

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = 1.0 - uv * 2.0;
    uv.x *= resolution.x / resolution.y;   
    uv.y *= -1.;

    vec2 y = normalize(vec2(uv.x, 1));
    vec2 x = normalize(vec2(-uv.y, 1));
    mat4 t = mat4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 3.0 + 0.3 * sin(time), 1);
    float c = cos(time);
    float s = sin(time);
    mat4 tr = mat4(c, 0, s, 0, 0, 1, 0, 0, -s, 0, c, 0, 0, 0, 0, 1);
    mat4 xr = mat4(1, 0, 0, 0, 0, x.y, x.x, 0, 0, -x.x, x.y, 0, 0, 0, 0, 1) * t;
    mat4 yr = mat4(y.y, 0, y.x, 0, 0, 1, 0, 0, -y.x, 0, y.y, 0, 0, 0, 0, 1);
    gl_FragColor = ray(yr * xr * t * tr, transpose(tr) * transpose(t) * transpose(xr) * transpose(yr));

}
