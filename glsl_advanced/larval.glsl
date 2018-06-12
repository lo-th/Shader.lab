// ------------------ channel define
// 0_# cube_grey1 #_0
// 1_# bufferFULL_larvalA #_1
// ------------------

// UI Framework Example. Based on:
// Larval - @P_Malin
// https://www.shadertoy.com/view/ldB3Rz
// Super Shader GUI - @P_Malin
// https://www.shadertoy.com/view/Xs2cR1
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Some kind of alien fractal thingy.
// A hacked together KIFS doodle.
// The fractal parameters aren't that exciting but I like the pretty colours :D

#define iChannelUI iChannel1

float UI_GetFloat( int iData )
{
    return texelFetch( iChannelUI, ivec2(iData,0), 0 ).x;
}

bool UI_GetBool( int iData )
{
    return UI_GetFloat( iData ) > 0.5;
}

vec3 UI_GetColor( int iData )
{
    return texelFetch( iChannelUI, ivec2(iData,0), 0 ).rgb;
}


void UI_Compose( vec2 fragCoord, inout vec3 vColor, out int windowId, out vec2 vWindowCoord )
{
    vec4 vUISample = texelFetch( iChannelUI, ivec2(fragCoord), 0 );
    
    if ( fragCoord.y < 2.0 )
    {
        // Hide data
        vUISample = vec4(1.0, 1.0, 1.0, 1.0);
    }
    
    vColor.rgb = vColor.rgb * (1.0f - vUISample.w) + vUISample.rgb;
    
    windowId = -1;
    vWindowCoord = vec2(0);
    
    if ( vUISample.a < 0.0 )
    {
        vWindowCoord = vUISample.rg;
        windowId = int(round(vUISample.b));
    }
}

const int
     DATA_UICONTEXT						= 0
	,DATA_WINDOW_CONTROLS   			= 2
	,DATA_SCROLLBAR_CONTROLS_WINDOW		= 3
    ,DATA_ANIMATE						= 4
	,DATA_ROT_X							= 5
	,DATA_ROT_Y							= 6
    ,DATA_EDIT_WHICH_COLOR              = 7
    ,DATA_WINDOW_EDIT_COLOR 			= 8
	,DATA_BACKGROUND_COLOR        		= 9
	,DATA_INTENSITY						= 10
    ,DATA_EXPOSURE						= 11
    ;
 

// ---------------------- 8< --------------------- 8< --------------------------


#define kRaymarchIterations 24
#define kIFSIterations 16

float kExposure = 0.1;

#define TEMPERATURE 2200.0

vec3 blackbody(float t)
{
    t *= TEMPERATURE;
    
    float u = ( 0.860117757 + 1.54118254e-4 * t + 1.28641212e-7 * t*t ) 
            / ( 1.0 + 8.42420235e-4 * t + 7.08145163e-7 * t*t );
    
    float v = ( 0.317398726 + 4.22806245e-5 * t + 4.20481691e-8 * t*t ) 
            / ( 1.0 - 2.89741816e-5 * t + 1.61456053e-7 * t*t );

    float x = 3.0*u / (2.0*u - 8.0*v + 4.0);
    float y = 2.0*v / (2.0*u - 8.0*v + 4.0);
    float z = 1.0 - x - y;
    
    float Y = 1.0;
    float X = Y / y * x;
    float Z = Y / y * z;

    mat3 XYZtoRGB = mat3(3.2404542, -1.5371385, -0.4985314,
                        -0.9692660,  1.8760108,  0.0415560,
                         0.0556434, -0.2040259,  1.0572252);

    return max(vec3(0.0), (vec3(X,Y,Z) * XYZtoRGB) * pow(t * 0.0004, 4.0));
}


// KIFS parameters
const float fScale=1.25;
vec3 vOffset = vec3(-1.0,-2.0,-0.2);	
mat3 m;

const float kFarClip = 30.0;

