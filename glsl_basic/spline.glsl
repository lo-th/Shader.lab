// Author : SÃ©bastien BÃ©rubÃ©
// Created : Oct 2014
// Modified : Jan 2016
//
// A quick & simple spline implementation to use in ShaderToy.
// The spline end folds on the start, making a cyclic path.
// Computation is reasonably cheap (<.5 ms to solve a value at time=t on my old laptop).
// The distance field, however, is more expensive to compute (iterative process).
//
// Useful for object property animation (camera path, speed, position, size, color, roughness, etc).
// The distance field itself is not the point here, albeit a nice way to visualize the resulting spline.
//
// Note 1 : There is no support for random array index access (only textures/resources), therefore the function
// "PointArray()" was coded.
//
// Note 2 : Works with float, vec2, vec3, vec4. Just replace the type. Packaging multiple properties to animate into
//          a vec4 is most probably more efficient than calling the vec2 function twice with different control points.
//
// License : Creative Commons Non-commercial (NC) license
//

// https://www.shadertoy.com/view/ls3SRr

const int POINT_COUNT = 8;
struct CtrlPts
{
    vec2 p[POINT_COUNT];
};
vec2 PointArray(int i, CtrlPts ctrlPts)
{
    if(i==0 || i==POINT_COUNT  ) return ctrlPts.p[0];
    if(i==1 || i==POINT_COUNT+1) return ctrlPts.p[1];
    if(i==2 || i==POINT_COUNT+2) return ctrlPts.p[2];
    if(i==3) return ctrlPts.p[3];
    if(i==4) return ctrlPts.p[4];
    if(i==5) return ctrlPts.p[5];
    if(i==6) return ctrlPts.p[6];
    if(i==7) return ctrlPts.p[7];
    return vec2(0);
}

vec2 catmullRom(float fTime, CtrlPts ctrlPts)
{
    float t = fTime;
    const float n = float(POINT_COUNT);
    
    int idxOffset = int(t*n);
    vec2 p1 = PointArray(idxOffset,ctrlPts);
    vec2 p2 = PointArray(idxOffset+1,ctrlPts);
    vec2 p3 = PointArray(idxOffset+2,ctrlPts);
    vec2 p4 = PointArray(idxOffset+3,ctrlPts);
    
    //For some reason, fract(t*n) returns garbage on my machine with small values of t.
    //return fract(n*t);
    //Using this below yields the same results, minus the glitches.
    t *= n;
    t = (t-float(int(t)));
    
    //A classic catmull-rom
    //e.g.
    //http://steve.hollasch.net/cgindex/curves/catmull-rom.html
    //http://www.lighthouse3d.com/tutorials/maths/catmull-rom-spline/
    vec2 val = 0.5 * ((-p1 + 3.*p2 -3.*p3 + p4)*t*t*t
               + (2.*p1 -5.*p2 + 4.*p3 - p4)*t*t
               + (-p1+p3)*t
               + 2.*p2);
    return val;
}

float distanceToLineSeg(vec2 p, vec2 a, vec2 b)
{
    //e = capped [0,1] orthogonal projection of ap on ab
    //       p
    //      /
    //     /
    //    a--e-------b
    vec2 ap = p-a;
    vec2 ab = b-a;
    vec2 e = a+clamp(dot(ap,ab)/dot(ab,ab),0.0,1.0)*ab;
    return length(p-e);
}

