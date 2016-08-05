var gui = ( function () {

    var ui;

    gui = {
        init: function(){
            ui = new UIL.Gui({css:'right:0px;' , size:240, color:'no', height:20, close:false });
            this.basic();
        },

        basic: function(){

            ui.add('fps',  {});
            ui.add('title',  { name:'Pixel Ratio' });
            ui.add('button',  {width:60, sa:5, sb:50, name:0.125}).onChange( function(){view.setQuality(0.125)} );
            ui.add('button',  {width:60, sa:5, sb:50, name:0.25}).onChange( function(){view.setQuality(0.25)} );
            ui.add('button',  {width:60, sa:5, sb:50, name:0.5}).onChange( function(){view.setQuality(0.5)} );
            ui.add('button',  {width:60, sa:5, sb:50, name:1}).onChange( function(){view.setQuality(1)} );

        },
        hide : function(b){

            ui.hide( b );

        },
       
    }

return gui;

})();