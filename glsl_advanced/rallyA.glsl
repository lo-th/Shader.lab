

// ------------------ channel define
// 0_# buffer64_rallyA #_0
// ------------------

// Shader Rally - @P_Malin

// Physics Hackery using the new mutipass things.

// WASD to drive. Space = brake
// G toggle gravity
// V toggle wheels (vehicle forces)
// . and , flip car

// Simulation Shader

//#define ENABLE_DEBUG_FORCES
#define ENABLE_GRAVITY_TOGGLE

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

/////////////////////////
// Constants

float PI = acos(-1.0);

/////////////////////////
// Storage

vec4 LoadVec4( in vec2 vAddr )
{
    vec2 vUV = (vAddr + 0.5) / iChannelResolution[0].xy;
    return texture2D( iChannel0, vUV, -16.0 );
}

vec3 LoadVec3( in vec2 vAddr )
{
    return LoadVec4( vAddr ).xyz;
}

float IsInside( vec2 p, vec2 c ) { vec2 d = abs(p-0.5-c) - 0.5; return -max(d.x,d.y); }

void StoreVec4( in vec2 vAddr, in vec4 vValue, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( IsInside( fragCoord, vAddr ) > 0.0 ) ? vValue : fragColor;
}

void StoreVec3( in vec2 vAddr, in vec3 vValue, inout vec4 fragColor, in vec2 fragCoord )
{
    StoreVec4( vAddr, vec4( vValue, 0.0 ), fragColor, fragCoord);
}


/////////////////////////

// Keyboard 


// Keyboard constants definition
const float KEY_SPACE = 32.5/256.0;
const float KEY_LEFT  = 37.5/256.0;
const float KEY_UP    = 38.5/256.0;
const float KEY_RIGHT = 39.5/256.0;
const float KEY_DOWN  = 40.5/256.0;
const float KEY_A     = 65.5/256.0;
const float KEY_B     = 66.5/256.0;
const float KEY_C     = 67.5/256.0;
const float KEY_D     = 68.5/256.0;
const float KEY_E     = 69.5/256.0;
const float KEY_F     = 70.5/256.0;
const float KEY_G     = 71.5/256.0;
const float KEY_H     = 72.5/256.0;
const float KEY_I     = 73.5/256.0;
const float KEY_J     = 74.5/256.0;
const float KEY_K     = 75.5/256.0;
const float KEY_L     = 76.5/256.0;
const float KEY_M     = 77.5/256.0;
const float KEY_N     = 78.5/256.0;
const float KEY_O     = 79.5/256.0;
const float KEY_P     = 80.5/256.0;
const float KEY_Q     = 81.5/256.0;
const float KEY_R     = 82.5/256.0;
const float KEY_S     = 83.5/256.0;
const float KEY_T     = 84.5/256.0;
const float KEY_U     = 85.5/256.0;
const float KEY_V     = 86.5/256.0;
const float KEY_W     = 87.5/256.0;
const float KEY_X     = 88.5/256.0;
const float KEY_Y     = 89.5/256.0;
const float KEY_Z     = 90.5/256.0;
const float KEY_COMMA = 188.5/256.0;
const float KEY_PER   = 190.5/256.0;

bool KeyIsPressed(float key)
{
    return texture2D( iChannel1, vec2(key, 0.0) ).x > 0.0;
}

bool KeyIsToggled(float key)
{
    return texture2D( iChannel1, vec2(key, 1.0) ).x > 0.0;
}

/////////////////////////
// Rotation

