


#define ONLY_INTEGER_SCALING 0

void main(){

    vec2 targetSize = vec2(32.,27.)*8.;
    vec2 tmp = iResolution.xy / targetSize;
    float scale = min(tmp.x, tmp.y);
#if ONLY_INTEGER_SCALING
    scale = floor(scale);
#endif
    vec2 windowOffset = floor((iResolution.xy - targetSize*scale)*.5);
    
    vec2 coord = (gl_FragCoord- windowOffset) / scale;
    if(coord.x < 0.0 || coord.y < 0.0 || coord.x >= targetSize.x || coord.y >= targetSize.y)
    {
        gl_FragColor.xyz = vec3(0.0);
        return;
    }
    
    gl_FragColor = texture2D(iChannel0, coord / iChannelResolution[0].xy) ;
    
}