vec2 debugDistanceField(vec2 uv, CtrlPts ctrlPts)
{
    //This is just to illustrate the resulting spline. A Spline distance field should not be computed this way.
    //If the real intent was to show a distance field, something like this perhaps should be used:
    //https://www.shadertoy.com/view/XsX3zf
    const float MAX_DIST = 10000.0;
    float bestX = 0.0;
    
    //Primary (rough) estimate : decent results with 2 lines per control point (faint blue lines)
    const int iter = POINT_COUNT*2+1;
    //const int iter = POINT_COUNT*1+1; //<-Faster
    //const int iter = POINT_COUNT*3+1; //<-Nicer
    float primarySegLength = 1.0/float(iter-1);
    vec2 pA = catmullRom(0., ctrlPts);
    float minRoughDist = MAX_DIST;
    float x = 0.0;
    for(int i=0; i < iter; ++i)
    {
        vec2 pB = catmullRom(x, ctrlPts);
        
        float d = distanceToLineSeg(uv, pA, pB);
        pA = pB;
        if(d<minRoughDist)
        {
            bestX = x;
            minRoughDist = d;
        }
         
        x += primarySegLength;
        x = min(x,0.99999); //<1 To prevent artifacts at the end.
    }
    
    //Secondary (smooth) estimate : refine (red curve)
    const int iter2 = 14;
    x = max(bestX-1.25*primarySegLength,0.0); //Starting 25% back on previous seg (50% overlap total)
    float minDist = MAX_DIST;
    pA = catmullRom(x, ctrlPts);
    for(int i=0; i < iter2; ++i)
    {
        vec2 pB = catmullRom(x, ctrlPts);
        float d = distanceToLineSeg(uv, pA, pB);
        pA = pB;
        
        if(d<minDist)
        {
            bestX = x;
            minDist = d;
        }
         
        //Covering 1.5x primarySegLength (50% overlap with prev, next seg)
        x += 1.5/float(iter2-1)*primarySegLength;
        x = min(x,0.99999); //<1 To prevent artifacts at the end.
    }
    
    
    return vec2(minDist,minRoughDist);
}

//Recenters and scales in the [0-1] range.
vec2 getUV(vec2 px)
{
    vec2 uv = px / iResolution.xx;
    return uv;
}

void main(){

    CtrlPts ctrlPts;
    ctrlPts.p[0] = vec2(0.10,0.25);
    ctrlPts.p[1] = vec2(0.2,0.1);
    ctrlPts.p[2] = vec2(0.6,0.35);
    ctrlPts.p[3] = vec2(0.4,0.1);
    ctrlPts.p[4] = vec2(0.8,0.35);
    ctrlPts.p[5] = vec2(0.6,0.55);
    ctrlPts.p[6] = vec2(0.5,0.45);
    ctrlPts.p[7] = vec2(0.3,0.49);
    
    if(iMouse.z > 0.1)
        ctrlPts.p[2] = getUV(iMouse.xy);
    //vec2 uv = getUV(gl_FragCoord.xy);

    vec2 uv = ((vUv * 2.0) - 1.0 ) * vec2(iResolution.z, 1.0);
    
    float fTime = iGlobalTime*0.15;
    vec2 pA = catmullRom(fract(fTime), ctrlPts);
    vec2 pB = catmullRom(fract(fTime+0.02), ctrlPts);
    
    //Compute Distance field
    vec2 dSeg = debugDistanceField(uv, ctrlPts);
    
    //Draw distance field background
    vec3 c = vec3(dSeg.x*7.0+smoothstep(0.20,0.3,abs(fract(dSeg.x*20.0)-0.5)));
    
    //Draw the spline
    c = mix(vec3(0,0.8,0.9),c,smoothstep(-0.005,0.0035,dSeg.y));
    c = mix(vec3(1,0  ,0.0),c,smoothstep(0.0,0.0025,dSeg.x));
    
    //Draw each control point
    float minDistP = 10000.0;
    for(int i=0; i < POINT_COUNT; ++i)
    {
        vec2 ctrl_pt = PointArray(i,ctrlPts);
        minDistP = min(length(uv-ctrl_pt),minDistP);
    }
    c = mix(vec3(0,0,1),c,smoothstep(0.008,0.011,minDistP));
    
    //Draw moving points
    c = mix(vec3(0,0.7,0),c,smoothstep(0.008,0.011,length(uv-pA)));
    c = mix(vec3(0,0.7,0),c,smoothstep(0.008,0.011,length(uv-pB)));
    c = mix(vec3(1,1,1),c,smoothstep(0.004,0.006,length(uv-pB)));
    
    gl_FragColor = vec4(c,1);
}