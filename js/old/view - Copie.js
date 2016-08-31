

var view = ( function () {

    'use strict';

    var isReady = false;

    var params = {

        Speed: 1,

        background: false,
        sphere: false,
        
        // toneMapping
        exposure: 3.0,
        whitePoint: 5.0,
        tone: "Uncharted2",

        pixelRatio : 1,

    }

    var interval = null;


    // channel names 
    var channels = [];

    var channelNames = [ [], [], [], [], [] ];

    var buffers = [];

    var tmpShader = null;



    
    var C_materials = [null, null, null, null];
    var C_textures = [null, null, null, null];
    var C_uniforms = [];
    var C_size = [0, 0, 0, 0];

    var isBuff = [false, false, false, false];

    var channelResolution;

    var currentScene = -1;

    var gl = null;

    var degtorad = 0.0174532925199432957;
    var radtodeg = 57.295779513082320876;

    var canvas, renderer, scene, camera, controls, light;//, clock;
    var vsize, mouse, key = new Float32Array( 20 );

    var time = 0;
    var frame = 0;

    var vs = { w:1, h:1, l:0, x:0 , y:0};

    //var isPostEffect = false, renderScene, effectFXAA, bloomPass, copyShader, composer = null;


    var gputmp = null;

    //var raycaster, mouse, mouseDown = false;

    var cubeCamera = null;
    var textureCubeCamera = null;
    var textureCube = null;

    var txt = {};
    var txt_name = [];
    var cube_name = [];

    var geo = {};
    var textures = {};
    var materials = {};
    var meshs = {};
    var shaders = {};

    var env;
    var envName;

    var extraUpdate = [];
    var toneMappings;

    var WIDTH = 512;

    var isWebGL2 = false;
    var isMobile = false;

    var isLoaded = false;
    var isError = false;

    var mesh, mesh2;
    var material = null;
    var uniforms = null;
    var tx, tx2;
    var vertex, fragment;

    var tmp_txt = [];

    

    var precision = 'highp';

    var base_uniforms = {

        iChannel0: { type: 't', value: null },
        iChannel1: { type: 't', value: null },
        iChannel2: { type: 't', value: null },
        iChannel3: { type: 't', value: null },

        iChannelResolution: { type: 'v2v', value: null },

        iGlobalTime: { type: 'f', value: time },
        iResolution: { type: 'v3', value: vsize },
        iMouse: { type: 'v4', value: null },
        iFrame: { type: 'i', value: 0 },
        iDate: { type: 'f', value: 0 },
        //
        key: { type:'fv', value:null },
         
    };

    // THREE JS TRANSPHERE

    var base_main = [
        ' ',
        'void main(){',
        '    vec4 color = vec4(0.0);',
        '    vec2 coord = vUv * iResolution.xy;',
        '    mainImage( color, coord );',
        '    #if defined( TONE_MAPPING )', 
        '    color.rgb = toneMapping( color.rgb );',
        '    #endif',
        '    gl_FragColor = color;',
        '}',
        ' '
    ];

   /* var base_main = [
        ' ',
        'void main(){',

        '    vec4 color = vec4(0.0);',

        '    // screen space',
        '    // vec2 coord = gl_FragCoord.xy;',
        '    // object space',
        '    vec2 coord = vUv * iResolution.xy;',

        '    mainImage( color, coord );',

        '    // tone mapping',
        '    #if defined( TONE_MAPPING )', 
        '    color.rgb = toneMapping( color.rgb );',
        '    #endif',

        '    gl_FragColor = color;',

        '}'
    ];*/


    view = {

        render: function () {

            requestAnimationFrame( view.render );

            var i = extraUpdate.length;
            while(i--) extraUpdate[i]();

            

            key = user.getKey();

            //console.log(clock.getDelta())

            if(uniforms){ 

                time += params.Speed * 0.01;
                frame ++;

                material.uniforms.iGlobalTime.value = time;
                material.uniforms.iFrame.value = frame;
               // uniforms.key.value = key;
                //uniforms.mouse.value = mouse;
            }

            
            for(i=0; i<4 ; i++){
                if( isBuff[i] ){ 
                    C_uniforms[i].iGlobalTime.value = time;
                    C_uniforms[i].iFrame.value = frame;
                    gputmp.render( C_materials[i], C_textures[i] );
                }
            }
            
            //if( isPostEffect ) composer.render();
            //else 
            renderer.render( scene, camera );

            
            
        },

        resize: function () {

            if(!isReady) return;

            vsize.x = window.innerWidth - vs.x - vs.y;
            vsize.y = window.innerHeight;
            vsize.z = vsize.x / vsize.y;
            camera.aspect = vsize.z;
            camera.updateProjectionMatrix();
            renderer.setSize( vsize.x, vsize.y );

            canvas.style.left = vs.x +'px';

            if( currentScene === 0 ){ 
                // 1 is distance from camera
                var h = 2 * Math.tan( (camera.fov * degtorad) * 0.5 ) * 1;
                mesh.scale.set(h*vsize.z, h, 1);

            }

            editor.resizeMenu( vsize.x );

            /*if( isPostEffect ){
                composer.setSize( vsize.x, vsize.y );
                effectFXAA.uniforms['resolution'].value.set(1 / vsize.x, 1 / vsize.y );
            }*/

        },

        

        testMobile: function () {
            var nav = navigator.userAgent;
            if (nav.match(/Android/i) || nav.match(/webOS/i) || nav.match(/iPhone/i) || nav.match(/iPad/i) 
                || nav.match(/iPod/i) || nav.match(/BlackBerry/i) || nav.match(/Windows Phone/i)) return true;
            else return false;        
        },

        init: function () {

            

            isMobile = view.testMobile();

            precision = isMobile ? 'lowp' : 'highp';

            toneMappings = {
                None: THREE.NoToneMapping,
                Linear: THREE.LinearToneMapping,
                Reinhard: THREE.ReinhardToneMapping,
                Uncharted2: THREE.Uncharted2ToneMapping,
                Cineon: THREE.CineonToneMapping
            };

            vsize = new THREE.Vector3( window.innerWidth, window.innerHeight, 0);
            vsize.z = vsize.x / vsize.y;

            channelResolution = [
                new THREE.Vector2(),
                new THREE.Vector2(),
                new THREE.Vector2(),
                new THREE.Vector2()
            ];

            mouse = new THREE.Vector4();


            base_uniforms.iChannelResolution.value = channelResolution;
            base_uniforms.iResolution.value = vsize;
            base_uniforms.iMouse.value = mouse;
            base_uniforms.key.value = key;



            ///////////

            canvas = document.createElement("canvas");
            canvas.className = 'canvas3d';
            canvas.oncontextmenu = function(e){ e.preventDefault(); };
            canvas.ondrop = function(e) { e.preventDefault(); };
            //document.body.appendChild( canvas );
            document.body.insertBefore( canvas, document.body.childNodes[0] );

            isWebGL2 = false;

            var options = { antialias: false, alpha:false, stencil:false, depth:false, precision:precision }

            // Try creating a WebGL 2 context first
            gl = canvas.getContext( 'webgl2', options );
            if (!gl) {
                gl = canvas.getContext( 'experimental-webgl2', options );
            }
            isWebGL2 = !!gl;

            if(!isWebGL2) {
                gl = canvas.getContext( 'webgl', options );
                if (!gl) gl = canvas.getContext( 'experimental-webgl', options );
            }

            console.log('Webgl 2 is ' + isWebGL2 );


            renderer = new THREE.WebGLRenderer({ canvas:canvas, context:gl, antialias:false, alpha:false, precision:precision });
            //renderer.setPixelRatio( window.devicePixelRatio );
            renderer.setPixelRatio( params.pixelRatio );
            renderer.setSize( vsize.x, vsize.y );
            renderer.setClearColor( 0x1e1e1e, 1 );

            //

            renderer.gammaInput = true;
            renderer.gammaOutput = true;

            //

            scene = new THREE.Scene();
            scene.matrixAutoUpdate = false;

            camera = new THREE.PerspectiveCamera( 45, vsize.z, 0.1, 5000 );
            camera.position.set(0,0,10);
            scene.add(camera);

            controls = new THREE.OrbitControls( camera, canvas );
            controls.target.set(0,0,0);
            controls.enableKeys = false;
            controls.update();


            window.addEventListener( 'resize', view.resize, false ); 
           // window.addEventListener( 'error', function(e, url, line){  editor.setTitle('Error'); }, false );

            //window.onerror = function(e, url, line){  editor.setTitle('Error'); };

            renderer.domElement.addEventListener( 'mousemove', view.move, false );
            renderer.domElement.addEventListener( 'mousedown', view.down, false );
            renderer.domElement.addEventListener( 'mouseup', view.up, false );

            //renderer.domElement.addEventListener( 'drop', function(e){ e.preventDefault(); return false; }, false );  
            renderer.domElement.addEventListener( 'dragover', function(e){ e.preventDefault(); return false; }, false );


            


            gputmp = new view.GpuSide();

            buffers.push( new view.Channel() );
            buffers.push( new view.Channel() );
            buffers.push( new view.Channel() );
            buffers.push( new view.Channel() );
            buffers.push( new view.Channel() );


            this.setTone();
            this.render();

            isReady = true;

            this.resize();
            this.loadAssets();
            
        },



        setTone : function(v) {

            var nup = false;

            if(v!==undefined){ 
                params.tone = v;
                nup = true;
            }

            renderer.toneMapping = toneMappings[ params.tone ];
            renderer.toneMappingExposure = params.exposure;
            renderer.toneMappingWhitePoint = params.whitePoint;

            if( material && nup ) material.needsUpdate = true;

            /*if(uniforms){
                if( nup ) material.needsUpdate = true;
                uniforms.exposure.value = params.exposure;
                uniforms.whitePoint.value = params.whitePoint;
            }*/

        },

        setQuality: function ( v ) {

            params.pixelRatio = v;
            renderer.setPixelRatio( params.pixelRatio );

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

        setLeft: function ( x, y ) { 
            vs.x = x; 
            vs.y = y;
        },

        needFocus: function () {
            canvas.addEventListener('mouseover', editor.unFocus, false );
        },

        haveFocus: function () {
            canvas.removeEventListener('mouseover', editor.unFocus, false );
        },

        

        /*initLights: function ( shadow ) {

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

        },*/

        /*initPostEffect: function () {

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

        },*/

        // -----------------------
        //  LOADING SIDE
        // -----------------------

        loadAssets : function ( EnvName ) {

            envName = envName || 'grey1'

            cube_name = [ 'grey1' ];

            txt_name = [ 'stone', 'bump', 'tex06', 'tex18', 'tex07', 'tex03', 'tex09', 'tex00', 'tex08', 'tex01', 'tex05', 'tex02', 'tex12', 'tex10', 'tex17' ];

            pool.load( ['glsl_basic/basic_vs.glsl', 'glsl_basic/basic_fs.glsl', 'textures/basic.png', 'textures/noise.png'], view.initModel );

        },

        loadAssetsPlus : function ( EnvName ) {

            var urls = [];

            editor.setMessage( 'load' );
            
            var i = txt_name.length;
            while(i--) urls.push('textures/'+txt_name[i]+'.png');

            urls.push('textures/cube/'+envName+'.cube');

            pool.load( urls, view.endLoading );

        },

        endLoading: function() {

            isLoaded = true;

            if(!isError) editor.setMessage( 'v' + (isWebGL2 ? '2' : '1'));
            else editor.setMessage('error');

            var p = pool.getResult();

            // init textures

            var i = txt_name.length, tx, j, name;
            while(i--){

                name = txt_name[i];
                tx = new THREE.Texture( p[name] );
                tx.wrapS = tx.wrapT = THREE.RepeatWrapping;
                if( name === 'tex10'|| name === 'tex12') tx.flipY = false;
                else tx.flipY = true;
                tx.needsUpdate = true;
                txt[name] = tx;

                // apply after first load
                j = channels.length;
                while(j--){
                    if( channels[j] === name ){ 
                        uniforms['iChannel'+j].value = tx;
                        channelResolution[j].x = tx.image.width; 
                        channelResolution[j].y = tx.image.height;
                    }
                }
            }

            // init envmap
            txt[envName] = p[envName];
            textureCube = p[envName];

            j = 4;
                while(j--){
                if( channels[j] === envName ) uniforms['iChannel'+j].value = txt[envName];
            }


        },

        


        /////////////////// CHANNEL

        createShaderMaterial : function ( frag, uni ) {

            //var uni = Uni || {};

            var m = new THREE.ShaderMaterial( {
                uniforms: uni,
                vertexShader: vertex,//[ 'void main(){', 'gl_Position = vec4( position, 1.0 );', '}'].join('\n'),
                fragmentShader: frag
            });

            return m;

        },

        createRenderTarget : function ( w, h ) {

            return new THREE.WebGLRenderTarget( w, h, { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, type: THREE.FloatType, stencilBuffer: false, format: THREE.RGBAFormat });

             //THREE.NearestFilter

        },

        /*createRenderTexture : function ( w, h ) {

            var a = new Float32Array( w * h * 4 );
            var texture = new THREE.DataTexture( a, w, h, THREE.RGBAFormat, THREE.FloatType );
            texture.needsUpdate = true;
            return texture;

        },*/

        createChannel : function( i, size, file, c ){

            //if(tmp_txt.indexOf(file) !== -1) return;

            var w = vsize.x; 
            var h = vsize.y;

            if(size !== "FULL") w = h = Number( size );

            //console.log( w, h );

            channelResolution[i].x = w; 
            channelResolution[i].y = h;

            C_uniforms[i] = THREE.UniformsUtils.clone( base_uniforms );
            C_uniforms[i].iChannelResolution.value = channelResolution;
            C_uniforms[i].iResolution.value = new THREE.Vector3( w, h, w / h );
            C_uniforms[i].iMouse.value = mouse;
            C_uniforms[i].key.value = key;

            C_uniforms[i].iGlobalTime.value = time;
            C_uniforms[i].iFrame.value = frame;

            C_textures[i] = view.createRenderTarget( w, h );

            

            //console.log( i, w, h, file );
            editor.load( file, i, view.applyChannel, c );

        },

        applyChannel : function ( i, frag, name, c ) {

            var f = view.makeFragment( frag, i+1 );

            //console.log( f );

            C_materials[i] = view.createShaderMaterial( f, C_uniforms[i] );
            isBuff[i] = true;

            txt[ name ] = C_textures[i].texture;

            //tmp_txt.push( name );

            //console.log(tmp_txt);

            if(c===0) uniforms['iChannel'+i].value = txt[ name ];
            else C_uniforms[c-1]['iChannel' + i].value = txt[ name ];

        },


        ///////////////////

        findChannel : function ( frag, c ) {

            var i = 4, pre, type, name, size, file, n, j;
            while(i--){

                pre = frag.search( i + '_#' );
                name = pre !== -1 ? frag.substring( pre + 4, frag.lastIndexOf( '#_' + i ) - 1 ) : null;
                type = cube_name.indexOf( name ) !== -1 ? 'samplerCube' : 'sampler2D';

                if(name !== null){
                    if( name.substring(0,6) === 'buffer'){
                        
                        // size
                        if( name.substring(6,10) === 'FULL' ) n = 10;
                        else if( ! isNaN(name.substring(6,10)) ) n = 10;
                        else if( ! isNaN(name.substring(6,9)) ) n = 9;
                        else if( ! isNaN(name.substring(6,8)) ) n = 8;
                        else if( ! isNaN(name.substring(6,7)) ) n = 7;

                        size = name.substring(6,n);
                        file = name.substring(n+1);

                    }
                    
                }

            }


        },

        makeFragment : function ( frag, c ){

            //console.log( c );

            var isch = c === 0 ? false : true;
            var Uni = [];
            var i = 4, pre, type, name, size, file, n, j;

            

            

            

            //if(!isch){


            while(i--){

                pre = frag.search( i + '_#' );
                name = pre !== -1 ? frag.substring( pre + 4, frag.lastIndexOf( '#_' + i ) - 1 ) : null;
                type = cube_name.indexOf( name ) !== -1 ? 'samplerCube' : 'sampler2D';

                if(name !== null){
                    if( name.substring(0,6) === 'buffer'){ 

                        //var s, n;
                        if( name.substring(6,10) === 'FULL' ) n = 10;
                        else if( ! isNaN(name.substring(6,10)) ) n = 10;
                        else if( ! isNaN(name.substring(6,9)) ) n = 9;
                        else if( ! isNaN(name.substring(6,8)) ) n = 8;
                        else if( ! isNaN(name.substring(6,7)) ) n = 7;

                        size = name.substring(6,n);
                        file = name.substring(n+1);

                        if( tmp_txt.indexOf(file) === -1 ){ 
                            view.createChannel( i, size, file, c );
                            tmp_txt.push( file );
                        }
                    }
                    
                }

                Uni.push( 'uniform '+ type +' iChannel' + i + ';' );

                j = c*4;

                if( txt[ name ] ){ 
                    if(c===0) {
                        uniforms['iChannel' + i].value = txt[ name ];
                        //if( type !== 'samplerCube' ) editor.setChannelPad( i, 'image', name );
                    }
                    else C_uniforms[c-1]['iChannel' + i].value = txt[ name ];

                    if( type !== 'samplerCube' ) {
                        channelResolution[i].x = txt[ name ].image.width; 
                        channelResolution[i].y = txt[ name ].image.height;
                    }
                }

                channels[j] = name; 

                channelNames[c][j] = name;

            }

            Uni.push(

                'uniform int iFrame;',
                'uniform vec4 iMouse;',
                'uniform vec3 iResolution;',
                'uniform float iGlobalTime;',
                'uniform vec2 iChannelResolution[4];',
                'uniform float key[20];',
                'uniform float iDate;',

                'varying vec2 vUv;'

            );

            // auto main for three js
            var Main = frag.indexOf( 'void main()' ) !== -1 ? [''] : base_main;

            return Uni.join('\n') + frag + Main.join('\n');

        },

        reset: function ( ) {



            //isBuff = [ false, false, false, false ];

            var i;

            //console.clear();
            

            i = tmp_txt.length;
            while(i--){ 
                txt[tmp_txt[i]].dispose();
                txt[tmp_txt[i]] = null;
            }

            tmp_txt = [];

            for(var i=0; i<4 ; i++){
                if( isBuff[i] ){ 

                    isBuff[i] = false;
                    C_materials[i].dispose();
                    C_textures[i].dispose();
                    C_uniforms[i] = null;
                    
                }
            }

            time = 0;
            frame = 0;

            channelNames = [ [], [], [], [], [] ];

            console.log('view reset');

        },



        applyFragment : function( frag, n ) {

            console.log( 'channel num: ' + n );

            view.validate( material.completeFragment( frag ) );

            /*material.dispose();
            material = new THREE.Shadertoy( frag );

            material.uniforms.iResolution.value = vsize;
            material.uniforms.iMouse.value = mouse;
            material.uniforms.key.value = key;

            mesh.material = material;*/
            editor.setTitle();

            console.log(material.channels);


            

            //fragment = view.makeFragment( frag, 0 );
            //view.validate( fragment );

        },

        /*applyMaterial : function ( frag ) {

            // reset old

            material.dispose();

            material = new THREE.ShaderMaterial({
                uniforms: uniforms,
                vertexShader: vertex,
                fragmentShader: fragment,
                //transparent: false,
            });

            


            mesh.material = material;
            editor.setTitle();

        },*/

        validate : function ( frag ) {

            var details, error, i, line, lines, log, message, status, _i, _len;
            var data = [];//{lineNumber:0, message:''}];

            var baseVar = [
                'precision '+precision+' float;',
                'precision '+precision+' int;',
                'uniform mat4 viewMatrix;',
                'uniform vec3 cameraPosition;',
            ].join('\n');

            try {

                tmpShader = gl.createShader( gl.FRAGMENT_SHADER );
                gl.shaderSource( tmpShader, baseVar + frag );
                gl.compileShader( tmpShader );
                status = gl.getShaderParameter( tmpShader, gl.COMPILE_STATUS );
                //if (!status) console.log( gl.getShaderInfoLog( tmpShader ) );
            } catch (e) {
                data.push( { lineNumber:0, message:e.getMessage } );
            } 

            if ( status === true ) {

                //gl.deleteShader( tmpShader );

                //view.applyMaterial( frag );

                material.updateFragment( frag );

                isError = false;

                if( isLoaded ) editor.setMessage( 'v' + (isWebGL2 ? '2' : '1'));

                //clearTimeout( interval );
                //interval = setTimeout( function() { view.applyMaterial(); }, 10 );
                //view.applyMaterial();

            }else{

                log = gl.getShaderInfoLog( tmpShader );
                //gl.deleteShader( tmpShader );
                
                lines = log.split('\n');
                for (_i = 0, _len = lines.length; _i < _len; _i++) {
                    i = lines[_i];
                    if (i.substr(0, 5) === 'ERROR') { error = i; }
                }

                if (!error) data.push( {lineNumber:0, message:'Unable to parse error.'} );
            
                details = error.split(':');
                if ( details.length < 4 ) data.push( {lineNumber:0, message:error } );

                line = details[2];
                message = details.splice(3).join(':');
                data.push( { lineNumber:parseInt( line )-11, message:message } );

                isError = true;
                if( isLoaded ) editor.setMessage( 'error' );
            }

            gl.deleteShader( tmpShader );
            tmpShader = null;

            editor.validate( data );

        },

        initModel : function () {

            var p = pool.getResult();
        
            // init base textures

            var tx = new THREE.Texture( p['basic'] );
            tx.wrapS = tx.wrapT = THREE.RepeatWrapping;
            tx.needsUpdate = true;
            txt['basic'] = tx;

            var tx2 = new THREE.Texture( p['noise'] );
            tx2.wrapS = tx2.wrapT = THREE.RepeatWrapping;
            tx2.flipY = false;
            tx2.needsUpdate = true;
            txt['noise'] = tx2;

            // init empty cube textures

            var imgs = [];
            var i=6;
            while(i--) imgs.push(p['basic']);
            txt[envName] = new THREE.CubeTexture( imgs );

            // init basic shader

           // vertex = p['basic_vs'];
           // fragment = p['basic_fs'];

            // init main uniforms

          /*  uniforms = THREE.UniformsUtils.clone( base_uniforms );

            uniforms.iChannelResolution.value = channelResolution;
            uniforms.iResolution.value = vsize;
            uniforms.iMouse.value = mouse;
            uniforms.key.value = key;*/

            material = new THREE.Shadertoy();

            material.uniforms.iResolution.value = vsize;
            material.uniforms.iMouse.value = mouse;
            material.uniforms.key.value = key;
            

            /*material = new THREE.ShaderMaterial({
                uniforms: uniforms,
                vertexShader: vertex,
                fragmentShader: fragment,
                transparent:false,
            });*/


            view.setScene( 0 );

            ready();

            view.loadAssetsPlus();

        },

        setScene : function( n ){

            var g;

            if(mesh !== null){
                if(currentScene === 0 ) camera.remove( mesh );
                else scene.remove( mesh );
            }

            if( n === 0 ){

                g = new THREE.PlaneBufferGeometry( 1, 1, 1, 1 );
                mesh = new THREE.Mesh( g, material );
     
                var mh = 2 * Math.tan( (camera.fov * degtorad) * 0.5 ) * 1;
                mesh.scale.set(mh*vsize.z, mh, 1);
                mesh.position.set(0,0,-1);

                camera.add( mesh );

            }

            if( n === 1 ){

                g = new THREE.SphereBufferGeometry(3, 30, 26, 30*degtorad, 120*degtorad, 45*degtorad, 90*degtorad );
                mesh = new THREE.Mesh( g, material );
                scene.add( mesh );

            }

            if( n === 2 ){

                g = new THREE.TorusBufferGeometry( 3, 1, 50, 20 );
                mesh = new THREE.Mesh( g, material );
                scene.add( mesh );

            }

            currentScene = n;

        },

        setBackground: function(){

            if( params.background ) scene.background = textureCube;
            else scene.background = null;

        },


        // -----------------------
        //  GET FUNCTION
        // -----------------------

        getMouse: function () { return mouse; },

        getKey: function () { return key; },

        getUniforms : function () { return THREE.UniformsUtils.clone( base_uniforms ); },

        getContext: function () { return gl; },

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

        /*moveCamera: function( c, t ){
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

        /*setEnv: function( img ){

            env = new THREE.Texture( img );
            env.mapping = THREE.SphericalReflectionMapping;
            env.needsUpdate = true;

            return env;

        },

        getEnv: function(){

            return env; 

        },*/

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

    // ------------------------------
    //   GPU RENDER
    // ------------------------------

    view.GpuSide = function(){

        this.renderer = view.getRenderer();
        this.scene = new THREE.Scene();
        this.camera = new THREE.Camera();
        this.camera.position.z = 1;

        this.baseMat = new THREE.MeshBasicMaterial({color:0x00FFFF});
        this.mesh = new THREE.Mesh( new THREE.PlaneBufferGeometry( 2, 2 ) , this.baseMat );
        
        this.scene.add( this.mesh );

    };

    view.GpuSide.prototype = {

        render : function ( mat, output ) {

            //console.log(output)

            this.mesh.material = mat;
            this.renderer.render( this.scene, this.camera, output );
            //this.mesh.material = this.baseMat;

        }
    }

    // ------------------------------
    //   CHANNEL
    // ------------------------------

    view.Channel = function(){
        
        this.size = new THREE.Vector3();
        this.renderTarget = null;
        this.texture = null;
        this.material = null;
        this.uniforms = null;
        this.fragment = null;

        this.actif = false;

    }

    view.Channel.prototype = {

        dispose : function () {

        },

        load : function ( file ) {

            editor.load( file, i, view.applyChannel, c );

        },

        init : function ( w, h, file ) {

            this.size.set( w, h, w / h );

            this.uniforms = view.getUniforms();
            this.uniforms.iResolution.value = this.size;
            this.uniforms.iMouse.value = view.getMouse();
            this.uniforms.key.value = view.getKey();

        },

        upUniforms : function ( time, frame ) {

            this.uniforms.iGlobalTime.value = time;
            this.uniforms.iFrame.value = frame;

        },

        resize : function () {

        }


    }

    return view;

})();



