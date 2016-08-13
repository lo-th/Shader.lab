
// ------------------ channel define
// 0_# grey1 #_0
// 1_# bump #_1
// ------------------


// Created by Stephane Cuillerdier - Aiekick/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// https://www.shadertoy.com/view/ltS3Wm

const int REFLEXIONS_STEP = 1; // count iteration for reflexion ( my refraction system seems to be wrong )

const vec2 RMPrec = vec2(0.5, 0.1); // ray marching tolerance precision // low, high
const vec2 DPrec = vec2(0.00001, 50.); // ray marching distance precision // low, high
    
float sphereThick = 0.02; // thick of sphere plates
float texDisplace = 0.25; // displace factor for texture
float texZoom = 4.; // zoom of texture
float boxThick = 0.3; // thick of each boxs
float boxCornerRadius = 0.03; // corner radius of each boxs
float baseRep = 0.63; // base thick for mod repeat pattern // must be > to boxThick*2.
float evoRep = 0.15; // evo thick factor mult to time and added to baseRep for animation
float sphereRadius = 6.; // radius of sphere before tex displace

float pSphere(vec3 p){return length(p)-boxThick;}
float pBox(vec3 p) {return length(max(abs(p)-vec3(boxThick),0.0))-boxCornerRadius;}
float pTorus(vec3 p, vec2 t) {return length(vec2(length(p.xz)-t.x,p.y))-t.y;}

float norPrec = 0.01; // normal precision 

const int RMStep = 150; // Ray Marching Iterations

#define mPi 3.14159
#define m2Pi 6.28318

vec2 uvMap(vec3 p)
{
    p = normalize(p);
    vec2 tex2DToSphere3D;
    tex2DToSphere3D.x = 0.5 + atan(p.y, p.x) / m2Pi;
    tex2DToSphere3D.y = 0.5 - asin(p.z) / mPi;
    return tex2DToSphere3D;
}

vec4 ExternalShape(vec3 p)
{
    // tex displace
    vec3 tex = texture2D(iChannel1, uvMap(p*texZoom)).rgb;
    float disp = dot(tex, vec3(texDisplace));
    disp = smoothstep(0., 1., disp);
    
    //sphere
    float sphereOut = length(p) -sphereRadius - disp;
    float sphereIn = sphereOut + sphereThick;
    float sphere = max(-sphereIn, sphereOut);
   
    return vec4(sphere, tex); // dist, color
}

vec4 InternalShape(vec3 p)
{
    // morphing time
    float t = sin(iGlobalTime*2.)*.5+1.;
    
    // shape set
    float sphereSet = pSphere(p); // sphere
    float cubeSet = pBox(p); // cube
    float primitiveSet = mix(sphereSet, cubeSet, t); // morphing sphere and cube
    
    return vec4(primitiveSet, vec3(0.8,0.5,0.2)); // dist, color
}

vec4 map(vec3 p)
{
    // time
    float t = sin(iGlobalTime*.5)*.5+.5;
    
    // external shape
    vec4 extShape = ExternalShape(p);
    
    // rep with mod
    vec3 rep = vec3(baseRep + evoRep*t);
    p = mod(p, rep) - rep/2.;
    
    // internal sahpe
    vec4 intShapeSet = InternalShape(p);
    
    // intersection
    float inter = max(extShape.x, intShapeSet.x);
    
    // col
    vec4 c = vec4(inter, intShapeSet.yzw);
       
    return c;
}

vec3 nor( in vec3 p, float prec)
{
    vec2 e = vec2( prec, 0.);
    vec3 n = vec3(
        map(p+e.xyy).x - map(p-e.xyy).x,
        map(p+e.yxy).x - map(p-e.yxy).x,
        map(p+e.yyx).x - map(p-e.yyx).x );
    return normalize(n);
}

// from iq
float calcAO( in vec3 pos, in vec3 nor)
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}


