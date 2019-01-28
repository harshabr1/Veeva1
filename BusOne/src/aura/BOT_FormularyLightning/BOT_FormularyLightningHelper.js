({
	loadFormulary : function(component) {
        var recordId = component.get("v.recordId");
        var action =component.get("c.getAllFormularies");
        
        //var self = this;
        
        //get Formularies
		action.setParams({formId: recordId});
        action.setCallback(this,function(res){
            var state = res.getState();
            if (state === "SUCCESS")
            {
                var jsonValue1=JSON.stringify(res.getReturnValue());
               // (List<Accountdata>)system.JSON.deserialize(JsonString, List<Accountdata>.class);
                console.log("From server1: " +jsonValue1); 
             	component.set("v.formulary", res.getReturnValue());
                 
                // $A.enqueueAction(action2);
            } 
        });
        
        $A.enqueueAction(action);
        
        var action2=component.get("c.getChannels");
        
          action2.setCallback(this,function(res){
            var state = res.getState();
            if(state == "SUCCESS")
        	{
        		console.log("From server2: " + JSON.stringify(res.getReturnValue()));         		
	            component.set("v.options", res.getReturnValue()); 
                
         	}
        });
        
        $A.enqueueAction(action2);
	}
})