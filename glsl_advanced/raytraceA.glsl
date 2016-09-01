// ------------------ channel define
// 0_# bufferFULL_raytraceA #_0
// 1_# cube_grey1 #_1
// ------------------

//thank for the demo https://www.shadertoy.com/view/4dtGWB
//and the tutorial https://www.shadertoy.com/view/XllGW4
//and https://www.shadertoy.com/view/Xl2XWt

#define PI 3.141592654
#define MAX_BOUNCE 4
#define MIN_DISTANCE 0.003

float seed = 0.;
float rand() { return fract(sin(seed++)*43758.5453123); }

struct Mat{
    vec3 color;
    float metallic;
    float glossiness;
};
void makeMat(out Mat mat,vec3 color,float metallic,float glossiness){
    mat.color = color;
    mat.metallic = metallic;
    mat.glossiness = glossiness;
}

//=================

vec2 sdBox( vec3 p, vec3 size ,vec3 pos,int mat)
{
  vec3  di = abs(p - pos) - size;
  float mc = max(di.x,max(di.y,di.z));
  float d = min(mc,length(max(di,0.0)));
  return vec2(d,mat);
}

vec2 sdSphere( vec3 p,vec3 pos, float r ,int mat) {
    float d = length(p - pos) - r;
    return vec2(d,mat);
}

