
// ------------------ channel define
// 0_# tex09 #_0
// 1_# noise #_1
// ------------------

// https://www.shadertoy.com/view/MsXXWH

// Red Cells - @P_Malin
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// Some red blood cells on an adventure.
// Click the mouse to rotate view.

float kFarClip=1000.0;
float kZRepeat = 5.0;

vec2 GetWindowCoord( const in vec2 vUV );
vec3 GetCameraRayDir( const in vec2 vWindow, const in vec3 vCameraPos, const in vec3 vCameraTarget );
vec3 GetSceneColour( in vec3 vRayOrigin,  in vec3 vRayDir );
vec3 ApplyPostFX( const in vec2 vUV, const in vec3 vInput );



float fPulse = 0.0;
float fDPulse = 0.0;

const float kExposure = 1.5;

const vec3 vLightColour = vec3(1.0, 0.01, 0.005);

vec3 vRimLightColour = vLightColour * 0.5;
vec3 vAmbientLight = vLightColour * 0.05;
vec3 vEmissiveLight = vLightColour * 1.0;
    
float kFogDensity = 0.0075;
vec3 vFogColour = vec3(1.0, 0.05, 0.005) * 0.25 * 10.0;

float GetGlobalTime()
{
    float fStartTime = 90.0;
    return fStartTime + iTime;
}

float GetPulseTime()
{
    float fGlobalTime = GetGlobalTime();
    
    float s= sin(fGlobalTime * 2.0);
    fPulse = s * s;
    fDPulse = cos(fGlobalTime * 2.0);
    return fGlobalTime + fPulse * 0.2;
}

float GetCameraZ()
{
    return GetPulseTime() * 20.0;
}

mat3 SetRot( const in vec3 r )
{
    float a = sin(r.x); float b = cos(r.x); 
    float c = sin(r.y); float d = cos(r.y); 
    float e = sin(r.z); float f = cos(r.z); 

    float ac = a*c;
    float bc = b*c;

    return mat3( d*f,      d*e,       -c,
                 ac*f-b*e, ac*e+b*f, a*d,
                 bc*f+a*e, bc*e-a*f, b*d );
}

vec3 TunnelOffset( float z )
{
    float r = 20.0;
    vec3 vResult = vec3( sin(z * 0.0234)* r, sin(z * 0.034)* r, 0.0 );
    return vResult;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 vUV = fragCoord.xy / iResolution.xy;

    vec2 vMouse = iMouse.xy / iResolution.xy;

    float fCameraZ = GetCameraZ();

    vec3 vCameraPos = vec3(0.0, 0.0, 0.0);
    vCameraPos.z += fCameraZ;
    vCameraPos += TunnelOffset(fCameraZ);
    
    vec3 vCameraTarget = vec3(0.0);

    float fAngle = 0.0;

    if(iMouse.z > 0.0)
    {
        fAngle = vMouse.x * 3.1415 * 2.0;
    }
    
    float fTargetLookahead = 40.0;
    
    float fCameraTargetZ = fCameraZ + fTargetLookahead * cos(fAngle); 
    
    vCameraTarget.z += fCameraTargetZ;
    vCameraTarget += TunnelOffset(fCameraTargetZ);
    
    vCameraTarget.x += sin(fAngle) * fTargetLookahead;

    // camera shake
    vec3 vShake = (textureLod(iChannel0, vec2(GetPulseTime() * 0.05, 0.0), 0.0).rgb * 2.0 - 1.0);
    vCameraTarget += vShake * fDPulse * 0.02 * length(vCameraTarget - vCameraPos);
    
    float fFOV = 0.5;
    
    vec3 vRayOrigin = vCameraPos;   
    vec3 vRayDir = GetCameraRayDir( GetWindowCoord(vUV) * fFOV, vCameraPos, vCameraTarget );
        
    vec3 vResult = GetSceneColour(vRayOrigin, vRayDir);
    
    vec3 vFinal = ApplyPostFX( vUV, vResult );
    
    fragColor = vec4(vFinal, 1.0);
}

// CAMERA

vec2 GetWindowCoord( const in vec2 vUV )
{
    vec2 vWindow = vUV * 2.0 - 1.0;
    vWindow.x *= iResolution.x / iResolution.y;

    return vWindow; 
}

