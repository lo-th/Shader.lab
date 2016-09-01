//Fast Edge detection by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/4s2XRd

#define EDGE_SIZE 0.07
#define SMOOTH 0.025

#define ITR 80
#define FAR 40.
#define time iGlobalTime
float hash( float n ) { return fract(sin(n)*43758.5453); }

vec3 rotx(vec3 p, float a)
{
    float s = sin(a), c = cos(a);
    return vec3(p.x, c*p.y - s*p.z, s*p.y + c*p.z);
}
vec3 roty(vec3 p, float a)
{
    float s = sin(a), c = cos(a);
    return vec3(c*p.x + s*p.z, p.y, -s*p.x + c*p.z);
}

vec2 map(vec3 p)
{
    vec3 id = floor( (p+3.)/6.0);
    p = mod( p+3., 6.0 ) - 3.;
    float rid = hash(dot(id,vec3(7.,43,113)));
    p = rotx(p,time*.5+rid+sin(rid*5.+time));
    p = roty(p,time*0.5+rid*1.1);
    
    float d = mix((max(abs(p.x),max(abs(p.y),abs(p.z)))-0.5),max(length(p)-1.,-(length(p)-0.4)),rid);
    return vec2(d*.85,rid);
}


/*  
    Keeping track of min distance, then, when the min distance 
    is both under a given threshold and starts increasing (meaning that
    a fold was just passed) then I mark that pixel as an edge. The min
    distance can then be smoothed allowing for arbitrarily smooth edges.
*/
vec4 march(in vec3 ro, in vec3 rd)
{
    float precis = 0.001;
    float h=precis*2.0;
    vec2 d = vec2(0.,10000.);
    float md = 1.;
    float id = 0.;;
    bool stp = false;
    for( int i=0; i<ITR; i++ )
    {
        if( abs(h)<precis || d.x>=FAR ) break;
        d.x += h;
        vec2 res = map(ro+rd*d.x);
        if (!stp) 
        {
            md = min(md,res.x);
            if (h < EDGE_SIZE && h < res.x && i>0)
            {
                stp = true;
                d.y = d.x;
            }
        }
        h = res.x;
        id = res.y;
    }
    
    if (stp) md = smoothstep(EDGE_SIZE-SMOOTH, EDGE_SIZE+0.01, md);
    else md = 1.;
    return vec4(d, md, id);
}

vec3 normal(in vec3 p, in float d)
{  
    vec2 e = vec2(-1., 1.)*0.003*d;
    return normalize(e.yxx*map(p + e.yxx).x + e.xxy*map(p + e.xxy).x +
                     e.xyx*map(p + e.xyx).x + e.yyy*map(p + e.yyy).x );   
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    vec2 q = fragCoord.xy/iResolution.xy;
    vec2 p = -1.0 + 2.0*q;
    p.x*=iResolution.x/iResolution.y;
    vec2 mo = iMouse.xy/iResolution.xy*2.-1.;
    mo = (mo==vec2(-1.))?mo=vec2(0.):mo;
    mo.x *= iResolution.x/iResolution.y;
    
    //camera
    vec3 ro = vec3(4.1,-time*2.,time-0.5);
    vec3 rd = normalize(vec3(p,2.5));
    rd = roty(rd,sin(time*0.2)*0.5+0.9+mo.x);
    rd = rotx(rd,sin(time*0.12+sin(time*.5)*1.)+0.9);
    
    vec4 rz = march(ro,rd);
    vec3 ligt = normalize( vec3(-.5, 0.2, -0.2) );
    float sun = dot(rd,ligt);
    vec3 bg = vec3(0.5,0.6,.9)*sun*0.5+0.6;
    vec3 col = bg;
    
    if ( rz.x < FAR )
    {
        vec3 pos = ro+rz.x*rd;
        float d = distance(ro,pos);
        vec3 nor= normal(pos,d);
        vec3 h = normalize(ligt - rd);
        col = sqrt(col);
        col = mix(sin(vec3(1,2,3)*rz.w*1.9)*0.5+0.35,col,0.2);
        
        float dif = clamp( dot(nor, ligt), 0., 1.);
        float spe = pow(clamp(dot(nor,h), 0., 1.),70.);
        float fre = 0.1*pow(clamp(1. + dot(nor, rd), 0., 1.), 2.);
        vec3 brdf = 1.5*vec3(.10, .11, .11);
        brdf += 1.30*dif*vec3(1., .9, .75);
        col = col*brdf + col*spe + fre*col;
    }
    
    col  = mix(col,bg,smoothstep(30.,40.,rz.x)); //Distance fog
    col *= mix(rz.z,1.,smoothstep(30.,40.,rz.y)); //Edges + Fog (using edge-eye distance)
    
    col = pow(col, vec3(.8))*1.;
    //vignetting from iq
    col *= 0.4 + 0.6*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.2 );
    
    fragColor = vec4( col, 1.0 );
}