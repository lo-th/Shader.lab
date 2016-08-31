
// ------------------ channel define
// 0_# bufferFULL_rallyA #_0
// 1_# bufferFULL_rallyC #_1
// ------------------


// Shader Rally - @P_Malin

// (Uncomment FAST_VERSION in "Buf C" for a framerate boost)

// Physics Hackery using the new mutipass things.

// WASD to drive. Space = brake
// G toggle gravity
// V toggle wheels (vehicle forces)
// . and , flip car

// Restart shader to reset car

// I'll add more soon (including a fast version of the rendering code maybe :)

// Image shader - final postprocessing

// https://www.shadertoy.com/view/XdcGWS


#define MOTION_BLUR_TAPS 32

vec2 addrVehicle = vec2( 0.0, 0.0 );

vec2 offsetVehicleParam0 = vec2( 0.0, 0.0 );

vec2 offsetVehicleBody = vec2( 1.0, 0.0 );
vec2 offsetBodyPos = vec2( 0.0, 0.0 );
vec2 offsetBodyRot = vec2( 1.0, 0.0 );
vec2 offsetBodyMom = vec2( 2.0, 0.0 );
vec2 offsetBodyAngMom = vec2( 3.0, 0.0 );

vec2 offsetVehicleWheel0 = vec2( 5.0, 0.0 );
vec2 offsetVehicleWheel1 = vec2( 6.0, 0.0 );
vec2 offsetVehicleWheel2 = vec2( 7.0, 0.0 );
vec2 offsetVehicleWheel3 = vec2( 8.0, 0.0 );

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


vec3 ApplyPostFX( const in vec2 vUV, const in vec3 vInput );

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

float GetCoC( float fDistance, float fPlaneInFocus )
{
    // http://http.developer.nvidia.com/GPUGems/gpugems_ch23.html

    float fAperture = 0.03;
    float fFocalLength = 1.0;
    
    return abs(fAperture * (fFocalLength * (fDistance - fPlaneInFocus)) /
          (fDistance * (fPlaneInFocus - fFocalLength)));  
}


// Random

#define MOD2 vec2(4.438975,3.972973)

float Hash( float p ) 
{
    // https://www.shadertoy.com/view/4djSRW - Dave Hoskins
    vec2 p2 = fract(vec2(p) * MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
    return fract(p2.x * p2.y);    
}


float fGolden = 3.141592 * (3.0 - sqrt(5.0));

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 vUV = fragCoord.xy / iResolution.xy;

    vec4 vSample = texture2D( iChannel1, vUV ).rgba;
    
    float fDepth = abs(vSample.w);
    
    vec3 vCameraPos = LoadVec3( addrCamera + offsetCameraPos );
    vec3 vCameraTarget = LoadVec3( addrCamera + offsetCameraTarget );
    
    vec3 vRayOrigin = vCameraPos;
    vec3 vRayDir = GetCameraRayDir( GetWindowCoord(vUV), vCameraPos, vCameraTarget );
        
    vec3 vWorldPos = vRayOrigin + vRayDir * fDepth;
    
    vec3 vPrevCameraPos = LoadVec3( addrPrevCamera + offsetCameraPos );
    vec3 vPrevCameraTarget = LoadVec3( addrPrevCamera + offsetCameraTarget );
    vec2 vPrevWindow = GetCameraWindowCoord( vWorldPos, vPrevCameraPos, vPrevCameraTarget );
    vec2 vPrevUV = GetUVFromWindowCoord(vPrevWindow);
    
    if( vSample.a < 0.0 ) 
    {
        vPrevUV = vUV;
    }
        
    vec3 vResult = vec3(0.0);
    
    float fTot = 0.0;
    
    float fPlaneInFocus = length(vCameraPos - vCameraTarget);
    
    float fCoC = GetCoC( abs(fDepth), fPlaneInFocus );
    
    float r = 1.0;
    vec2 vangle = vec2(0.0,fCoC); // Start angle
    
    vResult.rgb = vSample.rgb * fCoC;
    fTot += fCoC;
    
    float fMotionBlurTaps = float(MOTION_BLUR_TAPS);
    
    float f = 0.0;
    float fIndex = 0.0;
    for(int i=1; i<MOTION_BLUR_TAPS; i++)
    {
        vec2 vTapUV = mix( vUV, vPrevUV, f - 0.5 );
                
        float fRand = Hash( iGlobalTime + fIndex + vUV.x + vUV.y * 12.345);
        
        // http://blog.marmakoide.org/?p=1
        
        float fTheta = fRand * fGolden * fMotionBlurTaps;
        float fRadius = fCoC * sqrt( fRand * fMotionBlurTaps ) / sqrt( fMotionBlurTaps );        
        
        //float fTheta = fIndex * fGolden;
        //float fRadius = fCoC * sqrt( fIndex ) / sqrt( fMotionBlurTaps );
        
        vTapUV += vec2( sin(fTheta), cos(fTheta) ) * fRadius;
        
        vec4 vTapSample = texture2D( iChannel1, vTapUV ).rgba;
        if( sign(vTapSample.a) == sign(vSample.a) )
        {
            float fCurrCoC = GetCoC( abs(vTapSample.a), fPlaneInFocus );
            
            float fWeight = fCurrCoC + 1.0;
            
            vResult += vTapSample.rgb * fWeight;
            fTot += fWeight;
        }
        f += 1.0 / fMotionBlurTaps;
        fIndex += 1.0;
    }
    vResult /= fTot;
        
    vec3 vFinal = ApplyPostFX( vUV, vResult );

    // Draw depth
    //vFinal = vec3(1.0) / abs(vSample.a);    
    
    fragColor = vec4(vFinal, 1.0);
}

// POSTFX

vec3 ApplyVignetting( const in vec2 vUV, const in vec3 vInput )
{
    vec2 vOffset = (vUV - 0.5) * sqrt(2.0);
    
    float fDist = dot(vOffset, vOffset);
    
    const float kStrength = 0.75;
    
    float fShade = mix( 1.0, 1.0 - kStrength, fDist );  

    return vInput * fShade;
}

vec3 ApplyTonemap( const in vec3 vLinear )
{
    const float kExposure = 1.0;

#if 0
    return 1.0 - exp2(vLinear * -kExposure);    
#else    
    const float kWhitePoint = 2.0;
    return log(1.0 + vLinear * kExposure * 0.75) / log(1.0 + kWhitePoint);    
#endif    
}

vec3 ApplyGamma( const in vec3 vLinear )
{
    const float kGamma = 2.2;

    return pow(vLinear, vec3(1.0/kGamma));  
}

vec3 ApplyPostFX( const in vec2 vUV, const in vec3 vInput )
{
    vec3 vTemp = ApplyVignetting( vUV, vInput );    
    
    vTemp = ApplyTonemap(vTemp);
    
    return ApplyGamma(vTemp);       
}