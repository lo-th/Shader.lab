


THREE.Shadertoy = function ( frag, tone, objSpace ) {

    THREE.ShaderMaterial.call( this );

    this.objSpace = objSpace !== undefined ? objSpace : true;
    this.isTone = tone !== undefined ? tone : true;

    this.channels = [];

    this.channelRes = [
        new THREE.Vector2(512,512),
        new THREE.Vector2(512,512),
        new THREE.Vector2(512,512),
        new THREE.Vector2(512,512)
    ];

    this.uniforms = {

        iChannel0: { type: 't', value: null },
        iChannel1: { type: 't', value: null },
        iChannel2: { type: 't', value: null },
        iChannel3: { type: 't', value: null },

        iChannelResolution: { type: 'v2v', value: this.channelRes },

        iGlobalTime: { type: 'f', value: 0 },
        iResolution: { type: 'v3', value: null },
        iMouse: { type: 'v4', value: null },
        iFrame: { type: 'i', value: 0 },
        iDate: { type: 'f', value: 0 },
        //
        key: { type:'fv', value:null },

    }

    this.vertexShader = [
        'varying vec2 vUv;',
        'void main() {',
        '    vUv = uv;',
        '    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
        '}'
    ].join('\n');

    if( frag !== undefined ) this.fragmentShader = this.completeFragment( frag );
    else this.fragmentShader = 'void main() {\n\tgl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );\n}';

    /*var parameters = {
        uniforms: uniforms,
        vertexShader: vertex,
        fragmentShader: this.completeFragment( frag ),
    }

    //

    THREE.ShaderMaterial.call( this, parameters );*/

}


THREE.Shadertoy.prototype = Object.create( THREE.ShaderMaterial.prototype );
THREE.Shadertoy.prototype.constructor = THREE.Shadertoy;

THREE.Shadertoy.prototype.setUniforms = function ( name, value ) {

    this.uniforms[ name ].value = value;

}

THREE.Shadertoy.prototype.setChannelResolution = function ( n, x, y ) {

    this.channelRes[n].x = x;
    this.channelRes[n].y = y;

    //this.uniforms.iChannelResolution[n].value = new THREE.Vector2( x, y );
    this.uniforms.iChannelResolution.value = this.channelRes;

}

THREE.Shadertoy.prototype.updateFragment = function ( frag ) {

    this.fragmentShader = frag;//this.completeFragment( frag );
    this.needsUpdate = true;

}

THREE.Shadertoy.prototype.completeFragment = function ( frag ) {

    var def_main = [
        ' ',
        'void main(){',
        '    vec4 color = vec4(0.0);',
    ]

    if( this.objSpace ) def_main.push( '    vec2 coord = vUv * iResolution.xy;' );
    else def_main.push( '    vec2 coord = gl_FragCoord.xy;' );

    def_main.push( '    mainImage( color, coord );' );

    if( this.isTone ) def_main.push( '    #if defined( TONE_MAPPING )', '    color.rgb = toneMapping( color.rgb );', '    #endif' );

    def_main.push('    gl_FragColor = color;', '}');

    this.findChannels( frag );

    var prev = [

        'uniform '+ this.channels[0].type +' iChannel0;',
        'uniform '+ this.channels[1].type +' iChannel1;',
        'uniform '+ this.channels[2].type +' iChannel2;',
        'uniform '+ this.channels[3].type +' iChannel3;',

        'uniform int iFrame;',
        'uniform vec4 iMouse;',
        'uniform vec3 iResolution;',
        'uniform float iGlobalTime;',
        'uniform vec2 iChannelResolution[4];',
        'uniform float key[20];',
        'uniform float iDate;',

        'varying vec2 vUv;',
        ' ',

    ];

    var end = frag.indexOf( 'void main()' ) !== -1 ? [''] : def_main;

    return prev.join('\n') + frag + end.join('\n');

}

THREE.Shadertoy.prototype.findChannels = function ( frag ) {

    var i, pre, name, n;

    for( var i = 0; i < 4; i++ ){

        this.channels[i] = {};
        this.channels[i].type = 'sampler2D';
        this.channels[i].buffer = false;
        //this.channels[i].actif = false;

        pre = frag.search( i + '_#' );
        name = pre !== -1 ? frag.substring( pre + 4, frag.lastIndexOf( '#_' + i ) - 1 ) : '';
        this.channels[i].name = name;

        if( name ){

            //this.channels[i].actif = true;

            if( name.substring( 0, 4 ) === 'cube' ){

                this.channels[i].type = 'samplerCube';
                this.channels[i].name = name.substring( 5 );

            }

            if( name.substring( 0, 6 ) === 'buffer' ){

                if( name.substring(6,10) === 'FULL' ) n = 10;
                else if( ! isNaN(name.substring( 6, 10 ))) n = 10;
                else if( ! isNaN(name.substring( 6, 9 ))) n = 9;
                else if( ! isNaN(name.substring( 6, 8 ))) n = 8;
                else if( ! isNaN(name.substring( 6, 7 ))) n = 7;

                this.channels[i].size = name.substring( 6, n );
                this.channels[i].name = name.substring( n + 1 );
                this.channels[i].buffer = true;

            } 

        }

    }

}