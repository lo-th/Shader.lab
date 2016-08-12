void pR(inout vec2 p,float a)
{
    p=cos(a)*p+sin(a)*vec2(p.y,-p.x);
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}


// 3D voronoi https://www.shadertoy.com/view/ldl3Dl
vec3 hash( vec3 x )
{
    return texture2D( iChannel0, (x.xy+vec2(3.0,1.0)*x.z+0.5)/64.0, -1000. ).xyz;
}

vec2 hash2d( vec2 x )
{
    return texture2D( iChannel0, (x.xy)/64.0, -1000. ).xy;
}

vec3 voronoi( in vec3 x )
{
    vec3 p = floor( x );
    vec3 f = fract( x );

    //float id = 0.0;
    vec2 res = vec2( 100.0 );
    for( int k=-1; k<=1; k++ )
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec3 b = vec3( float(i), float(j), float(k) );
        vec3 r = vec3( b ) - f + hash( p + b );
        float d = dot( r, r );

        if( d < res.x )
        {
            //id = dot( p+b, vec3(1.0,57.0,113.0 ) );
            res = vec2( d, res.x );         
        }
        else if( d < res.y )
        {
            res.y = d;
        }
    }

    return vec3(  res , 0.0 );//abs(id)
}
// Gradient noise https://www.shadertoy.com/view/XdXGW8
float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash2d( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( hash2d( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash2d( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( hash2d( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}


float heightmap(vec2 p)
{
    float o = texture2D(iChannel1,(p)*0.0036,-100.0).x;
    return 1.-o;
}

float bump(vec2 p)
{
    mat2 mat = mat2(vec2(-0.95765948032,-0.28790331666), vec2(0.28790331666,-0.95765948032));
    float o = texture2D(iChannel1,(p * mat)*0.17,-100.0).x;
    return o;
}

vec4 scene(vec3 point)
{
    float v = 1. - texture2D(iChannel1, point.xz * 0.02).r;// voronoi(point * 0.2).x;
    float h1 = bump(point.xz);
    float h2 = heightmap(point.xz);
    float valley = pow((min(abs(sin(point.z* 0.03)*0.38 + point.x * 0.08) *0.6,1.)),1.0 + v * 3.2);
    float d = 1. + point.y + (mix(h1 * 0.3, (1.-h1) * 0.9 ,clamp(-0.3+v,0.0,1.0))) - (-3.+h2 * 8.) * valley;
    d = min(d-v*3.2 * valley,d) ;
   
    
    //d = min(d, sdSphere(p2 - vec3(10.),10.0));
    
    return vec4(d,v,h1,h2);
}

float sky(vec3 point)
{
    //vec3 p2;
    //const float cldspacing = 80.;
    //vec2 clsftuv = vec2(ceil(point.x/cldspacing)/64.,ceil(point.y/cldspacing)/64.);
    //vec2 clsft = vec2(texture2D(iChannel0,clsftuv).r,texture2D(iChannel0,clsftuv.yx).r);
    //p2.xz = mod(point.xz, cldspacing);
    //p2.y = point.y - 20.;
    //float d = sdSphere(p2 - vec3(cldspacing/2.,0.,cldspacing/2.),15.0);   
    
    
    //vec3 vrn = voronoi(point * 0.25);
    vec3 vrn2 = voronoi(point * 0.02);// + vec3(iGlobalTime * 0.01,iGlobalTime * 0.003,0.));
    //float v3 =  voronoi(point * 0.6).x;
    float v2 = 0.6 - vrn2.x * (1.5 - vrn2.y );
    float v =  voronoi(point * 0.25).x;// vrn.x;// * (1.4 - vrn.y);
    //v2 = texture2D(iChannel0, point.xz * 0.001 + vec2(iGlobalTime * 0.001)).r;
    float cld = max(8. - v2 * 9.8,0.);
    float d = sdSphere(vec3(cld,point.y - 26., cld),6.0);      
    v = -0.3 + v* 2.1 ;
    d += v;// + v3 * 1.4;
    
    return d;
}



vec3 calcNormal( in vec3 pos )
{
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 nor = vec3(
        scene(pos+eps.xyy).x - scene(pos-eps.xyy).x,
        scene(pos+eps.yxy).x - scene(pos-eps.yxy).x,
        scene(pos+eps.yyx).x - scene(pos-eps.yyx).x );
    return normalize(nor);
}

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = scene( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );

}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(){

    vec2 uv = gl_FragCoord.xy / iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    const vec3 SKY_COL = vec3(0.6,0.89,0.98);
    const vec3 SUN_COL = vec3(1.0,0.98,0.87);
    vec3 suncol = vec3(0.7031,0.4687,0.1055);
    
  
    const int RAY_STEPS = 256;
    const float NEAR_CLIP = .5;
    const float FAR_CLIP = 800.0;
    
    const int SKY_STEPS = 96;
    const float SKY_NEAR_CLIP = 20.;
    
    vec3 normal;
    vec3 intersection; 
    vec3 origin = vec3(0.0, -0.2 + 0.3 * sin(iGlobalTime * 2.), -1000.0 + iGlobalTime * 15.);
    vec3 direction;// = vec3(0.0, 0, 1.0);
    vec2 ml = vec2(0.);
    if (iMouse.x>10.)
    {
        ml.x = 2.5 - iMouse.x/iResolution.x * 5.;
        ml.y = -2.5 + iMouse.y/iResolution.y * 5.;
    }
    // camera   
    vec3 ro = origin;
    vec3 ta = origin + vec3( sin(iGlobalTime * 0.2)+ml.x,ml.y , 2. );
    
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );
    
    // ray direction
    direction = ca * normalize( vec3(uv.xy,2.0) );
   
    float distance = 0.;
    float totalDistance = NEAR_CLIP;
    float skyDistance = SKY_NEAR_CLIP;
    
    float spec =0.;
    float shadow =0.;
    float diff = 1.;
    float fog = 0.;
    float amb=0.;
    
    vec3 lig  = normalize(vec3(-0.3,0.3,0.6));//iMouse.x/iResolution.x,iMouse.y/iResolution.y
    vec3 texs;
    
    vec3 Col = vec3(4.0);
    for(int i =0 ;  i < RAY_STEPS; ++i) ////// Rendering main scene
    {
        intersection = origin + direction * totalDistance;
        vec4 s = scene(intersection);
        distance = s.r;
        texs = s.gba;
        totalDistance += distance;
                     
        if(distance <= 0.002 || totalDistance >= FAR_CLIP)
        {
            //Col = vec3(0.,1.,0.);
            break;
        }
    }
    if (totalDistance >= FAR_CLIP)
    {   
     
        //float myst = 0.0;
        for(int i =0 ;  i < SKY_STEPS; ++i)    ////////////// Rendering clouds
        {
            intersection = origin + direction * skyDistance;
            distance = sky(intersection);
            skyDistance += distance;
           
            //myst += max(1.2-distance,0.);
            if(distance <= 0.02 || skyDistance >= FAR_CLIP)
            {
                //Col = vec3(0.,1.,0.);
               break;
            }
        }
        float occl = 0.0;
        for(int i =0 ;  i < 4; ++i)
        {
            float d = sky(intersection + vec3(0.,-2. + 4.7 * float(i),0.));
            occl += d * 0.067;
        }
        occl = clamp(occl,0.1,2.0);
        float sunlight = 0.0;
        
        for(int i =0 ;  i < 4; ++i)
        {
            float d = sky(intersection +(1.3 * lig + lig) * 3.2 * float(i));
            sunlight += d * 0.037;
        }
        sunlight = max(sunlight,0.);
        //myst = clamp(1.0 - myst,0.,1.);
        Col = vec3(0.6,0.89,0.98) * occl + SUN_COL * sunlight * 4.;// +vec3(myst);
        fog = max((1.-(skyDistance / FAR_CLIP)), 0.);
        //Col = vec3(myst);
        //fog = 1.0;
       
    } else {
        
        float rock = clamp( texs.b * 2. - texs.g * 1. * (3.-intersection.y) * (0.3+texs.r) ,0. ,1.);
        float nstx = texture2D(iChannel0, intersection.xz).r;
        Col = mix(vec3(0.27,0.35,0.15) * (0.2 + pow(texs.g + texs.g * (-0.3 + nstx),2.2)), vec3(0.86,0.48,0.32) * (0.2 + pow(texs.g,0.6)), rock); //clamp(intersection.y,0.,1.)
        normal = calcNormal(intersection);

        diff = clamp(dot(normal , lig),0.,1.);
        shadow = softshadow( intersection, lig, 0.02, 2.5 ) * max(2. -texture2D(iChannel0, intersection.xz * 0.001+vec2(iGlobalTime * 0.001)).r * 3.1,0.);
        diff *= shadow;
        amb = 0.24 * normal.y;
        float dotrflct = dot(reflect( direction, normal ), lig );
        spec = shadow * (rock + ((1.-rock) * pow(nstx,4.0) * 2.) ) * pow(clamp(dotrflct, 0.0, 1.0 ),26.0);
        
        float depth = ((totalDistance / FAR_CLIP));
        fog = clamp(exp((intersection.y*0.3 - 1.3)*depth+0.24) * (1.-exp(depth*1.9-1.9)) ,0.,1.);//
        //fog = 1.0;
    }
    
   float horizon = abs(direction.y);
   float sun = max(1.0 - (1.0 + 10.0 * lig.y + horizon) * length(direction - lig),0.0)
        + 0.3 * pow(1.0-horizon,18.0) * (1.3-lig.y);
    
   vec3 chroma = vec3(mix(SKY_COL, suncol,clamp(sun,0.,1. ) * 0.85)) + vec3(0.06,0.06,0.06); 
    
   float luma = ((0.5 + 1.0 * pow(lig.y,0.4)) * (1.5-horizon) + pow(sun, 2.2) * lig.y * (5.0 + 15.0 * lig.y));
   
   float exposure = 2.3;
    
   vec3 fogCol =  chroma * luma * exposure;
    
    vec3 Final = mix(fogCol,Col * diff *SUN_COL*2.0 + spec* SUN_COL * 1.6 + Col * amb * SKY_COL, fog);
    gl_FragColor = vec4(Final ,totalDistance);
    //gl_FragColor = vec4(direction,0.);
    //gl_FragColor = vec4();
}