
uniform sampler2D iChannel1;
uniform vec3 resolution;
varying vec2 vUv;

void main() {
    vec2 uv = (1.0 - vUv * 2.0) * vec2(resolution.x / resolution.y, 1.0);
    gl_FragColor = texture2D(iChannel1, uv);
}
