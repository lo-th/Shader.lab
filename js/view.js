

var view = ( function () {

    'use strict';

    var isReady = false;
    var isClear = false;

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


    var tmpShader = null;

    var materials = [ null, null, null, null, null ];
    var buffers_1  = [ null, null, null, null, null ];
    var buffers_2  = [ null, null, null, null, null ];

    var tmp_txt = [];

    var currentScene = -1;

    var degtorad = 0.0174532925199432957;
    var radtodeg = 57.295779513082320876;

    var gl, canvas, renderer, gputmp, scene, camera, controls, light;//, clock;
    var vsize, mouse, key = new Float32Array( 20 );

    var time = 0;

    var vs = { w:1, h:1, l:0, x:0 , y:0};


    var txt = {};
    var txt_name = [];
    var cube_name = [];

    var geo = {};

    var extraUpdate = [];
    var toneMappings;

    var isWebGL2 = false;
    var isMobile = false;
    var isLoaded = false;
    var isError = false;

    var mesh, mesh2;

    var tmp_buffer = [];

    var precision = 'highp';


    view = {

        render: function () {

            var i, name;

            requestAnimationFrame( view.render );

            i = extraUpdate.length;
            while(i--) extraUpdate[i]();

            key = user.getKey();
            time += params.Speed * 0.01;


            if(isClear) { 

                //renderer.clearColor();
                //renderer.setClearColor( 0x1e1e1e, 1 );
                // renderer.clear();

                gl.clear(gl.DEPTH_BUFFER_BIT | gl.COLOR_BUFFER_BIT);

               //  gl.clearColor(1, 0.5, 0.5, 3);

                // console.log('isclear')
                //r
                isClear = false; 
            }

            //console.log(clock.getDelta())

            //i = materials.length;
            for( i = 0; i < 5; i ++ ){

                if( materials[i] !== null ){

                    materials[i].uniforms.iGlobalTime.value = time;
                    //materials[i].uniforms.iFrame.value = frame;

                    if( i !== 0 ){ 
                        name = materials[i].name;
                        gputmp.render( materials[i], buffers_1[i] );
                        gputmp.renderTexture( buffers_1[i].texture, buffers_2[i], buffers_1[i].width, buffers_1[i].height );
                        materials[i].uniforms.iFrame.value ++;
                    }

                }

            }

             
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

            for(var i = 1; i < 5; i++){
                if(materials[i] !== null){
                    if( buffers_1[i].isFull ){
                        buffers_1[i].setSize( vsize.x, vsize.y );
                        buffers_2[i].setSize( vsize.x, vsize.y );
                        materials[i].uniforms.iFrame.value = 0;
                    }            
                }
                
            }

            editor.resizeMenu( vsize.x );

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

            mouse = new THREE.Vector4();

            var drawBuffer = false;

            ///////////

            canvas = document.createElement("canvas");
            canvas.className = 'canvas3d';
            canvas.oncontextmenu = function(e){ e.preventDefault(); };
            canvas.ondrop = function(e) { e.preventDefault(); };
            //document.body.appendChild( canvas );
            document.body.insertBefore( canvas, document.body.childNodes[0] );

            isWebGL2 = false;

            var options = { antialias: false, alpha:false, stencil:false, depth:false, precision:precision, preserveDrawingBuffer:drawBuffer }

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


            renderer = new THREE.WebGLRenderer({ canvas:canvas, context:gl, antialias:false, alpha:false, precision:precision, preserveDrawingBuffer:drawBuffer, stencil:false  });
            //renderer = new THREE.WebGLRenderer({ canvas:canvas, antialias:false, alpha:false, preserveDrawingBuffer:true, precision:precision });
            renderer.setPixelRatio( params.pixelRatio );
            renderer.setSize( vsize.x, vsize.y );
            renderer.setClearColor( 0x1e1e1e, 1 );



            //

            renderer.gammaInput = true;
            renderer.gammaOutput = true;

            //renderer.autoClear = false;
            //renderer.sortObjects = false;
            renderer.autoClearColor = drawBuffer ? false : true;
            //renderer.autoClearStencil = false;

            //gl = renderer.getContext();

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

            if( materials[0] && nup ) materials[0].needsUpdate = true;


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

        // -----------------------
        //  LOADING SIDE
        // -----------------------

        loadAssets : function ( EnvName ) {

            //envName = envName || 'grey1'

            cube_name = [ 'grey1' ];

            txt_name = [ 'stone', 'bump', 'tex06', 'tex18', 'tex07', 'tex03', 'tex09', 'tex00', 'tex08', 'tex01', 'tex05', 'tex02', 'tex12', 'tex10', 'tex17' ];

            pool.load( [ 'textures/basic.png', 'textures/noise.png' ], view.initModel );

        },

        loadAssetsPlus : function ( EnvName ) {

            var urls = [];

            editor.setMessage( 'load' );
            
            var i = txt_name.length;
            while(i--) urls.push('textures/'+txt_name[i]+'.png');

            i = cube_name.length;
            while( i-- ) urls.push('textures/cube/'+cube_name[i]+'.cube');

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

            }

            i = cube_name.length;
            while(i--){
                name = cube_name[i];
                txt[name] = p[name];
            }

            // apply texture after final load
            i = materials.length;
            while(i--){
                view.pushChannel(i);
            }

        },

        // -----------------------
        //  VIEW RESET
        // -----------------------

        reset: function ( ) {



            var i, name;

            //console.clear();

            for( i = 1; i < 5; i++ ){

                if(materials[i] !== null ){

                    name = materials[i].name;

                    if( txt[ name ] ){ 
                        txt[ name ].dispose();
                        txt[ name ] = null;
                    }

                    materials[i].dispose();
                    buffers_1[i].dispose();
                    buffers_2[i].dispose();

                    materials[i] = null;
                    buffers_1[i] = null;
                    buffers_2[i] = null;
                }

            }

            time = 0;

            tmp_buffer = [];

            isClear = true;

            console.log('view reset');

        },

        // -----------------------
        //  FRAGMENT
        // -----------------------

        applyFragment : function( frag, n ) {

            view.validate( materials[n].completeFragment( frag ), n );
            if( n === 0 ) editor.setTitle();

        },

        pushChannel : function ( ) {

            var n, i, name, buff, channel, size;

            for( n = 0; n < 5; n ++ ){

                if( materials[n] !== null ){

                    channel = materials[n].channels;

                    for( i = 0; i < 4; i++ ){

                        name = channel[i].name;
                        buff = channel[i].buffer;

                        if(buff){

                            size = channel[i].size;
                            if(size === "FULL") materials[n].setChannelResolution( i, vsize.x, vsize.y );
                            else materials[n].setChannelResolution( i, Number( size ), Number( size ) );


                            if( tmp_buffer.indexOf(name) === -1 ) {

                                editor.load( name, channel[i].size ); 
                                tmp_buffer.push( name );
                            }
                        }
                            
                        if( name && txt[name] ){ 
                            materials[n].uniforms['iChannel'+i].value = txt[name];
                            //materials[n].channelRes[i].x = 128;
                            //materials[n].channelRes[i].y = 128;
                        }
                        
                    }
                }
            }

        },

        addBuffer : function ( frag, n, name, size ){

            //console.log( n, name, size );

            var isFull = size === "FULL" ? true : false;

            var w = isFull ? vsize.x : Number( size ); 
            var h = isFull ? vsize.y : Number( size );
            //if(size !== "FULL") w = h = Number( size );
            //var d = w / h;

            materials[n] = new THREE.Shadertoy( frag, false, isFull );
            materials[n].uniforms.iResolution.value = vsize;///new THREE.Vector3( w, h, d );
            materials[n].uniforms.iMouse.value = mouse;
            materials[n].uniforms.key.value = key;

            materials[n].name = name;

            buffers_1[n] = view.addRenderTarget( w, h, isFull );
            buffers_2[n] = view.addRenderTarget( w, h, isFull );

            //tmp_txt.push( name );
            //txt[ name ] = buffers[n].texture;

            txt[ name ] = buffers_2[n].texture;

            view.pushChannel(n);

        },

        addRenderTarget : function ( w, h, full ) {

            //console.log(w, h)

            full = full || false;

            var min = THREE.NearestFilter;// full ? THREE.NearestFilter : THREE.LinearFilter;
            var max = THREE.NearestFilter;//full ? THREE.NearestFilter : THREE.LinearFilter;
            var wt = THREE.ClampToEdgeWrapping;
            var ws = THREE.ClampToEdgeWrapping;

            var r = new THREE.WebGLRenderTarget( w, h, { minFilter: min, magFilter: max, type: THREE.FloatType, stencilBuffer: false, depthBuffer :false, format: THREE.RGBAFormat, wrapT:wt, wrapS:ws });
            r.isFull = full || false;
            return r;

        },

        addTexture : function( w, h ) {

            w = w || vsize.x;
            h = h || vsize.y;

            var a = new Float32Array( w * h * 4 );
            var texture = new THREE.DataTexture( a, w, h, THREE.RGBAFormat, THREE.FloatType );
            texture.needsUpdate = true;

            return texture;

        },

    

        addMaterial : function ( n ){

            materials[n] = new THREE.Shadertoy();
            materials[n].uniforms.iResolution.value = vsize;
            materials[n].uniforms.iMouse.value = mouse;
            materials[n].uniforms.key.value = key;
            //materials[n].extensions.drawBuffers = true;

        },

        // -----------------------
        //  EDITOR VALIDATE FRAG
        // -----------------------

        validate : function ( frag, n ) {

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

            } catch ( e ) {

                data.push( { lineNumber:0, message:e.getMessage } );

            }

            isError = status ? false : true;

            if ( isError ) {

                log = gl.getShaderInfoLog( tmpShader );
                lines = log.split('\n');
                for (_i = 0, _len = lines.length; _i < _len; _i++) {
                    i = lines[_i];
                    if (i.substr(0, 5) === 'ERROR') { error = i; }
                }

                if ( !error ) data.push( {lineNumber:0, message:'Unable to parse error.'} );
            
                details = error.split(':');
                if ( details.length < 4 ) data.push( {lineNumber:0, message:error } );

                line = details[2];
                message = details.splice(3).join(':');
                data.push( { lineNumber:parseInt( line )-11, message:message } );

            }

            gl.deleteShader( tmpShader );
            tmpShader = null;

            editor.validate( data );

            if( isError ){ 

                if( isLoaded ) editor.setMessage( 'error' );

            } else {

                materials[n].updateFragment( frag );
                view.pushChannel( n );
                if( isLoaded ){ 
                    editor.setMessage( 'v' + (isWebGL2 ? '2' : '1'));
                    //view.pushChannel( n );
                }

            }

        },

        // -----------------------
        //  BASIC SCENE
        // -----------------------

        initModel : function () {

            var p = pool.getResult();
        
            // init base textures

            var tx = new THREE.Texture( p['basic'] );
            tx.wrapS = tx.wrapT = THREE.RepeatWrapping;
            tx.needsUpdate = true;
            txt['basic'] = tx;

            tx = new THREE.Texture( p['noise'] );
            tx.wrapS = tx.wrapT = THREE.RepeatWrapping;
            tx.flipY = false;
            tx.needsUpdate = true;
            txt['noise'] = tx;

            view.addMaterial( 0 );

            view.setScene( 0 );

            ready();

            view.loadAssetsPlus();

        },

        // -----------------------
        //  SCENE SWITCH
        // -----------------------

        setScene : function( n ){

            var g;

            if(mesh !== null){
                if(currentScene === 0 ) camera.remove( mesh );
                else scene.remove( mesh );
            }

            if( n === 0 ){

                g = new THREE.PlaneBufferGeometry( 1, 1, 1, 1 );
                mesh = new THREE.Mesh( g, materials[0] );
     
                var mh = 2 * Math.tan( (camera.fov * degtorad) * 0.5 ) * 1;
                mesh.scale.set(mh*vsize.z, mh, 1);
                mesh.position.set(0,0,-1);

                camera.add( mesh );

            }

            if( n === 1 ){

                g = new THREE.SphereBufferGeometry(3, 30, 26, 30*degtorad, 120*degtorad, 45*degtorad, 90*degtorad );
                mesh = new THREE.Mesh( g, materials[0] );
                scene.add( mesh );

            }

            if( n === 2 ){

                g = new THREE.TorusBufferGeometry( 3, 1, 50, 20 );
                mesh = new THREE.Mesh( g, materials[0] );
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


        
        // -----------------------
        //  MATH FUNCTION
        // -----------------------

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

        this.baseMat = new THREE.MeshBasicMaterial({ color:0x00FFFF });
        this.mesh = new THREE.Mesh( new THREE.PlaneBufferGeometry( 2, 2 ) , this.baseMat );
        
        this.scene.add( this.mesh );

        this.passThruUniforms = { texture: { value: null }, resolution: { value: new THREE.Vector2(128,128) } };
        this.passThruShader = new THREE.ShaderMaterial( {
            uniforms: this.passThruUniforms,
            vertexShader: ['void main() {', 'gl_Position = vec4( position, 1.0 );', '}'].join('\n'),
            fragmentShader: ['uniform sampler2D texture;', 'uniform vec2 resolution;', 'void main() {', 'vec2 uv = gl_FragCoord.xy/ resolution.xy;', 'gl_FragColor = texture2D( texture, uv );', '}'].join('\n')
            //fragmentShader: ['uniform sampler2D texture;', 'void main() {', 'vec2 uv = gl_FragCoord.xy / resolution.xy;', 'gl_FragColor = texture2D( texture, uv );', '}'].join('\n')
        }); 

    };

    view.GpuSide.prototype = {

        render : function ( mat, output ) {

            this.mesh.material = mat;
            this.renderer.render( this.scene, this.camera, output, false );
            //this.mesh.material = this.passThruShader;

        },

        /*addResolutionDefine:function ( materialShader ) {

            materialShader.defines.resolution = 'vec2( ' + sizeX.toFixed( 1 ) + ', ' + sizeY.toFixed( 1 ) + " )";

        },*/

        renderTexture : function ( input, output, w, h ) {

            this.passThruUniforms.resolution.value.x = w;
            this.passThruUniforms.resolution.value.y = h;
            
            this.passThruUniforms.texture.value = input;
            this.render( this.passThruShader, output );
            //this.passThruUniforms.texture.value = null;

        }
    }


    return view;

})();



