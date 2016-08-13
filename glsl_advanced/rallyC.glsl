
// ------------------ channel define
// 0_# buffer128_rallyA #_0
// 1_# tex17 #_1
// 2_# tex05 #_2
// 3_# buffer128_rallyB #_3
// ------------------


// Shader Rally - @P_Malin

// Main HDR scene shader

// Uncomment the next line to speed things up a bit
//#define FAST_VERSION
//#define SHOW_PHYSICS_SHAPE

#define RAYTRACE_COUNT 2

vec3 g_pixelRandom;

vec2 addrVehicle = vec2( 0.0, 0.0 );

vec2 offsetVehicleParam0 = vec2( 0.0, 0.0 );

vec2 offsetVehicleBody = vec2( 1.0, 0.0 );
vec2 offsetBodyPos = vec2( 0.0, 0.0 );
vec2 offsetBodyRot = vec2( 1.0, 0.0 );
vec2 offsetBodyMom = vec2( 2.0, 0.0 );
vec2 offsetBodyAngMom = vec2( 3.0, 0.0 );

vec2 offsetVehicleWheel0 = vec2( 5.0, 0.0 );
vec2 offsetVehicleWheel1 = vec2( 7.0, 0.0 );
vec2 offsetVehicleWheel2 = vec2( 9.0, 0.0 );
vec2 offsetVehicleWheel3 = vec2( 11.0, 0.0 );

vec2 offsetWheelState = vec2( 0.0, 0.0 );
vec2 offsetWheelContactState = vec2( 1.0, 0.0 );

vec2 addrCamera = vec2( 0.0, 1.0 );
vec2 offsetCameraPos = vec2( 0.0, 0.0 );
vec2 offsetCameraTarget = vec2( 1.0, 0.0 );

vec2 addrPrevCamera = vec2( 0.0, 2.0 );

vec4 LoadVec4( in vec2 vAddr )
{
    vec2 vUV = (vAddr + 0.5) / iChannelResolution[0].xy;
    return texture2D( iChannel0, vUV, -100.0 );
}

vec3 LoadVec3( in vec2 vAddr )
{
    return LoadVec4( vAddr ).xyz;
}

mat3 QuatToMat3( const in vec4 q )
{
    vec4 qSq = q * q;
    float xy2 = q.x * q.y * 2.0;
    float xz2 = q.x * q.z * 2.0;
    float yz2 = q.y * q.z * 2.0;
    float wx2 = q.w * q.x * 2.0;
    float wy2 = q.w * q.y * 2.0;
    float wz2 = q.w * q.z * 2.0;
 
    return mat3 (   
     qSq.w + qSq.x - qSq.y - qSq.z, xy2 - wz2, xz2 + wy2,
     xy2 + wz2, qSq.w - qSq.x + qSq.y - qSq.z, yz2 - wx2,
     xz2 - wy2, yz2 + wx2, qSq.w - qSq.x - qSq.y + qSq.z );
}


/////////////////////////
// Rotation

vec2 Rotate( const in vec2 vPos, const in float t )
{
    float s = sin(t);
    float c = cos(t);
    
    return vec2( c * vPos.x + s * vPos.y, -s * vPos.x + c * vPos.y);
}

vec2 Rotate( const in vec2 vPos, const in vec2 sc )
{
    return vec2( sc.y * vPos.x + sc.x * vPos.y, -sc.x * vPos.x + sc.y * vPos.y);
}

vec3 RotX( const in vec3 vPos, float t )
{
    vec3 result;
    result.x = vPos.x;
    result.yz = Rotate( vPos.yz, t );
    return result;
}

vec3 RotY( const in vec3 vPos, float t )
{
    vec3 result;
    result.y = vPos.y;
    result.xz = Rotate( vPos.xz, t );
    return result;
}

vec3 RotZ( const in vec3 vPos, float t )
{
    vec3 result;
    result.z = vPos.z;
    result.xy = Rotate( vPos.xy, t );
    return result;
}

vec3 RotX( const in vec3 vPos, vec2 sc )
{
    vec3 result;
    result.x = vPos.x;
    result.yz = Rotate( vPos.yz, sc );
    return result;
}

vec3 RotY( const in vec3 vPos, vec2 sc )
{
    vec3 result;
    result.y = vPos.y;
    result.xz = Rotate( vPos.xz, sc );
    return result;
}

vec3 RotZ( const in vec3 vPos, vec2 sc )
{
    vec3 result;
    result.z = vPos.z;
    result.xy = Rotate( vPos.xy, sc );
    return result;
}


/////////////////




float kFarClip=1000.0;

vec2 GetWindowCoord( const in vec2 vUV );
vec2 GetUVFromWindowCoord( const in vec2 vWindow );
vec3 GetCameraRayDir( const in vec2 vWindow, const in vec3 vCameraPos, const in vec3 vCameraTarget );
vec2 GetCameraWindowCoord(const in vec3 vWorldPos, const in vec3 vCameraPos, const in vec3 vCameraTarget);
vec3 GetSceneColour( in vec3 vRayOrigin,  in vec3 vRayDir, out float fDepth );
vec3 ApplyPostFX( const in vec2 vUV, const in vec3 vInput );
vec3 Hash32( vec2 p );

vec2 g_TyreTrackOrigin;

void main(){
    
    g_pixelRandom = normalize( Hash32(gl_FragCoord.xy + iGlobalTime) );
    
    vec2 vUV = gl_FragCoord.xy / iResolution.xy;

    vec3 vCameraPos = LoadVec3( addrCamera + offsetCameraPos );
    vec3 vCameraTarget = LoadVec3( addrCamera + offsetCameraTarget );
    
    g_TyreTrackOrigin = floor(vCameraPos.xz);
    
    vec3 vRayOrigin = vCameraPos;
    vec3 vRayDir = GetCameraRayDir( GetWindowCoord(vUV), vCameraPos, vCameraTarget );
    
    float fDepth;
    vec3 vResult = GetSceneColour(vRayOrigin, vRayDir, fDepth);
    vResult = max( vResult, vec3(0.0));
        
    gl_FragColor = vec4(vResult, fDepth);
}

// CAMERA

vec2 GetWindowCoord( const in vec2 vUV )
{
    vec2 vWindow = vUV * 2.0 - 1.0;
    vWindow.x *= iResolution.x / iResolution.y;

    return vWindow; 
}

vec2 GetUVFromWindowCoord( const in vec2 vWindow )
{
    vec2 vScaledWindow = vWindow;
    vScaledWindow.x *= iResolution.y / iResolution.x;
    
     return vScaledWindow * 0.5 + 0.5;
}


vec3 GetCameraRayDir( const in vec2 vWindow, const in vec3 vCameraPos, const in vec3 vCameraTarget )
{
    vec3 vForward = normalize(vCameraTarget - vCameraPos);
    vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
    vec3 vUp = normalize(cross(vForward, vRight));
                              
    vec3 vDir = normalize(vWindow.x * vRight + vWindow.y * vUp + vForward * 2.0);

    return vDir;
}

