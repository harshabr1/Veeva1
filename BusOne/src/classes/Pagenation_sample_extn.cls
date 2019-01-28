public class Pagenation_sample_extn 
{
    Public ID acctID{get;set;}                           								//Used to store the current record id        
    Public string selected{get;set;}                        							//Used to store the selected channel VF page
    Public set<String> picklist;       	 												//Used to store the unique channels
    Public List<Account_Plan_vod__c> plansForChannel = new List<Account_Plan_vod__c>(); //Used to store the related plan demograpics records for the selected account
	//Constructor
    public Pagenation_sample_extn(ApexPages.StandardController controller)
    {
        //Getting the current account Id
        acctID=controller.getRecord().Id;
        //Getting the related plan demographics records based on selected account id
        if(acctID != null)
        {
        	plansForChannel = [select BOT_Account__c,BOT_Channel__c,id,name From Account_Plan_vod__c Where BOT_Account__c =: acctID order by BOT_Channel__c];
        	for(Account_Plan_vod__c st : plansForChannel)
        	{
            	//Getting the unique channel values
            	picklist.add(st.BOT_Channel__c);
        	}
		}        
    }
    public void get_Account_summary()
    {
        
    }
    //Creating chanel selection picklist values
    public List<selectOption> getDynamicList() 
    {
        List<selectOption> options = new List<selectOption>();
        if(picklist.size()>1 && picklist != null)
        {
        	options.add(new selectOption('--All--','--All--'));
        }
        for(String s : picklist)
        {
            //Add the channels to picklist to display on VF Page
            options.add(new selectOption(s,s));
        }
        return options;
    }    
    /*public string selected {get;set;}
    public List<Account_Plan_vod__c> accountsChannel;
    public Id selectedAccountId;
    public set<String> pickList;
    public Pagenation_sample_extn(apexPages.StandardController controller)
    {
        selectedAccountId=controller.getRecord().Id;        
        if(selectedAccountId != null && selectedAccountId != '')
        {
        	accountsChannel = [select BOT_Channel__c,id From Account_Plan_vod__c Where BOT_Account__c =: selectedAccountId order by BOT_Channel__c];
        	for(Account_Plan_vod__c c : accountsChannel)
        	{
            	pickList.add(c.BOT_Channel__c);
        	}
        }
        System.debug('Query records '+accountsChannel);
        System.debug('Selected Record '+selectedAccountId);
        System.debug('Channels '+pickList);
    }
    public void get_Account_summary()
    {
        
    }
    public List<selectOption> getDynamicList()
    {
        List<selectOption> options = new List<selectOption>();
        
        if(pickList.size()>0 && pickList != null)
        {
        	options.add(new selectOption('--All--','--All--'));
        	for(String p : pickList )
        	{
            	options.add(new selectOption(p,p));
        	}
        }
        return options;
    }*/
}