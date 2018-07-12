// ------------------ channel define
// V_# homewardV #_V
// 0_# bufferFULL_homewardA #_0
// 1_# bufferFULL_homewardB #_1
// 2_# tex06 #_2
// 3_# noise #_3
// ------------------


/*#define CAMERA_POS      0
#define CAMERA_TAR      1
#define SUN_DIRECTION   2
#define CROW_POS        3
#define CROW_HEADING    4
#define CROW_FLAPPING   5
#define CROW_HEADTILT   6
#define CROW_TURN       7
#define CROW_CLIMBING   8

#define FAR 850.

#define TAU 6.28318530718
#define SUN_COLOUR vec3(1.1, .95, .85)
#define FOG_COLOUR vec3(.48, .49, .53)

vec3 sunLight, crowPos;

//----------------------------------------------------------------------------------------

vec3 cameraPath( float z )
{
    return vec3(100.2*sin(z * .0045)+90.*cos(z *.012), 43.*(cos(z * .0047)+sin(z*.0013)) + 53.*(sin(z*0.0112)), z);
}
// Set up a camera matrix

//--------------------------------------------------------------------------
mat3 setCamMat( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}
#define HASHSCALE1 .1031

float hash11(float p)
{
    vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}*/


// https://www.shadertoy.com/view/Xllfzl


// Homeward
// by David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Music:-
// World OP by PeriTune | http://peritune.com
// Music promoted by https://www.free-stock-music.com
// Creative Commons Attribution 3.0 Unported License
// https://creativecommons.org/licenses/...

// Do the crow in this buffer...



#define PI acos(-1.)

mat3 crowDir;
vec4 flapping, headTilt;
float turn, specular;

//----------------------------------------------------------------------------------------
vec4 getStore(int num)
{
    //ivec2 loc = ivec2(num & 63, num/64); // Didn't need that many, doh!
    ivec2 loc = ivec2(num, 0);
    return  texelFetch(iChannel0, loc, 0);
}


//----------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------
float noise( in float p  )
{
    
    float f = fract(p);
    p = floor(p);
	f = f*f*(3.0-2.0*f);
	return mix(hash11(p),hash11(p+1.), f);
}

//----------------------------------------------------------------------------------------
float sMin( float a, float b, float k )
{
    
	float h = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.-h);
}
//----------------------------------------------------------------------------------------
mat2 rot2D(float a)
{
	float si = sin(a);
	float co = cos(a);
	return mat2(co, si, -si, co);
}

//----------------------------------------------------------------------------------------
float  sphere( vec3 p, float s )
{
    return length(p)-s;
}

//----------------------------------------------------------------------------------------
float featherBox( vec3 p, vec3 b, float r )
{
    b.y-= smoothstep(3.75, -4.0, p.z)*noise(p.x*6.)*.56;

    p.y+=  smoothstep(1.5, .0, p.z)*noise(p.x*3.+crowPos.z*1.)*.35;
    return length(max(abs(p)-b,0.0))-r;
}

//----------------------------------------------------------------------------------------
float featherTailBox( vec3 p, vec3 b, float r )
{
    //b.x /= smoothstep(-10.,4.,p.z);
    p.x *= clamp((p.z+4.)/6., 0.1,2.5);
    b.y-= smoothstep(.75, .0, p.z)*noise(p.x*3.)*.3;
    
    p.y+=  smoothstep(1., -4.0, p.z)*noise(p.x*3.+crowPos.z*1.)*.5;
    return length(max(abs(p)-b,0.0))-r;
}

//----------------------------------------------------------------------------------------
float segment(vec3 p,  vec3 a, vec3 b, float r1, float r2)
{
	vec3 pa = p - a;
	vec3 ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r1 + r2*h;
}


//--------------------------------------------------------------------------
float noise( in vec3 p )
{
    vec3 f = fract(p);
    p = floor(p);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel3, (uv+ 0.5)/256.0, 0.0).yx;
	return mix( rg.x, rg.y, f.z );
}