float sdCappedCylinder( vec3 p, vec2 h ,vec3 pos,int mat)
{
    p = p - pos;
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec4 map( in vec3 p )
{
    vec2 d  = sdBox(p,vec3(1.2,0.2,1.2),vec3(0,-0.21,0),0);
    
    for(int i = 0; i<5; i++){
        d = opU(d,sdSphere(p,vec3(0.8,0.2,-1.0 + 0.5 * float(i)) ,0.2,1 + i));//mat=1~5
    }

    for(int i = 0; i<5; i++){
        d = opU(d,sdSphere(p,vec3(-0.8,0.2,-1.0 + 0.5 * float(i)) ,0.2,6 + i));//mat=6~10
    }
    
    d = opU(d,sdSphere(p,vec3(-0.1,0.30,-0.5) ,0.3,11)); 
    d = opU(d,sdSphere(p,vec3(-0.3,0.15,0.3),0.15 ,12)); 
    d = opU(d,sdSphere(p,vec3(0.2,0.205,0.0) ,0.2,13)); 

    float mat = d.y;
    vec4 res = vec4( d.x, 1.0, 0.0, mat );
    return res;
}

//=================

vec4 intersect( in vec3 ro, in vec3 rd )
{
    float t = 0.0;
    vec4 res = vec4(-1.0);
    vec4 h = vec4(1.0);
    for( int i=0; i<100; i++ )
    {
        if( h.x<MIN_DISTANCE || t>10.0 ) break;
        h = map(ro + rd*t);
        res = vec4(t,h.yzw);
        t += h.x;
    }
    if( t>10.0 ) res=vec4(-1.0);
    return res;
}

vec3 getBackground( vec3 rd ) {
    //return mix( vec3(0.1,0.05,0.0), vec3(0.2, 0.3, 0.4), 0.5 + 0.5*dir.y );
    return textureCube(iChannel1, rd).xyz; 
}

vec3 calcNormal(in vec3 pos)
{
    vec3  eps = vec3(.001,0.0,0.0);
    vec3 nor;
    nor.x = map(pos+eps.xyy).x - map(pos-eps.xyy).x;
    nor.y = map(pos+eps.yxy).x - map(pos-eps.yxy).x;
    nor.z = map(pos+eps.yyx).x - map(pos-eps.yyx).x;
    return normalize(nor);
}

Mat getMat(int index){
    Mat mat;
    if(index ==0)       {
        makeMat(mat,vec3(0.90,0.10,0.00),0.0,0.5);
    }
    else if(index >= 1 && index <= 5)   {
        float glossiness = (float(index) - 1.0) / 4.0;
        makeMat(mat,vec3(0.80,0.80,0.80),1.0,glossiness);
    }
    else if(index >= 6 && index <=10)   {
        float glossiness = (float(index) - 6.0) / 4.0;
        makeMat(mat,vec3(0.80,0.80,0.80),0.0,glossiness);
    }
    else if(index == 11){
        makeMat(mat,vec3(0.00,0.60,0.90),0.0,0.5);
    }
    else if(index == 12){
        makeMat(mat,vec3(0.0,0.0,0.0),0.0,0.95);
    }
    else if(index == 13){
        makeMat(mat,vec3(1.00,0.80,0.50),1.0,0.5);
    }
    return mat;   
}

vec3 randDir(vec3 ref, float glossiness)
{
    vec3 w = ref;//normalize(mix(nor,ref,glossiness));
    vec3 u = normalize(cross(vec3(w.y,w.z,w.x), w));
    vec3 v = normalize(cross(w, u));

    float shininess = pow(8192.0, glossiness);

    float a = acos(pow(1.0 - rand() * (shininess + 1.0) / (shininess + 2.0), 1.0 / (shininess + 1.0)));
    a *= PI * 0.5;
    float phi = rand() * PI * 2.0;
    vec3 rlt = (u * cos(phi) + v * sin(phi)) * sin(a) + w * cos(a);

    return rlt;
}

float fresnelSchlick(float InCosine, float normalReflectance)
{
    float oneMinusCos = 1.0 - InCosine;
    float oneMinusCosSqr = oneMinusCos * oneMinusCos;
    float fresnel = normalReflectance +
        (1.0 - normalReflectance) * oneMinusCosSqr * oneMinusCosSqr * oneMinusCos;

    return fresnel;
}

//=========================

// light
vec3 light = normalize(vec3(0.8,0.5,0.2));
//vec3 lightColor = vec3(0.8,0.6,0.6);

vec3 render( in vec3 ro, in vec3 rd )
{   
    vec3 pos = ro;
    vec3 dir = rd; 

    vec3 finalLight = vec3(0.0);
    vec3 frac = vec3(1.0);
    for(int i= 0; i<MAX_BOUNCE; i++){
        vec4 tmat = intersect(pos,dir);
        if(tmat.x > 0.0){
            Mat mat = getMat(int(tmat.w));
            pos += tmat.x*dir;
            vec3 nor = calcNormal(pos);
            float r = mix(0.15,1.0,mat.metallic);
            r = fresnelSchlick(dot(nor,-dir),r);
            if(rand() > r){//diffuse
                vec4 tshadow = intersect(pos + nor * MIN_DISTANCE,randDir(light,0.995));//softshadow
                float shadow = tshadow.x>0.0?0.0:1.0;
                vec3 diff = mat.color * shadow * max(dot(nor,light),0.0);                
                finalLight += diff * frac;
                frac *= mat.color;
                dir = randDir(reflect(dir,nor),r);
            }
            else{//spec
                vec3 refColor = mix(vec3(1.0),mat.color,mat.metallic);
                frac *= refColor;
                dir = randDir(reflect(dir,nor),mat.glossiness);
            }            
            

            pos += nor * MIN_DISTANCE;
        }
        else{
            vec3 bkgColor = getBackground(dir);
            finalLight += bkgColor * frac;
            finalLight += pow(max(dot(dir,light),0.0),50.0);
            break;
        }
    }
    return finalLight;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    seed = iGlobalTime + iResolution.y * fragCoord.x / iResolution.x + fragCoord.y / iResolution.y;
    
    
    float weight = 1.0;
    //if mouse moved,reset weight
    {
        vec2 uvMouse = vec2(0.5,0.5) / iResolution.xy;
        vec4 lastMouse = texture2D(iChannel0, uvMouse);
        float mouseMove = length(lastMouse.xy * iResolution.xy - iMouse.xy);
        if(mouseMove > 1.0 || iFrame == 0){
            weight = 1.0;
        }
        else{
            weight = lastMouse.z;
        }
        weight = max(weight,0.0001);

        if(fragCoord.x == 0.5 && fragCoord.y == 0.5){
            fragColor = vec4(iMouse.xy/iResolution.xy,1.0/(1.0/weight + 1.0) ,0.0);
            return;
        }
    }
    
    vec2 p0 = fragCoord.xy + vec2(rand(),rand());//anti-aliasing
    vec2 p1 = -1.0 + 2.0 * p0 / iResolution.xy;
    p1.x *= iResolution.x/iResolution.y;

    float yaw = iMouse.x * 0.05;
    float pitch = clamp(iMouse.y * 2.0 /iResolution.y,-PI * 0.5,PI * 0.5);
       
    vec3 ro = 1.1*vec3(2.5*sin(0.25*yaw),2.5 * cos(pitch),2.5*cos(0.25*yaw));
    vec3 ww = normalize(vec3(0.0) - ro);
    vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww ));
    vec3 vv = normalize(cross(ww,uu));
    vec3 rd = normalize( p1.x*uu + p1.y*vv + 2.5*ww );

    vec3 col = render( ro, rd );
    
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 lastColor = texture2D(iChannel0, uv);
    
    fragColor = vec4(mix(lastColor.xyz,col,weight),1);
}

