//https://www.shadertoy.com/view/XsBGzc

float bit(float c1, float c2, float c3, float c4, float c5, vec2 p) {
    float chr=0.0;
    if (p.x==1.0) chr=c1;
    if (p.x==2.0) chr=c2;
    if (p.x==3.0) chr=c3;
    if (p.x==4.0) chr=c4;
    if (p.x==5.0) chr=c5;
    return floor(fract(chr/pow(10.0,p.y))*10.0);
}

float writestr(vec2 p, vec2 fragCoord) {
    p=floor(fragCoord.xy-p+1.0);
    if (p.y<1.0 || p.y>7.0) return 0.0;
    
            //M
      float b= bit( 1111111.0, 0100000.0, 0010000.0, 0100000.0, 1111111.0, p );
            //I
            p.x-=6.0;
            b+=bit( 1000001.0, 1111111.0, 1000001.0, 0000000.0, 0000000.0, p );
            //N
            p.x-=4.0;
            b+=bit( 1111111.0, 0100000.0, 0011100.0, 0000010.0, 1111111.0, p ); 
            //I
            p.x-=6.0;
            b+=bit( 1000001.0, 1111111.0, 1000001.0, 0000000.0, 0000000.0, p );
            //F
            p.x-=4.0;
            b+=bit( 1111111.0, 1001000.0, 1001000.0, 1000000.0, 0000000.0, p );
            //O
            p.x-=5.0;
            b+=bit( 0111110.0, 1000001.0, 1000001.0, 1000001.0, 0111110.0, p );
            //N
            p.x-=6.0;
            b+=bit( 1111111.0, 0100000.0, 0011100.0, 0000010.0, 1111111.0, p ); 
            //T
            p.x-=6.0;
            b+=bit( 1000000.0, 1000000.0, 1111111.0, 1000000.0, 1000000.0, p );
            //space
            p.x-=4.0;
            //B
            p.x-=6.0;
            b+=bit( 1111111.0, 1001001.0, 1001001.0, 0111001.0, 0000110.0, p );
            //Y
            p.x-=5.0;                   //rounding bug.. fract should be 0 but...
            b+=bit( 1100000.0, 0010000.0, 0001111.1, 0010000.0, 1100000.0, p );
            //space
            p.x-=4.0;   
            //A
            p.x-=6.0;
            b+= bit( 0111111.0, 1001000.0, 1001000.0, 1001000.0, 0111111.0, p );
            //V
            p.x-=6.0;
            b+=bit( 1111100.0, 0000010.0, 0000001.0, 0000010.0, 1111100.0, p );
            //I
            p.x-=6.0;
            b+=bit( 1000001.0, 1111111.0, 1000001.0, 0000000.0, 0000000.0, p );
            //X
            p.x-=4.0;
            b+=bit( 1000001.0, 0100010.0, 0011100.0, 0100010.0, 1000001.0, p );
    
    return b;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv=fragCoord.xy / iResolution.xy;
    
    
    vec2 strpos=vec2( iResolution.x/2.0-50.0, iResolution.y/2.0);
    
    vec3 col=vec3( writestr( strpos, fragCoord ) );

    if (col.x==0.0) {
        col=vec3(uv, 0.5+0.5*sin(iGlobalTime));
    }
    
    
    fragColor = vec4( col, 1.0 );
}