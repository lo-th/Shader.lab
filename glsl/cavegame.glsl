
// ------------------ channel define
// 0_# noise #_0
// -----------------

// https://www.shadertoy.com/view/MsXXRr

const float sensivity = .025;
const float speed     = 1.5;

float noise3f( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = texture2D( iChannel0, (uv+0.5)/256.0, -16.0 ).yx;
    return mix( rg.x, rg.y, f.z )*2.-1.;
}

float scene(vec3 p)
{
    return max( .4+noise3f(p*.7)*.5+noise3f(p*2.)*.1-abs(p.y), p.z+5.); //
}

vec3 raymarche(vec3 org, vec3 dir)
{
    vec3 p=org;
    float d=1.;
    for(int i=0; i<64; i++)
    {
        if(d>0.01)
        {
            d = scene(p);
            p += d * dir;
        }
    }
    return p;
}
vec3 raymarcheSmall(vec3 org, vec3 dir)
{
    vec3 p=org;
    float d=1.;
    for(int i=0; i<16; i++)
    {
        if(d>0.01)
        {
            d = .4+noise3f(p*.7)*.5-abs(p.y);
            p += d * dir;
        }
    }
    return p;
}

vec3 getNormal(vec3 p)
{
    vec3 eps = vec3(0.01,0.0,0.0);
    return normalize(vec3(
    scene(p+eps.xyy)-scene(p-eps.xyy),
    scene(p+eps.yxy)-scene(p-eps.yxy),
    scene(p+eps.yyx)-scene(p-eps.yyx)
    ));
}
float getAO(vec3 p, vec3 n, vec2 a)
{
    float dlt = a.x;
    float oc = 0.0, d = a.y;
    for(int i = 0; i<6; i++)
    {
        oc += (float(i) * dlt - scene(p + n * float(i) * dlt)) / d;
        d *= 2.0;
    }
    return clamp(1.0 - oc, 0.0, 1.0);
}

vec4 getColor(vec3 p, vec3 n, vec3 org, vec3 dir)
{
    vec3 lightdir = normalize(vec3(1.0,0.0,-1.0));  
    
    float diffuse = max( dot(n,lightdir), 0.0)*.5+.5;
    float ao = getAO(p,dir,vec2(1.0,2.5));
    
    vec4 color =  vec4(0.5,1.0,0.5,1.);
    if(p.y>0.)
        color = mix(vec4(.5,.7,1.,1.),vec4(.2,.7,.2,1.)*2., noise3f(p)*.5+.5);
    else
        color =  mix(vec4(.5,.7,1.,1.),vec4(1.5), ao);
    color *= diffuse  * ao ;    
    color = mix(color, vec4(1.), min(distance(p,org)*0.05,1.0)); //Fog
    
    return color*color*4.;
}

void main(){

    //vec2 v = -1.0 + 2.0 * gl_FragCoord.xy / iResolution.xy;
    //v.x *= iResolution.x/iResolution.y; 

    vec2 v = ((vUv * 2.0) - 1.0) * vec2(iResolution.z, 1.0);
    
    vec3 org = raymarcheSmall(vec3(iMouse.x*sensivity,0.,-pow(iGlobalTime,speed)),vec3(.0,-1.,.0))+vec3(.0,.15,.0);
    vec3 dir = normalize(vec3(v.x*1.6,v.y,-.9-1./pow(iGlobalTime,speed)));
    vec4 color=vec4(0.,1.,0.,1.);
    vec3 p = raymarche(org,dir);
    color = getColor(p,getNormal(p),org,dir);
        
    vec3 refdir = reflect(dir,getNormal(p));
    p = raymarcheSmall(p+refdir,refdir);
    color = mix( color, getColor(p,getNormal(p),org,dir), .15 );

    // tone mapping
    color.rgb = toneMap( color.rgb );
    //Fail ? red screen !
    if(scene(org)<.0)  color = vec4(1.,.0,.0,1.);

    gl_FragColor = color;

}



