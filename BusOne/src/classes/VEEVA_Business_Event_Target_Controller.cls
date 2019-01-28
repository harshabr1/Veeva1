public with sharing class VEEVA_Business_Event_Target_Controller {
    private ApexPages.StandardSetController controller;
    private Business_Event_Target_vod__c[] selected;
    private Call_Objective_vod__c temp = new Call_Objective_vod__c();

    public VEEVA_Business_Event_Target_Controller(ApexPages.StandardSetController stdController) { 
        controller = stdController;
        selected = (Business_Event_Target_vod__c[]) stdController.getSelected();        
    }
    
    public Call_Objective_vod__c getCallObjective()
    {
        return temp;
    }
    
    public List<SelectOption> getNCWReasons()
    {
        List<SelectOption> options = new List<SelectOption>();
        
        Schema.DescribeFieldResult fieldResult = Call_Objective_vod__c.NCW_Reason_vod__c.getDescribe();
        
        for(Schema.PicklistEntry ple : fieldResult.getPicklistValues())
        {
            options.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }       
        return options;
    }    

    public PageReference save() {
        System.Debug('Reason ' + temp.NCW_Reason_vod__c + ', Comment ' + temp.Comment_vod__c);
        List<Id> betIds = new List<Id>();
        for (Business_Event_Target_vod__c bet : selected)
        {
            System.Debug('BET Id ' + bet.Id);
            betIds.add(bet.Id);
        }
        
        List<Call_Objective_vod__c> callObjs =
            [select Id, Name
             from Call_Objective_vod__c
             where Completed_Flag_vod__c = false and
                   Business_Event_Target_vod__c in :betIds];
        
        if (callObjs.size() > 0)
        {            
            for (Call_Objective_vod__c callObj : callObjs)
            {
                System.Debug('Call Obj Id ' + callObj.Id + ', Name ' + callObj.Name);
                callObj.Delivery_Method_vod__c = 'NCW_vod';
                callObj.Completed_Flag_vod__c = true;
                callObj.NCW_Reason_vod__c = temp.NCW_Reason_vod__c;
                callObj.Comment_vod__c = temp.Comment_vod__c;
            }
            
            update(callObjs);
        }
        
        // Don't save Business Event Target, the trigger on Call Objective will do the job  
        return controller.cancel(); 
    }
}