// https://www.shadertoy.com/view/Xls3R7

uniform samplerCube envMap;
uniform vec3 iResolution;
uniform vec4 iMouse;
uniform float iGlobalTime;

varying vec2 vUv;
varying vec3 vEye;

float sphere(vec3 pos)
{
    return length(pos)-1.0;   
}

float box(vec3 pos)
{
    vec3 d = abs(pos) - 1.0;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float torus(vec3 pos)
{
    vec2 q = vec2(length(pos.xz)-2.0,pos.y);
    return length(q)-0.5;   
}

float blob7(float d1, float d2, float d3, float d4, float d5, float d6, float d7)
{
    float k = 2.0;
    return -log(exp(-k*d1)+exp(-k*d2)+exp(-k*d3)+exp(-k*d4)+exp(-k*d5)+exp(-k*d6)+exp(-k*d7))/k;
}

float scene(vec3 pos)
{
    float t = iGlobalTime;
    
    float p = torus(pos + vec3(0.0,3.0,0.0));
    float b = sphere(0.5*(pos + vec3(cos(t*0.5),sin(t*0.3),0.0)));
    float s1 = box(2.0*(pos + 3.0 * vec3(cos(t*1.1),cos(t*1.3),cos(t*1.7))))/2.0;
    float s2 = box(2.0*(pos + 3.0 * vec3(cos(t*0.7),cos(t*1.9),cos(t*2.3))))/2.0;
    float s3 = box(2.0*(pos + 3.0 * vec3(cos(t*0.3),cos(t*2.9),sin(t*1.1))))/2.0;
    float s4 = box(2.0*(pos + 3.0 * vec3(sin(t*1.3),sin(t*1.7),sin(t*0.7))))/2.0;
    float s5 = box(2.0*(pos + 3.0 * vec3(sin(t*2.3),sin(t*1.9),sin(t*2.9))))/2.0;
    
    return blob7(p, b, s1, s2, s3, s4, s5);
}

float calcIntersection( in vec3 ro, in vec3 rd )
{
    const float maxd = 15.0;
    const float precis = 0.001;
    float h = precis*2.0;
    float t = 0.0;
    float res = -1.0;
    for( int i=0; i<150; i++ )
    {
        if( h<precis||t>maxd ) break;
        h = scene( ro+rd*t );
        t += h;
    }

    if( t<maxd ) res = t;
    return res;
}

vec3 calcNormal( in vec3 pos )
{
    const float eps = 0.002;

    const vec3 v1 = vec3( 1.0,-1.0,-1.0);
    const vec3 v2 = vec3(-1.0,-1.0, 1.0);
    const vec3 v3 = vec3(-1.0, 1.0,-1.0);
    const vec3 v4 = vec3( 1.0, 1.0, 1.0);

    return normalize( v1*scene( pos + v1*eps ) + 
                      v2*scene( pos + v2*eps ) + 
                      v3*scene( pos + v3*eps ) + 
                      v4*scene( pos + v4*eps ) );
}

vec3 calcLight( in vec3 pos , in vec3 lightp, in vec3 lightc, in vec3 camdir)
{    
    vec3 normal = calcNormal(pos);
    vec3 lightdir = normalize(pos - lightp);
    float cosa = pow(0.5+0.5*dot(normal, -lightdir), 3.0);
    float cosr = max(dot(-camdir, reflect(lightdir, normal)), 0.0);
    
    vec3 ambiant = vec3(0.02);
    vec3 diffuse = vec3(0.7 * cosa);
    vec3 phong = vec3(0.3 * pow(cosr, 16.0));
    
    return lightc * (ambiant + diffuse + phong);
}

vec3 illuminate( in vec3 pos , in vec3 camdir )
{
    vec3 l1 = calcLight(pos, vec3(5.0,10.0,-20.0), vec3(1.0,1.0,1.0), camdir);
    vec3 l2 = calcLight(pos, vec3(-20,10.0,5.0), vec3(0.5,0.4,0.3), camdir);
    vec3 l3 = calcLight(pos, vec3(25.0,5.0,-5.0), vec3(0.4,0.3,0.2), camdir);
    vec3 l4 = calcLight(pos, vec3(-5.0,-15.0,10.0), vec3(0.1,0.1,0.1), camdir);
    return l1+l2+l3+l4;
}

vec3 background( vec3 rd ){

    return textureCube(envMap, rd).rgb * textureCube(envMap, -rd).rgb;

}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll ){

    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );

}

void main() {

    //vec2 xy = (gl_FragCoord.xy - iResolution.xy/2.0) / min(iResolution.xy.x, iResolution.xy.y);

    vec2 xy = ((vUv - 0.5) * 2.0) * vec2(iResolution.z, 1.0);
    
    float t = iGlobalTime;
    vec3 campos = vec3(10.0*sin(t*0.3),2.5*sin(t*0.5),-10.0*cos(t*0.3));
    vec3 camtar = vec3(0.0,0.0,0.0);
    
    mat3 camMat = calcLookAtMatrix( campos, camtar, 0.0 );
    vec3 camdir = normalize( camMat * vec3(xy,1.0) );
    
    vec3 col = vec3(0.0,0.0,0.0);
    
    float dist = calcIntersection(campos, camdir);
    
    if (dist==-1.0) col = background(camdir);
    else
    {
        vec3 inters = campos + dist * camdir;
        col = illuminate(inters, camdir);
    }
    
    col = pow( abs(col), vec3(0.8));
    
    gl_FragColor = vec4(col,1.0);
}