//----------------------------------------------------------------------------------------
vec3 getSky(vec3 dir, vec3 pos)
{
    vec3 col;
    vec3 clou = dir * 1. + pos*.025;
	float t = noise(clou);
    t += noise(clou * 2.1) * .5;
    t += noise(clou * 4.3) * .25;
    t += noise(clou * 7.9) * .125;
	col = mix(vec3(FOG_COLOUR), vec3(0.2, 0.2,.2),abs(dir.y))+ FOG_COLOUR *t*.4;
 
    return col;
}

//----------------------------------------------------------------------------------------
// Map a crow like asbtract bird thing...
float map(vec3 p, float t)
{
    float d, f;
    specular = .1;
    // Normalize rotation...
    vec3 q = crowDir*(p-crowPos);
    // Head...
    vec3 b = q- vec3(.0, 0, 2.8);
    b.yz = b.yz*rot2D(headTilt.x);
    b.xz = b.xz*rot2D(headTilt.y);
    d = segment(b,vec3(0,0,1), vec3(0,0,5.), 1.2, 3.); 

    // Body...
    b = q+vec3(0,1.,3);
  	d = sMin(d, segment(q, vec3(0), vec3(0,0,-14), 1.3, 11.5), 3.); 
    // Tail...
    b.xy = b.xy* rot2D(headTilt.w);
    d = sMin(d, featherTailBox(b, vec3(headTilt.z,.1,2.2), .3),4.3); 
    // Left wing...
    b = q + vec3(2.8,0,0);
    b.xy = rot2D(flapping.x)*b.xy;
    d = sMin(d, featherBox(b+(vec3(4,0,1.)), vec3(4,.05,2.5),.4), 2.);
    
    b =  b + vec3(8,0,0);
    b.xy = rot2D(flapping.y*1.5)*b.xy;
	f = featherBox(b+vec3(4,0,0), vec3(4,.05,3.5),.4);
    f = max(f, sphere(b+vec3(2,0,3), 5.));
    d = sMin(d, f, .1);
    
    // Right wing...
    b = q - vec3(2.8,0,0);
    b.xy = rot2D(-flapping.z)*b.xy;
    d = sMin(d, featherBox(b-(vec3(4,0,-1.)), vec3(4,.05,2.5),.4), 2.);
    
    
    b =  b - vec3(8,0,0);
    b.xy = rot2D(-flapping.w*1.5)*b.xy;
    f = featherBox(b-vec3(4,0,0), vec3(4,.05,3.5),.4);
    f = max(f, sphere(b-vec3(2,0,-3), 5.));
    d = sMin(d, f, .1);

    // Do some glassy eyes...
    b = q- vec3(.0, .0, 2.85);
    
    b.yz = b.yz*rot2D(headTilt.x);
    b.xz = b.xz*rot2D(headTilt.y);
	b.x = abs(b.x);

    f = sphere(b-vec3(.7,0.1,1.4), .25);
    if (f < d){ d = f; specular = 4.0;}

    
    return d;
}
//----------------------------------------------------------------------------------------
vec3 getNormal(vec3 p, float e)
{
    return normalize( vec3( map(p+vec3(e,0.0,0.0), e) - map(p-vec3(e,0.0,0.0), e),
                            map(p+vec3(0.0,e,0.0), e) - map(p-vec3(0.0,e,0.0), e),
                            map(p+vec3(0.0,0.0,e), e) - map(p-vec3(0.0,0.0,e), e) ) );
}

//----------------------------------------------------------------------------------------
vec3 lighting(in vec3 pos, in vec3 normal, in vec3 eyeDir, in float d)
{
	;
   	normal = reflect(eyeDir, normal); // Specular...
    vec3 col = pow(max(dot(sunLight, normal), 0.0), 10.0)  * SUN_COLOUR * specular;


	return min(col, 1.0);
}


//--------------------------------------------------------------------------
float marchScene(in vec3 rO, in vec3 rD, vec2 co, float t)
{
	t += .5*hash12(co);

    
    for( int j=0; j < 30; j++ )
	{
		if (t >= FAR) break;
		float h = map( rO + t*rD, t*0.012);
 		if(h < 0.03)
		{
  
            break;
	     }

        t += h + t*.005;
	}


    return t;
}


