// ------------------ channel define
// 0_# grey1 #_0
// ------------------

// c = center of sphere
// r = radius

// d = -(rd *dot* (ro - c)) + / - sqrt( ((rd *dot* (ro - c))^ 2) - length(ro-c) ^ 2 + r^2 )
   
// https://www.shadertoy.com/view/MtjXDy

float intersectSphere( vec3 rd , vec3 ro , vec3 c , float r ){
    
    vec3 rayDif =  ro - c;

    float matchVec = dot( rd ,rayDif );


    float underRoot =(matchVec * matchVec) - length( rayDif ) * length( rayDif ) + r * r;

    if( underRoot  < 0. ){

        return -1.;

    }else if( underRoot == 0. ){
        
        return -matchVec;
        
    }else{
        
        return -matchVec + underRoot;

    }
    
}

    
float map( vec3 rd ){
    
        
    vec3 c = vec3( 0., 0., 1. );
    float r = .447;
    
    vec3 ro = vec3( 0. );
    
    return intersectSphere( rd , ro , c , r );
    
}

// Calculates the normal by taking a very small distance,
// remapping the function, and getting normal for that
vec3 calcNormal( vec2 uv ){
    
    vec2 eps = vec2( 0.001, 0.0 );

    vec3 rd = vec3( uv , 1. );
    rd = normalize( rd );
    
    vec3 rdUX = normalize( vec3( uv + eps.xy , 1. ));
    vec3 rdUY = normalize( vec3( uv + eps.yx , 1. ));
    vec3 rdDX = normalize( vec3( uv - eps.xy , 1. ));
    vec3 rdDY = normalize( vec3( uv - eps.yx , 1. ));
    
    
    vec3 pUX = rdUX * map( rdUX );
    vec3 pDX = rdDX * map( rdDX );
    vec3 pUY = rdUY * map( rdUY );
    vec3 pDY = rdDY * map( rdDY );
    
    vec3 v1 = pUX - pDX;
    vec3 v2 = pUY - pDY;
    
    vec3 norm = normalize( cross( v1 , v2 ) );

    return norm;
    
}



vec3 doCol( vec3 eye , vec3 norm ){
 
    vec3 refl = reflect( eye , norm );
    
    vec3 c = textureCube( iChannel0 , normalize( refl ) ).xyz;
    
    return c;
    
}
    
 
void main(){

    vec2 uv = gl_FragCoord.xy / iResolution.y;
    
    uv -= vec2( .5 );
    uv.y *= -1.;
    
    vec3 rd = vec3( uv , 1. );
    rd = normalize( rd );
    vec3 ro = vec3( 0. );
    
    float intersectVal = intersectSphere( rd , ro , vec3( 0., 0., 1. ) , .447 );

    vec3 n = calcNormal( uv );
   
    
    vec3 col = doCol( rd , n );

    
    if( uv.x > .5 ){
     col = vec3( 0. );   
    }
    
    gl_FragColor = vec4( col ,1.0);
}