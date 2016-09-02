var gui = ( function () {

    var ui;

    gui = {
        
        init: function(){

            ui = new UIL.Gui({css:'right:0px;' , size:240, color:'no', height:20, close:false });
            ui.hide( true );
            this.basic();

        },

        basic: function(){

            var params = view.getParams(); 

            ui.add('fps',  {});
            
            ui.add( params, 'Speed', { min:0, max:10, stype:0, precision:2, stype :2 } );

            ui.add('title',  { name:'Pixel Ratio' });
            ui.add('button',  { value: [0.125, 0.25,0.5,1], simple:true, sa:10 }).onChange( function(v){view.setQuality(v)} );

            ui.add('title',  { name:'Scene' });
            ui.add('button',  { value: ['full', 'sphere','hero', 'head'], simple:true, sa:10 }).onChange( function(v){ gui.sceneSelect(v); } );

            ui.add('title',  { name:'Tone Mapping' });

            ui.add('list',   { name:'type',  list:['None', 'Linear', 'Reinhard', 'Uncharted2', 'Cineon'], value:params.tone, fontColor:'#D4B87B', height:20}).onChange( function(v){ view.setTone(v); } );
            ui.add( params, 'exposure', { min:0, max:10, stype:0, precision:2, stype :2 } ).onChange( function(){ view.setTone(); } );
            ui.add( params, 'whitePoint', { min:0, max:10, stype:0, precision:1, stype :2 } ).onChange( function(){ view.setTone(); } );


        },

        sceneSelect : function (v) {
            var n = 0;
            if(v === 'sphere') n = 1; 
            if(v === 'hero') n = 2;
            if(v === 'head') n = 3;
            view.setScene(n);
        },

        resize : function ( r ) {

            ui.setWidth( r-10 );

        },

        hide : function( b ){

            ui.hide( b );

        },
       
    }

    return gui;

})();