vec2 GetCameraWindowCoord(const in vec3 vWorldPos, const in vec3 vCameraPos, const in vec3 vCameraTarget)
{
    vec3 vForward = normalize(vCameraTarget - vCameraPos);
    vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
    vec3 vUp = normalize(cross(vForward, vRight));
    
    vec3 vOffset = vWorldPos - vCameraPos;
    vec3 vCameraLocal;
    vCameraLocal.x = dot(vOffset, vRight);
    vCameraLocal.y = dot(vOffset, vUp);
    vCameraLocal.z = dot(vOffset, vForward);

    vec2 vWindowPos = vCameraLocal.xy / (vCameraLocal.z / 2.0);
    
    return vWindowPos;
}

// RAYTRACE

struct SurfaceInfo
{
    vec3 vUVW;
    float fId;
};

struct ClosestSurface
{
    float fDist;
    SurfaceInfo surface;
};
    
void ClosestSurfaceInit( inout ClosestSurface closest, float fId, vec3 vUVW )
{
    closest.fDist = kFarClip;
    closest.surface.vUVW = vUVW;
    closest.surface.fId = fId;
}


ClosestSurface ClosestSurfaceUnion( const in ClosestSurface a, const in ClosestSurface b )
{
    if ( a.fDist < b.fDist )
    {
        return a;
    }

    return b;        
}
    
struct C_Intersection
{
    vec3 vPos;
    float fDist;    
    vec3 vNormal;
    SurfaceInfo surface;
};

vec2 Segment( vec3 vPos, vec3 vP0, vec3 vP1 )
{
    vec3 pa = vPos - vP0;
    vec3 ba = vP1 - vP0;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    
    return vec2( length( pa - ba*h ), h );
}

float SdCapsule( vec3 vPos, vec3 vP0, vec3 vP1, float r0, float r1 )
{
    vec2 vC = Segment( vPos, vP0, vP1 );
    
    return vC.x - mix(r0, r1, vC.y);
}

float SdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float SdSphere( vec3 p, float r )
{
    return length(p) - r;
}

float UdRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

///////////////////
// Scene State

struct VehicleState
{
    vec3 vPos;
    
    vec4 qRot;
    mat3 mRot;
    
    vec4 vWheelState0;
    vec4 vWheelState1;
    vec4 vWheelState2;
    vec4 vWheelState3;
    
    vec4 vWheelSC0;
    vec4 vWheelSC1;
    vec4 vWheelSC2;
    vec4 vWheelSC3;
};

struct SceneState
{
    VehicleState vehicleState;
};
    
SceneState SetupSceneState()
{
    SceneState sceneState;
    
    sceneState.vehicleState.vPos = LoadVec3( addrVehicle + offsetVehicleBody + offsetBodyPos );
    
    sceneState.vehicleState.qRot = LoadVec4( addrVehicle + offsetVehicleBody + offsetBodyRot );
    sceneState.vehicleState.mRot = QuatToMat3( sceneState.vehicleState.qRot );

    vec4 vWheelState0 = LoadVec4( addrVehicle + offsetVehicleWheel0 );
    vec4 vWheelState1 = LoadVec4( addrVehicle + offsetVehicleWheel1 );
    vec4 vWheelState2 = LoadVec4( addrVehicle + offsetVehicleWheel2 );
    vec4 vWheelState3 = LoadVec4( addrVehicle + offsetVehicleWheel3 );
    
    sceneState.vehicleState.vWheelState0 = vWheelState0;
    sceneState.vehicleState.vWheelState1 = vWheelState1;
    sceneState.vehicleState.vWheelState2 = vWheelState2;
    sceneState.vehicleState.vWheelState3 = vWheelState3;
    
    sceneState.vehicleState.vWheelSC0 = vec4( sin(vWheelState0.x), cos(vWheelState0.x), sin(vWheelState0.y), cos(vWheelState0.y) );
    sceneState.vehicleState.vWheelSC1 = vec4( sin(vWheelState1.x), cos(vWheelState1.x), sin(vWheelState1.y), cos(vWheelState1.y) );
    sceneState.vehicleState.vWheelSC2 = vec4( sin(vWheelState2.x), cos(vWheelState2.x), sin(vWheelState2.y), cos(vWheelState2.y) );
    sceneState.vehicleState.vWheelSC3 = vec4( sin(vWheelState3.x), cos(vWheelState3.x), sin(vWheelState3.y), cos(vWheelState3.y) );
    
    return sceneState;
}

///////////////////
// Random

#define MOD2 vec2(4.438975,3.972973)
#define MOD3 vec3(.1031,.11369,.13787)
#define MOD4 vec4(.1031,.11369,.13787, .09987)
#define HASHSCALE .1031

