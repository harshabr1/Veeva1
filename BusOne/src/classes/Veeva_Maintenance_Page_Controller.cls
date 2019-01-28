public class Veeva_Maintenance_Page_Controller {
/*****************************************************************************************************************************************
This is the extention of Veeva_Maintenanse_Page Visualforce page to support Apex Classes calls
Version 1.4, 2017-10-23
******************************************************************************************************************************************/
    
    // Alert Message for Javascript alert() in main Visualforce page
    public String textAlertMessage { get; set; }

    private String usedDateToString(Date d) {
        String ds = '';
        ds += d.year() + '-';
        if (d.month() < 10) {
            ds += '0';
        }
        ds += d.month() + '-';
        if (d.day() < 10) {
            ds += '0';
        }
        ds += d.day();
        ds += 'T00:00:00.000Z';
        return ds;
    }

    /*** Interface components ***/
    public Veeva_Maintenance_Page_Controller() {
    }
    
    /*** Apex Classes methods ***/
    
    /*** Call_Address analysis ***/
    private String calladdressbatchsize = '200';
    
    public void setcalladdressbatchsize(String s) {
        calladdressbatchsize = s;
    }
    
    public String getcalladdressbatchsize() {
        return calladdressbatchsize;
    }
    
    private Date usedStartDate = Date.newInstance(2017, 8, 1);
    private Date usedEndDate = Date.newInstance(2100, 12, 31);
    
    public void setusedStartDate(Date d) {
        if (d < Date.newInstance(2017, 8, 1)) {
            usedStartDate = Date.newInstance(2017, 8, 1);
        } else {
            usedStartDate = d;
        }
    }
    
    public Date getusedStartDate() {
        return usedStartDate;
    }

    public void setusedEndDate(Date d) {
        usedEndDate = d;
    }
    
    public Date getusedEndDate() {
        return usedEndDate;
    }
    
    public PageReference Test_Call_Addresses() {
        // Check data scope
        if (usedStartDate == null) usedStartDate = Date.newInstance(2017, 8, 1);
        if (usedEndDate == null) usedEndDate = Date.newInstance(2100, 12, 31);

        // Request an estimate of data amount
        Integer C = 0;
        try {
            C = [SELECT count() FROM Call2_vod__c WHERE LastModifiedDate >= :usedStartDate AND LastModifiedDate < :usedEndDate AND Parent_Address_vod__c = null AND Address_Line_1_vod__c != null];
        } catch(System.DMLException e) {
            textAlertMessage = 'SOQL error : ' + e.getMessage();
            return null;
        }
        textAlertMessage = 'Number of Calls to check : ' + C.format();
        return null;
    }
    
    public PageReference Check_Call_Addresses() {
        Integer APEX_BATCH_SIZE = 200;
        // Read selected batch size
        if (calladdressbatchsize != null && calladdressbatchsize.isNumeric()) APEX_BATCH_SIZE = integer.valueOf(calladdressbatchsize);
        if (APEX_BATCH_SIZE == null || APEX_BATCH_SIZE < 1) APEX_BATCH_SIZE = 200;
        // Check for Maximum value
        if (APEX_BATCH_SIZE > 2000) APEX_BATCH_SIZE = 2000;
        
        // Check data scope
        if (usedStartDate == null) usedStartDate = Date.newInstance(2017, 8, 1);
        if (usedEndDate == null) usedEndDate = Date.newInstance(2100, 12, 31);
        
        // Run Apex Class
        try {
            Veeva_Maintenance_Call_Address CallAddressCls = new Veeva_Maintenance_Call_Address();
            CallAddressCls.StartDate = usedDateToString(usedStartDate);
            CallAddressCls.EndDate = usedDateToString(usedEndDate);
            Id batchJobId = Database.executeBatch(CallAddressCls, APEX_BATCH_SIZE);
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }
        //  After successful call, navigate to the Private Library
        PageReference redirectSuccess = new PageReference('/_ui/core/chatter/files/FileTabPage');
        redirectSuccess.setRedirect(true);
        return redirectSuccess;
    }

    /*** Sample_Limit analysis ***/
    private Date SL_StartDate = Date.newInstance(System.today().year(), System.today().month(), 1);
    private Date SL_EndDate = System.today();
    
    public void setSL_StartDate(Date d) {
        SL_StartDate = d;
    }
    
    public Date getSL_StartDate() {
        return SL_StartDate;
    }

    public void setSL_EndDate(Date d) {
        SL_EndDate = d;
    }
    
    public Date getSL_EndDate() {
        return SL_EndDate;
    }

    public PageReference Check_Sample_Limits() {
        // Batch Size cannot be changed by the User
        Integer APEX_BATCH_SIZE = 100;
        
        // Check data scope
        Date slToday = System.today();
        if (SL_StartDate == null) SL_StartDate = Date.newInstance(slToday.year(), slToday.month(), 1);
        if (SL_EndDate == null) SL_EndDate = slToday;

        // Run Apex Class
        try {
            Veeva_Maintenance_Sample_Limit SampleLimitCls = new Veeva_Maintenance_Sample_Limit();
            SampleLimitCls.StartDate = usedDateToString(SL_StartDate);
            SampleLimitCls.EndDate = usedDateToString(SL_EndDate);
            Id batchJobId = Database.executeBatch(SampleLimitCls, APEX_BATCH_SIZE);
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }
        //  After successful call, navigate to the Private Library
        PageReference redirectSuccess = new PageReference('/_ui/core/chatter/files/FileTabPage');
        redirectSuccess.setRedirect(true);
        return redirectSuccess;
    }

}