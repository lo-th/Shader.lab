
// ------------------ channel define
// 0_# basic #_0
// ------------------

void main() {
    vec2 uv = ((vUv * 2.0) - 1.0) * vec2(iResolution.z, 1.0);
    gl_FragColor = texture2D(iChannel0, uv);
}
