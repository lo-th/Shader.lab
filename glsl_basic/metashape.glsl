
// ------------------ channel define
// 0_# cube_grey1 #_0
// ------------------


#define PI 3.14159265
#define TAU (2.0*PI)
#define PHI (sqrt(5)*0.5 + 0.5)
float sgn(float x) {
    return (x<0.)?-1.:1.;
}

vec2 sgn(vec2 v) {
    return vec2((v.x<0.)?-1.:1., (v.y<0.)?-1.:1.);
}

float square (float x) {
    return x*x;
}

vec2 square (vec2 x) {
    return x*x;
}

vec3 square (vec3 x) {
    return x*x;
}

float lengthSqr(vec3 x) {
    return dot(x, x);
}


// Maximum/minumum elements of a vector
float vmax(vec2 v) {
    return max(v.x, v.y);
}

float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

float vmax(vec4 v) {
    return max(max(v.x, v.y), max(v.z, v.w));
}

float vmin(vec2 v) {
    return min(v.x, v.y);
}

float vmin(vec3 v) {
    return min(min(v.x, v.y), v.z);
}

float vmin(vec4 v) {
    return min(min(v.x, v.y), min(v.z, v.w));
}


// https://www.shadertoy.com/view/Xls3R7

float sphere(vec3 pos, float r){

    return length(pos)-r;  

}

float box(vec3 pos){

    vec3 d = abs(pos) - 1.0;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));

}

// Box: correct distance to corners
float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float torus(vec3 pos){

    vec2 q = vec2(length(pos.xz)-2.0,pos.y);
    return length(q)-0.5;   

}
// Torus in the XZ-plane
float fTorus(vec3 p, float smallRadius, float largeRadius) {
    return length(vec2(length(p.xz) - largeRadius, p.y)) - smallRadius;
}
float fCapsule(vec3 p, float r, float c) {
    return mix(length(p.xz) - r, length(vec3(p.x, abs(p.y) - c, p.z)) - r, step(c, abs(p.y)));
}

float blob7(float d1, float d2, float d3, float d4, float d5, float d6, float d7){

    float k = 2.0;
    return -log(exp(-k*d1)+exp(-k*d2)+exp(-k*d3)+exp(-k*d4)+exp(-k*d5)+exp(-k*d6)+exp(-k*d7))/k;

}

float scene(vec3 pos){

    float t = iGlobalTime;
    
    //float p = torus(pos + vec3(0.0,3.0,0.0));
    float p = fTorus(pos + vec3(0.0,3.0,0.0), 0.5, 2.5);
    float b = sphere(0.5*(pos + vec3(cos(t*0.5),sin(t*0.3),0.0)), 1.3);
    float s1 = fBox(2.0*(pos + 3.0 * vec3(cos(t*1.1),cos(t*1.3),cos(t*1.7))), vec3(1.0))/2.0;
    float s2 = fBox(2.0*(pos + 3.0 * vec3(cos(t*0.7),cos(t*1.9),cos(t*2.3))), vec3(1.0))/2.0;
    float s3 = fBox(2.0*(pos + 3.0 * vec3(cos(t*0.3),cos(t*2.9),sin(t*1.1))), vec3(1.0))/2.0;
    float s4 = fBox(2.0*(pos + 3.0 * vec3(sin(t*1.3),sin(t*1.7),sin(t*0.7))), vec3(1.0))/2.0;
    //float s5 = box(2.0*(pos + 3.0 * vec3(sin(t*2.3),sin(t*1.9),sin(t*2.9))))/2.0;

    float s5 = fCapsule(2.0*(pos + 3.0 * vec3(sin(t*2.3),sin(t*1.9),sin(t*2.9))), 1.0, 1.0)/2.0;
    
    return blob7( p, b, s1, s2, s3, s4, s5 );

}

float calcIntersection( in vec3 ro, in vec3 rd ){

    const float maxd = 15.0;
    const float precis = 0.001;
    float h = precis * 2.0;
    float t = 0.0;
    float res = -1.0;
    for( int i=0; i<150; i++ ){

        if( h<precis||t>maxd ) break;
        h = scene( ro+rd*t );
        t += h;

    }

    if( t<maxd ) res = t;
    return res;

}

vec3 calcNormal( in vec3 pos ){

    const float eps = 0.002;

    const vec3 v1 = vec3( 1.0,-1.0,-1.0);
    const vec3 v2 = vec3(-1.0,-1.0, 1.0);
    const vec3 v3 = vec3(-1.0, 1.0,-1.0);
    const vec3 v4 = vec3( 1.0, 1.0, 1.0);

    return normalize( v1*scene( pos + v1*eps ) + v2*scene( pos + v2*eps ) + v3*scene( pos + v3*eps ) + v4*scene( pos + v4*eps ) );

}