vec3 lenseFlare(vec2 uv,vec3 dir, mat3 camMat)
{

    vec3 col = vec3(0);
    float bri = dot(dir, sunLight)*.7;
	if (bri > 0.0)
	{
		vec2 sunPos = vec2(dot( sunLight, camMat[0] ),dot( sunLight, camMat[1] ) );
        //sunPos = clamp(sunPos,-.5,.5);
        //sunPos *= vec2(iResolution.y/iResolution.x, 1.);
	    float z = textureLod(iChannel1,(sunPos+1.)*.5, 0.).w;
       	vec2 uvT = uv-sunPos;
        if (z >= FAR)
        {
            uvT = uvT*(length(uvT));
            bri = pow(bri, 6.0)*.7;

            // glare = the red shifted blob...
            float glare1 = max(dot(dir,sunLight),0.0)*1.4;
            // glare2 is the yellow ring...
            float glare2 = max(1.-length(uvT+sunPos*.4)*4.0, 0.0);
            uvT = mix (uvT, uv, -2.3);
            // glare3 is a splodge...
            float glare3 = max(1.-pow(length(uvT+sunPos*2.5)*3., 2.), 0.0);

            col += bri * vec3(1.0, .0, .0)  * pow(glare1, 12.5)*.05;
            col += bri * vec3(1.0, 1.0, .1) * pow(glare2, 2.0)*2.5;
            col += bri * SUN_COLOUR * pow(glare3, 3.)*3.0;
        }
	}
    return col;
}


//----------------------------------------------------------------------------------------
void mainImage( out vec4 colOut, in vec2 fragCoord )
{
    
    vec2 uv = (-iResolution.xy + 2.0 * fragCoord ) / iResolution.y;

  	vec3 col;

    sunLight 	= getStore(SUN_DIRECTION).xyz;
    vec3 camPos = getStore(CAMERA_POS).xyz;
    vec3 camTar = getStore(CAMERA_TAR).xyz;
    crowPos  	= getStore(CROW_POS).xyz;
    vec3 crowTar= getStore(CROW_HEADING).xyz;
    flapping	= getStore(CROW_FLAPPING);
    headTilt	= getStore(CROW_HEADTILT);
    turn  		= getStore(CROW_TURN).x;
    crowDir		= setCamMat(crowPos, crowTar, turn);
    crowDir 	= inverse(crowDir);
	mat3 camMat = setCamMat(camPos, camTar, (camTar.x-camPos.x)*.02);
    vec3 dir 	= camMat * normalize( vec3(uv, cos((length(uv*.5)))));


	
    colOut = texelFetch(iChannel1, ivec2(fragCoord), 0);
    float t = max(length(camPos-crowTar)-25., .0);
    float far = t+30.0;
    float dhit = marchScene(camPos, dir, fragCoord, t);
  
    if (dhit < far && dhit < colOut.w)
    {
      	
       	vec3  p = camPos+dhit*dir; 
        vec3 sky = getSky(dir, p);
       	vec3 nor =  getNormal(p, dhit*.003);
   		col = lighting(p,nor, dir, dhit);
        col = mix(sky, col.xyz , exp(-dhit*.0015)-.1);
    }else
    	col = texelFetch(iChannel1, ivec2(fragCoord), 0).xyz;
    
    
    col += lenseFlare(uv, dir, camMat);
    col = clamp(col, 0.0, 1.0);

	// Contrast & stretch...

    col = pow( col, vec3(1.7,1.95,2.) )*1.8;
    col = clamp(col, 0., 1.0);
	col = col*.2 + (col*col*(3.0-2.0*col))*.8;
 
    // Gamma...
    col = min(sqrt(col), 1.0);


    // Vignette...
    vec2 xy = abs((fragCoord.xy / iResolution.xy)-.5);
    col *= pow(abs(250.0* (.5-xy.y))*(.5-xy.x), .2 )*.7;
	colOut = vec4(col*smoothstep(.0, 2.,iTime), 1.0);
}