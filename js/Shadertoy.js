document.addEventListener("DOMContentLoaded", () => {
  // Dummy view object for providing shared GLSL code if needed
  const view = {
    getCommon: () => "" // Return shared shader code, if any
  };

  // Shadertoy class extends Three.js ShaderMaterial using ES6 class syntax
  class Shadertoy extends THREE.ShaderMaterial {
    constructor(frag, tone = true, objSpace = true, parameters = {}) {
      super(parameters);
      // Flag for drawing in object space vs. screen space
      this.objSpace = objSpace;
      // Flag for tone mapping inclusion
      this.isTone = tone;

      // Array for channel configuration (up to 4 channels)
      this.channels = [];
      // Common GLSL code name and content
      this.commonName = "";
      this.common = "";

      // Default resolution for each channel
      this.channelRes = [
        new THREE.Vector2(512, 512),
        new THREE.Vector2(512, 512),
        new THREE.Vector2(512, 512),
        new THREE.Vector2(512, 512)
      ];

      // Define the uniforms accessible in the shader
      this.uniforms = {
        iChannel0: { type: "t", value: null },
        iChannel1: { type: "t", value: null },
        iChannel2: { type: "t", value: null },
        iChannel3: { type: "t", value: null },
        iChannelResolution: { type: "v2v", value: this.channelRes },
        iGlobalTime: { type: "f", value: 0 },
        iTimeDelta: { type: "f", value: 0 },
        iTime: { type: "f", value: 0 },
        iResolution: { type: "v3", value: new THREE.Vector3() },
        iMouse: { type: "v4", value: new THREE.Vector4() },
        iFrame: { type: "i", value: 0 },
        iDate: { type: "v4", value: new THREE.Vector4() },
        key: { type: "fv", value: null }
      };

      // Simple vertex shader that passes UV coordinates to the fragment shader
      this.vertexShader = `
        varying vec2 vUv;
        void main() {
          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `;

      // Build the complete fragment shader by combining provided code with default structures
      this.fragmentShader = frag !== undefined ? this.completeFragment(frag) : `
        void main() {
          gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        }
      `;
    }

    // Update a uniform's value
    setUniforms(name, value) {
      this.uniforms[name].value = value;
    }

    // Update resolution of a specific channel (index n)
    setChannelResolution(n, x, y) {
      this.channelRes[n].set(x, y);
      this.uniforms.iChannelResolution.value = this.channelRes;
    }

    // Update fragment shader code and flag material update
    updateFragment(frag) {
      this.fragmentShader = frag;
      this.needsUpdate = true;
    }

    // Construct complete fragment shader code by combining default code, common GLSL and the provided shader code
    completeFragment(frag) {
      const defaultMain = [
        "", // Starting empty line
        "void main(){",
        "  vec4 color = vec4(0.0);",
        this.objSpace ? "  vec2 coord = vUv * iResolution.xy;" : "  vec2 coord = gl_FragCoord.xy;",
        "  mainImage(color, coord);",
        this.isTone ? "#if defined(TONE_MAPPING)\n  color.rgb = toneMapping(color.rgb);\n#endif" : "",
        "  gl_FragColor = color;",
        "}"
      ];

      // Extract channel and common definitions from provided fragment code
      this.findChannels(frag);
      this.findCommon(frag);
      this.updateCommon();

      // Prepend uniforms and varying declarations required by the shader
      const preamble = [
        `uniform ${this.channels[0]?.type || "sampler2D"} iChannel0;`,
        `uniform ${this.channels[1]?.type || "sampler2D"} iChannel1;`,
        `uniform ${this.channels[2]?.type || "sampler2D"} iChannel2;`,
        `uniform ${this.channels[3]?.type || "sampler2D"} iChannel3;`,
        "uniform int iFrame;",
        "uniform vec4 iMouse;",
        "uniform vec4 iDate;",
        "uniform vec3 iResolution;",
        "uniform float iGlobalTime;",
        "uniform float iTime;",
        "uniform float iTimeDelta;",
        "uniform vec2 iChannelResolution[4];",
        "uniform float key[20];",
        "varying vec2 vUv;",
        ""
      ];

      // If the provided fragment already defines a main() function, do not append our defaultMain
      const shaderEnd = frag.indexOf("void main()") !== -1 ? "" : defaultMain.join("\n");
      return preamble.join("\n") + this.common + "\n" + frag + "\n" + shaderEnd;
    }

    // Update the common GLSL code using the view helper
    updateCommon() {
      this.common = view.getCommon();
    }

    // Parse common shader code markers from the provided fragment shader
    findCommon(frag) {
      const pre = frag.search("V_#");
      const name = pre !== -1 ? frag.substring(pre + 4, frag.lastIndexOf("#_V") - 1) : "";
      if (name) this.commonName = name;
    }

    // Parse channel definitions from the provided fragment shader based on specific markers
    findChannels(frag) {
      let pre, name, n;
      for (let i = 0; i < 4; i++) {
        this.channels[i] = { type: "sampler2D", buffer: false, def: "", name: "" };
        pre = frag.search(i + "_#");
        name = pre !== -1 ? frag.substring(pre + 4, frag.lastIndexOf("#_" + i) - 1) : "";
        this.channels[i].name = name;
        if (name) {
          this.channels[i].def = "image";
          if (name.substring(0, 4) === "cube") {
            this.channels[i].type = "samplerCube";
            this.channels[i].name = name.substring(5);
            this.channels[i].def = "cube";
          }
          if (name.substring(0, 6) === "buffer") {
            // Determine number of characters representing the buffer size
            if (name.substring(6, 10) === "FULL") n = 10;
            else if (!isNaN(name.substring(6, 10))) n = 10;
            else if (!isNaN(name.substring(6, 9))) n = 9;
            else if (!isNaN(name.substring(6, 8))) n = 8;
            else if (!isNaN(name.substring(6, 7))) n = 7;
            this.channels[i].size = name.substring(6, n);
            this.channels[i].name = name.substring(n + 1);
            this.channels[i].buffer = true;
            this.channels[i].def = "buffer";
          }
        }
      }
    }
  }

  // Find the canvas element with class where the scene will be rendered
  const canvas = document.querySelector("");
  if (!canvas) {
    console.error(`No canvas element with class ${canvas} found.`);
    return;
  }

  // Initialize the Three.js renderer using the found canvas
  const renderer = new THREE.WebGLRenderer({ canvas });
  renderer.setSize(window.innerWidth, window.innerHeight);

  // Create a scene and an orthographic camera for a full-screen quad
  const scene = new THREE.Scene();
  const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);

  // Example fragment shader code defining a mainImage function that uses UV coordinates and time
  const fragShader = `
    void mainImage(out vec4 fragColor, in vec2 fragCoord) {
      vec2 uv = fragCoord / iResolution.xy;
      fragColor = vec4(uv, 0.5 + 0.5 * sin(iGlobalTime), 1.0);
    }
  `;

  // Create the shader material using our Shadertoy class with the fragment shader code
  const shaderToyMaterial = new Shadertoy(fragShader);
  // Set the iResolution uniform so the shader knows the canvas size
  shaderToyMaterial.uniforms.iResolution.value.set(window.innerWidth, window.innerHeight, 1);

  // Create a full-screen quad geometry and attach the shader material to it
  const geometry = new THREE.PlaneGeometry(2, 2);
  const mesh = new THREE.Mesh(geometry, shaderToyMaterial);
  scene.add(mesh);

  // Start time for animation timing
  const startTime = Date.now();

  // Animation loop: update time uniforms and render the scene on each frame
  const animate = () => {
    requestAnimationFrame(animate);
    const elapsed = (Date.now() - startTime) / 1000;
    shaderToyMaterial.uniforms.iGlobalTime.value = elapsed;
    shaderToyMaterial.uniforms.iTime.value = elapsed;
    shaderToyMaterial.uniforms.iFrame.value++;
    renderer.render(scene, camera);
  };
  animate();

  // Adjust renderer and resolution uniform on window resize
  window.addEventListener("resize", () => {
    renderer.setSize(window.innerWidth, window.innerHeight);
    shaderToyMaterial.uniforms.iResolution.value.set(window.innerWidth, window.innerHeight, 1);
  });
});