float Hash( float p ) 
{
    // https://www.shadertoy.com/view/4djSRW - Dave Hoskins
    vec2 p2 = fract(vec2(p) * MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
    return fract(p2.x * p2.y);    
}

vec3 Hash31(float p)
{
    // https://www.shadertoy.com/view/4djSRW - Dave Hoskins
   vec3 p3 = fract(vec3(p) * MOD3);
   p3 += dot(p3, p3.yzx + 19.19);
   return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

vec3 Hash32(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * HASHSCALE);
    p3 += dot(p3, p3.yxz+19.19);
    return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

float SmoothNoise(in vec2 o) 
{
    vec2 p = floor(o);
    vec2 f = fract(o);
        
    float n = p.x + p.y*57.0;

    float a = Hash(n+  0.0);
    float b = Hash(n+  1.0);
    float c = Hash(n+ 57.0);
    float d = Hash(n+ 58.0);
    
    vec2 f2 = f * f;
    vec2 f3 = f2 * f;
    
    vec2 t = 3.0 * f2 - 2.0 * f3;
    
    float u = t.x;
    float v = t.y;

    float res = a + (b-a)*u +(c-a)*v + (a-b+d-c)*u*v;
    
    return res;
}

float FBM( vec2 p, float ps ) {
    float f = 0.0;
    float tot = 0.0;
    float a = 1.0;
#ifndef FAST_VERSION
    for( int i=0; i<3; i++)
#endif
    {
        f += SmoothNoise( p ) * a;
        p *= 2.0;
        tot += a;
        a *= ps;
    }
    return f / tot;
}


///////////////////
// Scene

#define MAT_TERRAIN 1.0
#define MAT_WOOD 2.0

#define MAT_CAR_BODY 3.0
#define MAT_CHROME 4.0
#define MAT_GRILL 5.0
#define MAT_BLACK_PLASTIC 5.0
#define MAT_AXLE 5.0
#define MAT_REAR 5.0
#define MAT_WHEEL 6.0    
#define MAT_SUSPENSION 7.0

// Motion blur mask
#define MAT_FIRST_VEHICLE MAT_CAR_BODY

float GetTerrainDistance( const vec3 vPos )
{    
    float fbm = FBM( vPos.xz * vec2(0.5, 1.0), 0.5 );
    float fTerrainHeight = fbm * fbm;
    fTerrainHeight = fTerrainHeight * (sin(vPos.x * 0.1) + 1.0) * 0.5 + vPos.y + 3.0;    
    
    //float h = 1.0 - exp(-abs(vPos.x + 15.0) * 0.01);
    
    //fTerrainHeight += sin(vPos.x * 0.05) * 5.0 * h;
    //fTerrainHeight += sin(vPos.z * 0.05) * 5.0 * h;
    
    #ifndef FAST_VERSION
    {
        // Apply Tyre Track to Terrain
        float fRange = 20.0;
        vec2 vPrevFragOffset = vPos.xz - g_TyreTrackOrigin;
        vec2 vPrevUV = ( (vPrevFragOffset / fRange) + 1.0 ) / 2.0;

        vec4 vTrackSample = texture2D( iChannel3, vPrevUV );
        float fDepth = vTrackSample.x * (1.0 + vTrackSample.y);
        
        fTerrainHeight += fDepth * 0.05;        
    }
    #endif
    
    return fTerrainHeight;
}

ClosestSurface GetRampClosestSurface( const vec3 vPos, const float fRampSeed )
{
    ClosestSurface closest;
    
    vec3 vHash = Hash31( fRampSeed );
    
    closest.surface.fId = MAT_WOOD;
    closest.surface.vUVW = vPos.xyz;
    
    float fHeight = 2.0 + vHash.x * 6.0;
    float fRadius = 10.0 + vHash.y * 20.0;
    float fLedge = 2.0 + vHash.z * 3.0;
        
    float h2 = fRadius - fHeight;
    float fLength = sqrt(fRadius * fRadius - h2 * h2);
    fLength = fLength + fLedge;
    closest.fDist = sdBox( vPos - vec3( 0.0, fHeight * 0.5, fLength * 0.5 ), vec3(3.0, fHeight * 0.5, fLength * 0.5));
    

    vec3 vCylDomain = vPos - vec3( 0.0, fRadius, 0.0 );
    float fCylDist = length(vCylDomain.yz) - fRadius;
    
    //closest.fDist = fCylDist;
    
    if ( -fCylDist > closest.fDist )
    {
        closest.fDist = -fCylDist;
        closest.surface.fId = MAT_WOOD;
    }
    //closest.fDist = max( closest.fDist, -fCylDist);
    
    return closest;
}

ClosestSurface GetEnvironmentClosestSurface( const vec3 vPos )
{
    ClosestSurface terrainClosest;
    terrainClosest.surface.fId = MAT_TERRAIN;
    terrainClosest.surface.vUVW = vec3(vPos.xz,0.0);
    terrainClosest.fDist = GetTerrainDistance( vPos );
#ifdef FAST_VERSION
    return terrainClosest;
#else
    float fRepeat = 100.0;
    vec3 vRampDomain = vPos - vec3(-15.0, -3.0, 0.0);
    float fRampUnitZ = vRampDomain.z / fRepeat + 0.5;
    float fRampSeed = floor( fRampUnitZ );
    vRampDomain.z = (fract(fRampUnitZ) - 0.5) * fRepeat;
    ClosestSurface rampClosest = GetRampClosestSurface( vRampDomain, fRampSeed );

    return ClosestSurfaceUnion( terrainClosest, rampClosest );
#endif
}

float PlaneDist( const in vec3 vPos, const in vec3 vNormal, float fDist )
{
    return dot(vNormal.xyz, vPos) - fDist;
}

float PlaneDist( const in vec3 vPos, const in vec4 vPlane )
{
    return PlaneDist(vPos, vPlane.xyz, vPlane.w);
}




float CarBodyMin( float a, float b, float k )
{
    return smin(a, b, k);
}
  
float CarBodyMax( float a, float b, float k )
{
    return -CarBodyMin(-a, -b, k);
}

float WheelArchCombine( float a, float b )
{
    float size = 0.1;
    float r= clamp( 1.0 - abs(b) / size, 0.0, 1.0);
    a -= r * r * size;
    
    return CarBodyMax(a, b, 0.1);
}

float GetWheelArchDist( vec3 vPos )
{
    vPos.y = max( vPos.y, 0.0 );
    return  0.45 - length( vec2( length( vPos.zy ), vPos.x ));
    //return  0.45 - length( vPos.zy );
}

vec4 GetPlaneCoeffs( vec3 a, vec3 b, vec3 c )
{
    vec3 n = normalize( cross(a-b, b-c) );
    float d = -dot( n, a );
    
    return vec4( n, d );
}


ClosestSurface GetCarBodyClosestSurface( const in vec3 vCarPos )
{
    ClosestSurface closest;
    
#ifdef SHOW_PHYSICS_SHAPE
    vec4 vSpheres[6];
    vSpheres[0] = vec4(0.7, 0.7, 1.5, 0.5 );
    vSpheres[1] = vec4(-0.7, 0.7, 1.5, 0.5 );
    vSpheres[2] = vec4(0.7, 0.7, -1.5, 0.5 );
    vSpheres[3] = vec4(-0.7, 0.7, -1.5, 0.5 );
    vSpheres[4] = vec4(0.5, 1.0, 0.0, 0.7 );
    vSpheres[5] = vec4(-0.5, 1.0, 0.0, 0.7 );    

    closest.surface.vUVW = vCarPos.xyz;
    closest.surface.fId = MAT_CAR_BODY;
    closest.fDist = kFarClip;
    
    for (int s=0; s<6; s++)
    {
        float d = length( vCarPos.xyz - vSpheres[s].xyz) - vSpheres[s].w;
        
        closest.fDist = min( closest.fDist, d );
    }
#else    
    
    vec3 vAbsBodyPos = vCarPos - vec3(0.0, 0.3, 0.0);

    vec3 vBodyPos = vAbsBodyPos;
    vBodyPos.x = abs(vBodyPos.x);
    closest.surface.vUVW = vAbsBodyPos.xyz;
    closest.surface.fId = MAT_CAR_BODY;
   
    //closest.fDist = SdBox( vBodyPos - vec3(0.0, 0.5, 0.0), vec3(0.7, 0.2, 1.5)-0.2)  -0.2;
    
    vec3 vFrontWheelPos = -vec3( 0.0, -0.1, -1.25 ) ;
    vec3 vRearWheelPos = -vec3( 0.0, -0.1, 1.25 ) ;

    vec3 vWheelPos = vBodyPos - vFrontWheelPos;
    
    float fSeparation = (vFrontWheelPos.z - vRearWheelPos.z) * 0.5;
    vWheelPos.z = abs(vWheelPos.z + fSeparation ) - fSeparation;
    vWheelPos.x = abs(vWheelPos.x) - 0.8;
    
    float fWheelArchDist = GetWheelArchDist( vWheelPos );
    

    
    float fBodyBaseDist = kFarClip;

    {
        float fTopDist = PlaneDist( vBodyPos, normalize(vec3(0.0, 1.0, 0.0)), 0.8 );
        float fFrontDist = PlaneDist( vBodyPos, normalize(vec3(0.0, 0.2, 1.0)), 1.9 );    
        float fSideDist = PlaneDist( vBodyPos, normalize(vec3(1.0, -0.1, 0.0)), 0.85 );
        float fBaseDist = PlaneDist( vBodyPos, normalize(vec3(0.0, -1.0, 0.0)), -0.1 );
        float fBackDist = PlaneDist( vBodyPos, normalize(vec3(0.0, 0.0, -1.0)), 2.0 );

        float fX = abs(vBodyPos.x);
        fTopDist += fX * fX * 0.05;
        fFrontDist += fX * fX * 0.1;
        
        float fSmooth = 0.2;

        float fFrontTopDist = CarBodyMax( fTopDist, fFrontDist, 0.2 );

        fBodyBaseDist = fFrontTopDist;
        fBodyBaseDist = CarBodyMax( fBodyBaseDist, fSideDist, 0.3 );

        float fBaseBackDist = CarBodyMax( fBaseDist, fBackDist, 0.1 );
        fBodyBaseDist = CarBodyMax( fBodyBaseDist, fBaseBackDist, 0.1 );
    }

    fBodyBaseDist = WheelArchCombine( fBodyBaseDist, fWheelArchDist );   
            
    float fBodyTopDist = kFarClip;

    {
        float fTopDist = PlaneDist( vBodyPos, normalize(vec3(0.0, 1.0, 0.0)), 1.3 );
        float fFrontDist = PlaneDist( vBodyPos, normalize(vec3(0.0, 1.0, 0.7)), 1.1 );    
        float fSideDist = PlaneDist( vBodyPos, normalize(vec3(1.0, 0.4, 0.0)), 1.03 );
        float fBaseDist = PlaneDist( vBodyPos, normalize(vec3(0.0, -1.0, 0.0)), -0.7);
        float fBackDist = PlaneDist( vBodyPos, normalize(vec3(0.0, 0.0, -1.0)), 0.55 );

        float fX = abs(vBodyPos.x);
        fTopDist += fX * fX * 0.1;
        
        float fFrontTopDist = CarBodyMax( fTopDist, fFrontDist, 0.1 );

        fBodyTopDist = fFrontTopDist;
        fBodyTopDist = CarBodyMax( fBodyTopDist, fSideDist, 0.1 );

        float fBaseBackDist = CarBodyMax( fBaseDist, fBackDist, 0.1 );
        fBodyTopDist = CarBodyMax( fBodyTopDist, fBaseBackDist, 0.1 );
    }
        
    //fBodyTopDist = SdBox( vBodyPos - vec3(0.0, 0.5, -0.5), vec3(0.7, 0.5, 1.0)-0.2)  -0.2;
    
    //float fDistDome = SdSphere( vBodyPos - vec3(0.0, -0.5, -0.5), 2.0 );
    //float fDistBase = -vBodyPos.y;
    
    //closest.fDist = max( fDistDome, fDistBase );
    
    closest.fDist = fBodyBaseDist;
    
    closest.fDist = smin( closest.fDist, fBodyTopDist, 0.1);
    
#ifndef FAST_VERSION    
    float fRearSpace = SdBox( vBodyPos - vec3(0.0, 0.8, -1.3), vec3(0.7, 0.35, 0.65) - 0.05) - 0.05 ;
    
    fRearSpace = -min(-fRearSpace, -(fWheelArchDist + 0.02) );
    
    if( fRearSpace < -closest.fDist )
    {
        closest.fDist = -fRearSpace;
        closest.surface.fId = MAT_REAR;
    }
    
    
    ClosestSurface mirrorClosest;
    vec3 vMirrorDomain = vBodyPos - vec3(0.875, 0.9, 0.55);
    vMirrorDomain.z += vMirrorDomain.x * 0.1;
    mirrorClosest.fDist = SdBox( vMirrorDomain, vec3(0.125, 0.1, 0.06)-0.05)  -0.05;
    mirrorClosest.surface.vUVW = vBodyPos.xyz - vec3(0.5);
    mirrorClosest.surface.fId = MAT_CAR_BODY;    
    if ( mirrorClosest.fDist < -vMirrorDomain.z )
    {                
        if ( mirrorClosest.fDist < -0.01 )
        {
            mirrorClosest.surface.fId = MAT_CHROME;    
        }
        
        mirrorClosest.fDist = -vMirrorDomain.z;        
    }
    
    closest = ClosestSurfaceUnion( closest, mirrorClosest );

    
    /*ClosestSurface grillClosest;
    vec3 vGrillDomain = vBodyPos - vec3(0.0, 0.55, 1.85);
    vGrillDomain.z += vGrillDomain.y * 0.2;
    float fGrillDist = UdRoundBox( vGrillDomain, vec3(0.85, 0.05, 0.0), 0.1);
    if ( fGrillDist < closest.fDist )
    {
        closest.surface.fId = MAT_GRILL;
    }*/
    
    /*ClosestSurface lightClosest;
    vec3 vLightDomain = vBodyPos - vec3(0.5, 0.5, 2.0);
    if( vBodyPos.z < 0.5 )
    {
        vLightDomain = vBodyPos - vec3(0.3, 1.5, -0.2);
    }
    lightClosest.fDist = length(vLightDomain) - 0.15;
    float fFrontDist = length(vLightDomain + vec3(0.0, 0.0, 0.52)) - 0.5;
    lightClosest.fDist = -min( -lightClosest.fDist, -fFrontDist );
    lightClosest.surface.vUVW = vAbsBodyPos.xyz;
    lightClosest.surface.fId = MAT_CHROME; 

    closest = ClosestSurfaceUnion( closest, lightClosest );*/
    
#endif    
#endif
    return closest;
}

float g_fWheelR = 0.45;
float g_fWheelW = 0.25;
ClosestSurface GetWheelClosestSurface( vec3 vPos )
{   
    float theta = atan( vPos.z, vPos.y );
    float r = length( vPos.zy );    
    float x = vPos.x;
        
    float fr = r * ( 1.0 / g_fWheelR );
    
    if( fr < 0.5 )
    {
        x += 0.01 * clamp((0.5 - fr) * 30.0, 0.0, 1.0);
        
        if( fr < 0.3 )
        {
            float unitr = fr / 0.3;
            x = x + sqrt(1.0 - unitr * unitr) * 0.05;
            //x = x + 0.01;
        }    
    }
    else
    {
#ifndef FAST_VERSION    
        
        float fX = x * (1.0 / g_fWheelW);
        float tread = sin(theta * 15.0 + abs(fX) * 4.0);
        
        float treadThickness = 1.0 - clamp( 0.9 - fX * fX * 0.3, 0.0, 1.0 );
        
        r = -min( -r, -(r + abs(tread) * treadThickness * 0.05 + 0.025));
#endif
    }
    
    float fRound = 0.1;
    
    float fWheelR = g_fWheelR - fRound;
    float fWheelW = g_fWheelW - fRound;       
    
    vec2 rx = vec2( r,x );

    ClosestSurface closest;
    closest.surface.fId = MAT_WHEEL;
    closest.surface.vUVW = vPos.yzx;
    closest.fDist = length( max( abs(rx) - vec2(fWheelR, fWheelW), 0.0)) - fRound;
        
    return closest;
}

ClosestSurface GetVehicleClosestSurface( const in VehicleState vehicleState, const vec3 vPos )
{
    ClosestSurface closest;
    
    /*
    float fCullDist = length( vPos - vVehPos );
    if ( fCullDist > 3.5 ) 
    {
        closest.fDist = fCullDist - 1.0;
        closest.surface.fId = 0.0;
        closest.surface.vUVW = vec3(0.0);
        return closest;
    }
    */        
    
    
    vec3 vLocalPos = vehicleState.mRot * (vPos - vehicleState.vPos);
    
    
    //closest.fDist = 10000.0;
    //closest.surface.fId = 0.0;
    //closest.surface.vUVW = vec3(0.0);    
    closest = GetCarBodyClosestSurface( vLocalPos );
    
    vec3 vWheelPos0 = vec3( -0.9, -0.1, 1.25 );
    vec3 vWheelPos1 = vec3(  0.9, -0.1, 1.25 );
    vec3 vWheelPos2 = vec3( -0.9, -0.1, -1.25 );
    vec3 vWheelPos3 = vec3(  0.9, -0.1, -1.25 );        
        
    
    vec3 vWheelOrigin;
    vec4 vWheelState;
    vec4 vWheelSC;

    if ( vLocalPos.z > 0.0 )
    {
        if ( vLocalPos.x < 0.0 )
        {
            vWheelOrigin = vWheelPos0;
            vWheelState = vehicleState.vWheelState0;
            vWheelSC = vehicleState.vWheelSC0;
        }
        else
        {
            vWheelOrigin = vWheelPos1;
            vWheelState = vehicleState.vWheelState1;
            vWheelSC = vehicleState.vWheelSC1;
        }
    }
    else
    {
        if ( vLocalPos.x < 0.0 )
        {
            vWheelOrigin = vWheelPos2;
            vWheelState = vehicleState.vWheelState2;
            vWheelSC = vehicleState.vWheelSC2;
        }
        else
        {
            vWheelOrigin = vWheelPos3;
            vWheelState = vehicleState.vWheelState3;
            vWheelSC = vehicleState.vWheelSC3;
        }
    }
    
    vec3 vWheelPos = vWheelOrigin;
    float fWheelSide = sign(vWheelOrigin.x);
    
    vWheelPos.y -= vWheelState.z - g_fWheelR;
    vec3 vWheelLocalPos = vWheelPos - vLocalPos;
    vWheelLocalPos = RotY( vWheelLocalPos, vWheelSC.xy );        
    vWheelLocalPos = RotX( vWheelLocalPos, vWheelSC.zw );    
    vWheelLocalPos.x *= -fWheelSide;
    closest = ClosestSurfaceUnion( closest, GetWheelClosestSurface( vWheelLocalPos ) );
    
#ifndef FAST_VERSION    
    vec3 vAxleOrigin = vWheelOrigin;
    vAxleOrigin.x = 0.0;
    vAxleOrigin.y = 0.25;
    vec3 vAxleEnd = vWheelPos;
    vAxleEnd.x = 0.9 * fWheelSide;
    float cDist0 = SdCapsule(vLocalPos, vAxleOrigin, vAxleEnd, 0.05, 0.05);
    if( cDist0 < closest.fDist )
    {
        closest.surface.fId = MAT_AXLE;
        closest.fDist = cDist0;
    }
    
    float fSuspensionTop = 0.6;
    
    vec3 vSuspensionOrigin = vWheelOrigin;
    vSuspensionOrigin.x -= 0.4 * fWheelSide;
    vSuspensionOrigin.y = fSuspensionTop;
    //vSuspensionOrigin.z *= 0.9;

    vec3 vSuspensionDomain = vLocalPos - vSuspensionOrigin;
    vSuspensionDomain.z = abs(vSuspensionDomain.z) - 0.1;    
    
    vec3 vSuspensionEnd = vec3(0.03 * fWheelSide, -fSuspensionTop + (vWheelPos.y - vWheelOrigin.y) * 0.8, 0.0);
    //vec3 vSuspensionEnd = vWheelPos;
    //vSuspensionEnd.x = 0.5 * fWheelSide;
    //vSuspensionEnd.y += 0.05;
    //vec3 vSuspensionDomain = vLocalPos - vSuspensionOrigin;
    float cDist1 = SdCapsule(vSuspensionDomain, vec3(0.0), vSuspensionEnd, 0.05, 0.05);
    if( cDist1 < closest.fDist )
    {
        closest.surface.fId = MAT_SUSPENSION;
        closest.fDist = cDist1;
        closest.surface.vUVW = vSuspensionDomain;
        closest.surface.vUVW.y = closest.surface.vUVW.y / vSuspensionEnd.y;
    }
#endif 
    
    return closest;
}



ClosestSurface GetSceneClosestSurface( const in SceneState sceneState, const vec3 vPos )
{    
    ClosestSurface closest;
    
    ClosestSurfaceInit( closest, MAT_TERRAIN, vec3( 0.0 ) );
        
    ClosestSurface terrainClosest = GetEnvironmentClosestSurface( vPos );
    ClosestSurface vehicleClosest = GetVehicleClosestSurface( sceneState.vehicleState, vPos );
    closest = ClosestSurfaceUnion( terrainClosest, vehicleClosest );
    
    return closest;
}

vec3 GetSceneNormal( const in SceneState sceneState, const in vec3 vPos )
{
    const float fDelta = 0.0005;

    vec3 vDir1 = vec3( 1.0, -1.0, -1.0);
    vec3 vDir2 = vec3(-1.0, -1.0,  1.0);
    vec3 vDir3 = vec3(-1.0,  1.0, -1.0);
    vec3 vDir4 = vec3( 1.0,  1.0,  1.0);
    
    vec3 vOffset1 = vDir1 * fDelta;
    vec3 vOffset2 = vDir2 * fDelta;
    vec3 vOffset3 = vDir3 * fDelta;
    vec3 vOffset4 = vDir4 * fDelta;

    ClosestSurface c1 = GetSceneClosestSurface( sceneState, vPos + vOffset1 );
    ClosestSurface c2 = GetSceneClosestSurface( sceneState, vPos + vOffset2 );
    ClosestSurface c3 = GetSceneClosestSurface( sceneState, vPos + vOffset3 );
    ClosestSurface c4 = GetSceneClosestSurface( sceneState, vPos + vOffset4 );
    
    vec3 vNormal = vDir1 * c1.fDist + vDir2 * c2.fDist + vDir3 * c3.fDist + vDir4 * c4.fDist;   
        
    return normalize( vNormal );
}

void TraceScene( const in SceneState sceneState, out C_Intersection outIntersection, const in vec3 vOrigin, const in vec3 vDir )
{   
    vec3 vPos = vec3(0.0);
    
    float t = 0.1;
    const int kRaymarchMaxIter = 64;
    for(int i=0; i<kRaymarchMaxIter; i++)
    {
        float fClosestDist = GetSceneClosestSurface( sceneState, vOrigin + vDir * t ).fDist;
        t += fClosestDist;
        if(abs(fClosestDist) < 0.01)
        {
            break;
        }       
        if(t > kFarClip)
        {
            t = kFarClip;
            break;
        }
    }
    
    outIntersection.fDist = t;
    outIntersection.vPos = vOrigin + vDir * t;
    
    if( t >= kFarClip )
    {
        outIntersection.surface.fId = 0.0;
        outIntersection.surface.vUVW = vec3( 0.0 );
        outIntersection.vNormal = vec3(0.0, 1.0, 0.0);
    }
    else
    {
        outIntersection.vNormal = GetSceneNormal( sceneState, outIntersection.vPos );
        outIntersection.surface = GetSceneClosestSurface( sceneState, outIntersection.vPos ).surface;
    }
}

#define SOFT_SHADOW

float TraceShadow( const in SceneState sceneState, const in vec3 vOrigin, const in vec3 vDir, const in float fDist )
{
#ifndef SOFT_SHADOW
    C_Intersection shadowIntersection;
    TraceScene(sceneState, shadowIntersection, vOrigin, vDir);
    if(shadowIntersection.fDist < fDist) 
    {
        return 0.0;     
    }
    
    return 1.0;
#else   
    #define kShadowIter 32
    #define kShadowFalloff 10.0
    float fShadow = 1.0;
    float t = 0.01;
    float fDelta = 2.5 / float(kShadowIter);
    for(int i=0; i<kShadowIter; i++)
    {
        vec4 vUnused;
        ClosestSurface closest = GetSceneClosestSurface( sceneState, vOrigin + vDir * t );
        
        fShadow = min( fShadow, kShadowFalloff * closest.fDist / t );
        
        t = t + fDelta;
    }

    return clamp(fShadow, 0.0, 1.0);
#endif
}

// AMBIENT OCCLUSION

float GetAmbientOcclusion( const in SceneState sceneState, const in vec3 vPos, const in vec3 vNormal )
{
    float fAmbientOcclusion = 0.0;
#ifndef FAST_VERSION    
    
    float fStep = 0.1;
    float fDist = 0.0;
    for(int i=0; i<=5; i++)
    {
        fDist += fStep;
        
        vec4 vUnused;
        
        ClosestSurface closest = GetSceneClosestSurface( sceneState, vPos + vNormal * fDist );
        
        float fAmount = (fDist - closest.fDist);
        
        fAmbientOcclusion += max(0.0, fAmount * fDist );                                  
    }
#endif  
    return max(1.0 - fAmbientOcclusion, 0.0);
}

// LIGHTING

void AddLighting(inout vec3 vDiffuseLight, inout vec3 vSpecularLight, const in vec3 vViewDir, const in vec3 vLightDir, const in vec3 vNormal, const in float fSmoothness, const in vec3 vLightColour)
{
    float fNDotL = clamp(dot(vLightDir, vNormal), 0.0, 1.0);
    vec3 vHalfAngle = normalize(-vViewDir + vLightDir);
    float fNDotH = clamp(dot(vHalfAngle, vNormal), 0.0, 1.0);
    
    vDiffuseLight += vLightColour * fNDotL;
    
    float fSpecularPower = exp2(4.0 + 6.0 * fSmoothness);
    float fSpecularIntensity = (fSpecularPower + 2.0) * 0.125;
    vSpecularLight += vLightColour * fSpecularIntensity * clamp(pow(fNDotH, fSpecularPower), 0.0, 1.0) * fNDotL;
}

void AddPointLight(const in SceneState sceneState, inout vec3 vDiffuseLight, inout vec3 vSpecularLight, const in vec3 vViewDir, const in vec3 vPos, const in vec3 vNormal, const in float fSmoothness, const in vec3 vLightPos, const in vec3 vLightColour)
{
    vec3 vToLight = vLightPos - vPos;   
    float fDistance2 = dot(vToLight, vToLight);
    float fAttenuation = 100.0 / (fDistance2);
    vec3 vLightDir = normalize(vToLight);
    
    vec3 vShadowRayDir = vLightDir;
    vec3 vShadowRayOrigin = vPos + vShadowRayDir * 0.01;
    float fShadowFactor = TraceShadow( sceneState, vShadowRayOrigin, vShadowRayDir, length(vToLight));
    
    AddLighting(vDiffuseLight, vSpecularLight, vViewDir, vLightDir, vNormal, fSmoothness, vLightColour * fShadowFactor * fAttenuation);
}

void AddPointLightFlare(inout vec3 vEmissiveGlow, const in vec3 vRayOrigin, const in vec3 vRayDir, const in float fIntersectDistance, const in vec3 vLightPos, const in vec3 vLightColour)
{
    vec3 vToLight = vLightPos - vRayOrigin;
    float fPointDot = dot(vToLight, vRayDir);
    fPointDot = clamp(fPointDot, 0.0, fIntersectDistance);

    vec3 vClosestPoint = vRayOrigin + vRayDir * fPointDot;
    float fDist = length(vClosestPoint - vLightPos);
    vEmissiveGlow += sqrt(vLightColour * 0.05 / (fDist * fDist));
}

void AddDirectionalLight(const in SceneState sceneState, inout vec3 vDiffuseLight, inout vec3 vSpecularLight, const in vec3 vViewDir, const in vec3 vPos, const in vec3 vNormal, const in float fSmoothness, const in vec3 vLightDir, const in vec3 vLightColour)
{   
    float fAttenuation = 1.0;

    vec3 vShadowRayDir = -vLightDir;
    vec3 vShadowRayOrigin = vPos + vShadowRayDir * 0.01;
    float fShadowFactor = TraceShadow(sceneState, vShadowRayOrigin, vShadowRayDir, 10.0);
    
    AddLighting(vDiffuseLight, vSpecularLight, vViewDir, -vLightDir, vNormal, fSmoothness, vLightColour * fShadowFactor * fAttenuation);    
}

void AddDirectionalLightFlareToFog(inout vec3 vFogColour, const in vec3 vRayDir, const in vec3 vLightDir, const in vec3 vLightColour)
{
    float fDirDot = clamp(dot(-vLightDir, vRayDir) * 0.5 + 0.5, 0.0, 1.0);
    float kSpreadPower = 5.0;
    vFogColour += vLightColour * pow(fDirDot, kSpreadPower) * 0.5;
}

// SCENE MATERIALS

vec3 ProjectedTexture( vec3 pos, vec3 normal )
{
    vec3 vWeights = normal * normal;
    vec3 col = vec3(0.0);
    vec3 sample;
    sample = texture2D( iChannel1, pos.xz ).rgb;
    col += sample * sample * vWeights.y;
    sample = texture2D( iChannel1, pos.xy ).rgb;
    col += sample * sample * vWeights.z;
    sample = texture2D( iChannel1, pos.yz ).rgb;
    col += sample * sample * vWeights.x;
    col /= vWeights.x + vWeights.y + vWeights.z;
    return col;    
}

void GetSurfaceInfo( out vec3 vOutAlbedo, out float fOutR0, out float fOutSmoothness, out vec3 vOutBumpNormal, const in C_Intersection intersection )
{
    vOutBumpNormal = intersection.vNormal;
    
    /*if(false)
    {
        vOutAlbedo = vec3(0.1);
        fOutSmoothness = 0.0;           
        fOutR0 = 0.02;   
        return;
    }*/
        
    
    float fRange = 20.0;
    vec2 vPrevFragOffset = intersection.vPos.xz - g_TyreTrackOrigin;
    vec2 vPrevUV = ( (vPrevFragOffset / fRange) + 1.0 ) / 2.0;

    vec4 vTrackSample = texture2D( iChannel3, vPrevUV );            
    
    if ( vPrevUV.x < 0.0 || vPrevUV.x >=1.0 || vPrevUV.y < 0.0 || vPrevUV.y >= 1.0 )
    {
        vTrackSample = vec4(0.0);
    }
    
    fOutR0 = 0.02;

    if(intersection.surface.fId == MAT_TERRAIN)
    {
        vec2 vUV = intersection.surface.vUVW.xy * 0.1;
        vOutAlbedo = texture2D(iChannel1, vUV).rgb;
        
        #ifndef FAST_VERSION
        float fBumpScale = 1.0;
        
        vec2 vRes = iChannelResolution[0].xy;
        vec2 vDU = vec2(1.0, 0.0) / vRes;
        vec2 vDV = vec2(0.0, 1.0) / vRes;
        
        float fSampleW = texture2D(iChannel1, vUV - vDU).r;
        float fSampleE = texture2D(iChannel1, vUV + vDU).r;
        float fSampleN = texture2D(iChannel1, vUV - vDV).r;
        float fSampleS = texture2D(iChannel1, vUV + vDV).r;
        
        vec3 vNormalDelta = vec3(0.0);
        vNormalDelta.x += 
            ( fSampleW * fSampleW
             - fSampleE * fSampleE) * fBumpScale;
        vNormalDelta.z += 
            (fSampleN * fSampleN
             - fSampleS * fSampleS) * fBumpScale;
        
        vOutBumpNormal = normalize(vOutBumpNormal + vNormalDelta);
        #endif
        
        vOutAlbedo = vOutAlbedo * vOutAlbedo;   
        fOutSmoothness = vOutAlbedo.r * 0.3;
                
        //if(false)
        {       
            // Tyre tracks
            float fDepth = vTrackSample.x * (1.0 + vTrackSample.y);
            
            //vec3 vTex2 = texture2D(iChannel2, vUV).rgb;
            vec3 vTex2 = mix( vOutAlbedo, vec3( 0.9, 0.3, 0.01 ), 0.5);
            vOutAlbedo = mix( vOutAlbedo, vTex2, fDepth );
            
            //vOutAlbedo *= 1.0 - 0.2 * vTrackSample.r;
            
            vOutAlbedo *= 1.0 - 0.6 * vTrackSample.g;
            fOutSmoothness = mix( fOutSmoothness, fOutSmoothness * 0.75 + 0.25, fDepth );                        
        }  
    }
    else if(intersection.surface.fId == MAT_BLACK_PLASTIC)
    {
        vec2 vUV = intersection.surface.vUVW.xy;
        vOutAlbedo = texture2D(iChannel1, vUV).rgb;
        vOutAlbedo = vOutAlbedo * vOutAlbedo;   
        vOutAlbedo *= 0.01;
        fOutSmoothness = 0.1;//vOutAlbedo.r;            
        
        vec3 vDirt = (texture2D(iChannel1, intersection.surface.vUVW.zy).rgb + texture2D(iChannel1, intersection.surface.vUVW.xy).rgb) * 0.5;
        float fDirt = vDirt.r;
        
        float fMix = clamp( fDirt - intersection.surface.vUVW.y * 2.5 + 0.8, 0.0, 1.0 );
        
        vDirt = vDirt * vDirt * 0.1;

        vOutAlbedo = mix( vOutAlbedo, vDirt, fMix );
        fOutSmoothness = mix( fOutSmoothness, 0.01, fMix );        

    }
    else if(intersection.surface.fId == MAT_CHROME)
    {
        vOutAlbedo = vec3(0.1);
        fOutSmoothness = 1.0;           
        fOutR0 = 0.9;
    }
    else if(intersection.surface.fId == MAT_CAR_BODY)
    {
        vOutAlbedo = vec3(0.0, 0.0, 1.0);
        
        float fAbsX = abs( intersection.surface.vUVW.x );

        fOutSmoothness = 1.0;
        
        float fStripe = abs(fAbsX - (0.15));
        fStripe = smoothstep( 0.1 + 0.01, 0.1 - 0.01, fStripe);

        vOutAlbedo = mix( vOutAlbedo, vec3(1.0, 1.0, 1.0), fStripe);

        if ( intersection.surface.vUVW.y < 0.85 )
        {
            float fLine = abs(intersection.surface.vUVW.z - 0.7);
            fLine = min( fLine, abs(intersection.surface.vUVW.z + 0.6) );
            fLine = min( fLine, abs(fAbsX - 0.65) );
            fLine = min( fLine, abs(intersection.surface.vUVW.y - 0.2) );
            fLine = clamp( (fLine - 0.005) / 0.01, 0.0, 1.0);
            vOutAlbedo *= fLine;
            fOutR0 *= fLine;
            fOutSmoothness *= fLine;

        }
        
        if(fAbsX > 0.92 )
        {
            vOutAlbedo = vec3(0.02, 0.02, 0.02);
            fOutSmoothness = 0.2;
        }
                
        if( intersection.surface.vUVW.y > 0.85 && intersection.surface.vUVW.y < 1.2)
        {
            bool bFront = (intersection.surface.vUVW.z + intersection.surface.vUVW.y * 1.25 )  > 1.6;
            bool bRear = (intersection.surface.vUVW.z)  < -0.45;
            bool bSide = (fAbsX +intersection.surface.vUVW.y * 0.3) > 0.9;
            
            if ( !(bFront && bSide) && !(bRear && bSide))
            {
                vOutAlbedo = vec3(0.0, 0.0, 0.0);
                fOutR0 = 0.02;
                fOutSmoothness = 0.9;
            }
        }
        
        vec3 vGrillDomain = intersection.surface.vUVW - vec3(0.0, 0.55, 1.85);
        float fGrillDist = UdRoundBox( vGrillDomain, vec3(0.85, 0.05, 0.0), 0.1);
        if ( fGrillDist < 0.0 )
        {
            vOutAlbedo = vec3(0.0, 0.0, 0.0);
            fOutR0 = 0.02;
        }        

        vec3 vLightDomain = intersection.surface.vUVW;
        vLightDomain.x = abs( vLightDomain.x );
        vLightDomain -= vec3(0.6, 0.56, 1.85);
        float fLightDist = UdRoundBox( vLightDomain, vec3(0.1, 0.04, 0.5), 0.05);
        if ( fLightDist < 0.0 )
        {
            vOutAlbedo = vec3(0.5);
            fOutR0 = 1.0;
            fOutSmoothness = 0.8;
        }
        
        
        vec3 vDirt = (texture2D(iChannel1, intersection.surface.vUVW.zy).rgb + texture2D(iChannel1, intersection.surface.vUVW.xy).rgb) * 0.5;
        float fDirt = vDirt.r;
        
        float fMix = clamp( fDirt - intersection.surface.vUVW.y * 1.5 + 0.8, 0.0, 1.0 );
        
        vDirt = vDirt * vDirt * 0.1;

        vOutAlbedo = mix( vOutAlbedo, vDirt, fMix );
        fOutR0 = mix( fOutR0, 0.01, fMix );
        fOutSmoothness = mix( fOutSmoothness, 0.01, fMix );
        
        //vOutR0 = vec3(0.7, 0.5, 0.02);
        //vOutAlbedo = vOutR0 * 0.01;
        
    }
    else if(intersection.surface.fId == MAT_WHEEL)
    {
        vec2 vUV = intersection.surface.vUVW.xy;
        vOutAlbedo = texture2D(iChannel2, vUV).rgb;
        vOutAlbedo = vOutAlbedo * vOutAlbedo;   
        vOutAlbedo *= 0.01;
        float len = length(vUV);
        float fR = len * (1.0 / g_fWheelR);
        if ( fR < 0.5 )
        {
            fOutSmoothness = 1.0;        
            fOutR0 = 1.0;
        }
        else
        {
            fOutSmoothness = 0.1;
        }

        vec3 vDirt = (texture2D(iChannel1, intersection.surface.vUVW.zy).rgb + texture2D(iChannel1, intersection.surface.vUVW.xy).rgb) * 0.5;
        
        float fDirt = vDirt.r;
        fDirt = sqrt(fDirt);
        
        float fMix = clamp( fDirt - (1.0 - fR) * 1.0 + 0.8, 0.0, 1.0 );
        
        vDirt = vDirt * vDirt * 0.1;

        vOutAlbedo = mix( vOutAlbedo, vDirt, fMix );
        fOutR0 = mix( fOutR0, 0.01, fMix );
        fOutSmoothness = mix( fOutSmoothness, 0.01, fMix );
        
    }
    else if(intersection.surface.fId == MAT_SUSPENSION )
    {
        vOutAlbedo = vec3(0.1);
        fOutSmoothness = 1.0;           
        fOutR0 = 0.9;

        float fY = intersection.surface.vUVW.y;
        
        float fAngle = atan(intersection.surface.vUVW.x, intersection.surface.vUVW.y);        
        fAngle -= fY * 30.0;
        float fFAngle = fract(fAngle / (3.1415 * 2.0));
        if ( fFAngle < 0.5 )
        {
            fOutR0 = 0.0;
            vOutAlbedo = vec3(0.0);            
        }

        vec3 vDirt = (texture2D(iChannel1, intersection.surface.vUVW.zy).rgb + texture2D(iChannel1, intersection.surface.vUVW.xy).rgb) * 0.5;
        
        float fDirt = vDirt.r;
        fDirt = sqrt(fDirt);
        
        float fMix = clamp( fDirt + 0.1, 0.0, 1.0 );
        
        vDirt = vDirt * vDirt * 0.1;

        vOutAlbedo = mix( vOutAlbedo, vDirt, fMix );
        fOutR0 = mix( fOutR0, 0.01, fMix );
        fOutSmoothness = mix( fOutSmoothness, 0.01, fMix );
        
    }
    else if(intersection.surface.fId == MAT_WOOD)
    {
        vec2 vUV = intersection.surface.vUVW.xz * 0.1;
        vOutAlbedo = texture2D(iChannel2, vUV).rgb;
        vOutAlbedo = vOutAlbedo * vOutAlbedo;
        fOutSmoothness = vOutAlbedo.r;
        
        vOutAlbedo *= 1.0 - vTrackSample.g * 0.6;
    }
    
    //vOutR0 = vec3(0.9);
    //fOutSmoothness = 0.5;
}

vec3 vSkyTop = vec3(0.1, 0.5, 0.8);
vec3 vSkyBottom = vec3(0.02, 0.04, 0.06);

vec3 GetSkyColour( const in vec3 vDir )
{
    vec3 vResult = vec3(0.0);
    
    vResult = mix(vSkyBottom, vSkyTop, abs(vDir.y)) * 30.0;
    
#ifndef FAST_VERSION    
    float fCloud = texture2D( iChannel1, vDir.xz * 0.01 / vDir.y ).r;
    fCloud = clamp( fCloud * fCloud * 3.0 - 1.0, 0.0, 1.0);
    vResult = mix( vResult, vec3(8.0), fCloud );
#endif 
    
    return vResult; 
}

float GetFogFactor(const in float fDist)
{
    float kFogDensity = 0.0025;
    return exp(fDist * -kFogDensity);   
}

vec3 GetFogColour(const in vec3 vDir)
{
    return (vSkyBottom) * 25.0;
}


vec3 vSunLightColour = vec3(1.0, 0.9, 0.6) * 10.0;
vec3 vSunLightDir = normalize(vec3(0.4, -0.3, -0.5));
    
void ApplyAtmosphere(inout vec3 vColour, const in float fDist, const in vec3 vRayOrigin, const in vec3 vRayDir)
{       
    float fFogFactor = GetFogFactor(fDist);
    vec3 vFogColour = GetFogColour(vRayDir);            
    AddDirectionalLightFlareToFog(vFogColour, vRayDir, vSunLightDir, vSunLightColour);
    
    vec3 vGlow = vec3(0.0);
    //AddPointLightFlare(vGlow, vRayOrigin, vRayDir, fDist, vLightPos, vLightColour);                   
    
    vColour = mix(vFogColour, vColour, fFogFactor) + vGlow; 
}

// TRACING LOOP

    
vec3 GetSceneColour( in vec3 vRayOrigin,  in vec3 vRayDir, out float fDepth )
{
    vec3 vColour = vec3(0.0);
    float fRemaining = 1.0;
    
    SceneState sceneState = SetupSceneState();
    
    fDepth = 0.0;
    float fFirstTrace = 1.0;
    
#ifndef FAST_VERSION    
    for(int i=0; i<RAYTRACE_COUNT; i++)
#endif
    {   
        // result = reflection
        //vColour = vec3(0.0);
        //vRemaining = vec3(1.0);
        
        float fCurrRemaining = fRemaining;
        float fShouldApply = 1.0;
        
        C_Intersection intersection;                
        TraceScene( sceneState, intersection, vRayOrigin, vRayDir );

        float fHitDepth = intersection.fDist;
        if(intersection.surface.fId >= MAT_FIRST_VEHICLE)
        {
            fHitDepth = -fHitDepth;
        }
        
        fDepth = ( fFirstTrace > 0.0 ) ? fHitDepth : fDepth;
        fFirstTrace = 0.0;
        
        vec3 vResult = vec3(0.0);
        float fBlendFactor = 0.0;
                        
        if(intersection.surface.fId == 0.0)
        {
            fBlendFactor = 1.0;
            fShouldApply = 0.0;
        }
        else
        {       
            vec3 vAlbedo;
            float fR0;
            float fSmoothness;
            vec3 vBumpNormal;
            
            GetSurfaceInfo( vAlbedo, fR0, fSmoothness, vBumpNormal, intersection );         
        
            vec3 vDiffuseLight = vec3(0.0);
            vec3 vSpecularLight = vec3(0.0);

            //AddPointLight(sceneState, vDiffuseLight, vSpecularLight, vRayDir, intersection.vPos, vBumpNormal, fSmoothness, vLightPos, vLightColour);                              

            AddDirectionalLight(sceneState, vDiffuseLight, vSpecularLight, vRayDir, intersection.vPos, vBumpNormal, fSmoothness, vSunLightDir, vSunLightColour);                                
            
            vDiffuseLight += 0.2 * GetAmbientOcclusion(sceneState, intersection.vPos, vBumpNormal);

            float fSmoothFactor = pow(fSmoothness, 5.0);
            float fFresnel = fR0 + (1.0 - fR0) * pow(1.0 - dot(-vBumpNormal, vRayDir), 5.0) * fSmoothFactor;
            
            vResult = mix(vAlbedo * vDiffuseLight, vSpecularLight, fFresnel);       
            fBlendFactor = fFresnel;
            
            ApplyAtmosphere(vResult, intersection.fDist, vRayOrigin, vRayDir);      
            
            fRemaining *= fBlendFactor;         
            
            #ifndef FAST_VERSION
            float fRoughness = 1.0 - fSmoothness;
            fRoughness = pow(fRoughness, 5.0);
            vBumpNormal = normalize(vBumpNormal + g_pixelRandom * (fRoughness) * 0.5);
            #endif
            vRayDir = normalize(reflect(vRayDir, vBumpNormal));
            vRayOrigin = intersection.vPos;// + intersection.vNormal;            
        }           

        vColour += vResult * fCurrRemaining * fShouldApply;

#ifndef FAST_VERSION    
        if( fRemaining < 0.05 )
        {
            break;
        }               
#endif        
    }

    vec3 vSkyColor = GetSkyColour(vRayDir);
    
    ApplyAtmosphere(vSkyColor, kFarClip, vRayOrigin, vRayDir);      
    
    vColour += vSkyColor * fRemaining;
    
    return vColour;
}