vec3 GetCameraRayDir( const in vec2 vWindow, const in vec3 vCameraPos, const in vec3 vCameraTarget )
{
    vec3 vForward = normalize(vCameraTarget - vCameraPos);
    vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
    vec3 vUp = normalize(cross(vForward, vRight));
                              
    vec3 vDir = normalize(vWindow.x * vRight + vWindow.y * vUp + vForward * 2.0);

    return vDir;
}

// POSTFX

vec3 ApplyVignetting( const in vec2 vUV, const in vec3 vInput )
{
    vec2 vOffset = (vUV - 0.5) * sqrt(2.0);
    
    float fDist = dot(vOffset, vOffset);
    
    const float kStrength = 1.0;
    
    float fShade = mix( 1.0, 1.0 - kStrength, fDist );  

    return vInput * fShade;
}

vec3 ApplyTonemap( const in vec3 vLinear )
{   
    return (1.0 - exp2(vLinear * -kExposure));  
}

vec3 ApplyGamma( const in vec3 vLinear )
{
    const float kGamma = 2.2;

    return pow(vLinear, vec3(1.0/kGamma));  
}

vec3 ApplyPostFX( const in vec2 vUV, const in vec3 vInput )
{
    vec3 vTemp = vInput;
    
    vTemp = ApplyVignetting( vUV, vTemp );  
    
    vTemp = ApplyTonemap(vTemp);
    
    vTemp = ApplyGamma(vTemp);

    return vTemp;
}
    
// RAYTRACE

struct C_Intersection
{
    vec3 vPos;
    float fDist;    
    vec3 vNormal;
    vec3 vUVW;
    float fObjectId;
};

float GetCellShapeDistance( const in vec3 vPos  )
{   
    const vec3 vParam = vec3(1.0, 0.4, 0.4);

    float r = length(vPos.xz);
    vec2 vClosest = vec2(clamp(r - vParam.x, 0.0, vParam.x), vPos.y);
    float unitr = clamp(r / vParam.x, 0.0, 1.0);
    float stepr = 3.0 * unitr * unitr - 2.0 * unitr * unitr * unitr;
    return length(vClosest)-(vParam.y) - stepr * vParam.y * 0.5;

}

vec3 WarpCellDomain( const in vec3 vPos )
{
    vec3 vResult = vPos;
    vResult.y += (vPos.x * vPos.x - vPos.z * vPos.z) * 0.05;
    return vResult;
}

float GetCellDistance( const in vec3 vPos, const in float fSeed )
{
    vec3 vCellPos = vPos;
    
    vec3 vRotSpeed = vec3(0.0, 1.0, 2.0) + vec3(1.0, 2.0, 3.0) * fSeed;
    
    mat3 mCell = SetRot(vRotSpeed * GetGlobalTime());
    
    vCellPos = vCellPos * mCell;
    
    vCellPos = WarpCellDomain(vCellPos);
    
    float fCellDist = GetCellShapeDistance(vCellPos);
    
    return fCellDist;   
}

float GetCellProxyDistance( const in vec3 vPos, const in float fSeed )
{
    return length(vPos) - 1.4;
}

float GetSegment( const in float fPos, const in float fRepeat )
{
    float fTilePos = (fPos / fRepeat) + 0.5;
    return floor(fTilePos);
}

vec3 WarpTunnelDomain( const in vec3 vPos )
{
    return vPos - TunnelOffset(vPos.z);
}

