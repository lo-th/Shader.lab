

// ------------------ channel define
// 0_# bufferFULL_cubeA #_0
// ------------------

struct C{
    float d;
    int t;
};
    
float rand2(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float rand(vec3 v){
    return rand2(vec2(v.x+v.z,v.y+v.z));
}

int wait(float t){
    float period = 4.*3.141592/1.5;
    t = mod(t,period);
    if(t < period/2.){
        if(t < period/8.)return 0;
        if(t < period/4.)return 1;
        return int((t/period-1./4.)*40.)+2;
    }else{
        t-=period/2.;
        if(t < period/8.)return 10;
        if(t < period/4.)return 9;
        return 8-int((t/period-1./4.)*40.);
    }
    return 0;
}

float scal(float t){
    float period = 4.*3.141592/1.5;
    t = mod(t,period);
    float base = -1000.0;
    if(t < period/2.){
        if(t < period/8.)base=-1000.0;
        else if(t < period/4.)base=period/8.;
        else if(t<period*(1./4.+9./40.)){
            int x = int((t/period-1./4.)*40.);
            base = period*(1./4.+float(x)/40.);
        }
    }else{
        t -= period/2.;
        if(t < period/8.)base=-1000.0;
        else if(t < period/4.)base=period/8.;
        else if(t<period*(1./4.+9./40.)){
            int x = int((t/period-1./4.)*40.);
            base = period*(1./4.+float(x)/40.);
        }
    }
    return exp(-(t-base)*10.);
}

vec3 transform(vec3 p){
    float t = iGlobalTime+sin(iGlobalTime*1.5);
    p -= vec3(4,0,0);
    p *= mat3(cos(t),0,sin(t),0,1,0,-sin(t),0,cos(t));
    t *= 1.2;
    t += sin(iGlobalTime*0.5);
    p *= mat3(cos(t),sin(t),0,-sin(t),cos(t),0,0,0,1);
    return p;
}

float pattern(vec3 p){
    p = transform(p);
    float s = (0.7+scal(iGlobalTime)*0.08) / 0.7;
    p /= s;
    p /= 1.3;
    p += 0.5;
    float d = 0.;
    float t = iGlobalTime;
    vec3 e = vec3(float(int(t/(4.*3.141592/1.5))));
    for(int i=0;i<10;i++){
        if(wait(t) <= i)break;
        float w = pow(2.,float(i));
        float f;

        f = rand(vec3(0,0,float(i))+e);
        if(p.x < f)e.x+=w;
        else e.x-=w;
        if(pow(max(0.,1.-abs(p.x-f)),90.)*1.5 > 0.5+float(i)/20.)d = 1.;

        f = rand(vec3(1,0,float(i))+e);
        if(p.y < f)e.y+=w;
        else e.y-=w;
        if(pow(max(0.,1.-abs(p.y-f)),90.)*1.5 > 0.5+float(i)/20.)d = 1.;

        f = rand(vec3(2,0,float(i))+e);
        if(p.z < f)e.z+=w;
        else e.z-=w;
        if(pow(max(0.,1.-abs(p.z-f)),90.)*1.5 > 0.5+float(i)/20.)d = 1.;
    }
    return d<1.?0.:1.;
}

C dist(vec3 p){
    vec3 d = abs(transform(p)) - vec3(0.7+scal(iGlobalTime)*0.08);
    float u = min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
    return C(u-0.01,0);
}

C dist2(vec3 p){
    if(pattern(p) > 0.5){
        return C(1.,1);
    }else{
        return C(0.,0);
    }
}

vec3 normal(vec3 p){
    vec2 e = vec2(0.001,0);
    return normalize(vec3(
        dist(p+e.xyy).d - dist(p-e.xyy).d,
        dist(p+e.yxy).d - dist(p-e.yxy).d,
        dist(p+e.yyx).d - dist(p-e.yyx).d));
}

vec3 ground(vec3 v){
    return vec3(pow(dot(v,vec3(1,0,0)),4.)/8.);
}

vec3 object(vec3 p,vec3 v,vec3 n){
    float fac = 0.0;
    fac += pow(dot(reflect(v,n),vec3(-0.9,-0.5,-0.9)),1.)/8.;
    fac += pow(dot(reflect(v,n),vec3(-0.5,0.9,0.2)),1.)/4.;
    return vec3(fac);
}

vec3 neon(vec3 p,vec3 v,vec3 n){
    if(n.x > -0.2)return ground(v);
    else return vec3(0,0.5-0.5*n.x,1);
}

vec3 color(vec3 p, vec3 v){
    float d = 0.001;
    int maxIter = 100;
    C c=C(0.,-1);
    for(int i=0;i<100;i++){
        C ci=dist(p+d*v);
        float rd = ci.d;
        if(abs(rd) < 0.001){
            maxIter=i;
            c=ci;
            break;
        }
        d += rd;
    }
    if(c.t==-1)return ground(v);
    c=C(0.,-1);
    for(int i=0;i<100;i++){
        C ci=dist2(p+d*v);
        float rd = ci.d;
        if(abs(rd) < 0.001){
            maxIter=i;
            c=ci;
            break;
        }
        d += 0.0004;
    }
    if(c.t==-1)c.t=1;
    vec3 pos = p+d*v;
    vec3 n = normal(pos);
    if(c.t==0)return object(pos,v,n);
    else return neon(pos,v,n);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 R = iResolution.xy, 
    uv = (2.*fragCoord.xy - R)/R.y;
    vec3 p=vec3(0,0,0);
    vec3 v=vec3(1,uv.y,uv.x);
    v.yz/=3.;
    v=normalize(v);
    fragColor = vec4(color(p,v),1.0);
    vec3 flColor = texture2D(iChannel0,fragCoord.xy/R).xyz;
    fragColor.xyz += flColor*0.2;
}


//---------------------------

// THREE JS TRANSPHERE

void main(){

    vec4 color = vec4(0.0);

    // screen space
    //vec2 coord = gl_FragCoord.xy;
    // object space
    vec2 coord = vUv * iResolution.xy;

    mainImage( color, coord );

    // tone mapping
    #if defined( TONE_MAPPING ) 
    color.rgb = toneMapping( color.rgb ); 
    #endif

    gl_FragColor = color;

}

//---------------------------