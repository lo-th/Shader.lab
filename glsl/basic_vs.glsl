

//uniform float key[20];

varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vEye;

void main() {

    vUv = uv;
    vEye = cameraPosition;
    vNormal = normal;
    vPosition = position;

    //if(key[4]>0.1) vUv = uv * 2.0;

    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

}