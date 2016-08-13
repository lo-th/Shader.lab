
// ------------------ channel define
// 0_# noise #_0
// ------------------

/*by musk License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

    I've been planning to do something like this for years,
    but I never had the knowledge or time. Today I have both! Oh yeah!

    Inspired by the floating mountains of avatar. 
    Going for a more exotic tropical look.

    Instructions:

        - if you wait you get different ladscapes
        - click and drag slowly to look around with mouse
        - wait until water rises and lowers, 
        - if bored with landscape change time_offset parameter
        - you can pause and look around with mouse
        - to increase performance reduce iteration count
        - you can increase precision with high_precision_trace switch

    Screenshot: http://i.snag.gy/ckSmg.jpg
    Soundtrack: http://www.youtube.com/watch?v=aHMmoSX3hhM

    Features:
    
        - mouselook
        - soft shadows shadows
        - ambient occlusion
        - 2 distance fields & 2 materials
        - lens flare with occlusion
        - moving clouds & moving lightsource
        - 3d noise based terrain
        - 2d texture based mipmapped noise functions
        - reflection with occlusion
        - depth of field (nearby objects)
        - motion blur
        - post processing
        - changing water level

    I'm getting 20-30 fps on nvidia 9800. (not fullscreen)

    Please post bugs in comment section!!! 
    You can compare the render with my screenshot.
    Screenshot again: http://i.snag.gy/ckSmg.jpg

    History:

        - 19/02/2014 published

*/

//parameters
#define time_offset 0
#define general_speed 1.0
#define camera_speed 2.0
#define trace_iterations 100
#define light_occlusion_iterations 10
#define relection_occlusion_iterations 10
#define flare_occlusion_iterations 20

//switches
//#define high_precision_trace
#define motion_blur
#define render_water
#define render_terrain

//the following switches exclude each other
//#define shading_normal_only
//#define shading_light_occlusion_only
//#define shading_ambient_occlusion_only

//functions that build rotation matrixes
mat2 rotate_2D(float a){float sa = sin(a); float ca = cos(a); return mat2(ca,sa,-sa,ca);}
mat3 rotate_x(float a){float sa = sin(a); float ca = cos(a); return mat3(1.,.0,.0,    .0,ca,sa,   .0,-sa,ca);}
mat3 rotate_y(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,.0,sa,    .0,1.,.0,   -sa,.0,ca);}
mat3 rotate_z(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,sa,.0,    -sa,ca,.0,  .0,.0,1.);}

//2D texture based 3 component 1D, 2D, 3D noise
vec3 noise(float p){return texture2D(iChannel0,vec2(p/iChannelResolution[0].x,.0)).xyz;}
vec3 noise(vec2 p){return texture2D(iChannel0,p/iChannelResolution[0].xy).xyz;}
vec3 noise(vec3 p){float m = mod(p.z,1.0);float s = p.z-m; float sprev = s-1.0;if (mod(s,2.0)==1.0) { s--; sprev++; m = 1.0-m; };return mix(texture2D(iChannel0,p.xy/iChannelResolution[0].xy+noise(sprev).yz).xyz,texture2D(iChannel0,p.xy/iChannelResolution[0].xy+noise(s).yz).xyz,m);}

vec3 noise(float p, float lod){return texture2D(iChannel0,vec2(p/iChannelResolution[0].x,.0),lod).xyz;}
vec3 noise(vec2 p, float lod){return texture2D(iChannel0,p/iChannelResolution[0].xy,lod).xyz;}
vec3 noise(vec3 p, float lod){float m = mod(p.z,1.0);float s = p.z-m; float sprev = s-1.0;if (mod(s,2.0)==1.0) { s--; sprev++; m = 1.0-m; };return mix(texture2D(iChannel0,p.xy/iChannelResolution[0].xy+noise(sprev,lod).yz,lod).xyz,texture2D(iChannel0,p.xy/iChannelResolution[0].xy+noise(s,lod).yz,lod).xyz,m);}


vec3 air_color = vec3(.3,.45,.6);
float t;
//dinst2 function computes distance and fog density ;)
#ifdef render_terrain
vec2 terra(vec3 p)
{
    float q = length(p.xz)*.125;
    float lod = -16.0;
    vec3 nnn = noise(p*.125,lod);
    vec3 n1 =  p.y*.0125+nnn*8.0;
    vec3 n2 = p.y*.15+noise(p*.25+nnn.y,lod)*4.0;
    vec3 n3 = noise(p*vec3(1.0,0.5,1.0)+nnn.z,lod);
    float d = n1.x+n2.x+n3.x + noise(p.xz*4.10).x*.44*nnn.z;
    float density  = max(.0,pow(-p.y*.5,2.5)*.2)*(max(.0,pow(n1.y+nnn.z*.5+n2.y*.1,3.0)*.0000016)+.000025);
    return vec2(d,density*.3);
}
#else
vec2 terra(vec3 p)
{
    return vec2(1024.0*1024.0,.0);
}
#endif

