
vec2 tileUV(vec2 uv, vec2 pos, float ntile){

    pos.y = ntiles-pos.y-1.0;
    vec2 sc = vec2(1.0/ntile, 1.0/ntile);
    return vec2(uv*sc)+(pos*sc);
    
}

// tile rotation 
// angle in radian

vec2 rotUV(vec2 uv, float angle){

    float s = sin(angle);
    float c = cos(angle);
    mat2 r = mat2( c, -s, s, c);
    r *= 0.5; r += 0.5; r = r * 2.0 - 1.0;
    uv -= 0.5; uv = uv * r; uv += 0.5;
    return uv;

}



vec2 decalUV(vec2 uv, float pix, float max){

    float ps = uv.x / max;
    float mx = uv.x / (uv.x-(ps*2.0));
    vec2 decal = vec2( (ps*pix), - (ps*pix));
    vec2 sc = vec2(uv.x*mx,uv.y*mx);
    //'    uv -= ((2.0*pix)*ps);
    return (uv);

}