float GetTileSeed( const float fTile )
{
    //return fract(sin(fTile * 123.4567) * 1234.56);    

    // https://www.shadertoy.com/view/4djSRW
    // Hash without Sine - Dave_Hoskins
    #define MOD3 vec3(.1031,.11369,.13787)
    
    float p = fTile;
    
    vec3 p3  = fract(vec3(p) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 GetCellPos( const float fTile, const float fSeed )
{
    float fTileZ = fTile * kZRepeat;
    float fOffsetRadius = 2.0 + fSeed * 1.5;
    
    return vec3( fOffsetRadius * sin(fSeed * 3.14 * 2.0), fOffsetRadius * cos(fSeed * 3.14 * 2.0), fTileZ);
}


float GetSceneDistanceMain( out vec4 vOutUVW_Id, const in vec3 vPos )
{
    vOutUVW_Id = vec4(0.0, 0.0, 0.0, 0.0);
    float fOutDist = kFarClip;
    
    vec3 vCellDomain = vPos;
            
    vCellDomain.z -= GetPulseTime() * 30.0 + fPulse * 0.5;
        
    float fCurrTile = GetSegment(vCellDomain.z, kZRepeat);

    // approximate position of adjacent cell
    {
        float fTileMid = (fCurrTile) * kZRepeat;
        float fTile = fCurrTile;
        if(vCellDomain.z > fTileMid)
        {
            fTile++;
        }
        else
        {
            fTile--;
        }
        float fSeed = GetTileSeed(fTile);

        vec3 vCellPos = GetCellPos(fTile, fSeed);
        vec3 vCurrCellDomain = vCellDomain - vCellPos;

        vec4 vCellUVW_Id = vec4(vCurrCellDomain.xzy, 2.0);
            
        float fCellDist = GetCellProxyDistance( vCurrCellDomain, fSeed );
        
    
        if( fCellDist < fOutDist )
        {
            fOutDist = fCellDist;
            vOutUVW_Id = vCellUVW_Id;
        }
    }
    {
        float fTile = fCurrTile;                
        float fSeed = GetTileSeed(fTile);

        vec3 vCellPos = GetCellPos(fTile, fSeed);
        vec3 vCurrCellDomain = vCellDomain - vCellPos;
            
        vec4 vCellUVW_Id = vec4(vCurrCellDomain.xzy, 2.0);
        
        float fCellDist = GetCellDistance( vCurrCellDomain, fSeed );
        
    
        if( fCellDist < fOutDist )
        {
            fOutDist = fCellDist;
            vOutUVW_Id = vCellUVW_Id;
        }
    }
    
    float fNoiseMag = 0.01;
        
    float s =sin(vPos.z * 0.5) * 0.5 + 0.5;
    float s2 = s * s;
    float fWallDist = 6.0 - length(vPos.xy) + (2.0 - s2 * 2.0);
        
    if( fWallDist < fOutDist )
    {
        fOutDist = fWallDist;
        vOutUVW_Id = vec4(atan(vPos.x, vPos.y) * (2.0 / radians(360.0)), vPos.z * 0.05, 0.0, 1.0);
        
        fNoiseMag = 0.1;
    }
        
    // noise
    float fSample = textureLod(iChannel0, vOutUVW_Id.xy, 0.0).r;
    fOutDist -= fSample * fNoiseMag;
    
    return fOutDist;    
}

float GetSceneDistance( out vec4 vOutUVW_Id, const in vec3 vPosIn )
{
    vec3 vPos = vPosIn;

    vPos = WarpTunnelDomain(vPos);

    return GetSceneDistanceMain(vOutUVW_Id, vPos);
}

vec3 GetSceneNormal(const in vec3 vPos)
{
    const float fDelta = 0.01;

    vec3 vDir1 = vec3( 1.0, -1.0, -1.0);
    vec3 vDir2 = vec3(-1.0, -1.0,  1.0);
    vec3 vDir3 = vec3(-1.0,  1.0, -1.0);
    vec3 vDir4 = vec3( 1.0,  1.0,  1.0);
    
    vec3 vOffset1 = vDir1 * fDelta;
    vec3 vOffset2 = vDir2 * fDelta;
    vec3 vOffset3 = vDir3 * fDelta;
    vec3 vOffset4 = vDir4 * fDelta;

    vec4 vUnused;
    float f1 = GetSceneDistance( vUnused, vPos + vOffset1 );
    float f2 = GetSceneDistance( vUnused, vPos + vOffset2 );
    float f3 = GetSceneDistance( vUnused, vPos + vOffset3 );
    float f4 = GetSceneDistance( vUnused, vPos + vOffset4 );
    
    vec3 vNormal = vDir1 * f1 + vDir2 * f2 + vDir3 * f3 + vDir4 * f4;   
        
    return normalize( vNormal );
}

void TraceScene( out C_Intersection outIntersection, const in vec3 vOrigin, const in vec3 vDir )
{   
    vec4 vUVW_Id = vec4(0.0);       
    vec3 vPos = vec3(0.0);
    
    float t = 0.01;
    const int kRaymarchMaxIter = 96;
    for(int i=0; i<kRaymarchMaxIter; i++)
    {
        vPos = vOrigin + vDir * t;
        float fDist = GetSceneDistance(vUVW_Id, vPos);      
        t += fDist;
        if(abs(fDist) < 0.001)
        {
            break;
        }       
        if(t > 200.0)
        {
            t = kFarClip;
            vPos = vOrigin + vDir * t;
            vUVW_Id = vec4(0.0);
            break;
        }
    }
    
    outIntersection.fDist = t;
    outIntersection.vPos = vPos;
    outIntersection.vNormal = GetSceneNormal(vPos);
    outIntersection.vUVW = vUVW_Id.xyz;
    outIntersection.fObjectId = vUVW_Id.w;
}

// SCENE MATERIALS

vec3 SampleTunnel( vec2 vUV )
{
    // Sample texture twice to remove seam when UV co-ords wrap back to 0
    
    // sample a lower mip for more of a 'subsurface scattering' effect
    float mipBias = 4.0;

    // Sample the texture with UV modulo seam at the bottom
    vec3 vSampleA = texture(iChannel0, vUV, mipBias).rgb;
    
    vec2 vUVb = vUV;
    vUVb.x = fract(vUVb.x + 0.5) - 0.5; // move UV modulo seam
    
    // Sample the texture with UV modulo seam on the left
    vec3 vSampleB = texture(iChannel0, vUVb, mipBias).rgb;
    
    // Blend out seam around zero
    float fBlend = abs( fract( vUVb.x ) * 2.0 - 1.0 );
    
    return mix(vSampleA, vSampleB, fBlend);
}

void GetSurfaceInfo(out vec3 vOutAlbedo, out vec3 vEmissive, const in C_Intersection intersection )
{
    vEmissive = vec3(0.0);
        
    if(intersection.fObjectId == 1.0)
    {
        vOutAlbedo = vec3(1.0, 0.01, 0.005) * 0.5;
        
        vec3 vSample = SampleTunnel( intersection.vUVW.xy );
        
        vSample = vSample * vSample;
        
        vEmissive =  vSample.r * vEmissiveLight;
    }
    else if(intersection.fObjectId == 2.0)
    {
        vOutAlbedo = vec3(1.0, 0.01, 0.005);
    }
}

float GetFogFactor(const in float fDist)
{
    return exp(fDist * -kFogDensity);   
}

vec3 GetFogColour(const in vec3 vDir)
{
    return vFogColour;  
}

void ApplyAtmosphere(inout vec3 vColour, const in float fDist, const in vec3 vRayOrigin, const in vec3 vRayDir)
{       
    float fFogFactor = GetFogFactor(fDist);
    vec3 vFogColour = GetFogColour(vRayDir);            
    vColour = mix(vFogColour, vColour, fFogFactor); 
}

// TRACING LOOP

    
vec3 GetSceneColour( in vec3 vRayOrigin,  in vec3 vRayDir )
{
    vec3 vColour = vec3(0.0);
    
    {   
        C_Intersection intersection;                
        TraceScene( intersection, vRayOrigin, vRayDir );

        {       
            vec3 vAlbedo;
            vec3 vBumpNormal;
            vec3 vEmissive;
            
            GetSurfaceInfo( vAlbedo, vEmissive, intersection );         
                    
            vec3 vDiffuseLight = vAmbientLight;
            
            // rim light
            vDiffuseLight += clamp(dot(vRayDir, intersection.vNormal) + 0.5, 0.0, 1.0) * vRimLightColour;
            
            vColour = vAlbedo * vDiffuseLight + vEmissive;          
            
            ApplyAtmosphere(vColour, intersection.fDist, vRayOrigin, vRayDir);      
            
        }           

    }
    
    return vColour;
}


void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir )
{
    fragRayOri.z *= -1.0;
    fragRayDir.z *= -1.0;
         
    float fCameraZ = GetCameraZ();

    fragRayOri.z += fCameraZ;
    fragRayOri += TunnelOffset(fCameraZ);

    vec3 vResult = GetSceneColour(fragRayOri, fragRayDir);
    
    vec3 vFinal = ApplyPostFX( vec2(0.5), vResult );
    
    fragColor = vec4( vFinal, 1.0 );
}