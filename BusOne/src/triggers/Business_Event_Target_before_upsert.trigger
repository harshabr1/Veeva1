trigger Business_Event_Target_before_upsert on Business_Event_Target_vod__c (before insert, before update) {
    // To prevent circular
    if (VEEVA_BUSINESS_EVENT_TARGET_TRIG.invoked)
    {
        return;
    }
    VEEVA_BUSINESS_EVENT_TARGET_TRIG.invoked = true;
    
    Map<Id, RecordType> recTypes = new Map<Id, RecordType>(
        [select Id, Name
         from RecordType
         where SobjectType in ('Business_Event_Target_vod__c', 'Business_Event_vod__c')
           and IsActive=true]);

    List<Id> beIds = new List<Id>();
    for (Integer idx = 0; idx < Trigger.size; idx++)
    {
        if (Trigger.new[idx].Business_Event_vod__c == null || Trigger.new[idx].Account_vod__c == null)
        {
            Trigger.new[idx].addError(('[Bussiness_Event_vod__c/Account_vod__c] ' + VOD_GET_ERROR_MSG.getErrorMsg('REQUIRED', 'Common')), false);
            return;
        }
        beIds.add(Trigger.new[idx].Business_Event_vod__c);
    }
    
    Map<Id, Business_Event_vod__c> busEvnts = new Map<Id,Business_Event_vod__c>(
        [select Id, Name, Product_vod__c, Start_Date_vod__c, Date_Parameter_vod__c,
                RecordTypeId, Issue_Date_vod__c, Product_Launch_Date_vod__c, Active_vod__c
         from Business_Event_vod__c
         where Id in :beIds]);         
        
    for (Integer idx = 0; idx < Trigger.size; idx++)
    {
        Business_Event_Target_vod__c newBET =  Trigger.new[idx];
        Business_Event_vod__c busEvnt = busEvnts.get(newBET.Business_Event_vod__c);
        
        // Prevents targets from being added/modified to inactive business events
        if (!busEvnt.Active_vod__c)
        {
            newBET.addError((busEvnt.Name + ' ' + VOD_GET_ERROR_MSG.getErrorMsg('INACTIVE','BusinessEvent')), false);
            return;
        }
                
        newBET.External_Id_vod__c = newBET.Business_Event_vod__c + '_' +  newBET.Account_vod__c;        
        
        RecordType rt = recTypes.get(newBET.RecordTypeId);
        RecordType beRecType = recTypes.get(busEvnt.RecordTypeId);                
        if (rt == null || beRecType == null)
        {
            Trigger.new[idx].addError('RecordType must not be null', false);
            return;
        }
        else if (!rt.Name.equals(beRecType.Name))
        {
            Trigger.new[idx].addError('Business_Event_Target must be the same RecordType as Business_Event', false);
            return;
        }
        
        if (Trigger.isInsert &&
            [select count() from Business_Event_Target_vod__c
                           where Business_Event_vod__c = :newBET.Business_Event_vod__c
                             and Account_vod__c = :newBET.Account_vod__c] > 0)
        {
            newBET.addError((VOD_GET_ERROR_MSG.getErrorMsg('SAMPLE_DUPLICATE_INFORMATION_ALREADY_EXISTS','Blackberry') + ' ' +
                   Schema.SObjectType.Business_Event_Target_vod__c.Label + ' [' +
                    [select Name from Account where id = :newBET.Account_vod__c].Name + ', ' + busEvnt.Name + ', ' + rt.Name + ']'), false);
            return;        
        }        
        
        if ('EPPV'.equals(rt.Name))
        {
            RecordType EPPV = [SELECT Id FROM RecordType WHERE SobjectType='Call_Objective_vod__c' AND DeveloperName = 'EPPV_vod' AND IsActive=true];
            boolean handlePreExplain = false;
            boolean handleNewPurchase = false;
            if (0 == [select count()
                      from Call_Objective_vod__c
                      where Business_Event_vod__c = :newBET.Business_Event_vod__c and
                            RecordTypeId = :EPPV.Id and
                            Account_vod__c = :newBET.Account_vod__c and
                            Pre_Explain_Flag_vod__c = true and isDeleted = false])
            {
                handlePreExplain = true;
            }
            
            if ((Trigger.isInsert && Trigger.new[idx].Purchase_Date_vod__c != null) ||
                (Trigger.isUpdate && Trigger.old[idx].Purchase_Date_vod__c == null))
            {
                // new purchase date is not null, previous purchase date is null and is update
                if (0 == [select count()
                          from Call_Objective_vod__c
                          where Business_Event_vod__c = :newBET.Business_Event_vod__c and
                                RecordTypeId = :EPPV.Id and
                                Account_vod__c = :newBET.Account_vod__c and
                                Pre_Explain_Flag_vod__c = false])
                {
                    handleNewPurchase = true;
                }                
            }
            
            if (!handlePreExplain && !handleNewPurchase)
            {
                continue;
            }
                    
            // call objective
            Set<Id> territoryIds = new Set<Id>();
            for (UserTerritory ut : [select TerritoryId from UserTerritory where UserId in (select UserOrGroupId from AccountShare where AccountId = :newBET.Account_vod__c)])
            {
                territoryIds.add(ut.TerritoryId);
            }
            
            Id productId = null;
            for (Product_vod__c prod : [select Id, Company_Product_vod__c, Product_Type_vod__c, Parent_Product_vod__c
                                        from Product_vod__c
                                        where Id = :busEvnt.Product_vod__c])
            {
                if (prod.Company_Product_vod__c == true && prod.Product_Type_vod__c.equals('Detail'))
                {
                    productId = prod.Id;
                }
                else
                {
                    productId = prod.Parent_Product_vod__c;
                }
                break;
            }

            Id mrId = null;
            for (My_Setup_Products_vod__c myproduct: [SELECT OwnerId
                                                      FROM My_Setup_Products_vod__c
                                                      WHERE Product_vod__c = :productId AND IsDeleted = false AND
                                                      OwnerId IN (SELECT UserId FROM UserTerritory WHERE TerritoryId IN :territoryIds)
                                                      ORDER BY OwnerId LIMIT 1])
            {
                mrId = myproduct.OwnerId;
                break;
            }

            if (mrId == null)
            {
                mrId = [SELECT OwnerId FROM Account WHERE Id = :newBET.Account_vod__c AND IsDeleted = false].OwnerId;
            }

            Integer remaining_calls = Trigger.old == null ? 0 : Trigger.old[idx].Remaining_Calls_vod__c.intValue();
            Date next_visit_date = Trigger.old == null ? null : Trigger.old[idx].Next_Visit_Date_vod__c;

            if (handlePreExplain)
            {         
                    VEEVA_BUSINESS_EVENT_TARGET_TRIG.CallObjectiveHolder holder = new VEEVA_BUSINESS_EVENT_TARGET_TRIG.CallObjectiveHolder();
                    holder.callObj = new Call_Objective_vod__c();
                    holder.trig_idx = idx;
                    
                    holder.callObj.Pre_Explain_Flag_vod__c = true;
                    holder.callObj.From_Date_vod__c = busEvnt.Start_Date_vod__c;
                    if (Trigger.new[idx].Pre_Explain_Date_vod__c != null)
                    {
                        holder.callObj.To_Date_vod__c = Trigger.new[idx].Pre_Explain_Date_vod__c;
                    }
                    else
                    {
                        holder.callObj.To_Date_vod__c = busEvnt.Start_Date_vod__c.addDays(busEvnt.Date_Parameter_vod__c.intValue());
                    }
                    holder.callObj.Date_vod__c = datetime.newInstanceGmt(holder.callObj.To_Date_vod__c.year(),
                                                 holder.callObj.To_Date_vod__c.month(),holder.callObj.To_Date_vod__c.day(),12,0,0);
                    holder.callObj.Name_vod__c = busEvnt.Name + ' - ' + holder.callObj.From_Date_vod__c.format();
                    holder.callObj.OwnerId = mrId;
                    holder.callObj.Account_vod__c = newBET.Account_vod__c;
                    holder.callObj.Business_Event_vod__c = newBET.Business_Event_vod__c;
                    holder.callObj.RecordTypeId = EPPV.Id;
                    holder.callObj.Product_vod__c = busEvnt.Product_vod__c;
                                        
                    VEEVA_BUSINESS_EVENT_TARGET_TRIG.holders.add(holder);
                    
                    remaining_calls++;
                    if (next_visit_date == null || next_visit_date.daysbetween(holder.callObj.Date_vod__c.date()) < 0)
                    {
                        next_visit_date = holder.callObj.Date_vod__c.date();
                    }
                    
                    // Set Business Event Target Pre Explain Date
                    newBET.Pre_Explain_Date_vod__c =  holder.callObj.Date_vod__c.date();
            }
            
            if (handleNewPurchase)
            {                    
                    for (Date crtDate : VEEVA_JPN_EPPV_WORK_FLOW.createWorkFlow(busEvnt.Product_Launch_Date_vod__c,
                                                                          newBET.Purchase_Date_vod__c))
                    {
                        // call objective
                        VEEVA_BUSINESS_EVENT_TARGET_TRIG.CallObjectiveHolder holder = new VEEVA_BUSINESS_EVENT_TARGET_TRIG.CallObjectiveHolder();
                        holder.callObj = new Call_Objective_vod__c();
                        holder.trig_idx = idx;                                       
                        
                        holder.callObj.Pre_Explain_Flag_vod__c = false;
                        holder.callObj.From_Date_vod__c = crtDate.addDays(-1 * Math.Abs(busEvnt.Date_Parameter_vod__c.intValue()));
                        holder.callObj.To_Date_vod__c = crtDate;
                        holder.callObj.Date_vod__c = datetime.newInstanceGmt(holder.callObj.To_Date_vod__c.year(),
                                                     holder.callObj.To_Date_vod__c.month(), holder.callObj.To_Date_vod__c.day(),12,0,0);
                        holder.callObj.Name_vod__c = busEvnt.Name + ' - ' + holder.callObj.From_Date_vod__c.format();                                            
                        holder.callObj.OwnerId = mrId;
                        holder.callObj.Account_vod__c = newBET.Account_vod__c;
                        holder.callObj.Business_Event_vod__c = newBET.Business_Event_vod__c;
                        holder.callObj.RecordTypeId = EPPV.Id;
                        holder.callObj.Product_vod__c = busEvnt.Product_vod__c;
                                            
                        VEEVA_BUSINESS_EVENT_TARGET_TRIG.holders.add(holder);
                        
                        remaining_calls++;                        
                        if (next_visit_date == null || next_visit_date.daysbetween(holder.callObj.Date_vod__c.date()) < 0)
                        {
                            next_visit_date = holder.callObj.Date_vod__c.date();
                        }                      
                    }              
            }
            newBET.Next_Visit_Date_vod__c = next_visit_date;
            newBET.Remaining_Calls_vod__c = remaining_calls;
        }
        else if ('PI'.equals(rt.Name))
        {
            RecordType PI = [SELECT Id FROM RecordType WHERE SobjectType='Call_Objective_vod__c' AND DeveloperName = 'PI_vod' AND IsActive=true];
            if (0 == [select count()
                      from Call_Objective_vod__c
                      where Business_Event_vod__c = :busEvnt.Id and
                            RecordTypeId = :PI.Id and
                            Account_vod__c = :newBET.Account_vod__c])
            {
                // call objective
                Set<Id> territoryIds = new Set<Id>();
                for (UserTerritory ut : [select TerritoryId from UserTerritory where UserId in (select UserOrGroupId from AccountShare where AccountId = :newBET.Account_vod__c)])
                {
                    territoryIds.add(ut.TerritoryId);
                }
                
                Id productId = null;
                for (Product_vod__c prod : [select Id, Company_Product_vod__c, Product_Type_vod__c, Parent_Product_vod__c
                                                 from Product_vod__c
                                                 where Id = :busEvnt.Product_vod__c])
                {
                    if (prod.Company_Product_vod__c == true && prod.Product_Type_vod__c.equals('Detail'))
                    {
                        productId = prod.Id;
                    }
                    else
                    {
                        productId = prod.Parent_Product_vod__c;
                    }
                    break;
                }
                        
                Id mrId = null;
                for (My_Setup_Products_vod__c myproduct: [SELECT OwnerId
                                                          FROM My_Setup_Products_vod__c
                                                          WHERE Product_vod__c = :productId AND IsDeleted = false AND
                                                          OwnerId IN (SELECT UserId FROM UserTerritory WHERE TerritoryId IN :territoryIds)
                                                          ORDER BY OwnerId LIMIT 1])
                {
                    mrId = myproduct.OwnerId;
                    break;
                }
                        
                if (mrId == null)
                {
                    mrId = [SELECT OwnerId FROM Account WHERE Id = :newBET.Account_vod__c AND IsDeleted = false].OwnerId;
                }            
                
                VEEVA_BUSINESS_EVENT_TARGET_TRIG.CallObjectiveHolder holder = new VEEVA_BUSINESS_EVENT_TARGET_TRIG.CallObjectiveHolder();
                holder.callObj = new Call_Objective_vod__c();
                holder.trig_idx = idx;

                holder.callObj.From_Date_vod__c = busEvnt.Issue_Date_vod__c;
                holder.callObj.To_Date_vod__c = busEvnt.Issue_Date_vod__c.addDays(busEvnt.Date_Parameter_vod__c.intValue());
                holder.callObj.Date_vod__c = datetime.newInstance(holder.callObj.From_Date_vod__c.year(),
                                             holder.callObj.From_Date_vod__c.month(), holder.callObj.From_Date_vod__c.day(), 12, 0, 0);
                holder.callObj.Name_vod__c = busEvnt.Name + ' - ' + holder.callObj.From_Date_vod__c.format();
                holder.callObj.OwnerId = mrId;
                holder.callObj.Account_vod__c = newBET.Account_vod__c;
                holder.callObj.Business_Event_vod__c = newBET.Business_Event_vod__c;
                holder.callObj.RecordTypeId = PI.Id;
                holder.callObj.Product_vod__c = busEvnt.Product_vod__c;
                                        
                VEEVA_BUSINESS_EVENT_TARGET_TRIG.holders.add(holder);
                
                newBET.Next_Visit_Date_vod__c = holder.callObj.Date_vod__c.date();
            }            
        }        
    }
    Date today = Date.today();
    for (VEEVA_BUSINESS_EVENT_TARGET_TRIG.CallObjectiveHolder holder : VEEVA_BUSINESS_EVENT_TARGET_TRIG.holders)
    {
        if (today.daysBetween(holder.callObj.To_Date_vod__c) < 0)
        {
            Trigger.new[0].addError(VOD_GET_ERROR_MSG.getErrorMsg('NO_HIST_RECS','BusinessEvent'), false);
            return; 
        }        
    }    
}