vec2 GetSceneDistance( in vec3 vPos )
{
	float fTrap = kFarClip;
	
	float fTotalScale = 1.0;
	for(int i=0; i<kIFSIterations; i++)
	{	
		vPos.xyz = abs(vPos.xyz);
		vPos *= fScale;
		fTotalScale *= fScale;
		vPos += vOffset;
		vPos.xyz = (vPos.xyz) * m;
		
		float fCurrDist = length(vPos.xyz) * fTotalScale;
		//float fCurrDist = max(max(vPos.x, vPos.y), vPos.z) * fTotalScale;
		//float fCurrDist = dot(vPos.xyz, vPos.xyz);// * fTotalScale;		
		fTrap = min(fTrap, fCurrDist);
	}

	float l = length(vPos.xyz) / fTotalScale;
	
	float fDist = l - 0.1;
	return vec2(fDist, fTrap);
}

vec4 Raycast( const in vec3 vOrigin, const in vec3 vDir )
{
	float fClosest = kFarClip;
	vec2 d = vec2(0.0);
	float t = 0.01;
	for(int i=0; i<kRaymarchIterations; i++)
	{
		d = GetSceneDistance(vOrigin + vDir * t);
		fClosest = min(fClosest, d.x / t);
		if(abs(d.x) < 0.0001)
		{
			break;
		}
		t += d.x;
		if(t > kFarClip)
		{
			t = kFarClip;
			break;
		}
	}
	
	return vec4(t, d.x, d.y, fClosest);
}

vec3 GetSceneNormal( const in vec3 vPos )
{
    const float fDelta = 0.000001;

    vec3 vOffset1 = vec3( fDelta, -fDelta, -fDelta);
    vec3 vOffset2 = vec3(-fDelta, -fDelta,  fDelta);
    vec3 vOffset3 = vec3(-fDelta,  fDelta, -fDelta);
    vec3 vOffset4 = vec3( fDelta,  fDelta,  fDelta);

    float f1 = GetSceneDistance( vPos + vOffset1 ).x;
    float f2 = GetSceneDistance( vPos + vOffset2 ).x;
    float f3 = GetSceneDistance( vPos + vOffset3 ).x;
    float f4 = GetSceneDistance( vPos + vOffset4 ).x;

    vec3 vNormal = vOffset1 * f1 + vOffset2 * f2 + vOffset3 * f3 + vOffset4 * f4;

    return normalize( vNormal );
}

vec3 TraceRay( const in vec3 vOrigin, const in vec3 vDir )
{	
	vec4 vHit = Raycast(vOrigin, vDir);
	
	vec3 vHitPos = vOrigin + vDir * vHit.x;
	vec3 vHitNormal = GetSceneNormal(vHitPos);
	
	float fShade = 1.0;
	float fGlow = 0.0;
	vec3 vEnvDir = vDir;
	if(vHit.x < kFarClip)
	{
		vEnvDir = reflect(vDir, vHitNormal);
		fGlow = clamp(1.2 - vHit.z * 0.1, 0.0, 1.0);
		fGlow = pow(fGlow, 2.0);
		fShade = fGlow;
	}
	
	vec3 vEnv = texture2D(iChannel0, vEnvDir).rgb;
	vEnv = vEnv * vEnv;	
	vEnv = -log2(1.0 - min(vEnv, 0.99));

    vec3 vEnvColour = UI_GetColor( DATA_BACKGROUND_COLOR );
	vEnv *= vEnvColour;
	
	vec3 vColour = vEnv * (0.25 + fShade * 0.75);
	
    float fIntensity = UI_GetFloat( DATA_INTENSITY );
    
    float fTemp = 0.0;
	// object glow
	if(vHit.x < kFarClip)
	{	
        vColour += blackbody( fGlow ) * 20.0 * fIntensity;
	}
	
    
	// outer glow
	{				
		float f = 1.0 - clamp(vHit.w * 0.5, 0.0, 1.0);		
		
		float fGlowAmount = 0.0;
		
		// big glow
		float f1 = pow(f, 20.0);
		fGlowAmount += f1 * 2.0 * (0.5 + fShade * 0.5);
	
		// small glow
		float f2 = pow(f, 200.0);
		fGlowAmount += f2 * 5.0 * fShade;
		
		//vColour += vGlowColour * fGlowAmount;
        
        vColour += blackbody( fGlowAmount * 0.25 ) * 10.0 * fIntensity;        
	}    
    
	return vColour;
}


