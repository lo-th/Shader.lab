var gui = ( function () {

    var ui;

    gui = {
        init: function(){
            ui = new UIL.Gui({size:230, color:'no', height:20, close:false });
            this.basic();
        },

        basic: function(){

            ui.add('fps',  {});
            ui.add('title',  { name:'Quality' });
            ui.add('button',  {width:54, sa:2, sb:52, name:0.125}).onChange( function(){view.setQuality(0.125)} );
            ui.add('button',  {width:54, sa:2, sb:52, name:0.25}).onChange( function(){view.setQuality(0.25)} );
            ui.add('button',  {width:54, sa:2, sb:52, name:0.5}).onChange( function(){view.setQuality(0.5)} );
            ui.add('button',  {width:54, sa:2, sb:52, name:1}).onChange( function(){view.setQuality(1)} );

        },
        hide : function(b){

            ui.hide( b );

        },
       
    }

return gui;

})();