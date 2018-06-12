


THREE.Shadertoy = function ( frag, tone, objSpace, parameters ) {

    THREE.ShaderMaterial.call( this, parameters );

    this.overdraw = false;

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
        iTimeDelta: { type: 'f', value: 0 },
        iTime: { type: 'f', value: 0 },
        iResolution: { type: 'v3', value: null },
        iMouse: { type: 'v4', value: null },
        iFrame: { type: 'i', value: 0 },
        iDate: { type: 'v4', value: new THREE.Vector4() },
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

    var encode = [
        'float shift_right (float v, float amt) {',
            'v = floor(v) + 0.5;',
            'return floor(v / exp2(amt));',
        '}',
        'float shift_left (float v, float amt) {',
            'return floor(v * exp2(amt) + 0.5);',
        '}',
        'float mask_last (float v, float bits) {', 
            'return mod(v, shift_left(1.0, bits));',
        '}',
        'float extract_bits (float num, float from, float to) {',
            'from = floor(from + 0.5); to = floor(to + 0.5);',
            'return mask_last(shift_right(num, from), to - from);',
        '}',
        'vec4 encode_float (float val) {',
            'if (val == 0.0) return vec4(0, 0, 0, 0);',
            'float sign = val > 0.0 ? 0.0 : 1.0;',
            'val = abs(val);',
            'float exponent = floor(log2(val));',
            'float biased_exponent = exponent + 127.0;',
            'float fraction = ((val / exp2(exponent)) - 1.0) * 8388608.0;',
            'float t = biased_exponent / 2.0;',
            'float last_bit_of_biased_exponent = fract(t) * 2.0;',
            'float remaining_bits_of_biased_exponent = floor(t);', 
            'float byte4 = extract_bits(fraction, 0.0, 8.0) / 255.0;', 
            'float byte3 = extract_bits(fraction, 8.0, 16.0) / 255.0;', 
            'float byte2 = (last_bit_of_biased_exponent * 128.0 + extract_bits(fraction, 16.0, 23.0)) / 255.0;', 
            'float byte1 = (sign * 128.0 + remaining_bits_of_biased_exponent) / 255.0;',
            'return vec4(byte4, byte3, byte2, byte1);',
        '}',
        'float decode_float( vec4 val ) {',
            'float sign = ( val.a * 255. / pow( 2., 7. ) ) >= 1. ? -1. : 1.;',
            'float s = val.a * 255.;',
            'if( s > 128. ) s -= 128.;',
            'float exponent = s * 2. + floor( val.b * 255. / pow( 2., 7. ) );',
            'float mantissa = ( val.r * 255. + val.g * 255. * 256. + clamp( val.b * 255. - 128., 0., 255. ) * 256. * 256. );',
            'float t = val.b * 255.;',
            'if( t > 128. ) t -= 128.;',
            'mantissa = t * 256. * 256. + val.g * 255. * 256. + val.r * 255.;',
            'return sign * pow( 2., exponent - 127. ) * ( 1. + mantissa / pow ( 2., 23. ) );',
        '}',
    ];

    var prev = [

        'uniform '+ this.channels[0].type +' iChannel0;',
        'uniform '+ this.channels[1].type +' iChannel1;',
        'uniform '+ this.channels[2].type +' iChannel2;',
        'uniform '+ this.channels[3].type +' iChannel3;',

        'uniform int iFrame;',
        'uniform vec4 iMouse;',
        'uniform vec4 iDate;',
        'uniform vec3 iResolution;',
        'uniform float iGlobalTime;',
        'uniform float iTime;',
        'uniform float iTimeDelta;',
        'uniform vec2 iChannelResolution[4];',
        'uniform float key[20];',
        
        'varying vec2 vUv;',
        ' ',

    ];

    var end = frag.indexOf( 'void main()' ) !== -1 ? [''] : def_main;

    return prev.join('\n') + encode.join('\n') + frag + end.join('\n');

}

THREE.Shadertoy.prototype.findChannels = function ( frag ) {

    var i, pre, name, n;

    for( var i = 0; i < 4; i++ ){

        this.channels[i] = {};
        this.channels[i].type = 'sampler2D';
        this.channels[i].buffer = false;
        this.channels[i].def = '';
        //this.channels[i].actif = false;

        pre = frag.search( i + '_#' );
        name = pre !== -1 ? frag.substring( pre + 4, frag.lastIndexOf( '#_' + i ) - 1 ) : '';
        this.channels[i].name = name;

        if( name ){

            this.channels[i].def = 'image';

            //this.channels[i].actif = true;

            if( name.substring( 0, 4 ) === 'cube' ){

                this.channels[i].type = 'samplerCube';
                this.channels[i].name = name.substring( 5 );
                this.channels[i].def = 'cube';

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
                this.channels[i].def = 'buffer';

            } 

        }

    }

}