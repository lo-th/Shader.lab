

// ------------------ channel define
// 0_# bufferFULL_lostA #_0
// 1_# basic #_1
// ------------------
// https://www.shadertoy.com/view/MdyGRD


// Rendering parameters
#define FOV                 80.0
#define RAY_STEP_MAX        20.0
#define RAY_LENGTH_MAX      10.0
#define EDGE_LENGTH         0.1
#define EDGE_FULL
#define TEXTURE
#define SHADOW
#define BUMP_RESOLUTION     500.0
#define BUMP_INTENSITY      0.3
#define AMBIENT_NORMAL      0.2
#define AMBIENT_HIGHLIGHT   2.5
#define SPECULAR_POWER      2.0
#define SPECULAR_INTENSITY  0.3
#define FADE_POWER          1.5
#define GAMMA               0.8

// Math constants
#define DELTA   0.002
#define PI      3.14159265359

// PRNG (unpredictable)
float randUnpredictable (in vec3 seed) {
    seed = fract (seed * vec3 (5.6789, 5.4321, 6.7890));
    seed += dot (seed.yzx, seed.zxy + vec3 (21.0987, 12.3456, 15.1273));
    return fract (seed.x * seed.y * seed.z * 5.1337);
}

// PRNG (predictable)
float randPredictable (in vec3 seed) {
    return fract (11.0 * sin (3.0 * seed.x + 5.0 * seed.y + 7.0 * seed.z));
}

// HSV to RGB
vec3 hsv2rgb (in vec3 hsv) {
    hsv.yz = clamp (hsv.yz, 0.0, 1.0);
    return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.x + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
}

// Check whether there is a block at a given voxel edge
float blockCheck (in vec3 p, in vec3 n) {
    vec3 blockPosition = floor (p + 0.5 + n * 0.5);
    vec3 blockEven = mod (blockPosition, 2.0);
    float blockSum = blockEven.x + blockEven.y + blockEven.z;
    return max (step (blockSum, 1.5), step (blockSum, 2.5) * step (0.5, randPredictable (blockPosition))) *
        step (4.5, mod (blockPosition.x, 32.0)) *
        step (2.5, mod (blockPosition.y, 16.0)) *
        step (4.5, mod (blockPosition.z, 32.0));
}

// Cast a ray
vec3 hit (in vec3 rayOrigin, in vec3 rayDirection, in float rayLengthMax, out float rayLength, out vec3 hitNormal) {

    // Launch the ray
    vec3 hitPosition = rayOrigin;
    vec3 raySign = sign (rayDirection);
    vec3 rayInv = 1.0 / rayDirection;
    vec3 rayLengthNext = (0.5 * raySign - fract (rayOrigin + 0.5) + 0.5) * rayInv;
    for (float rayStep = 0.0; rayStep < RAY_STEP_MAX; ++rayStep) {

        // Reach the edge of the voxel
        rayLength = min (rayLengthNext.x, min (rayLengthNext.y, rayLengthNext.z));
        hitNormal = step (rayLengthNext.xyz, rayLengthNext.yzx) * step (rayLengthNext.xyz, rayLengthNext.zxy) * raySign;
        hitPosition = rayOrigin + rayLength * rayDirection;

        // Check whether we hit a block
        if (blockCheck (hitPosition, hitNormal) > 0.5 || rayLength > rayLengthMax) {
            break;
        }

        // Next voxel
        rayLengthNext += hitNormal * rayInv;
    }

    // Return the hit point
    return hitPosition;
}

