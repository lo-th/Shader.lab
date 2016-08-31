

// ------------------ channel define
// 2_# bufferFULL_liquidC #_2
// 3_# bufferFULL_liquidD #_3
// ------------------

//https://www.shadertoy.com/view/ldy3D1

// Display particles and colliders

// iChannel0 = [nothing]
// iChannel1 = [nothing]
// iChannel2 = Buf C (id & colliders)
// iChannel3 = Buf D (inputs)

#define PARTICLE_RADIUS             3.5
#define PARTICLE_VELOCITY_FACTOR    0.02

#define CEIL(x) (float (int ((x) + 0.9999))) // To workaround a bug with Firefox on Windows...

float rand (in vec2 seed) {
    return fract (sin (dot (seed, vec2 (12.9898, 78.233))) * 137.5453);
}

vec3 hsv2rgb (in vec3 hsv) {
    hsv.yz = clamp (hsv.yz, 0.0, 1.0);
    return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.x + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
}

float segDist (in vec2 p, in vec2 a, in vec2 b) {
    p -= a;
    b -= a;
    return length (p - b * clamp (dot (p, b) / dot (b, b), 0.0, 1.0));
}

vec3 particleColor (in float particleVelocity) {
    return mix (vec3 (0.5, 0.6, 0.8), vec3 (0.9, 0.9, 1.0), particleVelocity * PARTICLE_VELOCITY_FACTOR);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord) {

    // Check whether there is a collider here
    vec4 data = texture2D (iChannel2, fragCoord / iResolution.xy);
    vec3 color;
    if (data.a > 0.5) {

        // Display the collider (wood)
        vec2 uv = 0.02 * fragCoord;
        uv = uv.y * 13.0 + sin (uv * 11.0) * sin (uv.yx * 3.0);
        color = vec3 (0.8, 0.6, 0.4) * (1.0 - 0.5 * length (fract (uv) - 0.5));
    } else {

        // Display the background (light squares)
        vec2 uv = 0.05 * fragCoord;
        uv += 0.5 * cos (uv.yx + iGlobalTime);
        float angle = rand (floor (uv)) * 3.14159;
        vec3 hsv = vec3 (0.6 + 0.1 * cos (angle), 1.0, 0.2 + 0.1 * cos (angle * iGlobalTime));
        color = hsv2rgb (hsv) * smoothstep (1.0, 0.2, length (fract (uv) - 0.5));

        // Check whether there is a particle here
        float particleVelocity = data.b;
        float weightTotal = step (0.0, particleVelocity);
        float weightedVelocity = weightTotal * particleVelocity;

        // Check for nearby particles
        const float displayRadius = CEIL (PARTICLE_RADIUS);
        for (float i = -displayRadius; i <= displayRadius; ++i) {
            for (float j = -displayRadius; j <= displayRadius; ++j) {
                vec2 offset = vec2 (i, j);
                if (offset != vec2 (0.0)) {
                    particleVelocity = texture2D (iChannel2, (fragCoord + offset) / iResolution.xy).b;
                    if (particleVelocity >= 0.0) {
                        float weight = max (0.0, 1.0 - (length (offset) - 1.0) / PARTICLE_RADIUS);
                        weightTotal += weight;
                        weightedVelocity += weight * particleVelocity;
                    }
                }
            }
        }

        // Display the particle
        if (weightTotal > 0.0) {
            color += particleColor (weightedVelocity / weightTotal) * min (weightTotal * weightTotal, 1.0);
        }
    }

    // Display the direction of the gravity
    data = texture2D (iChannel3, vec2 (1.5, 0.5) / iResolution.xy);
    float gravityTimer = data.g;
    if (gravityTimer > 0.0) {
        float gravityDirection = data.r;
        vec2 frag = fragCoord - 0.5 * iResolution.xy;
        vec2 direction = vec2 (cos (gravityDirection), sin (gravityDirection));
        vec2 pointA = 25.0 * direction;
        vec2 pointB = 15.0 * direction;
        vec2 offset = 10.0 * vec2 (direction.y, -direction.x);
        float dist = segDist (frag, -pointA, pointA);
        dist = min (dist, segDist (frag, pointA, pointB + offset));
        dist = min (dist, segDist (frag, pointA, pointB - offset));
        color = mix (color, vec3 (smoothstep (4.0, 3.0, dist)), gravityTimer * smoothstep (6.0, 5.0, dist));
    }

    // Set the fragment color
    fragColor = vec4 (color, 1.0);
}