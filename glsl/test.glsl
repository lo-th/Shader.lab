
// ------------------ channel define
// 0_# noise #_0
// ------------------


// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


// Analytical ambient occlusion of a sphere. Left side of screen, stochastically 
// sampled occlusion. Right side of the screen, analytical solution (no rays casted).
//
// When the sphere is fully visible to the normal, the solution is easy. More info here:
// http://iquilezles.org/www/articles/sphereao/sphereao.htm
//
// When the sphere is only partially visible and see clipping, it gets more complicated:
// http://www.frostbite.com/wp-content/uploads/2014/11/course_notes_moving_frostbite_to_pbr.pdf

// Sphere intersection
float sphIntersect( in vec3 ro, in vec3 rd, in vec4 sph )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return -1.0;
    return -b - sqrt( h );
}

// Sphere occlusion
float sphOcclusion( in vec3 pos, in vec3 nor, in vec4 sph )
{
    vec3  di = sph.xyz - pos;
    float l  = length(di);
    float nl = dot(nor,di/l);
    float h  = l/sph.w;
    float h2 = h*h;
    float k2 = 1.0 - h2*nl*nl;

    // above/below horizon: Quilez - http://iquilezles.org/www/articles/sphereao/sphereao.htm
    float res = max(0.0,nl)/h2;
    // intersecting horizon: Lagarde/de Rousiers - http://www.frostbite.com/wp-content/uploads/2014/11/course_notes_moving_frostbite_to_pbr.pdf
    if( k2 > 0.0 ) 
    {
        #if 1
            res = nl*acos(-nl*sqrt( (h2-1.0)/(1.0-nl*nl) )) - sqrt(k2*(h2-1.0));
            res = res/h2 + atan( sqrt(k2/(h2-1.0)));
            res /= 3.141593;
        #else
            // cheap approximation: Quilez
            res = pow( clamp(0.5*(nl*h+1.0)/h2,0.0,1.0), 1.5 );
        #endif
    }

    return res;
}

//=====================================================

vec2 hash2( float n ) { return fract(sin(vec2(n,n+1.0))*vec2(43758.5453123,22578.1459123)); }

float iPlane( in vec3 ro, in vec3 rd )
{
    return (-1.0 - ro.y)/rd.y;
}

void main(){

    //vec2 p = (2.0*fragCoord.xy-iResolution.xy) / iResolution.y;
    //vec2 p = (1.0 - vUv * 2.0) * vec2(iResolution.z, -1.0);
    vec2 p = ((vUv - 0.5) * 2.0) * vec2(iResolution.z, 1.0);
    float s = (2.0*iMouse.x-iResolution.x) / iResolution.y;


    if( iMouse.z<0.001 ) s=0.0;
    
    vec3 ro = vec3(0.0, 0.0, 4.0 );
    vec3 rd = normalize( vec3(p,-2.0) );
    
    // sphere animation
    vec4 sph = vec4( cos( iGlobalTime + vec3(2.0,1.0,1.0) + 0.0 )*vec3(1.5,1.2,1.0), 1.0 );

    vec4 rrr = texture2D( iChannel0, (vUv.xy)/vec2(256.0), -99.0  ).xzyw;


    vec3 col = vec3(0.0);

    float tmin = 1e10;
    
    float t1 = iPlane( ro, rd );
    if( t1>0.0 )
    {
        tmin = t1;
        vec3 pos = ro + tmin*rd;
        vec3 nor = vec3(0.0,1.0,0.0);
        float occ = 0.0;
        
        if( p.x > s )
        {
            occ = sphOcclusion( pos, nor, sph );
        }
        else
        {
            vec3  ru  = normalize( cross( nor, vec3(0.0,1.0,1.0) ) );
            vec3  rv  = normalize( cross( ru, nor ) );

            occ = 0.0;
            for( int i=0; i<256; i++ )
            {
                vec2  aa = hash2( rrr.x + float(i)*203.1 );
                float ra = sqrt(aa.y);
                float rx = ra*cos(6.2831*aa.x); 
                float ry = ra*sin(6.2831*aa.x);
                float rz = sqrt( 1.0-aa.y );
                vec3  dir = vec3( rx*ru + ry*rv + rz*nor );
                float res = sphIntersect( pos, dir, sph );
                occ += step(0.0,res);
            }
            occ /= 256.0;
        }

        col = vec3(1.0);
        col *= 1.0 - occ;
    }

    float t2 = sphIntersect( ro, rd, sph );
    if( t2>0.0 && t2<tmin )
    {
        tmin = t2;
        float t = t2;
        vec3 pos = ro + t*rd;
        vec3 nor = normalize( pos - sph.xyz );
        col = vec3(1.2);
        col *= 0.6+0.4*nor.y;
    }

    col *= exp( -0.05*tmin );

    float e = 2.0/iResolution.y;
    col *= smoothstep( 0.0, 2.0*e, abs(p.x-s) );
    
    gl_FragColor = vec4( col, 1.0 );
}