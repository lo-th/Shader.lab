
// ------------------ channel define
// 0_# basic #_0
// ------------------

void main() {
    vec2 uv = (1.0 - vUv * 2.0) * vec2(iResolution.x / iResolution.y, 1.0);
    gl_FragColor = texture2D(iChannel0, uv);
}
