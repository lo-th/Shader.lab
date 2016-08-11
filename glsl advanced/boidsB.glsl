void main(){
    
    bool occupied = false;
    
    for(int i = -1; i <= 1; i++)
    {
        for(int j = -1; j <= 1; j++)
        {
            vec2 coord = gl_FragCoord + vec2(float(i), float(j));

            if(coord.x < -0.001)
                coord.x = iResolution.x + coord.x;

            if(coord.y < -0.001)
                coord.y = iResolution.y + coord.y;

            if(coord.x > iResolution.x)
                coord.x = coord.x - iResolution.x;

            if(coord.y > iResolution.y)
                coord.y = coord.y - iResolution.y;

            vec2 uv = coord / iResolution.xy;

            vec4 data = texture2D(iChannel0, uv);

            vec2 pos = data.xy;

            if(data.x > 0.001 && abs(pos.x - gl_FragCoord.x) < 0.5 && abs(pos.y - gl_FragCoord.y) < 0.5)
            {
                occupied = true;
                gl_FragColor = data;
            }
        }
    }
    
    if(!occupied)
        gl_FragColor = vec4(0, 0, 0, 0);
}