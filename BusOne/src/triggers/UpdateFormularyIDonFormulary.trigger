trigger UpdateFormularyIDonFormulary on Plan_Formulary_JO__c (after insert) 
{
    set<String> BOT_Formulary_Ids = new set<String>();
    for(Plan_Formulary_JO__c form : trigger.new)
    {
        BOT_Formulary_Ids.add(form.Name);
    }
    List<Formulary_Products_vod__c> formulary = [select id, Name, BOT_Account__c, BOT_Account_Plan__c, BOT_Formulary_Name__c, BOT_Formulary_Lives__c, BOT_Total_Formulary_Lives__c from Formulary_Products_vod__c where Name in : BOT_Formulary_Ids];
    for(Formulary_Products_vod__c f : formulary)
    {
        for(Plan_Formulary_JO__c form : trigger.new)
        {
            if(form.BOT_Account__c == f.BOT_Account__c && form.BOT_Plan_Demographics__c == f.BOT_Account_Plan__c && form.Name == f.Name)
            {
                f.Name = form.Name;
                f.BOT_Account__c = form.BOT_Account__c;
                f.BOT_Account_Plan__c = form.BOT_Plan_Demographics__c;
                f.BOT_Formulary_Name__c = form.BOT_Formulary_Name__c;
                f.BOT_Formulary_Lives__c = form.BOT_Formulary_Lives__c;
                f.BOT_Total_Formulary_Lives__c = form.BOT_Total_Formulary_Lives__c;
            }
        }
    }
    update formulary;
}