({
    getChannels : function(component) {
        //helper.getPlans(component);
        var accId = component.get("v.recordId");
        console.log("Account Id : "+accId);
        var action = component.get("c.getChannels");
        if(accId != null)
        	action.setParams({accountId:accId});
        else
            action.setParams({accountId:'0013C000006CiEYQA0'});
        action.setCallback(this, function(a){
            component.set("v.channels",a.getReturnValue());
        })
        $A.enqueueAction(action);
    },
    
    getAccountPlans: function(component, page) {
        
        // Get Account Id
        var accId = component.get("v.recordId");
        if(accId == null)
        	var accId = '0013C000006CiEYQA0';
        // Get the select option (drop-down) values for plans.   
        var recordToDisply = component.find("recordSize").get("v.value");
        //To get selected channel. If it is undefined then assigning "ALL" to selectedChannel variable
        var selectedChannel = component.find("levels").get("v.value");
        if(selectedChannel == undefined) {
            selectedChannel = "ALL";
            
        }
        // create a server side action. 
        var action = component.get("c.fetchAccountPlans");
        // set the parameters to method 
        action.setParams({
            "pageNumber": page,
            "recordToDisply": recordToDisply,
            "channel": selectedChannel,
            "accountId":accId
        });
        // set a call back   
        action.setCallback(this, function(a) {
            // store the response return value (wrapper class insatance)  
            var result = a.getReturnValue();
           	var test = 0; 
            // set the component attributes value with wrapper class properties.   
            component.set("v.paginationPlans", result.accountPlans);			
            component.set("v.page", result.page);
            component.set("v.total", result.total);
            component.set("v.pages", Math.ceil(result.total / recordToDisply));            
            /*
            if(result.total % recordToDisply == 0) {
                test = result.total / recordToDisply
            }
            else {
                test = parseInt(result.total / recordToDisply) + 1;
            }
            console.log("Result.total : " + result.total);
            console.log("Test : " + test);
            */
        });
                
        // enqueue the action 
        $A.enqueueAction(action);
	},
    
    getAccountFormulary: function(component, formularyPage) {
        // Get Account Id
        var accId = component.get("v.recordId");
        if(accId == null)
        	var accId = '0013C000006CiEYQA0';
        // Get the select option (drop-down) values for formulary.
        var formularyRecordToDisplay = component.find("formularyRecordSize").get("v.value");
        //To get selected channel. If it is undefined then assigning "ALL" to selectedChannel variable
        var selectedChannel = component.find("levels").get("v.value");
        if(selectedChannel == undefined) {
            selectedChannel = "ALL";
        }
        // create a server side action. 
        var action = component.get("c.fetchAccountFormulary");
        // set the parameters to method 
        action.setParams({
            "pageNumber": formularyPage,
            "formularyRecordToDisplay": formularyRecordToDisplay,
            "channel": selectedChannel,
            "accountId":accId
        });
        // set a call back   
        action.setCallback(this, function(a) {
            // store the response return value (wrapper class insatance)  
            var result = a.getReturnValue();
            // set the component attributes value with wrapper class properties.   
            component.set("v.paginationFormulary", result.accountFormulary);
            component.set("v.formularyPage", result.page);
            component.set("v.formularyTotal", result.total);
            component.set("v.formularyPages", Math.ceil(result.total / formularyRecordToDisplay));
            
        });
        // enqueue the action 
        $A.enqueueAction(action);
    },
    getAccountPharmacy: function(component, pharmacyPage) {
        // Get Account Id
        var accId = component.get("v.recordId");
        if(accId == null)
        	var accId = '0013C000006CiEYQA0';
        // Get the select option (drop-down) values for pharmacy services.
        var pharmacyRecordToDisplay = component.find("pharmacyRecordSize").get("v.value");
        //To get selected channel. If it is undefined then assigning "ALL" to selectedChannel variable
        var selectedChannel = component.find("levels").get("v.value");
        if(selectedChannel == undefined) {
            selectedChannel = "ALL";
        }
        
        // create a server side action. 
        var action = component.get("c.fetchAccountPharmacy");
        // set the parameters to method 
        
        action.setParams({
            "pageNumber": pharmacyPage,
            "pharmacyRecordToDisplay": pharmacyRecordToDisplay,
            "channel": selectedChannel,
            "accountId":accId
        });
        // set a call back   
        action.setCallback(this, function(a) {
            // store the response return value (wrapper class insatance)  
            var result = a.getReturnValue();
            
            // set the component attributes value with wrapper class properties.   
            component.set("v.paginationPharmacy", result.accountPharmacy);
            component.set("v.pharmacyPage", result.page);
            component.set("v.pharmacyTotal", result.total);
            component.set("v.pharmacyPages", Math.ceil(result.total / pharmacyRecordToDisplay));
            
        });
        // enqueue the action 
        $A.enqueueAction(action);
    },
})