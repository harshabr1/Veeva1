global with sharing class VEEVA_BATCH_SURVEY_PUBLISH extends BATCH_SURVEY_PUBLISH_ABSTRACT implements Database.Stateful{
    private final String initialState;
    String surveyAssignment;
    Date   surveyEnddate;
    String surveyProduct;
    Set<String> commonFieldlist = new Set<String>();
    Survey_vod__c surveyToUpdate;
    String surveyTargetRecType;
    Integer assignedCnt = 0;
    Integer noAssignedCnt = 0;
    String currentUserId;
        
    global VEEVA_BATCH_SURVEY_PUBLISH()
    {
    }
    
	global override void init()
	{
    	// we are updating the survey at the start of the batch job based on the End_Date_vod__c of survey_vod__c
        String surveyQuery = VOD_Utils.getAccessibleFieldsSoql('Survey_vod__c', ' Id = :surveyId');
        surveyToUpdate = Database.query(surveyQuery);
        surveyEnddate = surveyToUpdate.End_Date_vod__c;
        surveyAssignment = surveyToUpdate.Assignment_Type_vod__c;
        surveyProduct = surveytoUpdate.Product_vod__c;
        Map<String,String> surveyTargetRecTypes = new Map<String,String>();
        String surveyRecTypeName;

        for (RecordType rt :[Select Id,Developername,sObjectType from RecordType where sObjectType in ('Survey_vod__c','Survey_Target_vod__c')]){
        	if(rt.sObjectType == 'Survey_vod__c' && rt.Id == surveyToUpdate.RecordTypeId){
        		surveyRecTypeName= rt.Developername;
        	}
        	else{
        		surveyTargetRecTypes.put(rt.Developername,rt.Id);
        	}
        }
        surveyTargetRecType = surveyTargetRecTypes.get(surveyRecTypeName);
        currentUserId = System.Userinfo.getUserId();
		//Populate commonFieldNames
        populateCommonFields();  
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
               
        // This is the base query that drives the chunking.
        String query = 'SELECT Id,' +
                '       Status_vod__c, ' +
                '       Account_vod__c, ' +
                '       OwnerId,'		+
                '       No_Autoassign_vod__c,' +
                '       RecordTypeId'   +
                ' FROM  Survey_Target_vod__c ' +
                ' WHERE Survey_vod__c = :surveyId' ;                  
        if(newTargetsOnly)
        	query += ' AND Status_vod__c = \'Development_vod\'';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> batch) {
        List <Survey_Target_vod__c> surveyTargetToUpdate = new List <Survey_Target_vod__c> ();
        Set<String> accounts = new Set<String> ();
        Integer curAsgCnt = 0;
	    Integer curNoAsgCnt = 0;	  
        try{
           for (sObject obj : batch) {
	            Survey_Target_vod__c target = (Survey_Target_vod__c)obj;
	            if(target.Account_vod__c != null && !target.No_autoassign_vod__c)
	            	accounts.Add(target.Account_vod__c);
	        }
	       
	        //Get the owner mapping for target
	        Map<String,String> acctUserMap = new Map<String,String>();
	        if(accounts.size() > 0){
	        	acctUserMap = getUsersWithPermissionForAccounts(accounts);
	        }

	        for (SObject obj : batch) {
	        	Survey_Target_vod__c target = (Survey_Target_vod__c)obj;
        	
		        	//if the rep created the target, don't reassign it		        	
					if(target.Account_vod__c != null && !target.no_Autoassign_vod__c  && target.Status_vod__c != 'Submitted_vod'
						&& target.Status_vod__c != 'Late_Submission_vod' && target.Status_vod__c != 'Saved_vod') 
					{
			    		String userid = acctUserMap.get(target.Account_vod__c);
			    		if(userid == null || userid == ''){
			    			target.OwnerId = currentUserId;				    			
			    			curNoAsgCnt++;
			    		}
			    		else{
			    			target.OwnerId = userid; 
			    			curAsgCnt++;				    			
			    		}
					}
	    			//copy the common fields over
	    			for(String field : commonFieldlist){
	    				Object o = surveyToUpdate.get(field);
	    				target.put(field,o);
	    			}
	    			if(surveyTargetRecType != null && surveyTargetRecType != '')
	    				target.RecordTypeId = surveyTargetRecType;
	    			target.Name = surveyToUpdate.name;
					if(target.Status_vod__c != 'Submitted_vod'
						&& target.Status_vod__c != 'Late_Submission_vod' && target.Status_vod__c != 'Saved_vod')
	    				target.Status_vod__c = 'Pending_vod';
	    			surveyTargetToUpdate.add(target);
	        }	
	    	
  			update surveyTargetToUpdate;
  			assignedCnt = assignedCnt + curAsgCnt;
  			noAssignedCnt = noAssignedCnt + curNoAsgCnt;
        }
    	catch(Exception ex)
    	{
    		//if any exception thrown during the update, catch it and try again to assign the owner to publishing user
    		curNoAsgCnt = 0;
    		curAsgCnt = 0;
    		surveyTargetToUpdate.Clear();
    	    for (SObject obj : batch) {
        		Survey_Target_vod__c target = (Survey_Target_vod__c)obj;
    	
	        	//if the rep created the target, don't reassign it		        	
				if(!target.no_Autoassign_vod__c  && target.Status_vod__c != 'Submitted_vod'
						&& target.Status_vod__c != 'Late_Submission_vod' && target.Status_vod__c != 'Saved_vod') 
				{
					target.OwnerId = currentUserId;
					curNoAsgCnt++;
				}
				//copy the common fields over
    			for(String field : commonFieldlist){
    				Object o = surveyToUpdate.get(field);
    				target.put(field,o);
    			}
    			//copy record type
    			if(surveyTargetRecType != null && surveyTargetRecType != '')
    				target.RecordTypeId = surveyTargetRecType;
    			//copy survey name 
    			target.Name = surveyToUpdate.name;
				if(target.Status_vod__c != 'Submitted_vod'
						&& target.Status_vod__c != 'Late_Submission_vod' && target.Status_vod__c != 'Saved_vod')
    				target.Status_vod__c = 'Pending_vod';
    				
    			surveyTargetToUpdate.add(target);
    	    }

    	    update surveyTargetToUpdate;
  			noAssignedCnt = noAssignedCnt + curNoAsgCnt;
    	}
    }
        
	//this method, along with getting Users that are associated with accounts in thhe acctList, exludes Users from the
	//map that is returned if they do not have Read access to Survey_Target_vod__c
	private Map<String,String> getUsersWithPermissionForAccounts(set<String> acctList){
    		Map<String,String> acctUserMap = new Map<String,String>();
			Map<String,Set<String>> acct_groupIds = new Map<String, Set<String>>();
			Set<String> groupIdSet = new Set<String>();
			for (AccountShare acctShare : [Select AccountId,UserOrGroupId From AccountShare Where AccountId in :acctList And RowCause In ('Territory','TerritoryManual')]) {
				Set<String> groupIds = acct_groupIds.get(acctShare.AccountId);
				if(groupIds == null)
				{
					groupIds = new Set<String>();
					acct_groupIds.put(acctShare.AccountId,groupIds);
				}
				else
					groupIds.Add(acctShare.UserOrGroupId);
				groupIds.Add(acctShare.UserOrGroupId);
				groupIdSet.Add(acctShare.UserOrGroupId);
			}
			
			if (groupIdSet.size() <= 0)
			{
				return acctUserMap;
			}

			Map<String,Set<String>> acct_terrIds = new Map<String, Set<String>>();
			Set<String> terrIdSet = new Set<String>();
			
			for (Group gr : [Select Id,RelatedId From Group Where Id In :groupIdSet]) {
				for(String acctId : acct_groupIds.keySet())
				{
					Set<String> territoryIds = acct_terrIds.get(acctId);
					if(territoryIds == null)
					{
						territoryIds = new Set<String>();
						acct_terrIds.put(acctId, territoryIds);
					}

					if(acct_groupIds.get(acctId).contains(gr.Id))
					{
						territoryIds.add(gr.RelatedId);
						terrIdSet.add(gr.RelatedId);
					}
				}
			}
			
			if (terrIdSet.size() <= 0)
			{
				return acctUserMap;
			}
				

			//find the users in the account territories
			Map<Id,UserTerritory> userTerritories = new Map<Id,UserTerritory>([Select Id,UserId, TerritoryId From UserTerritory Where TerritoryId In :terrIdSet And IsActive=true]);
			Map<String,List<String>> acct_userids = new Map<String, List<String>>();
			Set<Id> alluserids = new Set<Id>();
			
			for (UserTerritory ut : userTerritories.values()) {
				for(String acctId : acct_terrIds.KeySet())
				{
					List<String> userIds = acct_userids.get(acctId);
					if(userIds == null)
					{
						userIds = new List<String>();
						acct_userids.put(acctId, userIds);
					}
					if(acct_terrIds.get(acctId).contains(ut.TerritoryId)){
						userIds.add(ut.UserId);
						alluserids.add(ut.UserId);
					}
				}
			}
			
			
			System.debug('userTerritory' + acct_userids);
			//if the assignment is Product_vod, filter using MYSetup
			if(surveyAssignment == 'Product_vod' && surveyProduct != null && surveyProduct != ''){
				Set<String> usersAccessProduct= new Set<String>();
				for(My_Setup_Products_vod__c msp: [Select OwnerId from My_Setup_Products_vod__c where Product_vod__c = :surveyProduct and isDeleted = false]){
					usersAccessProduct.add(msp.OwnerId);
				}
				for(String account : acct_userids.keySet()){
					List<String> curUserids = acct_userids.get(account);
					List<String> filteredUserids = new List<String>();
					for(String user : curUserids){
						if(usersAccessProduct.contains(user))
							filteredUserids.add(user);
					}
					acct_userids.put(account,filteredUserids);
				}
			}
			
			System.debug('acct_userids' + acct_userids);
	        //find the users whose has territories matching surveyTerritoryIds
			Set<String> userTerritoriesSvy = new Set<String>();
			if(surveyTerritoryIds != null && surveyTerritoryIds.size() > 0)
			{
				for(UserTerritory ut :[Select Id, UserId, TerritoryId From UserTerritory Where UserId In :alluserids And TerritoryId in :surveyTerritoryIds And IsActive = true])
				{
					userTerritoriesSvy.add(ut.Userid);
				}
			}
			
			Set<String> activeUserIdsWithPermission = new Set<String>();
			for (PermissionSetAssignment assignment : [
					SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN
						(SELECT ParentId FROM ObjectPermissions WHERE SObjectType = 'Survey_Target_vod__c' and PermissionsRead = true)
					AND AssigneeId IN
						(SELECT Id FROM User WHERE Id in :alluserids AND IsActive=true)]) {

				activeUserIdsWithPermission.add(assignment.AssigneeId);
			}
			for(string acctId : acctList)
			{
				List<String> userids = acct_userids.get(acctId);
				if(userids != null && userids.size() > 0){
					for(String id : userids)
					{
						if(activeUserIdsWithPermission.contains(id) &&  userTerritoriesSvy.Contains(id)){
							acctUserMap.put(acctId,id);
						}
					}
				}
			}
			
			return acctUserMap;
		}
    
    private void populateCommonFields(){
      // Get a map of field names for this object type.
      Map<String, Schema.SObjectField> fieldMapSurvey = Schema.SObjectType.Survey_vod__c.fields.getMap();
      Map<String, Schema.SObjectField> fieldMapSurveyTarget = Schema.SObjectType.Survey_Target_vod__c.fields.getMap();
	  Set<String> specialFields = new Set<String>{'Status_vod__c','Segment_vod__c','External_ID_vod__c'};
      if (fieldMapSurvey != null)
      {
      	 // Loop through all fields.
         for (Schema.SObjectField f : fieldMapSurvey.values())
         {
            // Describe each field.
            Schema.DescribeFieldResult fd = f.getDescribe();            
            // Is this field is queryable? If so, we can query it.
            if (fd.isAccessible())
            {
            	String name = fd.getName();
            	for (Schema.SObjectField ft : fieldMapSurveyTarget.values())
		         {
		            // Describe each field.
		            Schema.DescribeFieldResult ftd = ft.getDescribe();
		            if(ftd.isAccessible() && (ftd.getName()== name) && (ftd.isCustom()) && ftd.isUpdateable() 
		            && !specialFields.Contains(name) && !name.startsWith('zvod'))
		            {
		            	// This is the API name. 
	               		commonFieldlist.add(name);
		            }
		         }
            }
         }
      }
    }
    
    global void finish(Database.BatchableContext BC) {
    	
    	try
    	{
    		surveyToUpdate.Status_vod__c = 'Published_vod';
	    	update surveyToUpdate;
    	}
    	catch(Exception ex)
    	{
    		system.debug('failed to update survey status to published');
    	}
    	// Send email to the publishing user
    	try
    	{
	        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	
	    	AsyncApexJob a = [SELECT Id, toLabel(Status) , NumberOfErrors, JobItemsProcessed,
			      TotalJobItems, CreatedBy.Email
			      FROM AsyncApexJob WHERE Id =
			      :BC.getJobId()];
	
			string subject =  VOD_GET_ERROR_MSG.getErrorMsg('PUBLISH_EMAIL_SUBJECT','Surveys');
			string assignSuccess = VOD_GET_ERROR_MSG.getErrorMsg('PUBLISH_EMAIL_ASSIGN_SUCCESS','Surveys');
			string assignFail = VOD_GET_ERROR_MSG.getErrorMsg('PUBLISH_EMAIL_ASSIGN_FAILURE','Surveys');
			string footer = VOD_GET_ERROR_MSG.getErrorMsg('PUBLISH_EMAIL_FOOTER','Surveys');
			
		    mail.setPlainTextBody(assignSuccess + ' : ' + assignedCnt + '\n' 
		    + assignFail + ' : ' + noAssignedCnt + '\n\n'
		    + footer);
					
	        mail.setSubject(surveyToUpdate.name + ' - ' + subject + ' : ' + a.Status);       
	        String[] toAddresses = new String[] {a.CreatedBy.Email};
	        mail.setToAddresses(toAddresses);
	        mail.setCharset('UTF-8');
	        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    	}
    	catch(Exception ex)
    	{
    		system.debug('failed to send email');
    	}
    }

}