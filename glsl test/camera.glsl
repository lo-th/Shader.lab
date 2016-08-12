
// ------------------ channel define
// 0_# grey1 #_0
// ------------------vec2 

// https://www.shadertoy.com/view/MdKGzG

rot2D(vec2 p, float angle) {
 
    angle = radians(angle);
    float s = sin(angle);
    float c = cos(angle);
    
    return p * mat2(c,s,-s,c);
    
}

void main(){

    vec2 uv = (gl_FragCoord.xy - iResolution.xy * .5) / iResolution.y;
    vec2  m = (iMouse.xy / iResolution.xy) * 2. - 1.;
    
    vec3 dir = vec3(uv, 1.);
    dir.yz = rot2D(dir.yz,  90. * m.y);
    dir.xz = rot2D(dir.xz, 180. * m.x);
    
    gl_FragColor = textureCube(iChannel0, dir);
}