float intersection( in vec3 ro, in vec3 rd ){

    const float maxd = 20.0;
    const float precis = 0.001;
    float h = precis*2.0;
    float t = 0.0;
    float res = -1.0;
    for( int i=0; i<90; i++ )
    {
        if( h<precis||t>maxd ) break;
        h = scene( ro+rd*t );
        t += h;
    }

    if( t<maxd ) res = t;
    return res;
    
}

vec3 background( vec3 rd ){

    return textureCube(iChannel0, rd).rgb;
    //return textureCube(iChannel0, rd).rgb * textureCube(iChannel0, -rd).rgb;

}

vec3 calcLight( in vec3 pos , in vec3 lightp, in vec3 lightc, in vec3 camdir, in vec3 normal, in vec3 texture ){   

    //vec3 normal = calcNormal(pos);
    vec3 lightdir = normalize(pos - lightp);
    float cosa = pow(0.5+0.5*dot(normal, -lightdir), 3.0);
    float cosr = max(dot(-camdir, reflect(lightdir, normal)), 0.0);
    
    vec3 ambiant = vec3(0.02);
    vec3 diffuse = vec3(0.7 * cosa) * texture;
    vec3 phong = vec3(0.3 * pow(cosr, 16.0));
    
    return lightc * ( ambiant + diffuse + phong );

}

float reflection = 0.5;
float refraction = 0.2;

vec3 illuminate( in vec3 pos , in vec3 camdir ){

    vec3 normal = calcNormal(pos);

    const float ETA = 0.9;
    vec3 refrd = -refract(camdir,normal,ETA);
    vec3 refro = pos + 10.0 * refrd;
    float refdist = intersection(refro, refrd);
    vec3 refpos = refro + refdist * refrd;
    vec3 refnormal = calcNormal(refpos);
    
    vec3 tex0 = textureCube(iChannel0, refract(-refrd,-refnormal,1.0/ETA)).rgb;
    //vec3 tex1 = textureCube(iChannel0, refract(-refrd,-refnormal,1.0/ETA)).rgb;
    //if (refdist < -0.5) {
    //    tex0 = background(-refrd);
    //    tex1 = tex0;
    //}
    vec3 tex2 = textureCube(iChannel0, reflect(camdir,normal)).rgb;
    //vec3 tex3 = textureCube(iChannel0, reflect(camdir,normal)).rgb;
    //vec3 texture = vec3(1.0,0.9,0.9)* (0.4 * tex0 + 0.4 * tex1 + 0.03 * tex2 + 0.1 * tex3);

    vec3 texture = vec3(1.0) + (tex2 * reflection) + (tex0 * refraction); 

    vec3 l1 = calcLight(pos, vec3(5.0,10.0,-20.0), vec3(1.0,1.0,1.0), camdir, normal, texture );
    vec3 l2 = calcLight(pos, vec3(-20,10.0,5.0), vec3(0.5,0.4,0.3), camdir, normal, texture );
    vec3 l3 = calcLight(pos, vec3(25.0,5.0,-5.0), vec3(0.4,0.3,0.2), camdir, normal, texture );
    vec3 l4 = calcLight(pos, vec3(-5.0,-15.0,10.0), vec3(0.1,0.1,0.1), camdir, normal, texture );
    return l1+l2+l3+l4;

}



mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll ){

    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );

}

void main() {

    //vec2 xy = (gl_FragCoord.xy - iResolution.xy/2.0) / min(iResolution.xy.x, iResolution.xy.y);

    vec2 xy = ((vUv * 2.0) - 1.0) * vec2( iResolution.z, 1.0 );
    
    float t = iGlobalTime;
    // camera position from three js
    vec3 campos = cameraPosition;
    //vec3 campos = vec3(10.0*sin(t*0.3),2.5*sin(t*0.5),-10.0*cos(t*0.3));
    vec3 camtar = vec3(0.0,0.0,0.0);

    mat3 camMat = calcLookAtMatrix( campos, camtar, 0.0 );

    //mat4 camMat = viewMatrix;

    vec3 camdir = normalize( camMat * vec3(xy,1.0) );
    //vec3 camdir = normalize( camMat * vec4(xy,1.0, 0.0) ).xyz;
    
    vec3 col = vec3(0.0,0.0,0.0);
    
    float dist = calcIntersection( campos, camdir );
    
    if (dist==-1.0) col = background( camdir );
    else {
        vec3 inters = campos + dist * camdir;
        col = illuminate( inters, camdir );
    }
    
    //col = pow( abs(col), vec3(0.8));

    #if defined( TONE_MAPPING ) 
    col = toneMapping( col ); 
    #endif
    
    gl_FragColor = vec4(col,1.0);
}