// mat3 from quaternion
mat3 SetRot( const in vec4 q )
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

// mat3 from axis / angle
mat3 SetRot( vec3 vAxis, float fAngle )
{	
	return SetRot( vec4(normalize(vAxis) * sin(fAngle), cos(fAngle)) );
}

vec3 ApplyPostFx( const in vec3 vIn, const in vec2 fragCoord )
{
	vec2 vUV = fragCoord.xy / iResolution.xy;
	vec2 vCentreOffset = (vUV - 0.5) * 2.0;
	
	vec3 vResult = vIn;
	vResult.xyz *= clamp(1.0 - dot(vCentreOffset, vCentreOffset) * 0.4, 0.0, 1.0);

	vResult.xyz = 1.0 - exp(vResult.xyz * -kExposure * pow(2.0f, UI_GetFloat( DATA_EXPOSURE )) );
	
	vResult.xyz = pow(vResult.xyz, vec3(1.0 / 2.2));
	
	return vResult;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 vUV = fragCoord.xy / iResolution.xy;
	vec2 vWindow = vUV * 2.0 - 1.0;
	vWindow.x *= iResolution.x / iResolution.y;
	
	vec2 vMouse = iMouse.xy / iResolution.xy;
	
	float fHeading = iGlobalTime * 0.21;
	float fElevation = cos(iGlobalTime * 0.1) * 0.5;
	float fCameraDistance = 15.0 + sin(iGlobalTime * 0.05) * 5.0;
	
	float fSinElevation = sin(fElevation);
	float fCosElevation = cos(fElevation);
	float fSinHeading = sin(fHeading);
	float fCosHeading = cos(fHeading);
	
	vec3 vCameraOffset;
	vCameraOffset.x = fSinHeading * fCosElevation;
	vCameraOffset.y = fSinElevation;
	vCameraOffset.z = fCosHeading * fCosElevation;
	
	vec3 vCameraPos = vCameraOffset * fCameraDistance;

	vec3 vCameraTarget = vec3(0.0, 0.0, 0.0);
	
	vec3 vForward = normalize(vCameraTarget - vCameraPos);
	vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
	vec3 vUp = normalize(cross(vForward, vRight));
	
	float fFov = 2.0;
	
	vec3 vDir = normalize(vWindow.x * vRight + vWindow.y * vUp + vForward * fFov);
	
	vec3 vRotationAxis = vec3(1.0, 4.0, 2.0);

	// Rotate the rotation axis
	mat3 m2 = SetRot( vec3(0.1, 1.0, 0.01), iGlobalTime * 0.3 );		
	
	vRotationAxis = vRotationAxis * m2;
	
	float fRotationAngle = sin(iGlobalTime * 0.5);
	
    if ( !UI_GetBool( DATA_ANIMATE ) )
    {
		vRotationAxis = vec3( UI_GetFloat(DATA_ROT_X), 1.0, UI_GetFloat(DATA_ROT_Y) );
        fRotationAngle = length(vRotationAxis);
    }
	
	m = SetRot(vRotationAxis, fRotationAngle);
	
	vec3 vResult = TraceRay(vCameraPos, vDir);
	
	vResult = ApplyPostFx(vResult,fragCoord);
	
	int windowId;
    vec2 vWindowCoord;
    UI_Compose( fragCoord, vResult, windowId, vWindowCoord );
    
	fragColor = vec4(vResult,1.0);
}