// Main function
void mainImage (out vec4 fragColor, in vec2 fragCoord) {

    // Read the data
    vec3 headPosition;
    mat3 headOrientation;
    vec3 lightPosition;

    if (iFrame < 5) {
        headPosition = vec3 (13.05, 1.5, 13.0);
        lightPosition = vec3 (13.0, 1.0, 13.0);
        headOrientation [0] = vec3 (0.0, 0.0, -1.0);
        headOrientation [1] = vec3 (1.0, 0.0, 0.0);
    } else {
        vec4 data = texture2D (iChannel0, vec2 (0.5, 0.5) / iResolution.xy);
        headPosition = data.xyz;
        headOrientation [1].x = data.w;
        data = texture2D (iChannel0, vec2 (2.5, 0.5) / iResolution.xy);
        lightPosition = data.xyz;
        headOrientation [1].y = data.w;
        data = texture2D (iChannel0, vec2 (4.5, 0.5) / iResolution.xy);
        headOrientation [0] = data.xyz;
        headOrientation [1].z = data.w;
    }
    headOrientation [2] = cross (headOrientation [0], headOrientation [1]);

    // Animate the ambient lighting
    float ambientIntensity = max (step (1.0, mod (iGlobalTime, 10.0)), step (0.25, randUnpredictable (vec3 (iGlobalTime))));

    // Define the ray corresponding to this fragment
    vec3 rayOrigin = headPosition;
    vec3 rayDirection = headOrientation * normalize (vec3 (2.0 * fragCoord - iResolution.xy, 0.5 * iResolution.x / tan (FOV * PI / 360.0)));

    // Cast a ray
    float hitDistance;
    vec3 hitNormal;
    vec3 hitPosition = hit (rayOrigin, rayDirection, RAY_LENGTH_MAX, hitDistance, hitNormal);
    vec3 hitUV = hitPosition * abs (hitNormal.yzx + hitNormal.zxy);

    // Basic edge detection
    vec3 edgeDistance = fract (hitUV + 0.5) - 0.5;
    vec3 edgeDirection = sign (edgeDistance);
    edgeDistance = abs (edgeDistance);

    #ifdef EDGE_FULL
    vec3 hitNormalAbs = abs (hitNormal);
    vec2 edgeSmooth = vec2 (dot (edgeDistance, hitNormalAbs.yzx), dot (edgeDistance, hitNormalAbs.zxy));
    float highlightIntensity = (1.0 - blockCheck (hitPosition + edgeDirection * hitNormalAbs.yzx, hitNormal)) * smoothstep (0.5 - EDGE_LENGTH, 0.5 - EDGE_LENGTH * 0.5, edgeSmooth.x);
    highlightIntensity = max (highlightIntensity, (1.0 - blockCheck (hitPosition + edgeDirection * hitNormalAbs.zxy, hitNormal)) * smoothstep (0.5 - EDGE_LENGTH, 0.5 - EDGE_LENGTH * 0.5, edgeSmooth.y));
    highlightIntensity = max (highlightIntensity, (1.0 - blockCheck (hitPosition + edgeDirection, hitNormal)) * smoothstep (0.5 - EDGE_LENGTH, 0.5 - EDGE_LENGTH * 0.5, min (edgeSmooth.x, edgeSmooth.y)));
    #else
    float highlightIntensity = 1.0 - blockCheck (hitPosition + step (edgeDistance.yzx, edgeDistance.xyz) * step (edgeDistance.zxy, edgeDistance.xyz) * edgeDirection, hitNormal);
    highlightIntensity *= smoothstep (0.5 - EDGE_LENGTH, 0.5 - EDGE_LENGTH * 0.5, max (edgeDistance.x, max (edgeDistance.y, edgeDistance.z)));
    #endif

    // Texture
    #ifdef TEXTURE
    vec2 textureUV = fract (vec2 (dot (hitUV, hitNormal.yzx), dot (hitUV, hitNormal.zxy)) + 0.5);
    textureUV.x = (textureUV.x + mod (floor (iGlobalTime * 20.0), 6.0)) * 40.0 / 256.0;
    float textureIntensity = 1.0 - texture2D (iChannel1, textureUV).r;
    float texturePhase = 2.0 * PI * randUnpredictable (floor (hitPosition + 0.5 + hitNormal * 1.5));
    textureIntensity *= smoothstep (0.8, 1.0, cos (iGlobalTime * 0.2 + texturePhase));
    highlightIntensity = max (highlightIntensity, textureIntensity);
    #endif

    // Set the object color
    vec3 color = cos ((hitPosition + hitNormal * 0.5) * 0.05);
    color = hsv2rgb (vec3 (color.x + color.y + color.z + highlightIntensity * 0.05, 1.0, 1.0));

    // Lighting
    vec3 lightDirection = hitPosition - lightPosition;
    float lightDistance = length (lightDirection);
    lightDirection /= lightDistance;

    float lightIntensity = min (1.0, 1.0 / lightDistance);
    #ifdef SHADOW
    float lightHitDistance;
    vec3 lightHitNormal;
    hit (hitPosition - hitNormal * DELTA, -lightDirection, lightDistance, lightHitDistance, lightHitNormal);
    lightIntensity *= step (lightDistance, lightHitDistance);
    #endif

    // Bump mapping
    vec3 bumpUV = floor (hitUV * BUMP_RESOLUTION) / BUMP_RESOLUTION;
    hitNormal = normalize (hitNormal + (1.0 - highlightIntensity) * BUMP_INTENSITY * (hitNormal.yzx * (randUnpredictable (bumpUV) - 0.5) + hitNormal.zxy * (randUnpredictable (bumpUV + 1.0) - 0.5)));

    // Shading
    float ambient = mix (AMBIENT_NORMAL, AMBIENT_HIGHLIGHT, highlightIntensity) * ambientIntensity;
    float diffuse = max (0.0, dot (hitNormal, lightDirection));
    float specular = pow (max (0.0, dot (reflect (rayDirection, hitNormal), lightDirection)), SPECULAR_POWER) * SPECULAR_INTENSITY;
    color = (ambient + diffuse * lightIntensity) * color + specular * lightIntensity;
    color *= pow (max (0.0, 1.0 - hitDistance / RAY_LENGTH_MAX), FADE_POWER);

    // Light source
    lightDirection = lightPosition - rayOrigin;
    if (dot (rayDirection, lightDirection) > 0.0) {
        lightDistance = length (lightDirection);
        if (lightDistance < hitDistance) {
            vec3 lightNormal = cross (rayDirection, lightDirection);
            color += smoothstep (0.001, 0.0, dot (lightNormal, lightNormal));
        }
    }

    // Adjust the gamma
    color = pow (color, vec3 (GAMMA));

    // Set the fragment color
    fragColor = vec4 (color, 1.0);
}