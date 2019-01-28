({
    doInit : function(component, event, helper) {
        
    },
    selectedPlans : function(component, event, helper) {
        var selectedPlans = event.getParams("accPlans");
		component.set("v.Plans",selectedPlans);
        console.log("Plans from Child 1"+selectedPlans)
        //console.log("Plans from Child 2"+v.Plans)
	}
})