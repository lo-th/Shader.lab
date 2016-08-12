// Last time I blabber on about raymarching being fixed point iteration, I promise! (I think)

// In my last shader I observed that ray marching is equivalent to fixed point iteration
// with a relaxed termination condition: https://www.shadertoy.com/view/4ssGWl

// This shader illustrates the connection between raymarching and finding roots of the
// distance function along the ray.
// The graph shows the distance function along the ray that is marked with a cross in the
// 3D view. The gray axis is the ray parameter value (scaled arbitrarily).

// Note that these are signed distance values - they are positive (above the axis) when the
// ray is above the surface.

// Raymarching will walk along the axis from left to right. At every stop it queries
// the distance value and then walks forward by that amout.

// The red regions of the distance curve show regions where the ray march
// will tend to be inaccurate. These regions won't occur for a real distance field,
// but do here because we are using a heightfield as a distance field, and so the
// distance values vary in an unnatural way (decrease or increase too quicky).

// If the intersection point lies within a red region, the solution obtained is likely
// to be inaccurate. If FPI is used it won't converge but will orbit (as is the case here)
// around the intersection forever, at a radius proportional to the gradient (which is why
// bright spots appear on the when the front facing bumps become steep).

// https://www.shadertoy.com/view/ldsGWl


#define ITERCNT 60
#define STEPMULT 1.
#define SHOW_RAY_STEPS

// the wavy surface
float surfHeight( vec2 xz )
{
    float result = 2.*fract((iGlobalTime+3.)/10.)* (cos(xz.x) + cos(xz.y));
    result *= 1.-exp(-length(xz)/10.);
    return result;
}

// evaluate the ray
vec3 rayPt( vec3 ro, vec3 rd, float t )
{
    return ro + rd * t;
}

// the distance field
float distField( vec3 pt )
{
    float dSurf = pt.y - surfHeight(pt.xz);
    
    vec4 sph1 = vec4(0.,2.7,0.,1.);
    float dSph1 = 1000.;//length(pt.xyz-sph1.xyz)-sph1.w;
    vec4 sph2 = vec4(1.5,2.4,0.,0.5);
    float dSph2 = length(pt.xyz-sph2.xyz)-sph2.w;
    vec4 sph3 = vec4(-1.5,2.4,0.,0.5);
    float dSph3 = length(pt.xyz-sph3.xyz)-sph3.w;
    return min( dSph3, min( dSph2, min( dSph1, dSurf ) ) );
}

// raymarch with FPI termination criteria
float raymarchFPI( vec3 ro, vec3 rd, out float cnt )
{
    // FPI solves equations f(x)=x.
    // Choose
    //      f(t) = distField(ro+rd*t) + t
    // and use FPI to iterate on t until
    //      f(t) = t
    // (Which means distField() == 0)
    
    // initial guess for t - just pick the start of the ray
    float t = 0.;
    
    cnt = 0.;
    float last_t = 10000.; // something far away from t0
    for( int i = 0; i < ITERCNT; i++ )
    {
        // termination condition - iteration has converged to surface
        if( abs(last_t - t) < 0.001 )
            continue;
        
        cnt += 1.;
        
        last_t = t;
        
        vec3 pt = rayPt(ro,rd,t);
        float d = distField( pt );
        t += STEPMULT*d;
    }
    
    return t;
}


vec3 computePixelRay( in vec2 p, out vec3 cameraPos );
vec3 hsv2rgb(vec3 c);
vec3 rgb2hsv(vec3 c);


