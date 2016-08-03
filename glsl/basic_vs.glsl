
uniform vec3 resolution;
uniform float key[20];

varying vec2 vUv;
//varying vec2 viewUv;
varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vEye;

void main() {



    vEye = cameraPosition;
    vUv = uv;
    if(key[4]>0.1) vUv = uv * 2.0;
    vNormal = normal;
    vPosition = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

    //viewUv = gl_Position.xy / resolution.xy;
    //viewUv = 1.0 - uv * 2.0;
    //viewUv.x *= resolution.x / resolution.y;   
    //viewUv.y *= -1.;

}