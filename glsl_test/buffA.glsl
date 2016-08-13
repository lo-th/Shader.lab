#define fb iChannel0

vec3 hash3D( vec2 p )
{
    // texture based white noise
    return texture2D( iChannel1, p*0.14 ).xyz;
}

float voronoi( vec2 x ){

    vec2 cellFlo = floor(x);
    vec2 cellFra = fract(x);

    float md = 100.0; // minimum distance find
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        // current cell coordinate
        vec2 celPos = cellFlo + vec2(float(i),float(j));
        vec3 rnd = hash3D(celPos);
        // ptPos: random point location in local cell coordinate
        vec2 ptPos = vec2(.5) + vec2(sin(iGlobalTime*rnd.z*1.45), cos(iGlobalTime*rnd.z*1.174))*.5 ; //point in local cell axis
        ptPos += celPos;  // ptPos: now in global position
        
        vec2 v = ptPos-x;
        float d = dot(v,v);

        if( d<md )
        {
            md = d;
        }
    }
    return md ;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 posnorm = fragCoord.xy / iResolution.xy - 0.5;
    vec4 old = texture2D(fb, posnorm+0.5);
    vec2 p = fragCoord.xy/iResolution.xx;
    float c = voronoi( 8.0*p );
    vec4 cur = vec4(c, c*c, c*c*c, 1.);
    //
    //fragColor = cur;
    //fragColor = old * vec4(0.5,0.6,0.65,1.0)*0.75 + cur ; 
    fragColor = max(old*vec4(0.96,0.985,0.995,1.), cur );
    
}