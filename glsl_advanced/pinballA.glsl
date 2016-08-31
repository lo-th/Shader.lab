
// ------------------ channel define
// 0_# bufferFULL_pinballA #_0
// ------------------

//The "physics" is more complicated then the image! How can one ball bouncing off the surface
//be harder to mimic than 1000s of photons?
#define RADIUS 0.075
#define PI 3.14159
#define KEY_LEFT 39
#define KEY_RIGHT 37

#define inside(a) (fragCoord.y-a.y == 0.5 && (fract(a.x) == 0.1 || fragCoord.x-a.x == 0.5))
#define load(a) texture2D(iChannel0,(vec2(a,0.0)+0.5)/iResolution.xy)
#define save(a,b) if(inside(vec2(a,0.0))){fragColor=b;return;}

bool KeyDown(in int key){
    return (texture2D(iChannel1,vec2((float(key)+0.5)/256.0, 0.25)).x>0.0);
}
float Paddle(vec2 pa, vec2 ba){
    float t=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
    return length(pa-ba*t)+t*0.01;
}
float Tube(vec2 pa, vec2 ba){return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0));}
vec2 Tube2(vec2 pa, vec2 ba){
    float t=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
    return vec2(length(pa-ba*t)+t*0.01,t);
}

vec2 pdl,pdr;
vec4 st2;
float DEP(in vec2 p, bool bNoFlip){//determine the push from paddles
    vec2 dl=Tube2(p-vec2(-0.5,-1.0),pdl)-0.05;
    vec2 dr=Tube2(p-vec2(0.5,-1.0),pdr)-0.05;
    float y=p.y*0.12;
    p=abs(p);p.y=abs(p.y-1.0);
    float dB=length(p-vec2(0.74-y,0.79))-0.05;
    if(dB<RADIUS){
        st2.x=1.0;//light on
        st2.y+=(y>0.1?50.0:1.0);//points
        return 2.0;
    }
    if(!bNoFlip && min(dl.x,dr.x)<RADIUS){//possible push

       
        int keey=KEY_RIGHT;
        if(dl.x<dr.x){
            keey=KEY_LEFT;
            dr=dl;
        }
        if(KeyDown(keey))return 5.0*dr.y;
    }
    return 0.0;
}

float DE(in vec2 p){//2d version
    float y=p.y*0.12;
    float dP=min(Paddle(p-vec2(-0.5,-1.0),pdl),Paddle(p-vec2(0.5,-1.0),pdr));
    p.x=abs(p.x);
    float d=min(max(p.x-1.0,abs(p.y)-1.5),length(p-vec2(0.0,1.5))-1.0);
    p.y=abs(p.y);
    d=min(abs(d),Tube(p-vec2(0.47-y,0.95),vec2(0.32,-0.12)));
    p.y=abs(p.y-1.0);
    d=min(d,Tube(p-vec2(0.26,1.0),vec2(0.15,-0.14)));
    float dB=length(p-vec2(0.74-y,0.79));
    d=min(min(d,dB),dP);
    d-=0.05;
    return d;
}

vec2 rotate(vec2 v, float angle) {return cos(angle)*v+sin(angle)*vec2(v.y,-v.x);}

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    float kRight = max(0., key[0]);//texture2D( iChannel1, vec2(KEY_RIGHT, 0.25) ).x;
    float kLeft  = min(0., key[0]) * -1.0;
    float space  = key[4];

    if(fragCoord.y>1.0 || fragCoord.x>4.0)discard;
    //st0=paddle rotation,old ball pos st1=ball position, velocity
    vec4 st0=vec4(0.5,-0.5,0.0,0.0),st1=vec4(-0.94+RADIUS,1.0,0.0,0.0);
    //st3=last time
    vec4 st3=vec4(iGlobalTime-0.02,0.0,0.0,0.0);
    if( space > 0.2){
        st2=vec4(0.0,0.0,2.0,-1.0);// lightup, score, balls left, new ball
    }else{
        st0=load(0);
        st1=load(1);
        st2=load(2);
        st3=load(3);
    }
    if(st2.z<0.0)discard;
    if(st2.w<0.0){st1=vec4(-0.94+RADIUS,0.0,0.0,2.75+sin(iGlobalTime));st2.w=0.0;}
    float dt=iGlobalTime-st3.x;//iTimeDelta;
    st2.x=max(0.0,st2.x-3.0*dt);
#define GRAVITY 1.5
    st1.w-=GRAVITY*dt;
    vec2 oflp=st0.xy;
#define FLIPPER_SPEED 3.0
    if(kLeft>0.5)st0.x-=FLIPPER_SPEED*dt;
    else st0.x+=FLIPPER_SPEED*dt*0.5;
    if(kRight>0.5)st0.y+=FLIPPER_SPEED*dt;
    else st0.y-=FLIPPER_SPEED*dt*0.5;
    st0.xy=clamp(st0.xy,vec2(-0.25,-0.5),vec2(0.5,0.25));
    bool bNoFlip=(oflp==st0.xy);
    float t=0.0,d;
#define ITERS 16
    float sdt=dt/float(ITERS);
    vec2 sflp=(st0.xy-oflp)/float(ITERS);
    vec2 v=vec2(RADIUS*0.5,0.0);
    for(int i=0;i<ITERS;i++){//cutting the step into subframes (really important on show machines)
        pdl=rotate(vec2(0.33,0.0),oflp.x);pdr=rotate(vec2(-0.33,0.0),oflp.y);
        d=DE(st1.xy+st1.zw*t);
        if(d<RADIUS){//i put this inside the loop so there can be multiple subframe bounces
            st1.xy+=st1.zw*t;
            vec2 N=normalize(vec2(DE(st1.xy+v.xy)-DE(st1.xy-v.xy),DE(st1.xy+v.yx)-DE(st1.xy-v.yx)));
            if(dot(N,st1.zw)<0.0){//if the ball has gone more than half way thru we are screwed
                st1.zw=reflect(st1.zw,N)/(1.1+dot(-st1.zw,N)*0.2);
                st1.zw+=N*DEP(st1.xy,bNoFlip);
            }
            t=0.0;
        }
        t+=sdt;
        oflp+=sflp;
    }
    st1.xy+=st1.zw*t;
    if(st1.y<-1.45+RADIUS*1.1){st2.z-=1.0;st2.w=-1.0;}
    st0.zw=st0.zw*0.9+st1.xy*0.1;
    st3.x=iGlobalTime;
    save(0,st0);
    save(1,st1);
    save(2,st2);
    save(3,st3);
}