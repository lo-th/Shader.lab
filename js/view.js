

var view = ( function () {

    'use strict';

    var params = {
        background: false,
        sphere: false,
        exposure: 1.0,
        // bloom
        strength: 1.5,
        threshold: 0.9,
        radius: 1.0,

    }



    var degtorad = 0.0174532925199432957;
    var radtodeg = 57.295779513082320876;

    var canvas, renderer, scene, camera, controls, light, clock;
    var vsize, mouse, time, key = new Float32Array( 20 ), channelResolution, channels;

    var vs = { w:1, h:1, l:0, x:0 };

    var isPostEffect = false, renderScene, effectFXAA, bloomPass, copyShader, composer = null;

    //var raycaster, mouse, mouseDown = false;

    var cubeCamera = null;
    var textureCubeCamera = null;
    var textureCube = null;

    var txt = {};
    var txt_name = [];

    var geo = {};
    var textures = {};
    var materials = {};
    var meshs = {};
    var shaders = {};

    var env;
    var envName;

    var extraUpdate = [];

    var WIDTH = 512;


    var mesh;
    var material = null;
    var uniforms = null;
    var tx, tx2;
    var vertex;

    view = {

        render: function () {

            requestAnimationFrame( view.render );

            var i = extraUpdate.length;
            while(i--) extraUpdate[i]();

            time.x += clock.getDelta();
            key = user.getKey();

            if(uniforms){ 
                //uniforms.time.value = time.x;
                uniforms.iGlobalTime.value = time.x;
               // uniforms.key.value = key;
                //uniforms.mouse.value = mouse;
            }
            
            if( isPostEffect ) composer.render();
            else renderer.render( scene, camera );
            
        },

        resize: function () {

            vsize.x = window.innerWidth - vs.x;
            vsize.y = window.innerHeight;
            vsize.z = vsize.x / vsize.y;
            camera.aspect = vsize.z;
            camera.updateProjectionMatrix();
            renderer.setSize( vsize.x, vsize.y );

            canvas.style.left = vs.x +'px';

            if( mesh ){ 
                // 1 is distance from camera
                var h = 2 * Math.tan( (camera.fov * degtorad) * 0.5 ) * 1;
                mesh.scale.set(h*vsize.z, h, 1);

            }

            editor.resizeMenu( vsize.x );

            if( isPostEffect ){
                composer.setSize( vsize.x, vsize.y );
                effectFXAA.uniforms['resolution'].value.set(1 / vsize.x, 1 / vsize.y );
            }

        },

        reset: function ( ) {

            //console.clear();
            time.x = 0;
        },

        init: function () {

            channelResolution = [
                new THREE.Vector2(),
                new THREE.Vector2(),
                new THREE.Vector2(),
                new THREE.Vector2()
            ];

            canvas = document.createElement("canvas");
            canvas.className = 'canvas3d';
            canvas.oncontextmenu = function(e){ e.preventDefault(); };
            canvas.ondrop = function(e) { e.preventDefault(); };
            document.body.appendChild( canvas );

            time = new THREE.Vector2();
            clock = new THREE.Clock();

            //container = document.createElement( 'div' );
            //document.body.appendChild( container );

            vsize = new THREE.Vector3( window.innerWidth, window.innerHeight, 0);
            vsize.z = vsize.x / vsize.y;

            mouse = new THREE.Vector4();

            renderer = new THREE.WebGLRenderer({ canvas:canvas, antialias:false, alpha:true });
            renderer.setPixelRatio( window.devicePixelRatio );
            renderer.setSize( vsize.x, vsize.y );
            renderer.setClearColor( 0x000000, 0 );

            //renderer.gammaInput = true;
            //renderer.gammaOutput = true;

            //

            //container.appendChild( renderer.domElement );

            scene = new THREE.Scene();
            scene.matrixAutoUpdate = false;

            camera = new THREE.PerspectiveCamera( 50, vsize.z, 0.1, 1000 );
            camera.position.set(0,0,10);
            scene.add(camera)

            controls = new THREE.OrbitControls( camera, renderer.domElement );
            controls.target.set(0,0,0);
            controls.enableKeys = false;
            controls.update();


            window.addEventListener( 'resize', view.resize, false ); 

            renderer.domElement.addEventListener( 'mousemove', view.move, false );
            renderer.domElement.addEventListener( 'mousedown', view.down, false );
            renderer.domElement.addEventListener( 'mouseup', view.up, false );           

            this.render();
            
        },

        //

        move: function ( e ) {
            mouse.x = e.clientX - vs.x;//( e.clientX / vsize.x ) * 2 - 1;
            mouse.y =  vsize.y-e.clientY;//- ( e.clientY / vsize.y ) * 2 + 1;
        },

        down: function () {
            mouse.z = 1;
        },

        up: function () {
            mouse.z = 0;
        },

        //

        setLeft: function ( x ) { 
            vs.x = x; 
        },

        needFocus: function () {
            canvas.addEventListener('mouseover', editor.unFocus, false );
        },

        haveFocus: function () {
            canvas.removeEventListener('mouseover', editor.unFocus, false );
        },

        

        initLights: function ( shadow ) {

            //scene.add( new THREE.AmbientLight( 0x404040 ) );

            var pointLight = new THREE.PointLight( 0xFFFFFF, 0.25, 600);
            pointLight.position.set( -5,-10,-10 ).multiplyScalar( 10 );
            scene.add( pointLight );

            var pointLight2 = new THREE.PointLight( 0xFFFFFF, 0.25, 600);
            pointLight2.position.set( 5,-10,-10 ).multiplyScalar( 10 );
            scene.add( pointLight2 );

            
            light = new THREE.SpotLight( 0xFFFFFF, 0.5, 600 );
            light.position.set(-3,10,10).multiplyScalar( 10 );
            light.lookAt(new THREE.Vector3(0,0,0));

            //

            if( shadow ){
                light.shadow = new THREE.LightShadow( new THREE.PerspectiveCamera( 20, 1, 5, 200 ) );
                light.shadow.bias = 0.0001;
                light.shadow.mapSize.width = 1024;
                light.shadow.mapSize.height = 1024;
                light.castShadow = true;

                renderer.shadowMap.enabled = true;
                renderer.shadowMap.type = THREE.PCFShadowMap;
            }

            //

            scene.add( light );

            var light2 = new THREE.SpotLight( 0xFFFFFF, 0.25, 600 );
            light2.position.set(3,-5,10).multiplyScalar( 10 );
            light2.lookAt(new THREE.Vector3(0,0,0));

            scene.add( light2 );

        },


        

        initPostEffect: function () {

            renderScene = new THREE.RenderPass( scene, camera );
            //renderScene.clearAlpha = true;

            // renderScene.clear = true;
            effectFXAA = new THREE.ShaderPass( THREE.FXAAShader );
            effectFXAA.uniforms['resolution'].value.set( 1 / vsize.x, 1 / vsize.y );

            copyShader = new THREE.ShaderPass( THREE.CopyShader );

            bloomPass = new THREE.UnrealBloomPass( new THREE.Vector2( vsize.x, vsize.y ), params.strength, params.radius, params.threshold);

            composer = new THREE.EffectComposer( renderer );
            composer.setSize( vsize.x, vsize.y );

            composer.addPass(renderScene);
            composer.addPass(effectFXAA);
            composer.addPass(bloomPass);
            composer.addPass(copyShader);

            copyShader.renderToScreen = true;
            isPostEffect = true;

        },

        setBloom: function(){

            bloomPass.threshold = params.threshold;
            bloomPass.strength = params.strength;
            bloomPass.radius = params.radius;

        },

        initCubeCamera: function () {

            cubeCamera = new THREE.CubeCamera( 0.1, 1000, 512 );
            scene.add( cubeCamera );

            textureCubeCamera = cubeCamera.renderTarget.texture;

        },

        getCubeEnvMap: function () {

            return cubeCamera.renderTarget.texture;

        },

        // -----------------------
        //  RING SIDE
        // -----------------------

        loadAssets : function ( EnvName ) {

            txt_name = [ 'noise', 'stone', 'bump', 'tex19', 'tex06', 'tex18', 'tex07', 'tex03', 'tex09', 'tex00' ]

            envName = envName || 'grey1';

            pool.load( ['glsl/basic_vs.glsl', 'textures/noise.png', 'textures/stone.jpg', 'textures/bump.png', 'textures/tex06.png', 'textures/tex18.png', 'textures/tex07.png', 'textures/tex03.png', 'textures/tex09.png', 'textures/tex00.png','textures/cube/'+envName+'.cube'], view.initModel );

        },

        setMat : function( fragment ){

            channelResolution[0].x = txt.noise.image.width;
            channelResolution[0].y = txt.noise.image.height;


            uniforms = {
                iChannel0: {
                    type: 't',
                    value: txt.noise
                },
                iChannel1: {
                    type: 't',
                    value: txt.bump
                },
                iChannel2: {
                    type: 't',
                    value: txt.stone
                },
                iChannel3: {
                    type: 't',
                    value: txt.tex06
                },
                iChannel4: {
                    type: 't',
                    value: txt.tex18
                },
                iChannel5: {
                    type: 't',
                    value: txt.tex07
                },
                iChannel6: {
                    type: 't',
                    value: txt.tex03
                },
                iChannel7: {
                    type: 't',
                    value: txt.tex09
                },
                iChannel8: {
                    type: 't',
                    value: txt.tex00
                },
                envMap: {
                    type: 't',
                    value: textureCube
                },

                //

                //time: { type: 'f', value: time.x },
                //resolution: { type: 'v3', value: vsize },
                //mouse: { type: 'v4', value: mouse },

                //

                iChannelResolution: { type: 'v2v', value: channelResolution },

                iGlobalTime: { type: 'f', value: time.x },
                iResolution: { type: 'v3', value: vsize },
                iMouse: { type: 'v4', value: mouse },

                //


                key: {
                    type:'fv',
                    value:key
                }
            };

            //uniforms.resolution.value.x = vsize.x;
            //uniforms.resolution.value.y = vsize.y;
            //uniforms.envMap.value = textureCube;
            //uniforms.iChannel0.value = tx;
            //uniforms.iChannel1.value = tx2;

            if(material) material.dispose();

            material = new THREE.ShaderMaterial({
                uniforms: uniforms,
                vertexShader: vertex,
                fragmentShader: fragment,
                transparent:true,
            }); 

            mesh.material = material;

        },

        initTextures : function () {

            var p = pool.getResult();

            var i = txt_name.length, tx;
            while(i--){
                tx = new THREE.Texture( p[txt_name[i]] );
                tx.wrapS = tx.wrapT = THREE.RepeatWrapping;
                tx.flipY = false;
                tx.needsUpdate = true;

                txt[txt_name[i]] = tx;
            }

        },

        initModel : function () {

            view.initTextures();

            var p = pool.getResult();

            textureCube = p[envName];
            //scene.background = textureCube;

            

           // tx = new THREE.Texture(p['tex16']);
           // tx.wrapS = tx.wrapT = THREE.RepeatWrapping;
            //tx.minFilter = THREE.LinearFilter;
            //tx.anisotropy = 16;
            //tx.generateMipmaps = false;
           // tx.flipY = false;
           // tx.needsUpdate = true;

           // tx2 = new THREE.Texture(p['stone']);
           // tx2.wrapS = tx2.wrapT = THREE.RepeatWrapping;
           // tx2.needsUpdate = true;

            //mesh = new THREE.Mesh( new THREE.SphereBufferGeometry( 6, 30, 28 ) );
            var geom = new THREE.PlaneBufferGeometry( 1, 1, 1, 1 );
            mesh = new THREE.Mesh( geom );

            

            
            var mh = 2 * Math.tan( (camera.fov * degtorad) * 0.5 ) * 1;//camera.position.z;
            //var d = 2 * Math.tan( fov * 0.5 );
            //var height = 2 * Math.tan( vFOV / 2 ) * dist;

            

            mesh.scale.set(mh*vsize.z, mh, 1);
            //mesh.position.z = 10;

            //mesh.matrix = camera.matrixWorld;
            //mesh.matrixAutoUpdate = false;
            //mesh = new THREE.Sprite();
            //scene.add(mesh);

            camera.add(mesh);
            mesh.position.set(0,0,-1);
            //scene.add(mesh);

            vertex = p['basic_vs'];

            ready()

        },

        setBackground: function(){

            if( params.background ) scene.background = textureCube;
            else scene.background = null;

        },


        // -----------------------
        //  GET FUNCTION
        // -----------------------

        getParams: function () { return params; },

        getPixel: function ( texture, x, y, w, h ) { 

            w = w || 1;
            h = h || 1;
            var read = new Float32Array( 4 * (w * h) );
            renderer.readRenderTargetPixels( texture, x || 0, y || 0, w, h, read ); 
            return read;
            
        },

        getBgColor: function(){ return renderer.getClearColor(); },

        getRenderer: function(){ return renderer; },

        getDom: function () { return renderer.domElement; },

        getCamera: function () { return camera; },

        getScene: function () { return scene; },

        getControls: function () { return controls; },

        // -----------------------
        //  BASIC FUNCTION
        // -----------------------

        add: function ( mesh ) { scene.add( mesh ); },
        remove: function ( mesh ) { scene.remove( mesh ); },

        moveCamera: function( c, t ){
            camera.position.fromArray( c );
            controls.target.fromArray( t );
            controls.update();
        },

        moveTarget: function( v ){
            var offset = camera.position.clone().sub( controls.target );
           // controls.autoRotate = true
            var offset = controls.target.clone().sub( camera.position );//camera.position.clone().sub( controls.target );
           // camera.position.add(v.clone().add(offset));
            controls.target.copy( v );
            //camera.position.copy( v.add(dif));
            controls.update();
        },

        setCubeEnv: function( imgs ){

            env = new THREE.CubeTexture( imgs );
            env.format = THREE.RGBFormat;
            //env.mapping = THREE.SphericalReflectionMapping;
            env.needsUpdate = true;

            return env;

        },

        setEnv: function( img ){

            env = new THREE.Texture( img );
            env.mapping = THREE.SphericalReflectionMapping;
            env.needsUpdate = true;

            return env;

        },

        getEnv: function(){

            return env; 

        },

        initGeometry: function(){

            geo = {};

            geo[ 'box' ] =  new THREE.BoxBufferGeometry( 1, 1, 1 );
            geo[ 'sphere' ] = new THREE.SphereBufferGeometry( 1, 12, 10 );
            geo[ 'cylinder' ] =  new THREE.CylinderBufferGeometry( 1, 1, 1, 12, 1 );
            //geo[ 'capsule' ] =  new THREE.CapsuleBufferGeometry( 1, 1, 12, 1 );

        },

        

        addUpdate: function ( fun ) {

            extraUpdate.push( fun );

        },

     

       

        // MATH

        toRad: function ( r ) {

            var i = r.length;
            while(i--) r[i] *= degtorad;
            return r;

        },

        lerp: function ( a, b, percent ) { return a + (b - a) * percent; },
        randRange: function ( min, max ) { return view.lerp( min, max, Math.random()); },
        randRangeInt: function ( min, max, n ) { return view.lerp( min, max, Math.random()).toFixed(n || 0)*1; },

    }

    return view;

})();