void main(){

    float t = iGlobalTime*0.2;
    float cam_a = t; // angle z
    
    float cam_e = 8.5; // elevation
    float cam_d = 3.5; // distance to origin axis
    
    vec3 camUp=vec3(0,1,0);//Change camere up vector here
    vec3 camView=vec3(0,0,0); //Change camere view here
    float li = 0.55; // light intensity
    float refl_i = .6; // reflexion intensity
    float refr_i = .6; // reflexion intensity
    float refr_a = .8; // reflexion intensity
    float bii = 0.35; // bright init intensity
    
    /////////////////////////////////////////////////////////
    if ( iMouse.z>0.) cam_e = iMouse.x/iResolution.x * 10.; // mouse x axis 
    if ( iMouse.z>0.) cam_d = iMouse.y/iResolution.y * 50.; // mouse y axis 
    /////////////////////////////////////////////////////////
    
    vec2 scr = iResolution.xy;
    //vec2 uv = (2.* gl_FragCoord.xy - scr)/scr.y;
    vec2 uv = ((vUv * 2.0) - 1.0) * vec2(iResolution.z, 1.0);
    
    vec3 col = vec3(0.);
    
    vec3 ro = vec3(-sin(cam_a)*cam_d, cam_e+1., cos(cam_a)*cam_d); //
    vec3 rov = normalize(camView-ro);
    vec3 u = normalize(cross(camUp,rov));
    vec3 v = cross(rov,u);
    vec3 rd = normalize(rov + uv.x*u + uv.y*v);
    
    float b = bii;
    
    float d = 0.;
    vec3 p = ro+rd*d;
    float s = DPrec.x;
    
    vec3 ray, cubeRay;
    
    for(int k=0;k<REFLEXIONS_STEP;k++)
    {
        for(int i=0;i<RMStep;i++)
        {      
            if(s<DPrec.x||s>DPrec.y) break;
            s = map(p).x*(s>DPrec.x?RMPrec.x:RMPrec.y);
            d += s;
            p = ro+rd*d;
        }

        if (d<DPrec.y)
        {
            vec3 n = nor(p, norPrec);

            b=li;

            ray = reflect(rd, n);
            cubeRay = textureCube(iChannel0, ray).rgb  * refl_i ;

            ray = refract(ray, n, refr_a);
            cubeRay += textureCube(iChannel0, ray).rgb  * refr_i ;

            float ratio = float(k)/float(REFLEXIONS_STEP);
            
            if ( k == 0 ) 
                col = cubeRay+pow(b,15.); 
            else 
                col = mix(col, cubeRay+pow(b,25./ratio), ratio*0.8);  
            
            // lighting        
            float occ = calcAO( p, n);
            vec3  lig = normalize( vec3(-0.6, 0.7, -0.5) );
            float amb = clamp( 0.5+0.5*n.y, 0.0, 1.0 );
            float dif = clamp( dot( n, lig ), 0.0, 1.0 );
            float bac = clamp( dot( n, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-p.y,0.0,1.0);
            float dom = smoothstep( -0.1, 0.1, cubeRay.y );
            float fre = pow( clamp(1.0+dot(n,rd),0.0,1.0), 2.0 );
            float spe = pow(clamp( dot( cubeRay, lig ), 0.0, 1.0 ),16.0);

            vec3 brdf = vec3(0.0);
            brdf += 1.0*dif*vec3(1.00,0.90,0.60);
            brdf += 1.20*spe*vec3(1.00,0.90,0.60)*dif;
            brdf += 0.30*amb*vec3(0.50,0.70,1.00)*occ;
            brdf += 0.40*dom*vec3(0.50,0.70,1.00)*occ;
            brdf += 0.30*bac*vec3(0.25,0.25,0.25)*occ;
            brdf += 0.40*fre*vec3(1.00,1.00,1.00)*occ;
            brdf += 0.02;
            col = col*brdf;

            col = mix( col, vec3(0.8,0.9,1.0), 1.0-exp( -0.0005*d*d ) );

            col = mix(col, map(p).yzw, 0.5);
            
            ro = p;
            rd = ray;
            s = DPrec.x;
        }
        else if (k == 0)
        {
            col = textureCube(iChannel0, rd).rgb;
        }
    }

    // tone mapping
    #if defined( TONE_MAPPING ) 
    col = toneMapping( col ); 
    #endif

    gl_FragColor = vec4(col, 1.0);
}