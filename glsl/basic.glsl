
uniform sampler2D iChannel1;
uniform vec3 iResolution;
varying vec2 vUv;

void main() {
    vec2 uv = (1.0 - vUv * 2.0) * vec2(iResolution.x / iResolution.y, 1.0);
    gl_FragColor = texture2D(iChannel1, uv);
}
