public class BOT_RelFormulary_VF {
    public List<BOT_Formularies_Unique__c> formulary {get;set;}
    //public List<Formulary_Products_vod__c> formulary {get;set;}
    //public List<Formulary_Products_vod__c> modifiedFormulary = new List<Formulary_Products_vod__c>();
    public Boolean temp {get;set;}
/*
    public BOT_RelFormulary_VF(ApexPages.StandardController controller)
    {
        temp = false;

        formulary = [select Id, BOT_Channel__c, name, BOT_Formulary_Lives__c, (select Id, BOT_Formulary_Product__c, BOT_Channel__c, BOT_Formulary_Name__c, BOT_Product_Type__c, 
                     BOT_Account_Plan_Name__c from Formularies_Unique__r) from BOT_Formularies_Unique__c LIMIT 50];
        System.debug('formulary :'+formulary);
        if(formulary.size()>0 && formulary != null)
        {
            temp = true;            
        }

        formulary = [select Id, name, BOT_Account__c, BOT_Channel__c, BOT_Formulary_Name__c, BOT_Product_Type__c, BOT_Formulary_Lives__c, BOT_Sales_force_SNo__c 
                     from Formulary_Products_vod__c order by BOT_Account__c LIMIT 500];
        Formulary_Products_vod__c oneFormulary = formulary[0];
        Integer count = 0;
        for(Formulary_Products_vod__c form : formulary)
        {
            if(oneFormulary.BOT_Account__c == form.BOT_Account__c && oneFormulary.Name == form.Name)
            {
                count = count + 1;
                form.BOT_Sales_force_SNo__c = 0;
                System.debug('BOT_Sales_force_SNo__c : '+form.BOT_Sales_force_SNo__c);
            }
            else if(oneFormulary.BOT_Account__c != form.BOT_Account__c && oneFormulary.Name != form.Name)
            {
                oneFormulary.BOT_Sales_force_SNo__c = count;
                modifiedFormulary.add(oneFormulary);
                oneFormulary = form;
                count = 1;
            }
        }
        formulary.clear();
        formulary.addAll(modifiedFormulary);
        

    }
            */
}