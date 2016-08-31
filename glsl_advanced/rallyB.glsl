

// ------------------ channel define
// 0_# bufferFULL_rallyA #_0
// 1_# bufferFULL_rallyB #_1
// ------------------
// Tyre track buffer rendering shader

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
// Storage

vec4 LoadVec4( in vec2 vAddr )
{
    vec2 vUV = (vAddr + 0.5) / iChannelResolution[0].xy;
    return texture2D( iChannel0, vUV, -100.0 );
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




void UpdateTyreTracks( vec3 vCamPosPrev, vec3 vCamPos, inout vec4 fragColor, in vec2 fragCoord )
{
    float fRange = 20.0;
    vec2 vPrevOrigin = floor( vCamPosPrev.xz );
    vec2 vCurrOrigin = floor( vCamPos.xz );

    vec2 vFragOffset = ((fragCoord / iResolution.xy) * 2.0 - 1.0) * fRange;
    vec2 vFragWorldPos = vFragOffset + vCurrOrigin;
    
    vec2 vPrevFragOffset = vFragWorldPos - vPrevOrigin;
    vec2 vPrevUV = ( (vPrevFragOffset / fRange) + 1.0 ) / 2.0;
    vec4 vPrevSample = texture2D( iChannel1, vPrevUV );
    
    vec4 vWheelContactState[4];
    vWheelContactState[0] = LoadVec4( addrVehicle + offsetVehicleWheel0 + offsetWheelContactState );
    vWheelContactState[1] = LoadVec4( addrVehicle + offsetVehicleWheel1 + offsetWheelContactState );
    vWheelContactState[2] = LoadVec4( addrVehicle + offsetVehicleWheel2 + offsetWheelContactState );
    vWheelContactState[3] = LoadVec4( addrVehicle + offsetVehicleWheel3 + offsetWheelContactState );
    
    fragColor = vPrevSample;
    
    if ( vPrevUV.x < 0.0 || vPrevUV.x >= 1.0 || vPrevUV.y < 0.0 || vPrevUV.y >= 1.0 )
    {
        fragColor = vec4(0.0);
    }
    
    for ( int w=0; w<4; w++ )
    {        
        vec2 vContactPos = vWheelContactState[w].xy;
        
        float fDist = length( vFragWorldPos - vContactPos );
        
        if ( vWheelContactState[w].z > 0.01 )
        {
            float fAmount = smoothstep( 0.25, 0.1, fDist );
            fragColor.x = max(fragColor.x, fAmount * vWheelContactState[w].z );
            
            fragColor.y = max(fragColor.y, fAmount * vWheelContactState[w].w * 0.01);
        }       
    }
    
    
    fragColor.x = clamp( fragColor.x, 0.0, 1.0);
    fragColor.y = clamp( fragColor.y, 0.0, 1.0);
    
    if( iFrame < 1 )
    {
        fragColor.x = 0.0;  
    }
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0.0,0.0, 0.0, 1.0);
    
    Camera cam;
    CameraLoadState( cam, addrCamera );

    Camera prevCam;    
    CameraLoadState( prevCam, addrPrevCamera );
    
    UpdateTyreTracks( prevCam.vPos, cam.vPos, fragColor, fragCoord );        
}