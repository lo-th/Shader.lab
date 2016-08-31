// ------------------ channel define
// 0_# bufferFULL_rainA #_0
// ------------------

//OMGS
///proudly presents zguerrero`s slowmo fluid as rain on camera/window
/// work based on sauce: https://www.shadertoy.com/view/ltdGDn
// License: MINE, MY OWN! I knows you wants it precious

float smooth = 0.1;
float ballradius = 0.0;
float metaPow = 1.0;
float densityMin = 4.0;
float densityMax= 7.0;
float densityEvolution = 0.4;
float rotationSpeed = 0.005;
vec2 moveSpeed = vec2(0.1,0.0);
float distortion = 0.05;
float nstrenght = 1.0;
float nsize = 1.0;
vec3 lightColor = vec3(7.0,8.0,10.0);

float saturate1(float x)
{
    return clamp(x, 0.0, 1.0);
}
vec2 rotuv(vec2 uv, float angle, vec2 center)
{    
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * (uv - center) + center;
}
float hash(float n)
{
   return fract(sin(dot(vec2(n,n) ,vec2(12.9898,78.233))) * 43758.5453);  
}  

float metaBall(vec2 uv)
{
    return length(fract(uv) - vec2(0.5));
}
float rand(float co){
    return fract(sin(dot(vec2(co) ,vec2(12.9898,78.233))) * 43758.5453);
}
float metaNoiseRaw(vec2 uv, float density)
{
    float v =10.5, metaball0=3.;
    
    
    for(int i = 0; i < 23; i++)
    {
        float inc = float(rand(float(i))) + 1.0;
        float r1 = hash(15.3548*inc);
        float s1 = iGlobalTime*rotationSpeed*r1;
        vec2 f1 = moveSpeed*r1;
        vec2 c1 = vec2(hash(11.2*inc)*20., hash(33.2*inc))*70.0*rand(float(i)) - s1;   
        vec2 uv1 = -rotuv(uv*(1.0+r1*v), r1*60.0 + s1, c1) ;    
        float metaball1 = saturate1(metaBall(uv1)*density);
        
        metaball0 *= metaball1;
    }
    
    return pow(metaball0, metaPow);
}

float metaNoise(vec2 uv)
{ 
    float density = mix(densityMin,densityMax,sin(densityEvolution)*0.5+0.5);
    return 1.0 - smoothstep(ballradius, ballradius+smooth, metaNoiseRaw(uv, density));
}

vec4 calculateNormals(vec2 uv, float s){

    float offsetX = nsize*s/iResolution.x;
    float offsetY = nsize*s/iResolution.y;
    vec2 ovX = vec2(0.0, offsetX);
    vec2 ovY = vec2(0.0, offsetY);
    
    float X = (metaNoise(uv - ovX.yx) - metaNoise(uv + ovX.yx)) * nstrenght;
    float Y = (metaNoise(uv - ovY.xy) - metaNoise(uv + ovY.xy)) * nstrenght;
    float Z = sqrt(1.0 - saturate1(dot(vec2(X,Y), vec2(X,Y))));
    
    float c = abs(X+Y);
    return normalize(vec4(X,Y,Z,c));
    
}

void main(){

    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 uv2 = uv;

    vec2 sphereUvs = uv - vec2(0.5);
    float vign = length(sphereUvs);
    
    float noise = metaNoise(uv2);
    vec4 n = calculateNormals(uv2, smoothstep(0.0, 0.1, 1.0));
    n.xyz += texture2D(iChannel0,uv).xyz*0.99;
    
    gl_FragColor = vec4(vec3(n)+0.5, 1.0);
}