vec2 Rotate( const in vec2 vPos, const in float t )
{
    float s = sin(t);
    float c = cos(t);
    
    return vec2( c * vPos.x + s * vPos.y, -s * vPos.x + c * vPos.y);
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


/////////////////////////
// Vec

vec3 Vec3Parallel( vec3 x, vec3 n )
{
    float d = dot( x, n );
    
    return x - n * d;    
}

vec3 Vec3Perp( vec3 x, vec3 n )
{
    return x - Vec3Parallel( x, n );
}

/////////////////////////
// Quaternions

vec4 QuatMul(const in vec4 lhs, const in vec4 rhs) 
{
      return vec4( lhs.y*rhs.z - lhs.z*rhs.y + lhs.x*rhs.w + lhs.w*rhs.x,
                   lhs.z*rhs.x - lhs.x*rhs.z + lhs.y*rhs.w + lhs.w*rhs.y,
                   lhs.x*rhs.y - lhs.y*rhs.x + lhs.z*rhs.w + lhs.w*rhs.z,
                   lhs.w*rhs.w - lhs.x*rhs.x - lhs.y*rhs.y - lhs.z*rhs.z);
}

vec4 QuatFromAxisAngle( vec3 vAxis, float fAngle )
{
    return vec4( normalize(vAxis) * sin(fAngle), cos(fAngle) );    
}

vec4 QuatFromVec3( vec3 vRot )
{
    float l = length( vRot );
    if ( l <= 0.0 )
    {
        return vec4( 0.0, 0.0, 0.0, 1.0 );
    }
    return QuatFromAxisAngle( vRot, l );
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

vec3 QuatMul( vec3 v, vec4 q )
{
    // TODO Validate vs other quat code
    vec3 t = 2.0 * cross(q.xyz, v);
    return v + q.w * t + cross(q.xyz, t);
}

vec3 ObjToWorld( vec3 v, mat3 m )
{
    return v * m;
}

vec3 WorldToObj( vec3 v, mat3 m )
{
    return m * v;
}


float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}


// RAYTRACE

float kFarClip=10.0;

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
    closest.fDist = 10000.0;
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
    
///////////////////
// Random

#define MOD2 vec2(4.438975,3.972973)
#define MOD3 vec3(.1031,.11369,.13787)
#define MOD4 vec4(.1031,.11369,.13787, .09987)

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
    for( int i=0; i<3; i++)
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
#define MAT_CAR_BODY 4.0
#define MAT_CAR_WINDOW 3.0
#define MAT_CHROME 3.0
#define MAT_GRILL 2.0
#define MAT_BLACK_PLASTIC 2.0
#define MAT_AXLE 2.0
#define MAT_WHEEL 5.0    
#define MAT_REAR 2.0
#define MAT_SUSPENSION 6.0    
#define MAT_WOOD 7.0

float GetTerrainDistance( const vec3 vPos )
{    
    float fbm = FBM( vPos.xz * vec2(0.5, 1.0), 0.5 );
    float fTerrainHeight = fbm * fbm;
    fTerrainHeight = fTerrainHeight * (sin(vPos.x * 0.1) + 1.0) * 0.5 + vPos.y + 3.0;    
    
    //float h = 1.0 - exp(-abs(vPos.x + 15.0) * 0.01);
    
    //fTerrainHeight += sin(vPos.x * 0.05) * 5.0 * h;
    //fTerrainHeight += sin(vPos.z * 0.05) * 5.0 * h;

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
    
    closest.fDist = max( closest.fDist, -fCylDist);
    
    return closest;
}

ClosestSurface GetEnvironmentClosestSurface( const vec3 vPos )
{
    ClosestSurface terrainClosest;
    terrainClosest.surface.fId = MAT_TERRAIN;
    terrainClosest.surface.vUVW = vec3(vPos.xz,0.0);
    terrainClosest.fDist = GetTerrainDistance( vPos );

    //return terrainClosest;
    
    float fRepeat = 100.0;
    vec3 vRampDomain = vPos - vec3(-15.0, -3.0, 0.0);
    float fRampUnitZ = vRampDomain.z / fRepeat + 0.5;
    float fRampSeed = floor( fRampUnitZ );
    vRampDomain.z = (fract(fRampUnitZ) - 0.5) * fRepeat;
    ClosestSurface rampClosest = GetRampClosestSurface( vRampDomain, fRampSeed );

    return ClosestSurfaceUnion( terrainClosest, rampClosest );
}

ClosestSurface GetSceneClosestSurface( const vec3 vPos )
{    
    ClosestSurface closest = GetEnvironmentClosestSurface( vPos );
    
    return closest;
}

vec3 GetSceneNormal( const in vec3 vPos )
{
    const float fDelta = 0.0001;

    vec3 vDir1 = vec3( 1.0, -1.0, -1.0);
    vec3 vDir2 = vec3(-1.0, -1.0,  1.0);
    vec3 vDir3 = vec3(-1.0,  1.0, -1.0);
    vec3 vDir4 = vec3( 1.0,  1.0,  1.0);
    
    vec3 vOffset1 = vDir1 * fDelta;
    vec3 vOffset2 = vDir2 * fDelta;
    vec3 vOffset3 = vDir3 * fDelta;
    vec3 vOffset4 = vDir4 * fDelta;

    ClosestSurface c1 = GetSceneClosestSurface( vPos + vOffset1 );
    ClosestSurface c2 = GetSceneClosestSurface( vPos + vOffset2 );
    ClosestSurface c3 = GetSceneClosestSurface( vPos + vOffset3 );
    ClosestSurface c4 = GetSceneClosestSurface( vPos + vOffset4 );
    
    vec3 vNormal = vDir1 * c1.fDist + vDir2 * c2.fDist + vDir3 * c3.fDist + vDir4 * c4.fDist;   
        
    return normalize( vNormal );
}

void TraceScene( out C_Intersection outIntersection, const in vec3 vOrigin, const in vec3 vDir )
{   
    vec3 vPos = vec3(0.0);
    
    float t = 0.1;
    const int kRaymarchMaxIter = 32;
    for(int i=0; i<kRaymarchMaxIter; i++)
    {
        float fClosestDist = GetSceneClosestSurface( vOrigin + vDir * t ).fDist;
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
        outIntersection.vNormal = GetSceneNormal( outIntersection.vPos );
        outIntersection.surface = GetSceneClosestSurface( outIntersection.vPos ).surface;
    }
}

///////////////////

struct Body
{
    // Persistent State
    vec3 vPos;
    vec4 qRot;
    vec3 vMomentum;
    vec3 vAngularMomentum;
    
    // Derived
    mat3 mRot;
    
    // Constant
    float fMass;
    float fIT; // Hacky scalar for inertia tensor
    
    // Per frame
    vec3 vForce;
    vec3 vTorque;
};

void BodyLoadState( out Body body, vec2 addr )
{
    body.vPos = LoadVec3( addr + offsetBodyPos );
    body.qRot = LoadVec4( addr + offsetBodyRot );
    body.vMomentum = LoadVec3( addr + offsetBodyMom );
    body.vAngularMomentum = LoadVec3( addr + offsetBodyAngMom );
}

void BodyStoreState( vec2 addr, const in Body body, inout vec4 fragColor, in vec2 fragCoord )
{
    StoreVec3( addr + offsetBodyPos, body.vPos, fragColor, fragCoord );
    StoreVec4( addr + offsetBodyRot, body.qRot, fragColor, fragCoord );
    StoreVec3( addr + offsetBodyMom, body.vMomentum, fragColor, fragCoord );
    StoreVec3( addr + offsetBodyAngMom, body.vAngularMomentum, fragColor, fragCoord );
}

void BodyResetForFrame( inout Body body )
{
    body.vForce = vec3(0.0);
    body.vTorque = vec3(0.0);
}

void BodyCalculateDerivedState( inout Body body )
{
    body.mRot = QuatToMat3( body.qRot );    
}

void BodyApplyGravity( inout Body body, float dT )
{
    float fAccel_MpS = -9.81;
    body.vForce.y += body.fMass * fAccel_MpS;
}

void BodyIntegrate( inout Body body, float dT )
{
#ifdef ENABLE_GRAVITY_TOGGLE    
    if( !KeyIsToggled( KEY_G ) )
#endif // ENABLE_GRAVITY_TOGGLE        
    {
        BodyApplyGravity( body, dT );
    }
    
    body.vMomentum += body.vForce * dT;
    body.vAngularMomentum += body.vTorque * dT;
    
    vec3 vVel = body.vMomentum / body.fMass;
    vec3 vAngVel = body.vAngularMomentum / body.fIT;

    body.vPos += vVel * dT;
    vec4 qAngDelta = QuatFromVec3( vAngVel * dT );
    body.qRot = QuatMul( qAngDelta, body.qRot );

    body.qRot = normalize( body.qRot );
}

void BodyApplyForce( inout Body body, vec3 vPos, vec3 vForce )
{    
    body.vForce += vForce;
    body.vTorque += cross(vPos - body.vPos, vForce);     
}

void BodyApplyImpulse( inout Body body, vec3 vPos, vec3 vImpulse )
{    
    body.vMomentum += vImpulse;
    body.vAngularMomentum += cross(vPos - body.vPos, vImpulse);     
}

vec3 BodyPointVelocity( const in Body body, vec3 vWorldPos )
{
    vec3 vVel = body.vMomentum / body.fMass;
    vec3 vAngVel = body.vAngularMomentum / body.fIT;
    
    return vVel + cross( vAngVel, vWorldPos - body.vPos );
}


void BodyApplyDebugForces( inout Body body )
{
#ifdef ENABLE_DEBUG_FORCES    
    float debugForceMag = 20000.0;
    //if ( KeyIsPressed( KEY_LEFT ) )
    if ( key[0] < -0.2 )
    {
        vec3 vForcePos = body.vPos;
        vec3 vForce = vec3(-debugForceMag, 0.0, 0.0);
        BodyApplyForce( body, vForcePos, vForce );
    }
    //if ( KeyIsPressed( KEY_RIGHT ) )
    if ( key[0] > 0.2 )
    {
        vec3 vForcePos = body.vPos;
        vec3 vForce = vec3(debugForceMag, 0.0, 0.0);
        BodyApplyForce( body, vForcePos, vForce );
    }
    //if ( KeyIsPressed( KEY_UP ) )
    if ( key[1] < -0.2 )
    {
        vec3 vForcePos = body.vPos;
        vec3 vForce = vec3(0.0, 0.0, debugForceMag);
        BodyApplyForce( body, vForcePos, vForce );
    }
    //if ( KeyIsPressed( KEY_DOWN ) )
    if ( key[1] > 0.2 )
    {
        vec3 vForcePos = body.vPos;
        vec3 vForce = vec3(0.0, 0.0, -debugForceMag);
        BodyApplyForce( body, vForcePos, vForce );
    }
#endif // ENABLE_DEBUG_FORCES                
    
    float debugTorqueMag = 4000.0;
    if ( KeyIsPressed( KEY_COMMA ) )
    {
        vec3 vForcePos = body.vPos;
        vec3 vForce = vec3(0.0, -debugTorqueMag, 0.0);
        vForcePos.x += 2.0;
        BodyApplyForce( body, vForcePos, vForce );
        //vForcePos.x -= 4.0;
        //vForce = -vForce;
        //BodyApplyForce( body, vForcePos, vForce );
    }
    if ( KeyIsPressed( KEY_PER ) )
    {
        vec3 vForcePos = body.vPos;
        vec3 vForce = vec3(0.0, debugTorqueMag, 0.0);
        vForcePos.x += 2.0;
        BodyApplyForce( body, vForcePos, vForce );
        //vForcePos.x -= 4.0;
        //vForce = -vForce;
        //BodyApplyForce( body, vForcePos, vForce );
    }        
}

void BodyCollideShapeSphere( inout Body body, vec3 vSphereOrigin, float fSphereRadius, float dT )
{    
    vec3 vSphereWorld = ObjToWorld( vSphereOrigin, body.mRot) + body.vPos;
    
    ClosestSurface closest = GetSceneClosestSurface( vSphereWorld );
    
    float fDepth = fSphereRadius - closest.fDist;
    
    if ( fDepth < 0.0 )
        return;
    
    vec3 vNormal = GetSceneNormal( vSphereWorld );
    vec3 vHitPos = vSphereWorld - vNormal * closest.fDist;    
    vec3 vPointVel = BodyPointVelocity( body, vHitPos );
    
    float fDot = dot( vPointVel, vNormal );
    
    if( fDot >= 0.0 )
        return;
    
    float fRestitution = 0.5;
    
    vec3 vRelativePos = (vHitPos - body.vPos);
    float fDenom = (1.0/body.fMass );
    float fCr = dot( cross( cross( vRelativePos, vNormal ), vRelativePos), vNormal);
    fDenom += fCr / body.fIT;
    
    float fImpulse = -((1.0 + fRestitution) * fDot) / fDenom;
    
    fImpulse += fDepth / fDenom;
    
    vec3 vImpulse = vNormal * fImpulse;
    
    vec3 vFriction = Vec3Perp( vPointVel, vNormal ) * body.fMass;
    float fLimit = 100000.0;
    float fMag = length(vFriction);
    if( fMag > 0.0 )
    {           
        vFriction = normalize( vFriction );

        fMag = min( fMag, fLimit );
        vFriction = vFriction * fMag;

        //BodyApplyForce( body, vHitPos, vFriction );
        vImpulse += vFriction * dT;        
    }
    else
    {
        vFriction = vec3(0.0);
    }
    
    BodyApplyImpulse( body, vHitPos, vImpulse );
}
    
void BodyCollide( inout Body body, float dT )
{
    BodyCollideShapeSphere( body, vec3( 0.7, 0.7,  1.5), 0.5, dT );
    BodyCollideShapeSphere( body, vec3(-0.7, 0.7,  1.5), 0.5, dT );
    BodyCollideShapeSphere( body, vec3( 0.7, 0.7, -1.5), 0.5, dT );
    BodyCollideShapeSphere( body, vec3(-0.7, 0.7, -1.5), 0.5, dT );
    BodyCollideShapeSphere( body, vec3( 0.5, 1.0,  0.0), 0.7, dT );
    BodyCollideShapeSphere( body, vec3(-0.5, 1.0,  0.0), 0.7, dT );
}


/////////////////////////
struct Engine
{
    float fAngularMomentum;
};

/////////////////////////

struct Wheel
{
    // Persistent State
    float fSteer;
    float fRotation;
    float fExtension;
    float fAngularVelocity;
    
    // Results
    vec2 vContactPos;
    float fOnGround;
    float fSkid;    
    
    // Constant
    vec3 vBodyPos;    
    float fRadius;
    bool bIsDriven;
    bool bSteering;   
};
    
void WheelLoadState( out Wheel wheel, vec2 addr )
{    
    vec4 vState = LoadVec4( addr + offsetWheelState );
    
    wheel.fSteer = vState.x;
    wheel.fRotation = vState.y;
    wheel.fExtension = vState.z;
    wheel.fAngularVelocity = vState.w;
    
    // output data
    wheel.vContactPos = vec2( 0.0 );
    wheel.fOnGround = 0.0;
    wheel.fSkid = 0.0;
}
    
void WheelStoreState( vec2 addr, const in Wheel wheel, inout vec4 fragColor, in vec2 fragCoord )
{
    vec4 vState = vec4( wheel.fSteer, wheel.fRotation, wheel.fExtension, wheel.fAngularVelocity );
    StoreVec4( addr + offsetWheelState, vState, fragColor, fragCoord );

    vec4 vState2 = vec4( wheel.vContactPos.xy, wheel.fOnGround, wheel.fSkid );
    StoreVec4( addr + offsetWheelContactState , vState2, fragColor, fragCoord );
}

C_Intersection WheelTrace( vec3 vPos, vec3 vDir, Wheel wheel )
{
    C_Intersection intersection;
    TraceScene( intersection, vPos - vDir * wheel.fRadius, vDir );
    
    return intersection;
}


float ClampTyreForce( inout vec3 vVel, float fLimit )
{
    // Square clamp
    //vVelWheel.x = clamp( vVelWheel.x, -fLimit, fLimit);
    //vVelWheel.z = clamp( vVelWheel.z, -fLimit, fLimit);
    float fSkid = 0.0;
    
    // Circluar clamp
    float fMag = length(vVel);
    if( fMag > 0.0 )
    {           
        vVel = normalize( vVel );
    }
    else
    {
        vVel = vec3(0.0);
    }
    if ( fMag > fLimit )
    {
        fSkid = fMag - fLimit;
        fMag = fLimit;        
    }
    vVel = vVel * fMag;
    
    return fSkid;
}

void WheelUpdate( inout Engine engine, inout Body body, inout Wheel wheel, float dT )
{
    vec3 vWheelWorld = ObjToWorld( wheel.vBodyPos, body.mRot) + body.vPos;
    vec3 vWheelDown = ObjToWorld( vec3(0.0, -1.0, 0.0), body.mRot);
    
    float fSuspensionTravel = 0.25;
    C_Intersection intersection = WheelTrace( vWheelWorld, vWheelDown, wheel );
    
    float fTravel = clamp( intersection.fDist - wheel.fRadius, 0.0, fSuspensionTravel);
        
    // Apply suspension force
    // Simple spring-damper
    // (No anti-roll bar)
    float fWheelExt = fTravel / fSuspensionTravel;

    wheel.fOnGround = 1.0 - fWheelExt;
    
    float delta = (wheel.fExtension - fTravel) / fSuspensionTravel;

    float fForce = (1.0 - fWheelExt) * 5000.0 + delta * 15000.0;

    vec3 vForce = Vec3Perp( intersection.vNormal, vWheelDown) * fForce;
    //BodyApplyForce( body, vWheelWorld, vForce );                

    // Apply Tyre force

    // Super simplification of wheel / drivetrain / engine / tyre contact
    // ignoring engine / wheel angular momentum       

    // Figure out how contact patch is moving in world space
    vec3 vIntersectWorld = intersection.vPos;
    wheel.vContactPos = vIntersectWorld.xz;
    vec3 vVelWorld = BodyPointVelocity( body, vIntersectWorld );

    // Transform to body space
    vec3 vVelBody = WorldToObj( vVelWorld, body.mRot );

    // Transform to wheel space
    vec3 vVelWheel = RotY( vVelBody, wheel.fSteer );

    float fWScale = wheel.fRadius;

    float fWheelMOI = 20.0;
    if ( wheel.bIsDriven )
    {
        fWheelMOI = 30.0;

        // consta-torque mega engine
        //if( KeyIsPressed( KEY_W ) )
        if( key[1] < -0.2 )
        {
            wheel.fAngularVelocity += 2.0;
        }        

        //if( KeyIsPressed( KEY_S ) )
        if( key[1] > 0.2 )
        {
            wheel.fAngularVelocity -= 2.0;
        }        
    }

    //if( KeyIsPressed( KEY_SPACE ) )
    if( key[4] > 0.2 )
    {
        wheel.fAngularVelocity = 0.0; // insta-grip super brake
    }        

    vVelWheel.z -= wheel.fAngularVelocity * fWScale;

    vec3 vForceWheel = vVelWheel * body.fMass;

    // Hacked 'slip angle'
    //vForceWheel.x /=  1.0 + abs(wheel.fAngularVelocity * fWScale) * 0.1;

    float fLimit = 9000.0 * (1.0 - fWheelExt);

    wheel.fSkid = ClampTyreForce( vForceWheel, fLimit );    
    
    //vVelWheel.z += wheel.fAngularVelocity * fWScale;
    vec3 vForceBody = RotY( vForceWheel, -wheel.fSteer );

    // Apply force back on wheel

    wheel.fAngularVelocity += ((vForceWheel.z / fWScale) / fWheelMOI) * dT;

    vec3 vForceWorld = ObjToWorld( vForceBody, body.mRot );

    // cancel in normal dir
    vForceWorld = Vec3Parallel( vForceWorld, intersection.vNormal );

    vForce -= vForceWorld;
    //BodyApplyForce( body, vIntersectWorld, -vForceWorld );        
    
    BodyApplyForce( body, vIntersectWorld, vForce );        

    wheel.fExtension = fTravel;
    wheel.fRotation += wheel.fAngularVelocity * dT;    
}

void WheelUpdateSteerAngle( float fSteerAngle, inout Wheel wheel )
{
    if ( !wheel.bSteering )
    {
        wheel.fSteer = 0.0;
    }
    else
    {
        // figure out turning circle if wheel was central
        float turningCircle = wheel.vBodyPos.z / tan( fSteerAngle );
        float wheelTurningCircle = turningCircle - wheel.vBodyPos.x;
        wheel.fSteer = atan( abs(wheel.vBodyPos.z) / wheelTurningCircle);
    }
}

struct Vechicle
{
    Body body;    
    Engine engine;
    Wheel wheel[4];
    
    float fSteerAngle;
};

void VehicleLoadState( out Vechicle vehicle, vec2 addr )
{    
    BodyLoadState( vehicle.body, addr + offsetVehicleBody );
    WheelLoadState( vehicle.wheel[0], addr + offsetVehicleWheel0 );
    WheelLoadState( vehicle.wheel[1], addr + offsetVehicleWheel1 );
    WheelLoadState( vehicle.wheel[2], addr + offsetVehicleWheel2 );
    WheelLoadState( vehicle.wheel[3], addr + offsetVehicleWheel3 );
    
    vec4 vParam0;
    vParam0 = LoadVec4( addr + offsetVehicleParam0 );
    vehicle.fSteerAngle = vParam0.x;
}

void VehicleStoreState( vec2 addr, const in Vechicle vehicle, inout vec4 fragColor, in vec2 fragCoord )
{
    BodyStoreState( addr + offsetVehicleBody, vehicle.body, fragColor, fragCoord );
    WheelStoreState( addr + offsetVehicleWheel0, vehicle.wheel[0], fragColor, fragCoord );
    WheelStoreState( addr + offsetVehicleWheel1, vehicle.wheel[1], fragColor, fragCoord );
    WheelStoreState( addr + offsetVehicleWheel2, vehicle.wheel[2], fragColor, fragCoord );
    WheelStoreState( addr + offsetVehicleWheel3, vehicle.wheel[3], fragColor, fragCoord );

    vec4 vParam0 = vec4( vehicle.fSteerAngle, 0.0, 0.0, 0.0 );
    StoreVec4( addr + offsetVehicleParam0, vParam0, fragColor, fragCoord);
}

void VehicleResetForFrame( inout Vechicle vehicle )
{
    BodyResetForFrame( vehicle.body );
}

void VehicleSetup( inout Vechicle vehicle )
{
    vehicle.body.fMass = 1000.0;
    vehicle.body.fIT = 1000.0;

    vehicle.engine.fAngularMomentum = 0.0; // TODO : Move to state
    
    vehicle.wheel[0].vBodyPos = vec3( -0.9, -0.1, 1.25 );
    vehicle.wheel[1].vBodyPos = vec3(  0.9, -0.1, 1.25 );
    vehicle.wheel[2].vBodyPos = vec3( -0.9, -0.1, -1.25 );
    vehicle.wheel[3].vBodyPos = vec3(  0.9, -0.1, -1.25 );
    
    vehicle.wheel[0].fRadius = 0.45;
    vehicle.wheel[1].fRadius = 0.45;
    vehicle.wheel[2].fRadius = 0.45;
    vehicle.wheel[3].fRadius = 0.45; 
    
    vehicle.wheel[0].bIsDriven = false;
    vehicle.wheel[1].bIsDriven = false;
    vehicle.wheel[2].bIsDriven = true;
    vehicle.wheel[3].bIsDriven = true;    
    
    vehicle.wheel[0].bSteering = true;
    vehicle.wheel[1].bSteering = true;
    vehicle.wheel[2].bSteering = false;
    vehicle.wheel[3].bSteering = false;   
}


struct Camera
{
    vec3 vPos;
    vec3 vTarget;
};

void CameraLoadState( out Camera cam, in vec2 addr )
{
    cam.vPos = LoadVec3( addr + offsetCameraPos );
    cam.vTarget = LoadVec3( addr + offsetCameraTarget );
}

void CameraStoreState( Camera cam, in vec2 addr, inout vec4 fragColor, in vec2 fragCoord )
{
    StoreVec3( addr + offsetCameraPos, cam.vPos, fragColor, fragCoord );
    StoreVec3( addr + offsetCameraTarget, cam.vTarget, fragColor, fragCoord );    
}
    
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if (( fragCoord.x > 13.0 ) || ( fragCoord.y > 3.0 ) )
    {
        fragColor = vec4(0.0);
        return;
    }
    
    
    Vechicle vehicle;
    
    VehicleLoadState( vehicle, addrVehicle );
    VehicleSetup( vehicle );
    VehicleResetForFrame( vehicle );

    if ( iFrame < 1 )
    {        
        vehicle.body.vPos = vec3( 0.0, -2.5, 0.0 );
        vehicle.body.vMomentum = vec3( 0.0 );
        vehicle.body.qRot = vec4( 0.0, 0.0, 0.0, 1.0 );
        vehicle.body.vAngularMomentum = vec3( 0.0, 0.5, 0.0 );        
        
        vehicle.fSteerAngle = 0.0;
    }

    BodyCalculateDerivedState( vehicle.body );
    
    // TODO: dT for steering
    //if ( KeyIsPressed( KEY_A ) )
    if( key[0] < -0.2 )
    {
        vehicle.fSteerAngle += 0.05;
    }    
    //if ( KeyIsPressed( KEY_D ) )
    if( key[0] > 0.2 )
    {
        vehicle.fSteerAngle -= 0.05;
    }    
    
    vehicle.fSteerAngle *= 0.9;
    
    float fSteerAngle = vehicle.fSteerAngle / ( 1.0 + length(vehicle.body.vMomentum) * 0.0001 );
    
    WheelUpdateSteerAngle( fSteerAngle, vehicle.wheel[0] );
    WheelUpdateSteerAngle( fSteerAngle, vehicle.wheel[1] );
    WheelUpdateSteerAngle( fSteerAngle, vehicle.wheel[2] );
    WheelUpdateSteerAngle( fSteerAngle, vehicle.wheel[3] );
    
    float dT = 1.0 / 60.0;

    if ( !KeyIsToggled( KEY_V ) )
    {
        WheelUpdate( vehicle.engine, vehicle.body, vehicle.wheel[0], dT );
        WheelUpdate( vehicle.engine, vehicle.body, vehicle.wheel[1], dT );
        WheelUpdate( vehicle.engine, vehicle.body, vehicle.wheel[2], dT );
        WheelUpdate( vehicle.engine, vehicle.body, vehicle.wheel[3], dT );
    }
    
    BodyApplyDebugForces( vehicle.body );
    BodyCollide( vehicle.body, dT );
    BodyIntegrate( vehicle.body, dT );

    fragColor = vec4( 0.0 );
    
    VehicleStoreState( addrVehicle, vehicle, fragColor, fragCoord );
    
  
    Camera prevCam;
    
    // load old camera data
    CameraLoadState( prevCam, addrCamera );

    // store in addrPrevCamera
    CameraStoreState( prevCam, addrPrevCamera, fragColor, fragCoord );
    
    Camera cam;
    
    vec2 vMouse = iMouse.xy / iResolution.xy;
    float fAngle = (-vMouse.x * 2.0 + 1.0) * 3.14;
    float fDistance = 8.0 - vMouse.y * 6.0;
    
    cam.vTarget = vec3( 0.0, 1.0, 0.0 ) * vehicle.body.mRot + vehicle.body.vPos;
    cam.vPos = vec3( 0.0, 0.0, -fDistance ) * vehicle.body.mRot + vehicle.body.vPos + vec3(0.0, 2.0, 0.0);
    
    cam.vPos -= cam.vTarget;
    cam.vPos = RotY( cam.vPos, fAngle );
    cam.vPos += cam.vTarget;
            
    CameraStoreState( cam, addrCamera, fragColor, fragCoord );
}