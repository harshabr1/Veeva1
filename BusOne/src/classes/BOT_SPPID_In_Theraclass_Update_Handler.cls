public class BOT_SPPID_In_Theraclass_Update_Handler 
{
    public static void m1(List<BOT_Thera_Class__c>beforeList)
    {
        set<string> botsppid = new set<string>();                               //To store unique BOT SPP id values.
        List<BOT_Thera_Class__c> theraupdate = new List<BOT_Thera_Class__c>();  //To store the Thera class records with SFDC SPP id.
        for(BOT_Thera_Class__c tera:beforeList)
        {
            botsppid.add(tera.BOT_SPP_ID__c);    
        }
        //Retrieving the SPP records which is related with given Thera class records
        List<BOT_Specialty_Provider__c>sppdata=[select id,BOT_Account__c,BOT_Specialty_ID__c from BOT_Specialty_Provider__c where BOT_Specialty_ID__c in : botsppid];
        //Iterating the loop to Thera class records
        for(BOT_Thera_Class__c tera1:beforeList)
        {
            //Iterating the loop to get the related SPP records
            for(BOT_Specialty_Provider__c spp:sppdata)
            {
                //Identifiying the Unique SPP id which is related to Thera class and populating that SPP id into Thera Class record
                if(spp.BOT_Account__c==tera1.BOT_Account__c && spp.BOT_Specialty_ID__c==tera1.BOT_SPP_ID__c)
                {
                    tera1.BOT_Specialty__c=spp.id;
                    theraupdate.add(tera1);
                }
            }
        }
    }
}