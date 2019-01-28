/*
Name        : BOT_Display_AccountRelated_extn
Created by  : Sreenivasulu Adipudi
Created date: 21-MAR-2017
Description : It is controller class for BOT_Display_AccountRelated_data Visual Force page
*/
public with sharing class BOT_Display_AccountRelated_extn 
{
    Public List<Account> accList {get;set;}                     //To store the account object records
    Public List<Account_Plan_vod__c> accPlan {get;set;}         //To sorte the plan demographics records
    Public List<Formulary_Products_vod__c> formulary {get;set;} //To store the formulary records
    Public String Selected {get;set;}                           //To store the selected channel
    Public String SelectedName {get;set;}                       //To store the selected account name
    Public String SelectedPlan {get;set;}                       //To store the selected plan name
    Public Boolean temp {get;set;}                              //It is a temparary variable used for render the page block 
    Public Boolean temp1 {get;set;}                             //It is a temparary variable used for render the pabe block 
    Public Boolean diplayPicklist {get;set;}  
    //Constructor               
    Public BOT_Display_AccountRelated_extn(ApexPages.StandardController controller)
    {
        accList=[select ID,Name from Account ORDER BY Name ASC NULLS FIRST];
        accPlan=[SELECT Id,name,BOT_Plan_ID__c FROM Account_Plan_vod__c ORDER BY Name ASC NULLS FIRST LIMIT 900];                
    }
    //To fetch the Account records
    Public void displayAccounts()
    {  
        temp=False;
        temp1=False;
        //To fetch the all Account records
        if(selected=='--All--')
            accList=[select ID,Name from Account ORDER BY Name ASC NULLS FIRST];        
        else
            //To fetch the Account records which are related to selected channel
            accList=[select ID,Name from Account where Account_Type__c =: Selected ORDER BY Name ASC NULLS FIRST];
    }
    //To fetch the Plan demographics records
    Public void displayPlans()
    {
        temp=False;
        temp1=False;
        if(selectedName=='--All--')
            accPlan=[SELECT Id,name,BOT_Plan_ID__c FROM Account_Plan_vod__c ORDER BY Name ASC NULLS FIRST LIMIT 990];         
        else
            accPlan=[SELECT Id,name,BOT_Plan_ID__c FROM Account_Plan_vod__c 
                     where Account_vod__r.Name=:SelectedName ORDER BY Name 
                     ASC NULLS FIRST Limit 990];
    }
    //To fetch the Formulary records
    Public void displayform()
    {
        if(Selectedname=='--All--')
            formulary=[SELECT Id,BOT_Formulary_Name__c,BOT_Account_Plan__r.id,BOT_Account_Plan__r.name,
                      (select ID,Name,BOT_Status__c,BOT_Copay__c from Benefit_Designs__r) 
                      FROM Formulary_Products_vod__c ORDER BY Name ASC NULLS FIRST LIMIT 990];         
        else            
            formulary=[SELECT Id,BOT_Formulary_Name__c,BOT_Account_Plan__r.id,BOT_Account_Plan__r.name,
                      (select ID,Name,BOT_Status__c,BOT_Copay__c from Benefit_Designs__r) 
                      FROM Formulary_Products_vod__c where BOT_Account_Plan__r.BOT_Plan_ID__c =: SelectedPlan 
                      ORDER BY Name ASC NULLS FIRST LIMIT 990];
        
        if(formulary.size()>0 && formulary.size() != null)
        {
            temp=True;
            temp1=False;        
        }
        else            
        {
            temp=False;
            temp1=True;
        }        
    }
    public List<SelectOption> getdynamicList() 
    {
        List<selectOption> options = new List<selectOption>();
        options.add(new selectOption('--All--','--All--'));
        options.add(new selectOption('MCO','Commercial'));
        options.add(new selectOption('Stand-Alone Medicare','Medicare'));
        //options.add(new selectOption('PBM','PBM'));   
        return options;
    }
    public List<SelectOption> getdynamicnames() 
    {
        List<selectOption> names = new List<selectOption>();
        names.add(new selectOption('--All--','--All--'));
        for(Account acc:accList)
        {
            names.add(new selectOption(acc.name,acc.name));
        }
        return names;
    }
    public List<selectOption> getDynamicPlans() 
    {
        List<selectOption> plans = new List<selectOption>();
        plans.add(new selectOption('--All--','--All--'));
        for(Account_Plan_vod__c plan:accPlan)
        {
            plans.add(new selectOption(plan.BOT_Plan_ID__c,plan.name));
        }
        return plans;
    }
    public Class accountPlanWrapperClass
    {
        Public ID accPlanID {get;set;}
        public String accPlanName {get;set;}
        public List<Formulary_Products_vod__c> listOfFormularyProducts {get;set;}
    }
}