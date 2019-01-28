public class BOT_Diagnostic_Requirements_CP_extn {
    public List<BOT_Coverage_Policy__c> coveragePolicy {get;set;}
    public BOT_Diagnostic_Requirements_CP_extn(Apexpages.StandardController controller) 
    {
    	coveragePolicy = [select Id, BOT_Initial_Therapy_details__c, BOT_Diagnostic_Procedure__c, BOT_Conditions__c, BOT_Requirement_s__c, 
                          BOT_Diagnostic_Response__c, BOT_Monitor_for_Noneofthe_following__c from BOT_Coverage_Policy__c 
                          where id =: controller.getId()];
    }
}