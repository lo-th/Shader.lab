
// ------------------ channel define
// 0_# tex03 #_0
// ------------------

// https://www.shadertoy.com/view/Xss3z4

/*by mu6k, Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

 just playing around with some more rays...

 10/05/2013:
 - published

 24/05/2013:
 - added the compatibility fix as suggested by reinder

 muuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuusk!*/

float hash(vec2 x)
{
    return fract(cos(dot(x.xy,vec2(2.31,53.21))*124.123)*412.0);
}

float hash(float x)
{
    return fract(sin(cos(x)*124.123)*421.321);
}

float noise(vec2 p) 
{
    vec2 pm = mod(p,1.0);
    vec2 pd = p-pm;
    float v0=hash(pd.x+pd.y*41.0);
    float v1=hash(pd.x+1.0+pd.y*41.0);
    float v2=hash(pd.x+pd.y*41.0+41.0);
    float v3=hash(pd.x+pd.y*41.0+42.0);
    v0 = mix(v0,v1,smoothstep(0.0,1.0,pm.x));
    v2 = mix(v2,v3,smoothstep(0.0,1.0,pm.x));
    return mix(v0,v2,smoothstep(0.0,1.0,pm.y));
}

float dist(vec3 p) // distance function for the terrain, 2 layers of texture
{
    vec3 ps = p;
    
    p = ps;

    float d1 = p.y+2.0;
    
    p.x+=p.z*0.25;p.z-=p.x*0.25; //rotate
    d1-=textureLod(iChannel0,p.xz*0.01,0.0).r*0.7-5.5;;
    p.x+=p.z*0.25;p.z-=p.x*0.25; //rotate
    d1-=textureLod(iChannel0,p.xz*0.001,0.0).r*14.0-5.5;;   

    return d1;
}

float dist_smooth(vec3 p) //smoother version of the dist for the camera
{
    vec3 ps = p;
    
    p = ps;

    //p.z+=iTime*2.0+10.0; 
    float d1 = p.y+2.0;
    
    p.x+=p.z*0.25;p.z-=p.x*0.25;
    //d1-=texture(iChannel0,p.xz*0.01)*0.7-5.5;;
    p.x+=p.z*0.25;p.z-=p.x*0.25; 
    d1-=texture(iChannel0,p.xz*0.001).r*14.0-5.5;;  

    return d1;
}

vec3 normal(vec3 p) //returns the normal at a given position
{
    float e=0.1;
    float d=dist(p);
    return normalize(vec3(dist(p+vec3(e,0,0))-d,dist(p+vec3(0,e,0))-d,dist(p+vec3(0,0,e))-d));
}

//the sun has gone wild and is moving around like crazy...
//l is the light direction

vec3 l;

float shadow(vec3 p) //generates some really long shadows...
{
    float s = 0.0;
    for (int i=0; i<100; i++)
    {
        float d = dist(p);
        p+=l*(0.01+d*0.5);
        //float ss=clamp(0.0,d,1.0)*0.01;
        float ss = d; if (ss<0.0) ss = 0.0; if (ss>1.0) ss = 1.0;
        ss*=0.01;
        s+=ss;
        if (ss<0.0)
        {
            s=0.0;
            break;
        }
        if (p.y>150.0)
        {
            s+=float(99-i)*0.01; break;
        }
    }
    return pow(s,4.0);
}

float ao(vec3 p) //ambient occlusion
{
    vec3 n = normal(p);
    return (dist(p+n*0.5)/0.5+dist(p+n*4.33)*0.25)*0.5;
}

