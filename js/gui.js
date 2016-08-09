var gui = ( function () {

    var ui;

    gui = {
        init: function(){
            ui = new UIL.Gui({css:'right:0px;' , size:240, color:'no', height:20, close:false });
            this.basic();
        },

        basic: function(){

            var params = view.getParams(); 

            ui.add('fps',  {});
            ui.add('title',  { name:'Pixel Ratio' });
            ui.add('button',  {width:60, sa:5, sb:50, name:0.125}).onChange( function(){view.setQuality(0.125)} );
            ui.add('button',  {width:60, sa:5, sb:50, name:0.25}).onChange( function(){view.setQuality(0.25)} );
            ui.add('button',  {width:60, sa:5, sb:50, name:0.5}).onChange( function(){view.setQuality(0.5)} );
            ui.add('button',  {width:60, sa:5, sb:50, name:1}).onChange( function(){view.setQuality(1)} );

            ui.add('title',  { name:'Scene' });

            ui.add('button',  {width:60, sa:5, sb:50, name:'full'}).onChange( function(){view.setScene(0)} );
            ui.add('button',  {width:60, sa:5, sb:50, name:'sphere'}).onChange( function(){view.setScene(1)} );
            ui.add('button',  {width:60, sa:5, sb:50, name:'torus'}).onChange( function(){view.setScene(2)} );

            ui.add('title',  { name:'Tone Mapping' });

            //ui.add('list',   { name:'type',  list:['None', 'Linear', 'Reinhard', 'Uncharted2', 'Cineon'], value:params.tone, fontColor:'#D4B87B', height:20}).onChange( function(v){ view.setTone(v); } );
            ui.add( params, 'exposure', { min:0, max:10, stype:0, precision:2, stype :2 } ).onChange( function(){ view.setTone(); } );
            ui.add( params, 'whitePoint', { min:0, max:10, stype:0, precision:1, stype :2 } ).onChange( function(){ view.setTone(); } );


        },
        hide : function(b){

            ui.hide( b );

        },
       
    }

return gui;

})();