void main(){
    gl_FragColor = vec4(0.1);
    
    // get aspect corrected normalized pixel coordinate
    vec2 q = gl_FragCoord.xy / iResolution.xy;
    vec2 pp = -1.0 + 2.0*q;
    float aspect = iResolution.x / iResolution.y;
    pp.x *= aspect;
    
    if( pp.y > 0. )
    {
        // top half of screen. draw the 3d scene with a cross indicating
        // a particular ray

        pp.y = 2. * (pp.y-.5);
        
        // cross
        if( 
            (abs(pp.x) < 0.0125/aspect && abs(pp.y) < 0.1) ||
            (abs(pp.y) < 0.0125 && abs(pp.x) < 0.1/aspect) )
        {
            gl_FragColor.rgb = vec3(0.,1.,0.);
            return;
        }
        
        pp.x *= 2.;
        
        // ray march and shade based on iteration count
        vec3 ro;
        vec3 rd = computePixelRay( pp, ro );
        
        float cnt;
        float t = raymarchFPI(ro,rd, cnt);
        float iters = clamp(cnt/float(ITERCNT),0.,1.);
        
        gl_FragColor.xyz = vec3( iters );
    }
    else
    {
        // bottom half of screen. here we will draw the graph. this is done by finding
        // out which pixel we are on, computing a graph coordinate from that, and then
        // checking if we are close to the curve.
        
        // axis
        if( abs(gl_FragCoord.y - iResolution.y/4.) < 1.)
        {
            gl_FragColor.rgb = vec3(0.4);
        }
        
        // compute ray for the middle of the screen. this is where the cross
        // is located, and this is the ray that is graphed
        vec3 ro;
        vec3 rd = computePixelRay( vec2(0.), ro );
        
        // compute the t (x-axis) value for this pixel
        float tmax = 50.0;
        float thist = tmax * gl_FragCoord.x / iResolution.x;
        
        // evaluate the distance field for this value of t
        vec3 thisPt = rayPt( ro, rd, thist );
        float dist = distField( thisPt );
        
        // compute the dist (y-axis) value for this pixel
        // compute max y axis value from x axis range
        float maxDist = tmax * (iResolution.y*0.5/iResolution.x);
        float thisDist = maxDist * (pp.y+.5);
        
        // we'll also want the gradient, which tells us whether the
        // iteration will converge. compute it using forward differences
        // along the ray
        float eps = tmax/iResolution.x;
        vec3 nextPt = rayPt( ro, rd, thist + eps );
        float nextDist = distField(nextPt );
        float distGradient = (nextDist - dist) / eps;
        
        
        // when using FPI, the iterated function is t = distField + t
        // therefore the gradient of the iteration is d/dt(distField) + 1
        float fpiGrad = distGradient + 1.;
        
        // for fpi to converge, the gradient has to be in (-1,1). the next
        // few lines compute a color, blending to red over the last 20% of
        // this range
        fpiGrad = abs(fpiGrad);
        fpiGrad = smoothstep( .8, 1., fpiGrad );
        float g = 1.5 + -2.*fpiGrad;
        float r =  2.*fpiGrad;
        vec3 lineColor = clamp(vec3(r,g,0.),.0,1.);
        lineColor.g *= .85;
        
        // iq's awesome distance to implicit http://www.iquilezles.org/www/articles/distance/distance.htm
        float alpha = abs(thisDist - dist)*iResolution.y/sqrt(1.+distGradient*distGradient);
        // antialias
        alpha = smoothstep( 80., 30., alpha );
        gl_FragColor.rgb = (1.-alpha) * gl_FragColor.rgb + lineColor * alpha;
        
        
        // additional visualisation - for sphere tracing, visualise each sphere
        // need each t value, then plot circle at each t with the radius equal to the distance
        
        #ifdef SHOW_RAY_STEPS
        
        float stepTotalAlpha = 0.;
        
        float stept = 0.;
        
        float last_t = 10000.; // something far away from t0
        for( int i = 0; i < ITERCNT; i++ )
        {
            // termination condition - iteration has converged to surface
            if( abs(last_t - stept) < 0.001 )
                continue;
            
            last_t = stept;
            
            float stepx = -aspect + 2.*aspect * stept / tmax ;
            vec3 stepPt = rayPt( ro, rd, stept );
            
            float d = distField( stepPt );
            
            float stepDist = abs( d );
            float R = length( vec2(stepx,-.5) - pp );
            
            float circleR = stepDist / ( maxDist);
            // circle boundary
            float stepAlpha = 0.2*smoothstep( 5.0/iResolution.x, 0.0, abs(circleR - R) );
            // add a dot at the center
            stepAlpha += 0.3*smoothstep(5.0/iResolution.x,0.0,R);
                
            stepTotalAlpha += stepAlpha;
            
            stept += STEPMULT*d;
        }
        gl_FragColor.rgb += (1.-alpha) * clamp(stepTotalAlpha,0.,1.)*vec3(1.0,1.0,0.);
        
        #endif
    }
}






vec3 computePixelRay( in vec2 p, out vec3 cameraPos )
{
    // camera orbits around origin
    
    float camRadius = 3.8;
    // use mouse x coord
    float a = iGlobalTime*20.;
    //if( iMouse.z > 0. )
    //  a = iMouse.x;
    float theta = -(a-iResolution.x)/80.;
    float xoff = camRadius * cos(theta);
    float zoff = camRadius * sin(theta);
    cameraPos = vec3(xoff,2.5,zoff);
     
    // camera target
    vec3 target = vec3(0.,2.,0.);
     
    // camera frame
    xoff = 0.;
    float yoff = 0.;
    if( iMouse.z > 0. )
    {
        xoff = -2.5*(iMouse.x/iResolution.x - .5);
        yoff = 4.25*(iMouse.y/iResolution.y - .5);
    }
    
    vec3 toTarget = target-cameraPos;
    vec3 right = vec3(-toTarget.z,0.,toTarget.x);
    
    vec3 fo = normalize(target-cameraPos + vec3(0.,yoff,0.) + xoff*right );
    vec3 ri = normalize(vec3(fo.z, 0., -fo.x ));
    vec3 up = normalize(cross(fo,ri));
     
    // multiplier to emulate a fov control
    float fov = .5;
    
    // ray direction
    vec3 rayDir = normalize(fo + fov*p.x*ri + fov*p.y*up);
    
    return rayDir;
}




//http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}