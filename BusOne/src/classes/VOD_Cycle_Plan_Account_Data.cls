public with sharing class VOD_Cycle_Plan_Account_Data{
    public String accountId;
   
    public String planName;
    public String planStart;
    public String planEnd;
    public String archievedTotalPercent = '-1';
    public String plannedTotalCallsFormat = '-1';
    public String actualTotalCallsFormat = '-1';
    public String remainingTotalCallsFormat = '-1';
    public String archievedTotalPercentFormat = '-1';
    public Integer expectedAttainment = 0;
    
    public String archievedPercent = '-1';
    public String plannedCallsFormat = '-1';
    public String actualCallsFormat = '-1';
    public String remainingCallsFormat = '-1';
    public String archievedPercentFormat = '-1';
    public String cyclePlanId;
    public boolean hasData = false; 
    public boolean showActualCalls = false;
    public boolean showTotalCalls = false;
    public boolean showProdDetails = false;
    public boolean enableRemainingSetting = false;
    
    public String noDataMessage = '';
    
    public String headerLine = '';
    public String myCallLbl = 'My Calls';
    public String totalCallLbl = 'Total Calls';
    public String remainingLbl = 'Remaining';
    public static Integer[] THRESHOLD = new Integer[]{10,25};
    public List<String> tstLst;    //for debug use
    public String colors = '';
    public String colorsTm = '';
    public String prodLbl = 'Product';
    
    public boolean getEnableRemainingSetting() {
        return enableRemainingSetting;
    }
    
    public void setEnableRemainingSetting(boolean val) {
        enableRemainingSetting = val;
    }
    public String getRemainingLbl(){
        return remainingLbl;
    }
    public String getMyCallLbl(){
        return myCallLbl;   
    }
    public String getTotalCallLbl (){
        return totalCallLbl;
    }
    public String getActualLbl(){
        return Cycle_Plan_Detail_vod__c.Actual_Details_vod__c.getDescribe().getLabel();
    } 
    public String getPlannedLbl(){
        return Cycle_Plan_Detail_vod__c.Planned_Details_vod__c.getDescribe().getLabel();    
    } 
    public String getAchievedLbl(){
        return Cycle_Plan_Detail_vod__c.Attainment_vod__c.getDescribe().getLabel();        
    } 
    public String getScheduledLbl(){
        return Cycle_Plan_Detail_vod__c.Scheduled_Details_vod__c.getDescribe().getLabel();
    } 

    public String getTmActualLbl(){
        return Cycle_Plan_Detail_vod__c.Total_Actual_Details_vod__c.getDescribe().getLabel();
    } 
    public String getTmPlannedLbl(){
        return Cycle_Plan_Detail_vod__c.Total_Planned_Details_vod__c.getDescribe().getLabel();    
    } 
    public String getTmAchievedLbl(){
        return Cycle_Plan_Detail_vod__c.Total_Attainment_vod__c.getDescribe().getLabel();        
    } 
    public String getTmScheduledLbl(){
        return Cycle_Plan_Detail_vod__c.Total_Scheduled_Details_vod__c.getDescribe().getLabel();
    } 
    public String getProdLbl(){
        return prodLbl;
    }
    public Integer getExpectedAttainment(){
        return expectedAttainment;
    }
    public static String getVodUrl(){
        return VOD_Common.VOD_URL;
    }
    
    {
        try{
            Message_vod__c thrd = [Select Text_vod__c From Message_vod__c Where Name='MyCalls' and Category_vod__c='Cycleplan' And Active_vod__c=true and Language_vod__c=:UserInfo.getLanguage()];    
            if(thrd != null){
              myCallLbl = thrd.Text_vod__c;
            }
        }catch (System.QueryException e) {
           //do nothing , return default value;
        }
        try{
            Message_vod__c thrd = [Select Text_vod__c From Message_vod__c Where Name='REMAINING' and Category_vod__c='Common' And Active_vod__c=true and Language_vod__c=:UserInfo.getLanguage()];    
            if(thrd != null){
              remainingLbl = thrd.Text_vod__c;
            }
        }catch (System.QueryException e) {
           //do nothing , return default value;
        }
        try{
            Message_vod__c thrd = [Select Text_vod__c From Message_vod__c Where Name='TotalCalls' and Category_vod__c='Cycleplan' And Active_vod__c=true and Language_vod__c=:UserInfo.getLanguage()];    
            if(thrd != null){
              totalCallLbl = thrd.Text_vod__c;
            }
        }catch (System.QueryException e) {
           //do nothing , return default value;
        }        
        try{
            Message_vod__c thrd = [Select Text_vod__c From Message_vod__c Where Name='Product' and Category_vod__c='Mysetup' And Active_vod__c=true and Language_vod__c=:UserInfo.getLanguage()];    
            if(thrd != null){
              prodLbl = thrd.Text_vod__c;
            }
        }catch (System.QueryException e) {
           //do nothing , return default value;
        }        
    }    
    public static Integer[] getThreshold(){
        Integer[] rslt = new Integer[]{};
        try{
            String[] values = new String[]{};
            String messageName = 'CYCLE_PLAN_THRESHOLD';
            Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getInstance();
            if (settings != null) {
                String[] setting = new String[]{};
                setting = settings.CYCLE_PLAN_THRESHOLD_vod__c.split(';;');
                if (setting.size() == 2)
                    messageName = setting[0];
            } 
            
            Message_vod__c thrd = [Select Text_vod__c From Message_vod__c Where Name=:messageName And Active_vod__c=true];
            if(thrd != null)
                values = thrd.Text_vod__c.split(',');
                               
            try{
                for( String v: values){
                    rslt.add(Integer.valueOf(v));            
                }
            }catch(System.Exception ge){
              return THRESHOLD;
            }
            if(rslt.size() != 2 || rslt[0] >= rslt[1] || rslt[0] < 1 || rslt[1] >100){
              return THRESHOLD; 
            }
        }catch (System.QueryException e) {
            return THRESHOLD;
        }
        return rslt;
    }
    public String getNoDataMessage(){
        return noDataMessage ;
    }
    public String getThresholdJS(){
        return '[' + getThreshold()[0] + ',' + getThreshold()[1] + ']'; //for now
    }
    public String getColors(){
        return colors;
    }
    public void setColors(String c){
        this.colors = c;
    }
    public String getColorsTm(){
        return colorsTm;
    }
    public void setColorsTm(String c){
        this.colorsTm = c;
    }    
    public boolean getShowActualCalls (){
        return showActualCalls ;
    }
    public void setShowActualCalls(boolean inv){
        showActualCalls = inv;
    }
    public boolean getShowTotalCalls  (){
        return showTotalCalls ;
    }
    public void setShowTotalCalls(boolean inv){
        showTotalCalls = inv;
    }    
    public boolean getShowProdDetails  (){
        return showProdDetails ;
    }
    public void setShowProdDetails(boolean inv){
        showProdDetails = inv;
    }     
    public String getCyclePlanId(){
        return cyclePlanId;
    }
    public void setCyclePlanId(String s){
        cyclePlanId = s;
    }    
    public String getPlanName() {
        return planName;
    }

    public void setPlanName(String planName) {
        this.planName = planName;
    }

    public String getArchievedTotalPercent() {
        return archievedTotalPercent;
    }

    public void setArchievedTotalPercent(String archievedTotalPercent) {
        this.archievedTotalPercent = archievedTotalPercent;
    }

    public String getArchievedPercent() {
        return archievedPercent;
    }

    public void setArchievedPercent(String archievedPercent) {
        this.archievedPercent = archievedPercent;
    }

    public String getPlannedTotalCallsFormat() {
        return plannedTotalCallsFormat;
    }

    public void setPlannedTotalCallsFormat(String plannedTotalCallsFormat) {
        this.plannedTotalCallsFormat = plannedTotalCallsFormat;
    }

    public String getActualTotalCallsFormat() {
        return actualTotalCallsFormat;
    }

    public void setActualTotalCallsFormat(String actualTotalCallsFormat) {
        this.actualTotalCallsFormat = actualTotalCallsFormat;
    }

    public String getRemainingTotalCallsFormat() {
        return remainingTotalCallsFormat;
    }

    public void setRemainingTotalCallsFormat(String remainingTotalCallsFormat) {
        this.remainingTotalCallsFormat = remainingTotalCallsFormat;
    }

    public String getArchievedTotalPercentFormat() {
        return archievedTotalPercentFormat;
    }

    public void setArchievedTotalPercentFormat(String archievedTotalPercentFormat) {
        this.archievedTotalPercentFormat = archievedTotalPercentFormat;
    }

    public String getPlannedCallsFormat() {
        return plannedCallsFormat;
    }

    public void setPlannedCallsFormat(String plannedCallsFormat) {
        this.plannedCallsFormat = plannedCallsFormat;
    }

    public String getActualCallsFormat() {
        return actualCallsFormat;
    }

    public void setActualCallsFormat(String actualCallsFormat) {
        this.actualCallsFormat = actualCallsFormat;
    }

    public String getRemainingCallsFormat() {
        return remainingCallsFormat;
    }

    public void setRemainingCallsFormat(String remainingCallsFormat) {
        this.remainingCallsFormat = remainingCallsFormat;
    }

    public String getArchievedPercentFormat() {
        return archievedPercentFormat;
    }

    public void setArchievedPercentFormat(String archievedPercentFormat) {
        this.archievedPercentFormat = archievedPercentFormat;
    }
    
    public List<String> getTstLst(){
        return tstLst;
    }
    public void setAccountId(String s){
        accountId = s;
    }
    public String getAccountId(){
        return accountId;
    }
    public String getHeaderLine(){
      return headerLine;
    }
    public boolean getHasResult(){
        return getCyclePlanDetail().size()>0; 
    }
    public List<Cycle_Plan_Detail_vod__c> getCyclePlanDetail(){
        List<Cycle_Plan_Detail_vod__c> rslt = new List<Cycle_Plan_Detail_vod__c>();
        String cyclePlanTargetId = '';
        
        Set<String> tNames = new Set<String>();
/*        
        Account vodAt = [select territory_vod__c from account where Id = :getAccountId()];
        String vodtr = (String)vodAt.territory_vod__c;
        if(vodtr != null && vodtr.length() > 0){
            tNames.addAll(vodtr.split(';'));
        }
*/        
        
        AccountShare[] ats = [Select Id, UserOrGroupId from AccountShare where accountId = :getAccountId()];
        if(ats != null && ats.size() > 0){
          Set<Id> asIds = new Set<Id>();
          for(AccountShare theas : ats){
              asIds.add(theas.UserOrGroupId );
          }
          if(asIds != null && asIds.size() > 0){
              Group[] gps = [Select Id, RelatedId from Group where Type='Territory' and Id IN :asIds];
              if(gps != null && gps.size() > 0){
                 Set<Id> gpIds = new Set<Id>();
                 for(Group thegp : gps){
                     gpIds.add(thegp.RelatedId );
                 }
                 if(gpIds != null && gpIds.size() > 0){
                     Territory[] trts = [select id, name from Territory where Id IN :gpIds];
                     if(trts != null && trts.size() >0){
                         for(Territory thetr : trts){
                             tNames.add(thetr.name);
                         }
                     }
                 }
              }
          }
        }

// get user territories
        List <String> UserTerrIds = new List<String> (); 
        List<UserTerritory> Userterr = [SELECT TerritoryId from UserTerritory  where UserId = :UserInfo.getUserId() AND IsActive = true];

        for (UserTerritory ut : Userterr) {
           UserTerrIds.add(ut.TerritoryId);
        }
        
        List<Territory> terr = null;
        Set<String> commonTerrs = new Set<String>();
        if (UserTerrIds.size () > 0 && tNames.size() > 0 ){
      
           terr = [Select Name From Territory where Id in :UserTerrIds];
           if (terr != null && terr.size() > 0) {
                for (Territory tt: terr) {
                   if(tNames.contains(tt.Name)){
                       commonTerrs.add(tt.Name);
                   }
                }           
           }
        }
        
        List<Cycle_Plan_vod__c> cpln2 = new List<Cycle_Plan_vod__c>();
        if(showActualCalls && showTotalCalls){
          cpln2 = [select Id, Territory_vod__c,name,start_date_vod__c,end_date_vod__c,
                        (select Id,actual_calls_vod__c,planned_calls_vod__c,Remaining_vod__c,attainment_vod__c,
                                total_actual_calls_vod__c,total_planned_calls_vod__c,Total_Remaining_vod__c,total_attainment_vod__c
                         from cycle_plan_targets__r where cycle_plan_account_vod__c = :getAccountId())  
                 from Cycle_Plan_vod__c 
                 where territory_vod__c in :commonTerrs
                       and active_vod__c = true
                       and start_date_vod__c <= :Date.today()
                       and end_date_vod__c >= :Date.today()
                 order by Territory_vod__c];
        }else if(showActualCalls && !showTotalCalls){
          cpln2 = [select Id, Territory_vod__c,name,start_date_vod__c,end_date_vod__c,
                        (select Id,actual_calls_vod__c,planned_calls_vod__c,Remaining_vod__c,attainment_vod__c
                         from cycle_plan_targets__r where cycle_plan_account_vod__c = :getAccountId())  
                 from Cycle_Plan_vod__c 
                 where territory_vod__c in :commonTerrs 
                       and active_vod__c = true
                       and start_date_vod__c <= :Date.today()
                       and end_date_vod__c >= :Date.today()
                 order by Territory_vod__c];  
        }else if(!showActualCalls && showTotalCalls){
          cpln2 = [select Id, Territory_vod__c,name,start_date_vod__c,end_date_vod__c,
                        (select Id,total_actual_calls_vod__c,total_planned_calls_vod__c,Total_Remaining_vod__c,total_attainment_vod__c
                         from cycle_plan_targets__r where cycle_plan_account_vod__c = :getAccountId())  
                 from Cycle_Plan_vod__c 
                 where territory_vod__c in :commonTerrs 
                       and active_vod__c = true
                       and start_date_vod__c <= :Date.today()
                       and end_date_vod__c >= :Date.today()
                 order by Territory_vod__c];      
        }else {
          cpln2 = [select Id, Territory_vod__c,name,start_date_vod__c,end_date_vod__c,
                        (select Id from cycle_plan_targets__r where cycle_plan_account_vod__c = :getAccountId())  
                 from Cycle_Plan_vod__c 
                 where territory_vod__c in :commonTerrs 
                       and active_vod__c = true
                       and start_date_vod__c <= :Date.today()
                       and end_date_vod__c >= :Date.today()
                 order by Territory_vod__c];       
        }
        if ((cpln2 != null) && (cpln2 .size() > 0)) {
            for (Cycle_Plan_vod__c pln: cpln2 ) {
                if(pln != null && pln.get('Id') != null){
                    if(pln.cycle_plan_targets__r != null &&pln.cycle_plan_targets__r.size() >0 ){
                        Cycle_Plan_Target_vod__c ctgt =(Cycle_Plan_Target_vod__c) pln.cycle_plan_targets__r.get(0);
                        cyclePlanTargetId = ctgt.Id;
                        cyclePlanId = (String)pln.get('Id');
                        planName = pln.Name;
                        planEnd = pln.End_Date_vod__c.format();
                        planStart = pln.Start_Date_vod__c.format();
//start date should be earlier than end date is not checked here   
                        Integer toStart = pln.Start_Date_vod__c.daysBetween(Date.today());
                        Integer cspn = pln.Start_Date_vod__c.daysBetween(pln.End_Date_vod__c) + 1; //count in the start day
                        if(toStart == 0){ //first day of play
                            expectedAttainment = 0;
                        }else{                     
                            expectedAttainment = toStart*100/cspn; //no round function here to prevent 100% to happen
                        }
                        if(showTotalCalls){
                            archievedTotalPercent = (ctgt.Total_Attainment_vod__c==null?'0':ctgt.Total_Attainment_vod__c.toPlainString());
                            plannedTotalCallsFormat = (ctgt.Total_Planned_Calls_vod__c == null?Decimal.valueOf(0).format():ctgt.Total_Planned_Calls_vod__c.format());
                            actualTotalCallsFormat = (ctgt.Total_Actual_Calls_vod__c == null?Decimal.valueOf(0).format():ctgt.Total_Actual_Calls_vod__c.format());
                            remainingTotalCallsFormat = (ctgt.Total_Remaining_vod__c == null?Decimal.valueOf(0).format():ctgt.Total_Remaining_vod__c.format());
                            archievedTotalPercentFormat = (ctgt.Total_Attainment_vod__c==null?Decimal.valueOf(0).format():ctgt.Total_Attainment_vod__c.format());
                        }
                        if(showActualCalls ){
                            archievedPercent = (ctgt.Attainment_vod__c == null?'0':ctgt.Attainment_vod__c.toPlainString());
                            plannedCallsFormat = (ctgt.Planned_Calls_vod__c==null?Decimal.valueOf(0).format():ctgt.Planned_Calls_vod__c.format());
                            actualCallsFormat = (ctgt.Actual_Calls_vod__c==null?Decimal.valueOf(0).format():ctgt.Actual_Calls_vod__c.format());
                            remainingCallsFormat = (ctgt.Remaining_vod__c==null?Decimal.valueOf(0).format():ctgt.Remaining_vod__c.format());
                            archievedPercentFormat = (ctgt.Attainment_vod__c == null?Decimal.valueOf(0).format():ctgt.Attainment_vod__c.format());
                        }
                        
                        //tstLst.add((String)pln.get('Territory_vod__c') + ' targetid :' + cyclePlanTargetId );
                        break;
                    }
                }
            }
        }
        if(cyclePlanTargetId.length() > 0 && showProdDetails ){
            Map<String, Schema.SObjectField> tgtmp = Schema.SObjectType.Product_vod__c.fields.getMap();
            Set<String> ks = tgtmp.keySet();
            boolean  hasNoCyclePlanField= ks.contains('no_cycle_plans_vod__c');
        
            if(hasNoCyclePlanField){
                rslt = [select product_vod__r.name,actual_details_vod__c, Attainment_vod__c, planned_Details_vod__c,Scheduled_Details_vod__c,product_vod__c,Total_Actual_Details_vod__c,Total_Planned_Details_vod__c,Total_Attainment_vod__c,Total_Scheduled_Details_vod__c from cycle_plan_detail_vod__c where Cycle_plan_target_vod__c=:cyclePlanTargetId and product_vod__r.No_Cycle_Plans_vod__c != true];
            }else{
                rslt = [select product_vod__r.name,actual_details_vod__c, Attainment_vod__c, planned_Details_vod__c,Scheduled_Details_vod__c,product_vod__c,Total_Actual_Details_vod__c,Total_Planned_Details_vod__c,Total_Attainment_vod__c,Total_Scheduled_Details_vod__c from cycle_plan_detail_vod__c where Cycle_plan_target_vod__c=:cyclePlanTargetId ];
            }
            Integer[] thd = getThreshold();
            String tmpColors = '';
            String tmpTmColors = '';
            for(Cycle_Plan_Detail_vod__c cd: rslt){
                if((expectedAttainment - cd.Attainment_vod__c) <= thd[0]){
                    tmpColors = tmpColors + ',"green"';
                }else if((expectedAttainment - cd.Attainment_vod__c) <= thd[1]){
                    tmpColors = tmpColors + ',"orange"';
                }else{
                    tmpColors = tmpColors + ',"red"';
                }
                
                if((expectedAttainment - cd.Total_Attainment_vod__c) <= thd[0]){
                    tmpTmColors = tmpTmColors + ',"green"';
                }else if((expectedAttainment - cd.Total_Attainment_vod__c) <= thd[1]){
                    tmpTmColors = tmpTmColors + ',"orange"';
                }else{
                    tmpTmColors = tmpTmColors + ',"red"';
                }                
            }
            tmpColors = tmpColors.replaceFirst(',','');
            setColors('[' + tmpColors + ']');
            
            tmpTmColors = tmpTmColors.replaceFirst(',','');
            setColorsTm('[' + tmpTmColors + ']');
            
        }else{
            setColors('[]');
            setColorsTm('[]');
        }
        if(cyclePlanTargetId.length() == 0){
            try{
               Message_vod__c displayMsg = [Select Text_vod__c From Message_vod__c Where Name='CYCLE_PLAN_NO_DATA_DISPLAY' And Active_vod__c=true and Language_vod__c=:'en_US'];    
               if('true'.equalsIgnoreCase(displayMsg.Text_vod__c)){
                    Message_vod__c msg = [Select Text_vod__c From Message_vod__c Where Name='CYCLE_PLAN_NO_DATA_MESSAGE' And Active_vod__c=true and Language_vod__c=:UserInfo.getLanguage()];    
                    noDataMessage = msg.Text_vod__c;
               }
            }catch (System.QueryException e) {
                //do nothing here, this error should not break app logic
            }
        }
        if(rslt.size() > 0){
            hasData = true;
        }
        if(rslt.size() == 0 && cyclePlanId == null){
            headerLine =  noDataMessage ;
        }else{
            headerLine = planStart + ' - ' +planEnd;
        }
        return rslt;
    }
}