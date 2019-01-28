public class VEEVA_CYCLE_PLAN_REALTIME_CALC {
    private static boolean invoked = false;
    public static void invokeCalculation(List<Call2_vod__c> calls) {
        if (invoked)
            return;

        invoked = true;
        Set<String> setPlansInSet = new Set<String>();
        set<String> accounts = new set<String>();

        //account and territory together will be a composite unique key
        for(Call2_vod__c call : calls) {
            if(accounts.contains(call.Account_vod__c) == false){
                accounts.add(call.Account_vod__c);
            }
        }

        List<Cycle_Plan_Target_vod__c>  targetObjs = new List<Cycle_Plan_Target_vod__c>();

        for(Cycle_Plan_Target_vod__c target : [SELECT Id, Cycle_Plan_account_vod__c, Cycle_Plan_vod__r.Territory_vod__c,
                Cycle_Plan_vod__r.Start_Date_vod__c,
                Cycle_Plan_vod__r.End_Date_vod__c
                FROM  Cycle_Plan_Target_vod__c
                WHERE Cycle_Plan_vod__r.Active_vod__c = true
                    AND Cycle_Plan_account_vod__c in :accounts
                    AND Cycle_Plan_vod__r.Start_Date_vod__c <= LAST_N_DAYS:1
                    AND Cycle_Plan_vod__r.End_Date_vod__c >= LAST_N_DAYS:1]) {
            String territory = target.Cycle_Plan_vod__r.Territory_vod__c;
            String account = target.Cycle_Plan_account_vod__c;
            Date startDate = target.Cycle_Plan_vod__r.Start_Date_vod__c;
            Date endDate = target.Cycle_Plan_vod__r.End_Date_vod__c;

            if(account != null && territory != null ){
                for(Call2_vod__c call : calls){
                    if(call != null && call.Call_Date_vod__c >= startDate && call.Call_Date_vod__c <= endDate && call.Territory_vod__c.equals(territory)){
                        setPlansInSet.add(target.Id);
                    }
                }
            }
        }


        if(setPlansInSet.size() > 0) {
        updateCyclePlan(setPlansInSet);
        }
        invoked = false;
    }

    @future
    public static void updateCyclePlan(set<String> targetIds){

        List <Cycle_Plan_Target_vod__c> planTargetsToUpdate = new List <Cycle_Plan_Target_vod__c> ();
        Set<String> setPlansInSet = new Set<String> ();

        List <Cycle_Plan_Detail_vod__c> planDetailsToUpdate = new List <Cycle_Plan_Detail_vod__c> ();
        Set<String> setPlanDetailssInSet = new Set<String> ();

        String customActualWhereClause = getCalcCyclePlansActual();
        String customScheduleWhereClause = getCalcCyclePlanScheduled();

        set<String> allActualIds = new set<String>();
        set<String> allScheduledIds= new set<String>();

        Map<String, set<String>> mapTargetScheduledCalls = new  Map<String, set<String>>();
        Map<String, set<String>> mapTargetActualCalls = new Map<String,set<String>>();

        for(Cycle_Plan_Target_vod__c target : [SELECT Id,
                Cycle_Plan_vod__r.Start_Date_vod__c,
                Cycle_Plan_vod__r.End_Date_vod__c,
                Cycle_Plan_vod__r.Territory_vod__c,
                Cycle_Plan_Account_vod__c
                FROM  Cycle_Plan_Target_vod__c where Id in :targetIds] ) {

            String acct = target.Cycle_Plan_Account_vod__c;
            Date startDate = target.Cycle_Plan_vod__r.Start_Date_vod__c;
            Date endDate = target.Cycle_Plan_vod__r.End_Date_vod__c;
            String terr = target.Cycle_Plan_vod__r.Territory_vod__c;

            String selStmt = 'Select Id' +
            ' FROM Call2_vod__c' +
            ' WHERE Account_vod__c = :acct' +
            ' and Call_Date_vod__c >= :startDate' +
            ' and Call_Date_vod__c <= :endDate' +
            ' and Territory_vod__c = :terr';

            String selStmtActual;
            String selStmtScheduled;

            if(customActualWhereClause != null && customActualWhereClause.length() > 0){
                selStmtActual = selStmt + ' and ' + customActualWhereClause ;
            }
            else
            selStmtActual = selStmt;

            system.debug(selStmtActual);

            List<Call2_vod__c> actualResults = Database.query(selStmtActual);
            set<String> actualIds= new Set<String>();

            Integer callsActual = 0;
            for(Call2_vod__c call : actualResults){
                actualIds.add(call.Id);
                allActualIds.add(call.Id);
            }
            callsActual = actualIds.size();

            if(customScheduleWhereClause !=null && customScheduleWhereClause.length() > 0) {
                selStmtScheduled = selStmt + ' and ' + customScheduleWhereClause;
            }
            else
                selStmtScheduled = selStmt;

            List<Call2_vod__c> scheduledResults = Database.query(selStmtScheduled);
            Integer callsSched = 0;
            set<String> scheduledIds= new Set<String>();
            for(Call2_vod__c call : scheduledResults){
                scheduledIds.add(call.Id);
                allScheduledIds.add(call.Id);
            }
            callsSched = scheduledIds.size();


            Cycle_Plan_Target_vod__c PlanTarget =
                new Cycle_Plan_Target_vod__c(ID = target.Id,
                        Scheduled_Calls_vod__c = callsSched,
                        Actual_Calls_vod__c = callsActual
                        );

            if (setPlansInSet.contains(target.Id) == false) {
                //System.debug('3 - ' + PlanTarget);
                planTargetsToUpdate.add (PlanTarget);
                setPlansInSet.add(target.Id);
                mapTargetActualCalls.put(target.Id,actualIds);
                mapTargetScheduledCalls.put(target.Id, scheduledIds);
            }
        }

        //now calculate cycle plan details
        List<AggregateResult> callDetailScheduled = [Select product_vod__c, call2_vod__c,count(Id) totCalls
                FROM Call2_Detail_vod__c
                WHERE call2_vod__c IN :allScheduledIds
                group by call2_vod__c, product_vod__c];

        List<AggregateResult> callDetailActual = [Select product_vod__c,call2_vod__c, count(Id) totCalls
                FROM Call2_Detail_vod__c
                WHERE call2_vod__c IN : allActualIds
                group by call2_vod__c, product_vod__c];

        for(Cycle_Plan_Detail_vod__c detail : [Select Id, Cycle_Plan_target_vod__c, product_vod__c FROM Cycle_Plan_Detail_vod__c WHERE
                Cycle_Plan_Target_vod__c in :setPlansInSet]){

            String product = detail.Product_vod__c;
            Integer callDetailSchedCount = 0;
            Integer callDetailActualCount = 0;
            String targetId = detail.Cycle_Plan_target_vod__c;
            if(product == null || targetId == null )
                continue;
            Set<String> actualCallIds = mapTargetActualCalls.get(targetId);
            Set<String> scheduledCallIds = mapTargetScheduledCalls.get(targetId);

            for (AggregateResult ars : callDetailScheduled) {
                if(scheduledCallIds.contains((String)ars.get('Call2_vod__c')) && ars.get('Product_vod__c') == product ) {
                    callDetailSchedCount += (Integer)ars.get('totCalls');
                }
            }

            for (AggregateResult ars : callDetailActual) {
                if(actualCallIds.contains((String)ars.get('Call2_vod__c')) && ars.get('Product_vod__c') == product) {
                    callDetailActualCount += (Integer)ars.get('totCalls');
                }
            }
            Cycle_Plan_Detail_vod__c PlanDetail =
                new Cycle_Plan_Detail_vod__c(ID = detail.Id,
                        Scheduled_Details_vod__c = callDetailSchedCount,
                        Actual_Details_vod__c = callDetailActualCount
                );

            if (setPlanDetailssInSet.contains(detail.Id) == false) {
                planDetailsToUpdate.add (PlanDetail);
                setPlanDetailssInSet.add(detail.Id);
            }
        }

        if (planTargetsToUpdate.size () > 0 ) {
            //System.debug (planTargetsToUpdate);
            try {
                update planTargetsToUpdate;
            }

            catch (DMLException e) { // ignore the error
                System.debug(e.getMessage());

            }
            planTargetsToUpdate.clear();
        }

        if (planDetailsToUpdate.size () > 0) {
            //System.debug (planDetailsToUpdate);
            try {
                update planDetailsToUpdate;
            }
            catch (DMLException e) { // ignore the error
                System.debug(e.getMessage());
            }
            planDetailsToUpdate.clear();
        }

    }

    public static String getCalcCyclePlansActual(){
        Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getInstance();
        if (vsc != null && vsc.CALC_CYCLE_PLANS_ACTUAL_vod__c != null){
        String [] messageParts = vsc.CALC_CYCLE_PLANS_ACTUAL_vod__c.Split(';;');
        if(messageParts.size() > 1)
            return VOD_GET_ERROR_MSG.getErrorMsg(messageParts[0],messageParts[1]);
        else
            return null;
        }
        else
            return null;
    }

    public static String getCalcCyclePlanScheduled(){
    Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getInstance();
    if (vsc != null && vsc.CALC_CYCLE_PLANS_SCHEDULED_vod__c != null){
        String [] messageParts = vsc.CALC_CYCLE_PLANS_SCHEDULED_vod__c.Split(';;');
        if(messageParts.size() > 1)
            return VOD_GET_ERROR_MSG.getErrorMsg(messageParts[0],messageParts[1]);
        else
            return null;
    }
    else
        return null;
    }

    public static boolean isEnableRealTimeCC() {
        Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getInstance();
        if (vsc != null && vsc.CALC_CYCLE_PLANS_REALTIME_vod__c == true)
            return true;
        return false;
    }
}