/**   _   _____ _   _   
*    | | |_   _| |_| |
*    | |_ _| | |  _  |
*    |___|_|_| |_| |_|
*    @author lo.th / http://lo-th.github.io/labs/
*    CODEMIRROR ultimate editor
*/

var editor = ( function () {

    'use strict';

    //var rl = 250;

    //var channels = [];

    var content, codeContent, code, separator_l, separator_r, menuCode, version, bigmenu2, channelPad;//, debug, title; 

    var codes = {};
    var mainCode = '';
    var current = '';

    var ch = [];
    //var callback = function(){};
    var isSelfDrag = false;
    var isFocus = false;
    var errorLines = [];
    var widgets = [];
    var interval = null;
    var left = 0;
    var right = 0;
    var old_l = ~~ (window.innerWidth*0.4);
    var old_r = 250;
    //var fileName = '';
    //var fileName_old = '';
    var nextDemo = null;
    var selectColor = '#308AFF';
    var scrollOn = false;
    //var menuPins;
    var bigmenu;
    var github;
    var bigButton = [];
    var rubrics = [];
    var bigContent;

    var isMenu = false;

    var isWithCode = true;
    var isSepDown = false;

    var is_l_down = false;
    var is_r_down = false;

    var context = null;

    var octo, octoArm;

    var icon_Github = [
        "<svg width='60' height='60' viewBox='0 0 250 250' style='fill:rgba(255,255,255,0.2); color:#000000; position: absolute; top: 0; border: 0; right: 0;'>",
        "<path d='M0,0 L115,115 L130,115 L142,142 L250,250 L250,0 Z' id='octo' onmouseover='editor.Gover();' onmouseout='editor.Gout();' onmousedown='editor.Gdown();'></path>",
        "<path d='M128.3,109.0 C113.8,99.7 119.0,89.6 119.0,89.6 C122.0,82.7 120.5,78.6 120.5,78.6 C119.2,72.0 123.4,76.3 123.4,76.3 C127.3,80.9 125.5,87.3 125.5,87.3 C122.9,97.6 130.6,101.9 134.4,103.2' fill='currentColor' style='transform-origin: 130px 106px;' id='octo-arm'></path>",
        "<path d='M115.0,115.0 C114.9,115.1 118.7,116.5 119.8,115.4 L133.7,101.6 C136.9,99.2 139.9,98.4 142.2,98.6 C133.8,88.0 127.5,74.4 143.8,58.0 C148.5,53.4 154.0,51.2 159.7,51.0 C160.3,49.4 163.2,43.6 171.4,40.1 C171.4,40.1 176.1,42.5 178.8,56.2 C183.1,58.6 187.2,61.8 190.9,65.4 C194.5,69.0 197.7,73.2 200.1,77.6 C213.8,80.2 216.3,84.9 216.3,84.9 C212.7,93.1 206.9,96.0 205.4,96.6 C205.1,102.4 203.0,107.8 198.3,112.5 C181.9,128.9 168.3,122.5 157.7,114.1 C157.9,116.9 156.7,120.9 152.7,124.9 L141.0,136.5 C139.8,137.7 141.6,141.9 141.8,141.8 Z' fill='currentColor' id='octo-body'></path></svg>",
    ].join("\n");

    editor = {

        init : function ( withCode ) {

            //if( Callback ) callback = Callback;

            isWithCode = withCode !== undefined ? withCode : true;

            // big menu

            bigmenu2 = document.createElement( 'div' );
            bigmenu2.className = 'bigmenu';
            document.body.appendChild( bigmenu2 );

            bigmenu = document.createElement( 'div' );
            bigmenu.className = 'bigmenu';
            document.body.appendChild( bigmenu );

            this.makeBigMenu();

            // github logo

            github = document.createElement( 'div' );
            github.style.cssText = "position:absolute; right:0; top:0; width:1px; height:1px; pointer-events:none;";
            github.innerHTML = icon_Github; 
            document.body.appendChild( github );

            octo = document.getElementById('octo');
            octoArm = document.getElementById('octo-arm');

            // separator

            separator_l = document.createElement('div');
            separator_l.className = 'separator';
            document.body.appendChild( separator_l );

            separator_r = document.createElement('div');
            separator_r.className = 'separator';
            document.body.appendChild( separator_r );

            separator_r.style.left = 'auto';
            separator_r.style.right = right + 'px';

            separator_l.name = 'l';
            separator_r.name = 'r';

            // editor

            content = document.createElement('div');
            content.className = 'editor';
            document.body.appendChild( content );

            codeContent = document.createElement('div');
            codeContent.className = 'codeContent';
            content.appendChild( codeContent );

            code = CodeMirror( codeContent, {
                lineNumbers: true, matchBrackets: true, indentWithTabs: true, styleActiveLine: true,
                theme:'monokai', mode: "text/x-glsl",
                tabSize: 4, indentUnit: 4, highlightSelectionMatches: {showToken: /\w/}
            });

            menuCode = document.createElement('div');
            menuCode.className = 'menuCode';
            content.appendChild( menuCode );

            version = document.createElement( 'div' );
            version.className = 'version';
            content.appendChild( version );

            code.on('change', function () { editor.onChange() } );
            code.on('focus', function () { isFocus = true; view.needFocus(); } );
            code.on('blur', function () { isFocus = false; } );
            code.on('drop', function () { if ( !isSelfDrag ) code.setValue(''); else isSelfDrag = false; } );
            code.on('dragstart', function () { isSelfDrag = true; } );

            // channel pad

            this.initChannelPad();


            if( isWithCode ) editor.show();

        },

        initChannelPad : function () {

            channelPad = document.createElement( 'div' );
            channelPad.className = 'channelPad';
            document.body.appendChild( channelPad );
            
            for( var i = 0; i < 4; i++ ){
                ch[i] = document.createElement( 'div' );
                ch[i].className = 'ch';
                channelPad.appendChild( ch[i] );
            }

        },

        setChannelPad : function ( i, type, name ) {

            var c = document.createElement( 'div' );

            if( type === 'buffer' ){

            }else if( type === 'image' ){

                var img = pool.getResult()[name];
                if(img){
                    c = document.createElement( 'canvas' );
                    c.width = c.height = 64;
                    c.getContext('2d').drawImage( img,0,0,64,64);
                }
                

            } else if( type === 'cube' ){


            }

            c.className = 'chIn';
            ch[i].appendChild(c);

        },

        clearChannelPad : function () {

            var i = 4, j, b;
            while(i--){
                j = ch[i].childNodes.length;
                while(j--){
                    b = ch[i].childNodes[j];
                    //b.removeEventListener('mousedown', editor.codeDown );
                    ch[i].removeChild( b );
                }

            }

        },

        /////////////////////

        setMessage : function( t ) {

            if(t === 'v1') { version.style.background = 'rgba(0,255,255,0.3)'; version.style.width='40px'; }
            else if(t === 'v2') { version.style.background = 'rgba(0,255,0,0.3)'; version.style.width='40px'; }
            else if(t === 'error') { t = '/!&#92; error'; version.style.background = 'rgba(255,0,0,0.3)'; version.style.width='100px'; }
            else if(t === 'load'){ t = '/?&#92; loading'; version.style.background = 'rgba(0,50,255,0.3)'; version.style.width='130px';}
            version.innerHTML = t;

        },


        /*wheel : function( e ){

            e.preventDefault();
            e.stopPropagation();

            var delta = 0;
            if(e.wheelDeltaY) delta = -e.wheelDeltaY*0.04;
            else if(e.wheelDelta) delta = -e.wheelDelta*0.2;
            else if(e.detail) delta = e.detail*4.0;

            console.log(delta)

        },*/

        

        selectCode : function (){

            if(isWithCode) editor.hide();
            else editor.show();

        },

        hide : function (){

            isWithCode = false;
            content.style.display = 'none';
            separator_l.style.display = 'none';


            old_l = left;
            old_r = right;
            left = 0;
            right = 0;

            this.removeSeparatorEvent();

            editor.Bdefault(bigButton[1]);
            editor.resize();

            channelPad.style.display = 'none';
            gui.hide( true );

        },

        show : function (){

            isWithCode = true;
            editor.Bselect( bigButton[1] );
            content.style.display = 'block';
            separator_l.style.display = 'block';
            separator_r.style.display = 'block';

            left = old_l;
            right = old_r;
 
            this.addSeparatorEvent();
            editor.resize();

            channelPad.style.display = 'block';
            gui.hide(false);

        },

        resizeMenu : function ( w ) {

            if( bigmenu ){
                bigmenu.style.width = w +'px';
                bigmenu2.style.width = w +'px';
            }

        },

        resize : function ( e ) {

            if( e ){
                if( is_l_down ) left = e.clientX + 5;
                if( is_r_down ) { 
                    right = window.innerWidth - e.clientX + 5; 
                    
                    gui.resize( right );
                }
            }

            view.setLeft( left, right );
            view.resize();

            separator_r.style.right = right - 10 + 'px';
            github.style.right = right + 'px';
            channelPad.style.width = right - 10 + 'px';

            separator_l.style.left = left - 10 + 'px';
            bigmenu.style.left = left +'px';
            bigmenu2.style.left = left +'px';
            content.style.width = left - 10 + 'px';

            code.refresh();

        },

        tell : function ( str ) { 
            //debug.innerHTML = str; 
        },

        // MENUCODE

        clearMenuCode : function () {

            //codes = {};

            var i = menuCode.childNodes.length, b;
            while(i--){
                b = menuCode.childNodes[i];
                b.removeEventListener('mousedown', editor.codeDown );
                menuCode.removeChild( b );
            }

        },

        selectMenuCode : function () {

            var i = menuCode.childNodes.length, b;
            while(i--){
                b = menuCode.childNodes[i];
                if( b.name === current ) b.style.borderBottom = '1px solid #1e1e1e';
                else b.style.borderBottom = 'none';
            }

        },

        addCode : function ( name, m ) {

            var b = document.createElement('div');
            b.className = 'code';
            b.name = name;
            b.innerHTML = name;
            b.addEventListener('mousedown', editor.codeDown );
            if(m) b.style.borderBottom = '1px solid #1e1e1e';
            menuCode.appendChild( b );

        },

        codeDown : function ( e ) {

            var name = e.target.name;
            current = name;

            editor.selectMenuCode();
            code.setValue( codes[name] );

        },

        // bigmenu

        makeBigMenu : function() {

            //bigmenu.style.width = window.innerWidth - left +'px';

            bigButton[0] = document.createElement( 'div' );
            bigButton[0].className = 'bigButton';
            bigmenu.appendChild( bigButton[0] );
            bigButton[0].innerHTML = "MENU";
            bigButton[0].addEventListener('mousedown', editor.selectBigMenu, false );
            bigButton[0].name = 'demo';

            bigButton[1] = document.createElement( 'div' );
            bigButton[1].className = 'bigButton';
            bigmenu.appendChild( bigButton[1] );
            bigButton[1].innerHTML = "CODE";
            bigButton[1].addEventListener('mousedown', editor.selectCode, false );
            bigButton[1].name = 'code';

            //editor.Bselect( bigButton[1] );


            bigContent = document.createElement( 'div' );
            bigContent.className = 'bigContent';
            bigmenu2.appendChild( bigContent );





            //bigContent.style.display = "none";




            var i = bigButton.length;
            while(i--){
                bigButton[i].addEventListener('mouseover', editor.Bover, false );
                bigButton[i].addEventListener('mouseout', editor.Bout, false );
            }

        },

        selectBigMenu : function ( e ) {

            if(isMenu) editor.hideBigMenu();
            else editor.showBigMenu()
        },

        showBigMenu : function ( e ) {

            var lng, i;

            //bigContent.style.display = "block";
            bigmenu2.style.background = "rgba( 30,30,30,0.9 )";
            bigmenu2.style.borderBottom = "1px solid #626262";
            bigmenu2.style.height = 'auto';
            bigmenu2.style.display = 'block';
            //bigmenu.addEventListener('mouseout', editor.selectBigMenu, false );
            isMenu = true;

            //

            lng = demos_basic.length;
            if( lng )  editor.addRubric('BASIC');
            for( i = 0; i < lng ; i++ ) editor.addButton( demos_basic[i] );

            //

            lng = demos.length;
            if( lng ) editor.addRubric('SHADERS');
            for( i = 0; i < lng ; i++ ) editor.addButton( demos[i] );

            //

            lng = demos_advanced.length;
            if( lng ) editor.addRubric('ADVANCED');
            for( i = 0; i < lng ; i++ ) editor.addButton( demos_advanced[i] );

            //

            lng = demos_texture.length;
            if( lng ) editor.addRubric('TEXTURES');
            for( i = 0; i < lng ; i++ ) editor.addButton( demos_texture[i] );
    
        },

        hideBigMenu : function ( e ) {

            bigmenu2.style.background = "rgba(37,37,37,0)";
            bigmenu2.style.borderBottom = "1px solid rgba(255, 255, 255, 0)";
            bigmenu2.style.height = '0px';
            bigmenu2.style.display = 'none';
            isMenu = false;

            var i = bigContent.childNodes.length, b;
            while(i--){
                b = bigContent.childNodes[i];
                b.removeEventListener('mousedown', editor.bigDown );
                bigContent.removeChild( b );
            }

            editor.Bdefault(bigButton[0]);

        },

        addRubric : function ( name ) {

            var r = document.createElement('div');
            r.className = 'mRubric';
            r.innerHTML = name;
            bigContent.appendChild( r );

        },

        addButton : function ( name ) {

            var b = document.createElement('div');
            b.innerHTML = '&bull; ' + name;
            b.name = name;

            if( name === mainCode ){ 
                b.className = 'mButtonSelect';
            } else {
                b.className = 'mButton';
                b.addEventListener('mousedown', editor.bigDown, false );
            }

            bigContent.appendChild( b );
        
        },

        bigDown : function ( e ) {

            editor.hideBigMenu();
            editor.load( e.target.name );

        },

        Bover : function ( e ) {

            //e.target.style.border = "1px solid "+selectColor;
            e.target.style.background = selectColor;;
            e.target.style.color = "#FFF";

        },

        Bout : function ( e ) {

            var s = 0;
            if(e.target.name == 'code' && isWithCode) s = 1;
            if(e.target.name == 'demo' && isMenu) s = 1;

            if(s===0){
                editor.Bdefault( e.target );
            } else {
                editor.Bselect( e.target );
            }
            
        },

        Bselect : function ( b ) {

            //b.style.border = "1px solid rgba(255, 255, 255, 0)";
            b.style.background = "#626262";//"rgba(255, 255, 255, 0.2)";
            b.style.color = "#000000";

        },

        Bdefault : function ( b ) {

            //b.style.border = "1px solid #626262";
            b.style.background = "#1e1e1e";
            b.style.color = "#dedede";

        },

        // github logo

        Gover : function ( ) {
            octo.setAttribute('fill', '#105AE2'); 
            octoArm.style.webkitAnimationName = 'octocat-wave'; 
            octoArm.style.webkitAnimationDuration = '560ms';
        },

        Gout : function ( ) {
            octo.setAttribute('fill','rgba(255,255,255,0.2)');  
            octoArm.style.webkitAnimationName = 'none';
        },

        Gdown : function ( ) {
            window.location.assign('https://github.com/lo-th/Shader.lab');
        },

        // separator

        addSeparatorEvent : function () {

            separator_l.addEventListener('mouseover', editor.mid_over, false );
            separator_l.addEventListener('mouseout', editor.mid_out, false );
            separator_l.addEventListener('mousedown', editor.mid_down, false );

            separator_r.addEventListener('mouseover', editor.mid_over, false );
            separator_r.addEventListener('mouseout', editor.mid_out, false );
            separator_r.addEventListener('mousedown', editor.mid_down, false );
            
        },

        removeSeparatorEvent : function () {

            separator_l.removeEventListener('mouseover', editor.mid_over, false );
            separator_l.removeEventListener('mouseout', editor.mid_out, false );
            separator_l.removeEventListener('mousedown', editor.mid_down, false );

            separator_r.removeEventListener('mouseover', editor.mid_over, false );
            separator_r.removeEventListener('mouseout', editor.mid_out, false );
            separator_r.removeEventListener('mousedown', editor.mid_down, false );
            
        },

        sep_out : function ( s ) {

            s.style.background = 'none';
            s.style.borderLeft = '1px solid #626262';
            s.style.borderRight = '1px solid #626262';
        
        },

        mid_over : function ( e ) { 

            var n = e.target.name;
            var t = n === 'l' ? separator_l : separator_r;

            t.style.background = 'rgba(255, 255, 255, 0.2)';
            t.style.borderLeft = '1px solid rgba(255, 255, 255, 0)';
            t.style.borderRight = '1px solid rgba(255, 255, 255, 0)';

        },

        mid_out : function ( e ) { 

            var n = e.target.name;

            if( is_l_down && n==='l' ) return;
            if( is_r_down && n==='r' ) return;

            editor.sep_out( n === 'l' ? separator_l : separator_r );

        },

        mid_down : function ( e ) {

            var n = e.target.name;
            if( n === 'l' ) is_l_down = true;
            if( n === 'r' ) is_r_down = true;

            document.addEventListener('mouseup', editor.mid_up, false );
            document.addEventListener('mousemove', editor.resize, false );

        },

        mid_up : function ( e ) {

            is_l_down = false;
            is_r_down = false;

            document.removeEventListener('mouseup', editor.mid_up, false );
            document.removeEventListener('mousemove', editor.resize, false );

            editor.sep_out(separator_l);
            editor.sep_out(separator_r);
            //editor.mid_out();

        },

        // code

        load : function ( name, size ) {

            var prev = 'glsl/';
            var end = '.glsl';
            //var t = '';
            var isMain = false;

            var n = editor.getChannelNumber( name );

            //console.log(n)

            if( demos_basic.indexOf( name ) !== -1 ) prev = 'glsl_basic/';
            else if( demos_texture.indexOf( name ) !== -1 ) prev = 'glsl_texture/';
            else if( demos_advanced.indexOf( name ) !== -1 ) prev = 'glsl_advanced/';
            else if( demos_advanced.indexOf( name.substring( 0, name.length-1 ) ) !== -1 ) prev = 'glsl_advanced/';
            
            var isMain = n === 0 ? true : false;

            if( isMain ){ 
                if( name !== mainCode ) editor.clear(); 
            } else {
                if( codes[ name ] ) return;
            }
            
            var xhr = new XMLHttpRequest();
            xhr.overrideMimeType( 'text/plain; charset=x-user-defined' ); 
            xhr.open( 'GET', prev + name + end, true );

            xhr.onload = function(){

                //if( isMain && name !== mainCode ) editor.clear();

                //if( codes[ name ] !== undefined ) return;

                codes[ name ] = xhr.responseText;
                editor.addCode( name, isMain );

                if(n === 0 ) {

                    mainCode = name;
                    current = name;
                    code.setValue( codes[name] );

                } else {

                    view.addBuffer( codes[ name ], n, name, size );

                }

                /*if( fun !== undefined ) {
                    fun( n, xhr.responseText, name, c );
                   // return;
                }/* else {
                    fileName = name;
                    //channels[n] = xhr.responseText;
                    if( n === 0 ) code.setValue( xhr.responseText );
                }*/

            }
            
            xhr.send();

        },

        clear : function () {

            editor.clearChannelPad();
            editor.clearMenuCode();

            current = '';
            mainCode = '';
            codes = {};

            view.reset();

        },

        unFocus : function () {

            code.getInputField().blur();
            view.haveFocus();

        },

        refresh : function () {

            code.refresh();

        },

        getFocus : function () {

            return isFocus;

        },

        validate : function ( result ) {

            return code.operation( function () {
                while ( errorLines.length > 0 ) code.removeLineClass( errorLines.shift(), 'background', 'errorLine' );
                var i = widgets.length;
                while(i--) code.removeLineWidget( widgets[ i ] );
                widgets.length = 0;
                //var string = value;
                try {
                    //var result = esprima.parse( string, { tolerant: true } ).errors;
                    i = result.length;
                    while(i--){
                        var error = result[ i ];
                        var m = document.createElement( 'div' );
                        m.className = 'esprima-error';
                        m.textContent = error.message;//.replace(/Line [0-9]+: /, '');
                        var l = error.lineNumber - 1;
                        errorLines.push( l );
                        code.addLineClass( l, 'background', 'errorLine' );
                        var widget = code.addLineWidget( l, m );
                        widgets.push( widget );
                    }
                } catch ( error ) {
                    var m = document.createElement( 'div' );
                    m.className = 'esprima-error';
                    m.textContent = error.message;//.replace(/Line [0-9]+: /, '');
                    var l = error.lineNumber - 1;
                    errorLines.push( l );
                    code.addLineClass( l, 'background', 'errorLine' );
                    var widget = code.addLineWidget( l, m );
                    widgets.push( widget );
                }
                return errorLines.length === 0;
            });

        },

        onChange : function () {

            var n = editor.getChannelNumber( current );
            codes[ current ] = code.getValue();

            clearTimeout( interval );
            interval = setTimeout( function() { view.applyFragment( codes[ current ], n ); }, 300 );
            //if( this.validate( value ) ) interval = setTimeout( function() { editor.inject( value ); }, 500);

        },

        getChannelNumber : function ( name ){

            var n = 0;
            var t = name.substring( name.length - 1 );
            if(t === 'A') n = 1;
            if(t === 'B') n = 2;
            if(t === 'C') n = 3;
            if(t === 'D') n = 4;
            return n;

        },

        //inject : function ( value ) {

            //view.setMat( value );

            /*
            var oScript = document.createElement("script");
            oScript.language = "javascript";
            oScript.type = "text/javascript";
            oScript.text = value;
            document.getElementsByTagName('BODY').item(0).appendChild(oScript);
            */

           // menuCode.innerHTML = '&bull; ' + fileName;
            //title.innerHTML = fileName.charAt(0).toUpperCase() + fileName.substring(1).toLowerCase();//fileName;

            //callback( fileName );

        //},

        setError : function ( value ) {
            menuCode.innerHTML = '<font color="red">' + value + '</font>';
        },

        setTitle : function ( value ) {

            if( value === undefined ){ 

                //editor.clearMenuCode();
                //editor.addCode( fileName );
                //menuCode.innerHTML = '&bull; ' + fileName;
                location.hash = mainCode;
                //callback( fileName );
            }
            else menuCode.innerHTML = '<font color="red">' + value + '</font>';

        },
    }


    return editor;

})();