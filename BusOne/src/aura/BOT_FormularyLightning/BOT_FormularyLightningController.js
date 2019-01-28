({
	initialize: function(component, event, helper) {
		helper.loadFormulary(component); 
      /* var opts = [
            { value: "--All--", label: "--All--" },
            { value: "Commercial", label: "Commercial" },
            { value: "Medicare", label: "Medicare" }
         ];
         component.set("v.options", opts);*/
        
       /*  var action=component.get("c.getChannels");
        action.setParams({ obj:"Formulary_Products_vod__c",str:"BOT_Channel__c"});
        action.setCallBack(this,function(res){
            var state = response.getState();
            if(state === "SUCCESS")
            {
             	var stringItems = response.getReturnValue();
                component.set("v.options", stringItems); 
            }
            
        });
         $A.enqueueAction(action);*/
	},
    channelFilter:function(component,event,helper)
    {
     	 var selectedChannel = component.find("levels").get("v.value");
         var recordId = component.get("v.recordId");
     	 var action=component.get("c.retrieveFormularies"); 
         
         action.setParams({accId: recordId,
                           channel:selectedChannel});
        
        action.setCallback(this,function(res){
            var state=res.getState();
            if(state == "SUCCESS")
        	{
                $A.get("e.c:hideSpinner").fire();
        		console.log("From server3: " +JSON.stringify(res.getReturnValue()));         		
	            component.set("v.formulary", res.getReturnValue()); 
         	}
        });
        $A.get("e.c:showSpinner").fire();
        
        $A.enqueueAction(action);
        
    },
    showSpinner: function(component, event, helper) {
       // make Spinner attribute true for display loading spinner
      
       component.set("v.Spinner", true); 
      $A.util.removeClass(
      component.find('spinner'), 
      "slds-hide");   

   },
    
    hideSpinner : function(component,event,helper){
     // make Spinner attribute to false for hide loading spinner    
     //   component.set("v.Spinner", false);
     $A.util.addClass(
      component.find('spinner'), 
      "slds-hide");
    }
})