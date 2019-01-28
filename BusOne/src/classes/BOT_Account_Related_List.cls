public with sharing class BOT_Account_Related_List {
	//To get channels dynamically
    @AuraEnabled
    public static List<String> getChannels(Id accountId) {
        //List<Account_Plan_vod__c> allChannels = new List<Account_Plan_vod__c>();
        set<String> uniqueChannels = new set<String>();
        List<String> channels = new List<String>();
        //allChannels = [select id, BOT_Channel__c from Account_Plan_vod__c where BOT_Account__c=:accountId order by BOT_Channel__c];
        for(Account_Plan_vod__c plan : [select id, BOT_Channel__c from Account_Plan_vod__c where BOT_Account__c=:accountId order by BOT_Channel__c]) {
            uniqueChannels.add(plan.BOT_Channel__c);
        }
        if(uniqueChannels.size() > 1)
        	channels.add('ALL');
        channels.addAll(uniqueChannels);
        return channels;
    }
    
    //To get Account plan records related to selected account
    @AuraEnabled
    public static AccountPlanWrapper fetchAccountPlans(Decimal pageNumber ,Integer recordToDisply, String channel, Id accountId) {
    	Integer pageSize = recordToDisply;
      	Integer offset = ((Integer)pageNumber - 1) * pageSize;
        // create a instance of wrapper class.
        AccountPlanWrapper plan = new AccountPlanWrapper();
        // set the pageSize,Page(Number), total records and accounts List(using OFFSET)
        plan.pageSize = pageSize;
        plan.page = (Integer) pageNumber;
        if(accountId != null && channel == 'ALL' && channel != '')
        {
        	plan.total = [SELECT count() FROM Account_Plan_vod__c where BOT_Account__c=:accountId];
        	plan.accountPlans = [select Id, BOT_Channel__c, Name, BOT_Product_Type__c, BOT_Formulary_Used__c, BOT_PBM__c, 
                     			BOT_Product_Lives_Rx__c from Account_Plan_vod__c where BOT_Account__c=:accountId order by BOT_Channel__c 
                                LIMIT :recordToDisply OFFSET :offset];
        }
        else if(accountId != null && channel != '')
        {
			plan.total = [SELECT count() FROM Account_Plan_vod__c where BOT_Account__c=:accountId and BOT_Channel__c=:channel];
        	plan.accountPlans = [select Id, BOT_Channel__c, Name, BOT_Product_Type__c, BOT_Formulary_Used__c, BOT_PBM__c, 
                     			BOT_Product_Lives_Rx__c from Account_Plan_vod__c where BOT_Account__c=:accountId and BOT_Channel__c=:channel 
                                order by BOT_Channel__c LIMIT :recordToDisply OFFSET :offset];            
        }
        // return the wrapper class instance .
        return plan;
    }
    
    //To get Formulary records related to selected account
    @AuraEnabled
    public static AccountFormularyWrapper fetchAccountFormulary(Decimal pageNumber ,Integer formularyRecordToDisplay, String channel, Id accountId) {
    	Integer pageSize = formularyRecordToDisplay;
      	Integer offset = ((Integer)pageNumber - 1) * pageSize;
        // create a instance of wrapper class.
        AccountFormularyWrapper form = new AccountFormularyWrapper();
        // set the pageSize,Page(Number), total records and accounts List(using OFFSET)
        form.pageSize = pageSize;
        form.page = (Integer) pageNumber;
        if(accountId != null && channel == 'ALL' && channel != '')
        {
        	form.total = [SELECT count() FROM Formulary_Products_vod__c where BOT_Account__c=:accountId];
        	form.accountFormulary = [select Id, BOT_Channel__c, BOT_Formulary_Name__c, BOT_Product_Type__c, BOT_Account_Plan__r.Name, 
                         			BOT_Formulary_Lives__c, BOT_Sales_force_SNo__c from Formulary_Products_vod__c where 
                                    BOT_Account__c=:accountId order by BOT_Channel__c LIMIT :formularyRecordToDisplay OFFSET :offset];
        }
        else if(accountId != null && channel != '')
        {
			form.total = [SELECT count() FROM Formulary_Products_vod__c where BOT_Account__c=:accountId and BOT_Channel__c=:channel];
        	form.accountFormulary = [select Id, BOT_Channel__c, BOT_Formulary_Name__c, BOT_Product_Type__c, BOT_Account_Plan__r.Name, 
                         			BOT_Formulary_Lives__c, BOT_Sales_force_SNo__c from Formulary_Products_vod__c where 
                                    BOT_Account__c=:accountId and BOT_Channel__c=:channel order by BOT_Channel__c 
                                    LIMIT :formularyRecordToDisplay OFFSET :offset];            
        }
        /*
        Decimal firstFormularyLives = form.accountFormulary[0].BOT_Formulary_Lives__c;
        Decimal count = 0;
        Boolean isFirst = true;
        for(Formulary_Products_vod__c f : form.accountFormulary)
        {   
            if(f.BOT_Formulary_Lives__c == firstFormularyLives && isFirst == true)
            {
            	count = count + 1;
                //f.BOT_Formulary_Lives__c = 0;
                f.BOT_Sales_force_SNo__c = count;
                System.debug('BOT formulary Sno : '+f.BOT_Sales_force_SNo__c);
                isFirst = false;
            }
            if(f.BOT_Formulary_Lives__c == firstFormularyLives && isFirst == false)
            {
            	count = count + 1;
                f.BOT_Formulary_Lives__c = 0;
                f.BOT_Sales_force_SNo__c = count;
                System.debug('BOT formulary Sno : '+f.BOT_Sales_force_SNo__c);
            }
            else
            {
            	firstFormularyLives = f.BOT_Formulary_Lives__c;
               	count = 0;
                isFirst = true;
            }
        }
       	System.debug('Modified lives : '+form.accountFormulary);
		*/
        
    	// return the wrapper class instance .
        return form;
    }
    
    //To get Pharmacy Services records related to selected account
    @AuraEnabled
    public static AccountPharmacyWrapper fetchAccountPharmacy(Decimal pageNumber ,Integer pharmacyRecordToDisplay, String channel, Id accountId) {
    	Integer pageSize = pharmacyRecordToDisplay;
      	Integer offset = ((Integer)pageNumber - 1) * pageSize;
        // create a instance of wrapper class.
        AccountPharmacyWrapper pharm = new AccountPharmacyWrapper();
        // set the pageSize,Page(Number), total records and accounts List(using OFFSET)
        pharm.pageSize = pageSize;
        pharm.page = (Integer) pageNumber;
        if(accountId != null && channel == 'ALL' && channel != '')
        {
        	pharm.total = [SELECT count() FROM BOT_Pharamcy_Service__c where BOT_Account__c=:accountId];
        	pharm.accountPharmacy = [select Id, BOT_Channel__c, name, BOT_PBM_Name__c, BOT_Corporate__c, BOT_Other_Provider_Name__c 
                        			from BOT_Pharamcy_Service__c where BOT_Account__c=:accountId order by BOT_Channel__c 
                                    LIMIT :pharmacyRecordToDisplay OFFSET :offset];
        }
        else if(accountId != null && channel != '')
        {
			pharm.total = [SELECT count() FROM BOT_Pharamcy_Service__c where BOT_Account__c=:accountId and BOT_Channel__c=:channel];
        	pharm.accountPharmacy = [select Id, BOT_Channel__c, name, BOT_PBM_Name__c, BOT_Corporate__c, BOT_Other_Provider_Name__c 
                        			from BOT_Pharamcy_Service__c where BOT_Account__c=:accountId and BOT_Channel__c=:channel 
                                	order by BOT_Channel__c LIMIT :pharmacyRecordToDisplay OFFSET :offset];            
        }
    	// return the wrapper class instance .
    	return pharm;
    } 
    
    // create a wrapper class for Account Plans with @AuraEnabled Properties    
 	public class AccountPlanWrapper {
    	@AuraEnabled public Integer pageSize {get;set;}
    	@AuraEnabled public Integer page {get;set;}
    	@AuraEnabled public Integer total {get;set;}
    	@AuraEnabled public List<Account_Plan_vod__c> accountPlans {get;set;}
    }
    
    // create a wrapper class for Account Formularies with @AuraEnabled Properties
    public class AccountFormularyWrapper {
    	@AuraEnabled public Integer pageSize {get;set;}
    	@AuraEnabled public Integer page {get;set;}
    	@AuraEnabled public Integer total {get;set;}
    	@AuraEnabled public List<Formulary_Products_vod__c> accountFormulary {get;set;}        
    }
    
    // create a wrapper class for Account Formularies with @AuraEnabled Properties
    public class AccountPharmacyWrapper {
    	@AuraEnabled public Integer pageSize {get;set;}
    	@AuraEnabled public Integer page {get;set;}
    	@AuraEnabled public Integer total {get;set;}
    	@AuraEnabled public List<BOT_Pharamcy_Service__c> accountPharmacy {get;set;} 
    }
}