#ifdef render_water
vec2 water(vec3 p)
{
    return vec2(p.y+38.0-sin(t*.04)*12.0,.0);
}
#else
vec2 water(vec3 p)
{
    return vec2(1024.0*1024.0,.0);
}
#endif

vec2 dist2(vec3 p)
{
    vec2 f1 = terra(p);
    vec2 f2 = water(p);
    return vec2(min(f1.x,f2.x),f1.y+f2.y);
}

float dist(vec3 p)
{
    return dist2(p).x;
}

float amb_occ(vec3 p)
{
    float acc=0.0;
    #define ambocce 1.9

    acc+=dist(p+vec3(-ambocce,-ambocce,-ambocce));
    acc+=dist(p+vec3(-ambocce,-ambocce,+ambocce));
    acc+=dist(p+vec3(-ambocce,+ambocce,-ambocce));
    acc+=dist(p+vec3(-ambocce,+ambocce,+ambocce));
    acc+=dist(p+vec3(+ambocce,-ambocce,-ambocce));
    acc+=dist(p+vec3(+ambocce,-ambocce,+ambocce));
    acc+=dist(p+vec3(+ambocce,+ambocce,-ambocce));
    acc+=dist(p+vec3(+ambocce,+ambocce,+ambocce));
    return 0.5+acc /(16.0*ambocce);
}

vec3 lensflare(vec2 uv,vec2 pos)
{
    vec2 main = uv-pos;
    vec2 uvd = uv*(length(uv));
    
    float ang = atan(-main.x,-main.y);
    float dist=length(main); dist = pow(dist,.1);
    
    float f0 = 1.0/(length(uv-pos)*32.0+1.0);
    
    f0 = f0+f0*(sin(noise((pos.x+pos.y)*2.2+ang*4.0+5.954)*16.0)*.1+dist*.1+.8).x;
    
    float f1 = max(0.01-pow(length(uv+1.2*pos),1.9),.0)*7.0;

    float f2 = max(1.0/(1.0+32.0*pow(length(uvd+0.8*pos),2.0)),.0)*00.25;
    float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*pos),2.0)),.0)*00.23;
    float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*pos),2.0)),.0)*00.21;
    
    vec2 uvx = mix(uv,uvd,-0.5);
    
    float f4 = max(0.01-pow(length(uvx+0.4*pos),2.4),.0)*6.0;
    float f42 = max(0.01-pow(length(uvx+0.45*pos),2.4),.0)*5.0;
    float f43 = max(0.01-pow(length(uvx+0.5*pos),2.4),.0)*3.0;
    
    uvx = mix(uv,uvd,-.4);
    
    float f5 = max(0.01-pow(length(uvx+0.2*pos),5.5),.0)*2.0;
    float f52 = max(0.01-pow(length(uvx+0.4*pos),5.5),.0)*2.0;
    float f53 = max(0.01-pow(length(uvx+0.6*pos),5.5),.0)*2.0;
    
    uvx = mix(uv,uvd,-0.5);
    
    float f6 = max(0.01-pow(length(uvx-0.3*pos),1.6),.0)*6.0;
    float f62 = max(0.01-pow(length(uvx-0.325*pos),1.6),.0)*3.0;
    float f63 = max(0.01-pow(length(uvx-0.35*pos),1.6),.0)*5.0;
    
    vec3 c = vec3(.0);
    
    c.r+=f2+f4+f5+f6; c.g+=f22+f42+f52+f62; c.b+=f23+f43+f53+f63;
    c = c*1.3 - vec3(length(uvd)*.05);
    c+=vec3(f0);
    
    return c*=(noise(vec3(uv*.7,t*.03712))*.6+.7)*(noise(uv*8.0).y*.4+.9);;
}

vec3 normal(vec3 p) //returns the normal, uses the distance function
{
    float e = .1;
    float d=dist(p);
    vec3 n = normalize(vec3(dist(p+vec3(e,0,0))-d,dist(p+vec3(0,e,0))-d,dist(p+vec3(0,0,e))-d));
    n = normalize(n*4.0+( noise(p*vec3(2.5,14.5,2.5))-vec3(.5) )*2.0+( noise(p*7.0)-vec3(.5)) );
    return n;
    
}

