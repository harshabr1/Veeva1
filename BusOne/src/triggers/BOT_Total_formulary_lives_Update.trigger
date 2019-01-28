trigger BOT_Total_formulary_lives_Update on Formulary_Products_vod__c (before update) 
{
    List<Formulary_Products_vod__c> formulary = new List<Formulary_Products_vod__c>();
    List<Formulary_Products_vod__c> formularyList = new List<Formulary_Products_vod__c>();
    set<String> formularyName = new set<String>();
    AggregateResult[] res = [SELECT BOT_Account__c, BOT_Formulary_Name__c, Sum(BOT_Formulary_Lives__c) lives FROM Formulary_Products_vod__c group by BOT_Account__c, BOT_Formulary_Name__c];
    for(AggregateResult r:res)
    {
        Formulary_Products_vod__c form = new Formulary_Products_vod__c();
        form.BOT_Account__c = String.valueOf(r.get('BOT_Account__c'));
        form.BOT_Formulary_Name__c = String.valueOf(r.get('BOT_Formulary_Name__c'));
        form.BOT_Total_Formulary_Lives__c = Integer.valueOf(r.get('lives'));
        formulary.add(form);
    }
    for(Formulary_Products_vod__c form : formulary)
    {
        formularyName.add(form.BOT_Formulary_Name__c);
    }
    formularyList = [select Id, BOT_Account__c, BOT_Formulary_Name__c, BOT_Total_Formulary_Lives__c from Formulary_Products_vod__c where BOT_Formulary_Name__c in : formularyName];
    for(Formulary_Products_vod__c form : formularyList)
    {
        for(Formulary_Products_vod__c f : formulary)
        {
            if(f.BOT_Account__c==form.BOT_Account__c && f.BOT_Formulary_Name__c==form.BOT_Formulary_Name__c)
            {
                form.BOT_Total_Formulary_Lives__c=f.BOT_Total_Formulary_Lives__c;
            }
        }
    }
    update formularyList;
}