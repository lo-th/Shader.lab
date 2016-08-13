#define RGB 0.0039215686274509803921568627451
#define PI_90 1.570796326794896
#define M_PI 3.14159265358979323846
#define TWO_PI 6.28318530717958647692
#define PHASE_TIME 0.1666666666666666667
#define DEG_TO_RAD 0.0174532925199432957

////////////////////////////
//       TWEEN BASE       //
////////////////////////////

// LINEAR
float linear( float k ) { return k; }
// QUAD
float inQuad(float k) { return k * k; }
float outQuad(float k) { return k * ( 2.0 - k );}
float inOutQuad(float k) {
    if ( ( k *= 2.0 ) < 1.0 ) return 0.5 * k * k;
    return - 0.5 * ( --k * ( k - 2.0 ) - 1.0 );
}
// CUBIC
float inCubic(float k) { return k * k * k; }
float outCubic(float k) { return --k * k * k + 1.0; }
float inOutCubic(float k) {
    if ( ( k *= 2.0 ) < 1.0 ) return 0.5 * k * k * k;
    return 0.5 * ( ( k -= 2.0 ) * k * k + 2.0 );
}
// QUART
float inQuart(float k) { return k * k * k * k; }
float outQuart(float k) { return 1.0 - ( --k * k * k * k ); }
float inOutQuart(float k) {
    if ( ( k *= 2.0 ) < 1.0) return 0.5 * k * k * k * k;
    return - 0.5 * ( ( k -= 2.0 ) * k * k * k - 2.0 );
}
// QUINT
float inQuint(float k) { return k * k * k * k * k; }
float outQuint(float k) { return --k * k * k * k * k + 1.0; }
float inOutQuint(float k) {
    if ( ( k *= 2.0 ) < 1.0 ) return 0.5 * k * k * k * k * k;
    return 0.5 * ( ( k -= 2.0 ) * k * k * k * k + 2.0 );
}
// SINE
float inSine(float k) { float j = k * PI_90; return 1.0 - cos( j ); }
float outSine(float k) { float j = k * PI_90; return sin( j ); }
float inOutSine(float k) { float j = k * M_PI; return 0.5 * ( 1.0 - cos( j ) ); }
// EXPO
float inExpo(float k) { return k == 0.0 ? 0.0 : pow( 1024.0, k - 1.0 ); }
float outExpo(float k) { return k == 1.0 ? 1.0 : 1.0 - pow( 2.0, - 10.0 * k ); }
float inOutExpo(float k) {
    if ( k == 0.0 ) return 0.0;
    if ( k == 1.0 ) return 1.0;
    if ( ( k *= 2.0 ) < 1.0 ) return 0.5 * pow( 1024.0, k - 1.0 );
    return 0.5 * ( - pow( 2.0, - 10.0 * ( k - 1.0 ) ) + 2.0 );
}
// CIRC
float inCirc(float k) { return 1.0 - sqrt( 1.0 - k * k ); }
float outCirc(float k) { return sqrt( 1.0 - ( --k * k ) ); }
float inOutCirc(float k) {
    if ( ( k *= 2.0 ) < 1.0) return - 0.5 * ( sqrt( 1.0 - k * k ) - 1.0 );
    return 0.5 * ( sqrt( 1.0 - ( k -= 2.0 ) * k ) + 1.0 );
}
// ELASTIC
float inElastic(float k) {
    float s;
    float a = 0.1;
    float p = 0.4;
    float tpi = TWO_PI;
    if ( k == 0.0 ) return 0.0;
    if ( k == 1.0 ) return 1.0;
    //if ( !a || a < 1.0 ) { a = 1.0; s = p / 4.0; }
    if ( a < 1.0 ) { a = 1.0; s = p / 4.0; }
    else s = p * asin( 1.0 / a ) / tpi;
    return - ( a * pow( 2.0, 10.0 * ( k -= 1.0 ) ) * sin( ( k - s ) * tpi / p ) );
}
float outElastic(float k) {
    float s;
    float a = 0.1; 
    float p = 0.4;
    float tpi = TWO_PI;
    if ( k == 0.0 ) return 0.0;
    if ( k == 1.0 ) return 1.0;
    //if ( !a || a < 1.0 ) { a = 1.0; s = p / 4.0; }
    if ( a < 1.0 ) { a = 1.0; s = p / 4.0; }
    else s = p * asin( 1.0 / a ) / tpi;
    return ( a * pow( 2.0, - 10.0 * k) * sin( ( k - s ) * tpi / p ) + 1.0 );
}
float inOutElastic(float k) {
    float s;
    float a = 0.1;
    float p = 0.4;
    float tpi = TWO_PI;
    if ( k == 0.0 ) return 0.0;
    if ( k == 1.0 ) return 1.0;
    //if ( !a || a < 1.0 ) { a = 1.0; s = p / 4.0; }
    if ( a < 1.0 ) { a = 1.0; s = p / 4.0; }
    else s = p * asin( 1.0 / a ) / tpi;
    if ( ( k *= 2.0 ) < 1.0 ) return - 0.5 * ( a * pow( 2.0, 10.0 * ( k -= 1.0 ) ) * sin( ( k - s ) * tpi / p ) );
    return a * pow( 2.0, -10.0 * ( k -= 1.0 ) ) * sin( ( k - s ) * tpi / p ) * 0.5 + 1.0;
}
// BACK
float inBack(float k) {
    float s = 1.70158;
    return k * k * ( ( s + 1.0 ) * k - s );
}
float outBack(float k) {
  float s = 1.70158;
  return --k * k * ( ( s + 1.0 ) * k + s ) + 1.0;
}
float inOutBack(float k) {
  float s = 1.70158 * 1.525;
  if ( ( k *= 2.0 ) < 1.0 ) return 0.5 * ( k * k * ( ( s + 1.0 ) * k - s ) );
  return 0.5 * ( ( k -= 2.0 ) * k * ( ( s + 1.0 ) * k + s ) + 2.0 );
}
// BOUNCE
float outBounce(float k) {
    if ( k < ( 1.0 / 2.75 ) ) return 7.5625 * k * k;
    else if ( k < ( 2.0 / 2.75 ) ) return 7.5625 * ( k -= ( 1.5 / 2.75 ) ) * k + 0.75;
    else if ( k < ( 2.5 / 2.75 ) ) return 7.5625 * ( k -= ( 2.25 / 2.75 ) ) * k + 0.9375;
    else return 7.5625 * ( k -= ( 2.625 / 2.75 ) ) * k + 0.984375;
}
float inBounce(float k) { return 1.0 - outBounce( 1.0 - k ); }
float inOutBounce(float k) {
    if ( k < 0.5 ) return inBounce( k * 2.0 ) * 0.5;
    return outBounce( k * 2.0 - 1.0 ) * 0.5 + 0.5;
}

