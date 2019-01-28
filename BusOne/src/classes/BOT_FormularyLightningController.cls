public class BOT_FormularyLightningController 
{
    @AuraEnabled
    Public static List<Formulary_Products_vod__c> getAllFormularies(String formId)
    {
     	return [SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Account_Plan__r.Name,BOT_Formulary_Name__c,BOT_Formulary_Lives__c
                FROM Formulary_Products_vod__c
                WHERE BOT_Account__c=:formId
                ORDER BY BOT_Channel__c,Name
                LIMIT 50000
               ];   
    }
    
    @AuraEnabled
    Public static List<String> getChannels()
    {
     	String[] options = new String[]{}; 

        Schema.DescribeFieldResult fieldResult = Formulary_Products_vod__c.BOT_ChannelPBM__c.getDescribe();
        
         options.add('--All--');
        
		for(PicklistEntry f:fieldResult.getpicklistvalues())
		{
			options.add(f.getLabel());
		}
        
        return options;
    }
    
    @auraEnabled
    Public Static List<Formulary_Products_vod__c> retrieveFormularies(String accId,String channel)
    {
     	return [SELECT ID,Name,BOT_Channel__c,BOT_Product_Type__c,BOT_Account_Plan__r.Name,BOT_Formulary_Name__c,BOT_Formulary_Lives__c
                FROM Formulary_Products_vod__c
                WHERE BOT_Account__c=:accId AND BOT_Channel__c=:channel
                ORDER BY BOT_Channel__c,Name
                LIMIT 50000
               ];      
    }

}