vec3 sky(vec3 dir) //atmospere
{
    dir.y = clamp(0.0,dir.y,1.0);
    float atmos = ((sin(l.y*3.14159+1.0))*pow((2.0-dir.y),4.0))*(dot(dir,l)*0.2+0.2);
    float atmos2 = ((l.y*0.5)*pow((2.0-dir.y),1.5));
    vec3 atmosc; atmosc.r = atmos*0.2; 
    atmosc.g=atmosc.r-0.5;atmosc.b=atmosc.g-0.3;
    atmosc = clamp(vec3(0.0),atmosc,vec3(2.0));
    
    vec3 atmos2c; atmos2c.b = atmos2*0.5; 
    atmos2c.g=atmos2c.b-0.2;atmos2c.r=atmos2c.g-0.2;
    atmos2c = clamp(vec3(0.0),atmos2c,vec3(2.0));
    vec3 final = atmosc*0.5+atmos2c;
    
    final += vec3(0.1,0.13,0.2);
    
    final = max(vec3(.0),final);
    return final;
}


float stars(vec3 dir) //stars are generated using 2d noise on a UV sphere
{
    vec2 staruv = vec2(atan(dir.x/dir.z)*88.0+iTime*0.1,dir.y*64.0);
    float st = (noise(staruv)+noise(staruv*5.1)+noise(staruv*2.7))*0.3633;
    if (st<0.0) st = 0.0;
    st = pow(st,25.0);
    st*=1.0-abs(dir.y);
    return st;
}   

vec3 sun(vec3 dir) //makes that bright spot on the sky
{
    float sun = dot(dir,l);
    sun+=1.0; sun*=0.5; sun= pow(sun,127.0);
    return vec3(sun);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    l =normalize(vec3(sin(iTime*0.41),sin(iTime*0.1)*0.27+0.30,cos(iTime*0.512)));

    
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 m = iMouse.xy / iResolution.xy - 0.5;
    m+=vec2(0.0,0.1);
    
    //move the camera forward!
    vec3 pos = vec3(sin(iTime*0.013)*10.0,-1.0,cos(iTime*0.01)+iTime*3.0);
    //move the camera up based on the distance from the heightmap
    pos = vec3(pos.x,-5.0-dist_smooth(pos),pos.z);
    //camera direction
    vec3 dir = vec3((uv.x-0.5)*iResolution.x/iResolution.y,uv.y-0.5,1.0);
    dir.xy+=m*0.1;
    //dir.z += sin(iTime*0.35117)*0.1;
    dir.z = (1.0-length(dir)*0.5);
    dir = normalize(dir);
    
    vec3 color,skycolor=sky(dir),suncolor=vec3(sun(dir)),starscolor=vec3(stars(dir));
    float t = iTime;
    float totald = 0.0; //distance travelled, used for fog
    
    float visp = (dir.x+dir.z*0.5+0.95-dir.y*0.5); visp=abs(visp); visp=pow(visp,0.8)*0.19;
    float vis= texture(iChannel1,vec2(visp,0.0)).y;
    vis = min(1.0,vis*1.2*(0.92+visp*0.6));
    vis=pow(vis,20.0)*2.5*dir.y;

    color = skycolor+suncolor+starscolor+vec3(vis)*vec3(0.4,0.7,0.2);; //first do the sky
    
    for (int i=0; i<150; i++) //now raymarch
    {
        float d = dist(pos);
        pos += dir * d*0.5;
        totald+=d;
        
        if (pos.y>10.0)
        {
            break; //ray is in the sky and will never hit anything else
        }
        if (d<totald*0.001) //hit
        {
            vec3 n = normal(pos); //get normal
            
            float diffuse = dot(normal(pos),l); //direct sun light
            if (diffuse<0.0) diffuse = 0.0;

    
            vec3 ambientc = (sky(n));
            
            color= mix(ambientc*.7*(0.5+n.y*0.5),(ambientc+vec3(0.8,0.6,0.4)),diffuse*ao(pos)*shadow(pos));

            color = mix(skycolor+suncolor*.2,color,1.0/(1.0+totald*0.05)); //fog
            
            break;
        }
    }
    
    color = color*vec3(1.5,1.5,1.5);
    color -= length(uv.xy-0.5)*0.3;
    color+=(hash(uv.xy+color.xy)-0.5)*0.015;
    
    
    float w=color.x+color.y+color.z;
    color = mix(color,vec3(w,w,w)*0.3,w*0.35);
    
    fragColor = vec4(color,1.0);
}