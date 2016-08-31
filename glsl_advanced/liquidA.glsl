
// ------------------ channel define
// 0_# bufferFULL_liquidA #_0
// 1_# bufferFULL_liquidB #_1
// 2_# bufferFULL_liquidC #_2
// 3_# bufferFULL_liquidD #_3
// ------------------

// Update the density of each particle

// iChannel0 = Buf A (density)
// iChannel1 = Buf B (velocity & position)
// iChannel2 = Buf C (id & colliders)
// iChannel3 = Buf D (inputs)

#define PARTICLE_RADIUS         2.5
#define PARTICLE_DENSITY_REST   0.4

#define CEIL(x) (float (int ((x) + 0.9999))) // To workaround a bug with Firefox on Windows...

float particleDensity;
vec2 particlePosition;
vec2 particleIdCheck;

void densityUpdate (in vec2 offset) {

    // Get the position of the cell
    vec2 cellPosition = floor (particlePosition + offset) + 0.5;

    // Get the particle ID
    vec2 particleId = texture2D (iChannel2, cellPosition / iResolution.xy).rg;

    // Check whether there is a particle here
    if (offset == vec2 (0.0)) {

        // This is the current particle
        particleIdCheck = particleId;
    } else if (particleId.x > 0.0) {

        // Get the position of this other particle
        vec2 otherParticlePosition = texture2D (iChannel1, particleId / iResolution.xy).ba;

        // Check whether these 2 particles touch each other
        float dist = length (otherParticlePosition - particlePosition);
        if (dist < 2.0 * PARTICLE_RADIUS) {

            // Compute the density
            float compression = 1.0 - dist / (2.0 * PARTICLE_RADIUS);
            particleDensity += compression * compression * compression;
        }
    }
}

void mainImage (out vec4 fragColor, in vec2 fragCoord) {

    // Check for a reset
    bool reset = iFrame == 0 || texture2D (iChannel3, vec2 (0.5) / iResolution.xy).a > 0.5;

    // Define the density
    if (reset) {
        particleDensity = 1.0;
    } else {

        // Get the particle data
        particlePosition = texture2D (iChannel1, fragCoord / iResolution.xy).ba;
        if (particlePosition.x > 0.0) {
            particleDensity = 1.0;

            // Check for nearby particles
            particleIdCheck = vec2 (-1.0);
            const float collisionRadius = CEIL (PARTICLE_RADIUS * 2.0);
            for (float i = -collisionRadius; i <= collisionRadius; ++i) {
                for (float j = -collisionRadius; j <= collisionRadius; ++j) {
                    densityUpdate (vec2 (i, j));
                }
            }

            // Make sure the particle is still tracked
            if (particleIdCheck != fragCoord) {

                // The particle is lost...
                particleDensity = 0.0;
            }
        } else {

            // The particle is lost...
            particleDensity = 0.0;
        }
    }

    // Compute the "density factor" to ease the computation of the pressure force
    float particleDensityFactor = (particleDensity - PARTICLE_DENSITY_REST) / (particleDensity * particleDensity);

    // Update the fragment
    fragColor = vec4 (particleDensity, particleDensityFactor, 0.0, 0.0);
}