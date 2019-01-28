public with sharing class VOD_CALL_BOOKING {
    private List<Call2_vod__c> selectedCalls;  
    private ApexPages.StandardSetController stdController;
     
    
    public VOD_CALL_BOOKING(ApexPages.StandardSetController controller) {
       String ids = '(';
       sObject[] records;
       this.selectedCalls = new List<Call2_vod__c>();
       
       records = controller.getSelected();
       if (records.size() == 0){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, System.Label.SELECT_AT_LEAST_ONE));
           return;  
       }

       Boolean first = true;
        for (sObject record : records) {
            if (first)
                first = false;
            else
                ids += ',';
            ids += '\'' + record.Id + '\'';               
        }
         
       ids = ids + ')';
       
       String query = 'SELECT Id, Account_vod__r.Name, Address_Line_1_vod__c, City_vod__c, Territory_vod__c, Call_Datetime_vod__c, Status_vod__c, Assigner_vod__c, Assignment_Datetime_vod__c FROM Call2_vod__c WHERE Id IN ' + ids;
       this.selectedCalls = (List<Call2_vod__c>)Database.query(query);
       this.stdController = controller; 
    }
    
    public PageReference assign() {
        for (Call2_vod__c call : this.selectedCalls){
            if (call.Status_vod__c == 'Saved_vod'){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, System.Label.NO_ASSIGN_SAVED));
                return null;
            }
                
            call.Assigner_vod__c = UserInfo.getUserId();
            call.Assignment_Datetime_vod__c = System.now();
        }
        try {
            //this will update Assigner_vod and Assignment_Datetime            
            update this.selectedCalls;
            
            //this will change ownerId
            if (this.selectedCalls.size() > 0)
                return this.stdController.save();
            else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, System.Label.SELECT_AT_LEAST_ONE));
                return null;
            }
 
        } Catch (DMLException e) {
              ApexPages.addMessages(e);
              return null;
        }
    }
    public PageReference redirectToAccountPage() {
        PageReference redirect = new PageReference('/' + ApexPages.currentPage().getParameters().get('id'));
        redirect.setRedirect(true);
        return redirect;
    }

    public Datetime callDate {get;set;}
    public String getFormattedDate() {
        if (callDate == null) {
            return '';
        }
        return callDate.format();
    }

    public VOD_CALL_BOOKING() {
    }
}