({
    //To get channels dynamically
    doInit : function(component, event, helper) {
        // This function call on the component load first time     
        // Get the page Number if it's not define, take 1 as default for plans
        var page = component.get("v.page") || 1;
               
        // Get the page Number if it's not define, take 1 as default for formulary
        var formularyPage = component.get("v.formularyPage") || 1;
        
        // Get the page Number if it's not define, take 1 as default for pharmacy services
        var pharmacyPage = component.get("v.pharmacyPage") || 1;
           
        // To get channels dynamically
        helper.getChannels(component);
        // Initially selectedChannel is set to "ALL" to get all records
        var selectedChannel = "ALL";
        // Call the helper function to get plans   
        helper.getAccountPlans(component, page);
        // Call the helper functions to get formularies
        helper.getAccountFormulary(component, formularyPage);
        // Call the helper functions to get pharmacy Services
        helper.getAccountPharmacy(component, pharmacyPage);
    },
    channelFilter: function(component, event, helper) {
        
        var page = 1;
        var formularyPage = 1;
        var pharmacyPage = 1;
        
        // To get channels dynamically
        // helper.getChannels(component);
        // Call the helper function to get plans   
        helper.getAccountPlans(component, page);
        // Call the helper functions to get formularies
        helper.getAccountFormulary(component, formularyPage);
        // Call the helper functions to get pharmacy Services
        helper.getAccountPharmacy(component, pharmacyPage);
    },

    navigate: function(component, event, helper) {
        // this function call on click on the previous page button  
        var page = component.get("v.page") || 1;
        // get the previous button label  
        var direction = event.getSource().get("v.label");
        // set the current page,(using ternary operator.)  
        //page = direction === "Previous Page" ? (page - 1) : (page + 1);
        if(direction === "Previous Page") {
            page = page-1;
        }
        else if(direction === "Next Page") {
        	page = page+1;
        }
        else if(direction === "First Page") {
        	page = 1;        
        }
        else {
            page = component.get("v.pages");
        }
        // call the helper function
        helper.getAccountPlans(component, page);
    },
    
    formularyNavigate: function(component, event, helper) {
    	
        // this function call on click on the previous page button
    	var formularyPage = component.get("v.formularyPage") || 1;
        // get the previous button label
        var direction = event.getSource().get("v.label");
        // set the current page,(using ternary operator.)
        //formularyPage = direction === "Previous Page" ? (formularyPage - 1) : (formularyPage + 1);
        if(direction === "Previous Page") {
            formularyPage = formularyPage-1;
        }
        else if(direction === "Next Page") {
        	formularyPage = formularyPage+1;
        }
        else if(direction === "First Page") {
        	formularyPage = 1;        
        }
        else {
            formularyPage = component.get("v.formularyPages");
        }
        // call the helper function
        helper.getAccountFormulary(component, formularyPage);
    },
    
    pharmacyNavigate: function(component, event, helper) {
    	
        // this function call on click on the previous page button
    	var pharmacyPage = component.get("v.pharmacyPage") || 1;
        // get the previous button label
        var direction = event.getSource().get("v.label");
        // set the current page,(using ternary operator.)
        //pharmacyPage = direction === "Previous Page" ? (pharmacyPage - 1) : (pharmacyPage + 1);
        if(direction === "Previous Page") {
            pharmacyPage = pharmacyPage-1;
        }
        else if(direction === "Next Page") {
        	pharmacyPage = pharmacyPage+1;
        }
        else if(direction === "First Page") {
        	pharmacyPage = 1;        
        }
        else {
            pharmacyPage = component.get("v.pharmacyPages");
        }

        // call the helper function
        helper.getAccountPharmacy(component, pharmacyPage);    
    },
    
    onSelectChange: function(component, event, helper) {
        
        // this function call on the select option change,	 
        var page = 1;
        helper.getAccountPlans(component, page);
    },
    
    onFormularySelectChange: function(component, event, helper) {
                
        // this function call on the select option change,
        var formularyPage = 1;
        helper.getAccountFormulary(component, formularyPage);
    },
    
    onPharmacySelectChange: function(component, event, helper) {
        // this function call on the select option change,
        var pharmacyPage = 1;
        helper.getAccountPharmacy(component, pharmacyPage);
    }
})