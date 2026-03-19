// The MIT License
// Copyright © 2025 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// Snap unit vectors to 45 degree angles without using atan.



// spalmer+iq version (2.8x faster than trigonometric), fixed by FordPerfect
vec2 snap45( in vec2 v )
{
    v = round(v*1.30656296); // sqrt(1.0+sqrt(0.5))
    return v*(abs(v.x)+abs(v.y)>1.5?sqrt(0.5):1.0);
    
    // as fast (ADD, FMA, MUL) instead of (ADD, CMP, SEL, MUL)
    // return v*((2.0-sqrt(0.5))-(1.0-sqrt(0.5))*(abs(v.x)+abs(v.y)));
}

// spalmer version (2.1x faster than trigonometric), fixed by FordPerfect
vec2 snap45_spalmer( in vec2 v )
{
    return normalize(round(v*1.30656296)); // sqrt(1.0+sqrt(0.5)) = 1/2sin(PI/8)
}

// iq version (1.8x faster than trigonometric)
vec2 snap45_iq( in vec2 v )
{
    vec2  s = sign(v);
    float x = abs(v.x);
    return x>0.92387953?vec2(s.x,0.0): // cos(PI*1/8)
           x<0.38268343?vec2(0.0,s.y): // cos(PI*3/8)
                        s*sqrt(0.5);
}

// iq initial experiment, not great
vec2 snap45_experiment( in vec2 v )
{
    vec2 s = sign(v);
    vec2 a = abs(v);
    return (a.y<a.x*(sqrt(2.0)-1.0)) ? vec2(s.x,0.0) :
           (a.x<a.y*(sqrt(2.0)-1.0)) ? vec2(0.0,s.y) :
                                       s*sqrt(0.5);
}

// trigonometric reference, very slow (specially in CPUs)
vec2 snap45_trig( in vec2 v )
{
    const float r = 6.283185/8.0; // 45 degrees

    float a = atan(v.y,v.x);      // vector to angle
    float s = r*round(a/r);       // snap angle
    return vec2(cos(s),sin(s));   // angle to vector
}

//===============================================================

float line( in vec2 p, in vec2 b, in float th, in float w )
{
    return smoothstep(w,-w,length(p-b*clamp(dot(p,b)/dot(b,b),0.0,1.0))-th);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
 	vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    float px = 2.0/iResolution.y;
    
    // full background
    vec3 col = vec3(21,32,43)/255.0;

    const float ra = 0.9;

    // draw circle
    {
    float r = length(p);
    if( r<ra )
    {
        // radial gradient
        col += 0.25*r*r/(ra*ra);
        // 8 regions
        vec2 q = abs(p);
        if( q.y<q.x*(sqrt(2.0)-1.0) ||
            q.x<q.y*(sqrt(2.0)-1.0) ) col += 0.03;
    }
    col += 0.4*smoothstep(1.5*px,0.0,abs(r-ra)-0.003);
    }
    
    // draw 8 octants
    {
    const vec2 k = vec2(-sqrt(2.0+sqrt(2.0))/2.0,
                         sqrt(2.0-sqrt(2.0))/2.0 );
    vec2 q = abs(p);
    q -= 2.0*min(dot(vec2( k.x,k.y),q),0.0)*vec2( k.x,k.y);
    q -= 2.0*min(dot(vec2(-k.x,k.y),q),0.0)*vec2(-k.x,k.y);
    col += 0.2*line(q, vec2(0.0,ra), 0.003, px);
    }
    
    // draw vector, and snap vector
    {
    vec2 v = normalize( iMouse.z>0.001 ? 
        2.0*iMouse.xy-iResolution.xy :
        cos(6.283185*(iTime/10.0+vec2(0.0,-0.25))));
    vec2 s = snap45( v );
    col = mix( col, vec3(0.9,0.90,0.90), line(p, v*ra, 0.003, px) );
    col = mix( col, vec3(3.0,0.95,0.20), line(p, s*ra, 0.004, px) );
    }   
    
    fragColor = vec4( col, 1.0 );
}