float cloud(vec3 d)
{
    float a = .0;
    vec2 geo = d.xz/(pow(d.y,.5))*.5;
    geo += + vec2(t*.005);
    geo += noise(geo).yz*.5;
    a = (noise(geo*256.0).y)*.02+(noise(geo*08.0).y)*.30;
    geo += noise(geo*4.0).yz*.2;
    a = a
        +(noise(geo*32.0).y)*.07
        +(noise(geo*16.0).y)*.15
        +(noise(geo*128.0).y)*.03
        +(noise(geo*04.0).y)*.60
        ;
    a = min(max(.0,a),1.0);
    return a;
}

vec3 backdrop(vec3 d)
{
    float cl = cloud(d);
    vec3 ac = air_color*(-d.y*.5+.7);
    return mix(mix(mix(ac,vec3(1.0),pow(cl,5.0)),vec3(.1)+ac*.5,pow(cl,4.0)*.5),ac,.7);;
}

void main(){
    //vec2 uv = fragCoord.xy / iResolution.xy - 0.5;
    //uv.x *= iResolution.x/iResolution.y; //fix aspect ratio
    vec2 uv = ( ( vUv * 2.0 ) - 1.0 ) * vec2(iResolution.z, 1.0);

    vec3 mouse = vec3(iMouse.xy/iResolution.xy - 0.5,iMouse.z-.5);

    #ifdef motion_blur
    t = (iGlobalTime + noise(gl_FragCoord.xy).y/24.0 + float(time_offset))*general_speed;
    #else
    t = (iGlobalTime + float(time_offset))*general_speed;
    #endif

    
    vec3 p = vec3(.0,.0,8.0);
    vec3 d = normalize(vec3(uv,-0.5 ));
    
    
    
    mouse.xy+=vec2(.7422+sin(t*.16)*.01,.5+sin(t*.17)*.01);
    
    mouse*=16.0;
    
    mat3 rotation = rotate_x(mouse.y)*rotate_y(mouse.x);
    mat3 inv_rotation = rotate_y(-mouse.x)*rotate_x(-mouse.y);
    p*=rotation; d*=rotation;
    
    p.x+=t*camera_speed-1.0/(t*.3)-540.0+sin(t*.031)*40.0;
    p.y-=24.0;
    p.xz+=vec2(sin(t*.12),sin(t*.13))*4.0;
    
    vec3 start_pos = p;
    
    d+=(noise(uv*iResolution.y)-vec3(.5))*.001;
    p+=d*noise(uv*iResolution.y)*.05;
    
    vec3 c = backdrop(d);
    
    float acc = .0;
    float ds;
    for (int i=0; i<trace_iterations; i++)
    {
        vec2 distres = dist2(p);
        #ifdef high_precision_trace
        float ds = distres.x*.5;
        #else
        float ds = distres.x;
        #endif
        float de = distres.y;
        p+=ds*d;
        acc+=de*ds;
        //if (ds<.01) break;
        if (acc>1.0 || ds<.01|| p.y>8.0) 
        {
            break;
        }
    }
    
    acc = min(acc,1.0);
    
    vec3 light = normalize(vec3(sin(t*0.047),1.0-cos(t*.0471)*cos(t*.0271)*.8,cos(t*.0317)));
    
    float flare = dot(d,light)*.5+.5;
    c+=pow(flare,800.0)*1.5;
    
    if (acc<1.0&&dist(p)<2.1)
    {
        float od = 1.0;
        vec3 odir = light;
        vec3 opos = p+odir;
        
        
        for (int i=0; i<light_occlusion_iterations; i++)
        {
            float dd = dist(opos);
            od = min(dd*2.0,od);
            #ifdef high_precision_trace
            opos+=dd*odir*1.0;
            #else
            opos+=dd*odir*2.0;
            #endif
            if (od<.02||opos.y>4.0) break;
        }
        
        
        od = max(od,.0);
        vec3 n = normal(p);
        
        float diffuse = dot(n,light)*.8+.2; 
            diffuse = pow(max(.0,diffuse*od),.7); 
            diffuse = diffuse*.7 + .3;
        
        float ao = amb_occ(p)*.8+.2;
            
            float ao2 = dist(p+n)*1.0*.5+.4;
        
        if (terra(p).x<water(p).x)
        {
            
            float shade = (dist(p-d)*.7+.3);
            //float vertical = noise(p*vec3(2.5,14.5,2.5)).y*.5+.5;
            
            float top = max(.0,n.y);
            n+=top*noise(p.xz*16.0)*.5;
            n+=top*noise(p.xz*64.0)*.5;
            n=normalize(n);
            top = max(.0,n.y);
            
            float specular  = pow(dot(reflect(d,n),light)*.5+.5,40.0)*od;
            
            c = mix(noise(p*vec3(.1,0.1,.1)),vec3(.6,.4,.2),.5+noise(p)*.6);
            c = mix(c,texture2D(iChannel1,p.xz*.05).xyz,top);
            c = mix(c,
                    mix(texture2D(iChannel1,p.xz*.75).xyz,texture2D(iChannel1,p.xz*.35).xyz,.5)
                    *vec3(.4,.6,.2),top*c.y);
             
            ao2=min(ao2,1.0);
            #ifdef shading_normal_only
            c=n*.3+vec3(.3);
            #else
            #ifdef shading_light_occlusion_only
            c=vec3(od*.35+.15);
            #else
            #ifdef shading_ambient_occlusion_only
            c=vec3(ao*ao2*.5);
            #else
            c*=ao*ao2*diffuse;
            #endif
            #endif
            #endif
        }
        else
        {
            float dterra = terra(p).x;
            vec3 n = vec3(.0,1.0,.0);//*(sin(dterra*16.0)*.5/(1.0+dterra*4.0)+.5);
            n+=(noise(p.xz*8.0+vec2(1.4,-1.3)*t)-.5)*.3;
            n+=(noise(p.xz*16.0+vec2(-1.8,+1.5)*t)-.5)*.3;
            n+=(noise(p.xz*32.0+vec2(1.7,1.5)*t)-.5)*.3;
            n+=(noise(p.xz*256.0+vec2(-1.1,-1.2)*t)-.5)*.3;
            n=normalize(n);
            
            float diffuse = dot(n,light)*.5+.5; 
            diffuse = diffuse * od; 
            diffuse = diffuse*.7 + .3;
            
            float or = 1.0;
            vec3 odir = reflect(d,n);
            vec3 opos = p+odir;
            
            for (int i=0; i<relection_occlusion_iterations; i++)
            {
                float dd = dist(opos);
                or = min(dd*1.0,or);
                #ifdef high_precision_trace
                opos+=dd*odir*1.0;
                #else
                opos+=dd*odir*8.0;
                #endif
                if (or<.02||opos.y>4.0) break;
            }
            
            or = max(.0,or);
            vec3 water_color = vec3(.1,.4,.3);
            water_color = mix(vec3(.1,.4,.3)*.1,vec3(.3,.4,.4),1.0/(0.7+dterra));
            water_color = mix(water_color,noise(p.xz*.2)*.4,.1);
            
            float specular = dot(reflect(d,n),light)*.5+.5;
            //specular *= 1.0-cloud(reflect(d,n));
            #ifdef shading_normal_only
            c=n*.3+vec3(.3);
            #else
            #ifdef shading_light_occlusion_only
            c=vec3(od*.35+.15);
            #else
            #ifdef shading_ambient_occlusion_only
            c=vec3(ao*ao2*.5);
            #else
            c = (vec3(.0)
                + backdrop(n)*or 
                + water_color*diffuse
                + vec3(pow(specular,4.0)*.3+pow(specular,40.0)*.5+pow(specular,180.0)*1.0)*or
                )*ao*ao2;
                ;
            #endif 
            #endif
            #endif
        }
        //c=vec3(ao*ao2*.2+.4)*(od*.5+.5);
        
    }
    
    c = mix(c,air_color,acc);
    
    float of = 1.0;
    
    {
        vec3 odir = light;
        vec3 opos = start_pos;
                
        for (int i=0; i<flare_occlusion_iterations; i++)
        {
            float dd = dist(opos);
            of = min(dd*6.0+0.2,of);
            #ifdef high_precision_trace
            opos+=dd*odir*1.0;
            #else
            opos+=dd*odir*2.0;
            #endif
            if (of<.02||opos.y>4.0) break;
        }
    }

    of = max(.0,of);
    
    vec3 projected_flare = (-light*inv_rotation);
    if (projected_flare.z>.0)
    c += max(vec3(.0),lensflare(uv*1.2,-projected_flare.xy/projected_flare.z*.6)*projected_flare.z*of);//*(1.0-cloud(light));
    
    //c = vec3(of);
    
    c*=1.0+1.0/(1.0+t*4.0);
    
    c-=length(uv)*.1;
    c+=noise(vec3(uv*iResolution.y,iGlobalTime*60.0))*0.02;
    c=mix(c,vec3(length(c)),length(c)*2.0-1.0);
    c = max(vec3(.0),c);

    c = pow(c,vec3(1.0/1.8));

    #if defined( TONE_MAPPING ) 
    c = toneMapping( c ); 
    #endif
    
    gl_FragColor = vec4(c,1.0);
    
}