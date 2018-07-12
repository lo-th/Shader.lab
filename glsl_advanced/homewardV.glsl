#define CAMERA_POS      0
#define CAMERA_TAR      1
#define SUN_DIRECTION   2
#define CROW_POS        3
#define CROW_HEADING    4
#define CROW_FLAPPING   5
#define CROW_HEADTILT   6
#define CROW_TURN       7
#define CROW_CLIMBING   8

#define FAR 850.

#define TAU 6.28318530718
#define SUN_COLOUR vec3(1.1, .95, .85)
#define FOG_COLOUR vec3(.48, .49, .53)

vec3 sunLight, crowPos;

//----------------------------------------------------------------------------------------

vec3 cameraPath( float z )
{
    return vec3(100.2*sin(z * .0045)+90.*cos(z *.012), 43.*(cos(z * .0047)+sin(z*.0013)) + 53.*(sin(z*0.0112)), z);
}
// Set up a camera matrix

//--------------------------------------------------------------------------
mat3 setCamMat( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}
#define HASHSCALE1 .1031

float hash11(float p)
{
    vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
