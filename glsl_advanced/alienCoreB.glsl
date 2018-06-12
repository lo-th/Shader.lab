// ------------------ channel define
// 0_# bufferFULL_alienCoreA #_0
// ------------------

//Blur Pass1
vec2 sampleDist = vec2(2.0,2.0);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    vec2 uv = fragCoord.xy/iResolution.xy;
    
    vec4 tex = vec4(0.0);
    vec2 dist = sampleDist/iResolution.xy;
    
    for(int x = -2; x <= 2; x++)
    {
    	for(int y = -2; y <= 2; y++)
        {
			tex += texture2D(iChannel0, uv + vec2(x,y)*dist);
        }
    }
        
    tex /= 25.0;
    
	fragColor = tex;
}