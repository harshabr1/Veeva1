//this class provide web service to access custom labels
//if client need to newlly added custom labels, please add an entry for the label here

global with sharing class CustomLabelFetcher{
    public static final Map<String,String> VOD_LABLES_MAP;
    public static final List<String> VOD_LABLES_LIST;
    public static final String STR_DELIMITER= ':::';
    static {
        VOD_LABLES_MAP = new Map<String,String>();
        VOD_LABLES_LIST = new List<String>();
        
        VOD_LABLES_MAP.put('ACCOUNT_ADDRESS_MERGE_BEHAVIOR',System.Label.ACCOUNT_ADDRESS_MERGE_BEHAVIOR);
        VOD_LABLES_MAP.put('ADDRESS_DEL_LOCK_MSG',System.Label.ADDRESS_DEL_LOCK_MSG);
        VOD_LABLES_MAP.put('ADDRESS_PRIMARY_MSG',System.Label.ADDRESS_PRIMARY_MSG);
        VOD_LABLES_MAP.put('ADDRESS_UPD_LOCK_MSG',System.Label.ADDRESS_UPD_LOCK_MSG);
        VOD_LABLES_MAP.put('AFFIL_NO_UPD_ENT',System.Label.AFFIL_NO_UPD_ENT);
        VOD_LABLES_MAP.put('ApplyProductPlan_HelperText_vod',System.Label.ApplyProductPlan_HelperText_vod);
        VOD_LABLES_MAP.put('ApplyProductPlan_NumTacticsColumnLabel_vod',System.Label.ApplyProductPlan_NumTacticsColumnLabel_vod);
        VOD_LABLES_MAP.put('ApplyProductPlan_Title_vod',System.Label.ApplyProductPlan_Title_vod);
        VOD_LABLES_MAP.put('Call_Event_Display_Label',System.Label.Call_Event_Display_Label);
        VOD_LABLES_MAP.put('Call_Event_RecordType_Display',System.Label.Call_Event_RecordType_Display);
        VOD_LABLES_MAP.put('CANCEL_SAMPLE_ORDER_NOT_BRC',System.Label.CANCEL_SAMPLE_ORDER_NOT_BRC);
        VOD_LABLES_MAP.put('CANCEL_SAMPLE_ORDER_NOT_OWNER',System.Label.CANCEL_SAMPLE_ORDER_NOT_OWNER);
        VOD_LABLES_MAP.put('CANCEL_SAMPLE_ORDER_NO_ORDER_ERROR',System.Label.CANCEL_SAMPLE_ORDER_NO_ORDER_ERROR);
        VOD_LABLES_MAP.put('CANNOT_DEL_INQ',System.Label.CANNOT_DEL_INQ);
        VOD_LABLES_MAP.put('CANNOT_SUBMIT_CALL',System.Label.CANNOT_SUBMIT_CALL);
        VOD_LABLES_MAP.put('CANNOT_UPD_INQ',System.Label.CANNOT_UPD_INQ);
        VOD_LABLES_MAP.put('COL_PRE_MAP',System.Label.COL_PRE_MAP);
        VOD_LABLES_MAP.put('Common_CancelButton_vod',System.Label.Common_CancelButton_vod);
        VOD_LABLES_MAP.put('Common_None_vod',System.Label.Common_None_vod);
        VOD_LABLES_MAP.put('Common_ReturnToPreviousPage_vod',System.Label.Common_ReturnToPreviousPage_vod);
        VOD_LABLES_MAP.put('Common_SaveButton_vod',System.Label.Common_SaveButton_vod);
        VOD_LABLES_MAP.put('DEL_KEY_MSG',System.Label.DEL_KEY_MSG);
        VOD_LABLES_MAP.put('DEL_PRODUCT',System.Label.DEL_PRODUCT);
        VOD_LABLES_MAP.put('DEL_PROD_STRAT',System.Label.DEL_PROD_STRAT);
        VOD_LABLES_MAP.put('DEL_SAMPORDER',System.Label.DEL_SAMPORDER);
        VOD_LABLES_MAP.put('DISABLE_VEEVA_MERGE_vod',System.Label.DISABLE_VEEVA_MERGE_vod);
        VOD_LABLES_MAP.put('DUP_AFFIL',System.Label.DUP_AFFIL);
        VOD_LABLES_MAP.put('EXCLUDED_USERS',System.Label.EXCLUDED_USERS);
        VOD_LABLES_MAP.put('LIMIT_AFFIL_MSG',System.Label.LIMIT_AFFIL_MSG);
        VOD_LABLES_MAP.put('MUST_HAVE_FROM',System.Label.MUST_HAVE_FROM);
        VOD_LABLES_MAP.put('MUST_HAVE_TO',System.Label.MUST_HAVE_TO);
        VOD_LABLES_MAP.put('NO_DEL_ACCOUNT',System.Label.NO_DEL_ACCOUNT);
        VOD_LABLES_MAP.put('NO_DEL_ADDRESS',System.Label.NO_DEL_ADDRESS);
        VOD_LABLES_MAP.put('NO_DEL_ANA_MARKET',System.Label.NO_DEL_ANA_MARKET);
        VOD_LABLES_MAP.put('NO_DEL_CALL_W_TRAN',System.Label.NO_DEL_CALL_W_TRAN);
        VOD_LABLES_MAP.put('NO_DEL_CONTACT',System.Label.NO_DEL_CONTACT);
        VOD_LABLES_MAP.put('NO_DEL_DEA_ADDRESS',System.Label.NO_DEL_DEA_ADDRESS);
        VOD_LABLES_MAP.put('NO_DEL_MEDEVENT',System.Label.NO_DEL_MEDEVENT);
        VOD_LABLES_MAP.put('NO_DEL_MED_INQ_WITH_SIG',System.Label.NO_DEL_MED_INQ_WITH_SIG);
        VOD_LABLES_MAP.put('NO_DEL_SAMPLOT_W_TRAN',System.Label.NO_DEL_SAMPLOT_W_TRAN);
        VOD_LABLES_MAP.put('NO_DEL_SUB',System.Label.NO_DEL_SUB);
        VOD_LABLES_MAP.put('NO_DOUBLE_CONFIRM',System.Label.NO_DOUBLE_CONFIRM);
        VOD_LABLES_MAP.put('NO_DUP_COL_OR_PPLAN',System.Label.NO_DUP_COL_OR_PPLAN);
        VOD_LABLES_MAP.put('NO_FUTURE_SUBMIT',System.Label.NO_FUTURE_SUBMIT);
        VOD_LABLES_MAP.put('NO_MOD_ACCOUNT_NAME',System.Label.NO_MOD_ACCOUNT_NAME);
        VOD_LABLES_MAP.put('NO_PARENT_CHAIN',System.Label.NO_PARENT_CHAIN);
        VOD_LABLES_MAP.put('NO_SIG_DEL',System.Label.NO_SIG_DEL);
        VOD_LABLES_MAP.put('NO_TOUCH_EVE',System.Label.NO_TOUCH_EVE);
        VOD_LABLES_MAP.put('NO_TOUCH_EVE_INPROG',System.Label.NO_TOUCH_EVE_INPROG);
        VOD_LABLES_MAP.put('NO_TOUCH_SAMP_INV',System.Label.NO_TOUCH_SAMP_INV);
        VOD_LABLES_MAP.put('NO_TOUCH_SAMP_TRAN',System.Label.NO_TOUCH_SAMP_TRAN);
        VOD_LABLES_MAP.put('NO_TOUCH_SAMP_TRAN_AUD',System.Label.NO_TOUCH_SAMP_TRAN_AUD);
        VOD_LABLES_MAP.put('NO_TOUCH_SAMP_ORDER_TRAN_AUD',System.Label.NO_TOUCH_SAMP_ORDER_TRAN_AUD);
        VOD_LABLES_MAP.put('NO_UPDATE_FIELD',System.Label.NO_UPDATE_FIELD);
        VOD_LABLES_MAP.put('NO_UPD_DEA_ADDRESS',System.Label.NO_UPD_DEA_ADDRESS);
        VOD_LABLES_MAP.put('NO_UPD_SUB',System.Label.NO_UPD_SUB);
        VOD_LABLES_MAP.put('ONLY_ONE_FROM',System.Label.ONLY_ONE_FROM);
        VOD_LABLES_MAP.put('ONLY_ONE_NAME_DT',System.Label.ONLY_ONE_NAME_DT);
        VOD_LABLES_MAP.put('ONLY_ONE_TO',System.Label.ONLY_ONE_TO);
        VOD_LABLES_MAP.put('PackageLabel_CreateButton_vod',System.Label.PackageLabel_CreateButton_vod);
        VOD_LABLES_MAP.put('PackageLabel_ReturnTitle_vod',System.Label.PackageLabel_ReturnTitle_vod);
        VOD_LABLES_MAP.put('PackageLabel_TransferTitle_vod',System.Label.PackageLabel_TransferTitle_vod);
        VOD_LABLES_MAP.put('TRANSFER_TO_REQ',System.Label.TRANSFER_TO_REQ);
        VOD_LABLES_MAP.put('Unable_To_Add_Event',System.Label.Unable_To_Add_Event);
        VOD_LABLES_MAP.put('UPD_SAMPORDER',System.Label.UPD_SAMPORDER);
        VOD_LABLES_MAP.put('User_Territory_Territory_Column_Label_vod',System.Label.User_Territory_Territory_Column_Label_vod);
        VOD_LABLES_MAP.put('User_Territory_Territory_Description_Column_Label_vod',System.Label.User_Territory_Territory_Description_Column_Label_vod);
        VOD_LABLES_MAP.put('User_Territory_Title_vod',System.Label.User_Territory_Title_vod);
        VOD_LABLES_MAP.put('User_Territory_User_Column_Label_vod',System.Label.User_Territory_User_Column_Label_vod);
        VOD_LABLES_MAP.put('USE_MULTI_SAMPLE_vod',System.Label.USE_MULTI_SAMPLE_vod);
        VOD_LABLES_MAP.put('VOD_SERVER_URL',System.Label.VOD_SERVER_URL);
        VOD_LABLES_MAP.put('VOD_VERSION',System.Label.VOD_VERSION);
        
        VOD_LABLES_LIST.add('ACCOUNT_ADDRESS_MERGE_BEHAVIOR' + STR_DELIMITER +System.Label.ACCOUNT_ADDRESS_MERGE_BEHAVIOR);
        VOD_LABLES_LIST.add('ADDRESS_DEL_LOCK_MSG' + STR_DELIMITER +System.Label.ADDRESS_DEL_LOCK_MSG);
        VOD_LABLES_LIST.add('ADDRESS_PRIMARY_MSG' + STR_DELIMITER +System.Label.ADDRESS_PRIMARY_MSG);
        VOD_LABLES_LIST.add('ADDRESS_UPD_LOCK_MSG' + STR_DELIMITER +System.Label.ADDRESS_UPD_LOCK_MSG);
        VOD_LABLES_LIST.add('AFFIL_NO_UPD_ENT' + STR_DELIMITER +System.Label.AFFIL_NO_UPD_ENT);
        VOD_LABLES_LIST.add('ApplyProductPlan_HelperText_vod' + STR_DELIMITER +System.Label.ApplyProductPlan_HelperText_vod);
        VOD_LABLES_LIST.add('ApplyProductPlan_NumTacticsColumnLabel_vod' + STR_DELIMITER +System.Label.ApplyProductPlan_NumTacticsColumnLabel_vod);
        VOD_LABLES_LIST.add('ApplyProductPlan_Title_vod' + STR_DELIMITER +System.Label.ApplyProductPlan_Title_vod);
        VOD_LABLES_LIST.add('Call_Event_Display_Label' + STR_DELIMITER +System.Label.Call_Event_Display_Label);
        VOD_LABLES_LIST.add('Call_Event_RecordType_Display' + STR_DELIMITER +System.Label.Call_Event_RecordType_Display);
        VOD_LABLES_LIST.add('CANCEL_SAMPLE_ORDER_NOT_BRC' + STR_DELIMITER +System.Label.CANCEL_SAMPLE_ORDER_NOT_BRC);
        VOD_LABLES_LIST.add('CANCEL_SAMPLE_ORDER_NOT_OWNER' + STR_DELIMITER +System.Label.CANCEL_SAMPLE_ORDER_NOT_OWNER);
        VOD_LABLES_LIST.add('CANCEL_SAMPLE_ORDER_NO_ORDER_ERROR' + STR_DELIMITER +System.Label.CANCEL_SAMPLE_ORDER_NO_ORDER_ERROR);
        VOD_LABLES_LIST.add('CANNOT_DEL_INQ' + STR_DELIMITER +System.Label.CANNOT_DEL_INQ);
        VOD_LABLES_LIST.add('CANNOT_SUBMIT_CALL' + STR_DELIMITER +System.Label.CANNOT_SUBMIT_CALL);
        VOD_LABLES_LIST.add('CANNOT_UPD_INQ' + STR_DELIMITER +System.Label.CANNOT_UPD_INQ);
        VOD_LABLES_LIST.add('COL_PRE_MAP' + STR_DELIMITER +System.Label.COL_PRE_MAP);
        VOD_LABLES_LIST.add('Common_CancelButton_vod' + STR_DELIMITER +System.Label.Common_CancelButton_vod);
        VOD_LABLES_LIST.add('Common_None_vod' + STR_DELIMITER +System.Label.Common_None_vod);
        VOD_LABLES_LIST.add('Common_ReturnToPreviousPage_vod' + STR_DELIMITER +System.Label.Common_ReturnToPreviousPage_vod);
        VOD_LABLES_LIST.add('Common_SaveButton_vod' + STR_DELIMITER +System.Label.Common_SaveButton_vod);
        VOD_LABLES_LIST.add('DEL_KEY_MSG' + STR_DELIMITER +System.Label.DEL_KEY_MSG);
        VOD_LABLES_LIST.add('DEL_PRODUCT' + STR_DELIMITER +System.Label.DEL_PRODUCT);
        VOD_LABLES_LIST.add('DEL_PROD_STRAT' + STR_DELIMITER +System.Label.DEL_PROD_STRAT);
        VOD_LABLES_LIST.add('DEL_SAMPORDER' + STR_DELIMITER +System.Label.DEL_SAMPORDER);
        VOD_LABLES_LIST.add('DISABLE_VEEVA_MERGE_vod' + STR_DELIMITER +System.Label.DISABLE_VEEVA_MERGE_vod);
        VOD_LABLES_LIST.add('DUP_AFFIL' + STR_DELIMITER +System.Label.DUP_AFFIL);
        VOD_LABLES_LIST.add('EXCLUDED_USERS' + STR_DELIMITER +System.Label.EXCLUDED_USERS);
        VOD_LABLES_LIST.add('LIMIT_AFFIL_MSG' + STR_DELIMITER +System.Label.LIMIT_AFFIL_MSG);
        VOD_LABLES_LIST.add('MUST_HAVE_FROM' + STR_DELIMITER +System.Label.MUST_HAVE_FROM);
        VOD_LABLES_LIST.add('MUST_HAVE_TO' + STR_DELIMITER +System.Label.MUST_HAVE_TO);
        VOD_LABLES_LIST.add('NO_DEL_ACCOUNT' + STR_DELIMITER +System.Label.NO_DEL_ACCOUNT);
        VOD_LABLES_LIST.add('NO_DEL_ADDRESS' + STR_DELIMITER +System.Label.NO_DEL_ADDRESS);
        VOD_LABLES_LIST.add('NO_DEL_ANA_MARKET' + STR_DELIMITER +System.Label.NO_DEL_ANA_MARKET);
        VOD_LABLES_LIST.add('NO_DEL_CALL_W_TRAN' + STR_DELIMITER +System.Label.NO_DEL_CALL_W_TRAN);
        VOD_LABLES_LIST.add('NO_DEL_CONTACT' + STR_DELIMITER +System.Label.NO_DEL_CONTACT);
        VOD_LABLES_LIST.add('NO_DEL_DEA_ADDRESS' + STR_DELIMITER +System.Label.NO_DEL_DEA_ADDRESS);
        VOD_LABLES_LIST.add('NO_DEL_MEDEVENT' + STR_DELIMITER +System.Label.NO_DEL_MEDEVENT);
        VOD_LABLES_LIST.add('NO_DEL_MED_INQ_WITH_SIG' + STR_DELIMITER +System.Label.NO_DEL_MED_INQ_WITH_SIG);
        VOD_LABLES_LIST.add('NO_DEL_SAMPLOT_W_TRAN' + STR_DELIMITER +System.Label.NO_DEL_SAMPLOT_W_TRAN);
        VOD_LABLES_LIST.add('NO_DEL_SUB' + STR_DELIMITER +System.Label.NO_DEL_SUB);
        VOD_LABLES_LIST.add('NO_DOUBLE_CONFIRM' + STR_DELIMITER +System.Label.NO_DOUBLE_CONFIRM);
        VOD_LABLES_LIST.add('NO_DUP_COL_OR_PPLAN' + STR_DELIMITER +System.Label.NO_DUP_COL_OR_PPLAN);
        VOD_LABLES_LIST.add('NO_FUTURE_SUBMIT' + STR_DELIMITER +System.Label.NO_FUTURE_SUBMIT);
        VOD_LABLES_LIST.add('NO_MOD_ACCOUNT_NAME' + STR_DELIMITER +System.Label.NO_MOD_ACCOUNT_NAME);
        VOD_LABLES_LIST.add('NO_PARENT_CHAIN' + STR_DELIMITER +System.Label.NO_PARENT_CHAIN);
        VOD_LABLES_LIST.add('NO_SIG_DEL' + STR_DELIMITER +System.Label.NO_SIG_DEL);
        VOD_LABLES_LIST.add('NO_TOUCH_EVE' + STR_DELIMITER +System.Label.NO_TOUCH_EVE);
        VOD_LABLES_LIST.add('NO_TOUCH_EVE_INPROG' + STR_DELIMITER +System.Label.NO_TOUCH_EVE_INPROG);
        VOD_LABLES_LIST.add('NO_TOUCH_SAMP_INV' + STR_DELIMITER +System.Label.NO_TOUCH_SAMP_INV);
        VOD_LABLES_LIST.add('NO_TOUCH_SAMP_TRAN' + STR_DELIMITER +System.Label.NO_TOUCH_SAMP_TRAN);
        VOD_LABLES_LIST.add('NO_TOUCH_SAMP_TRAN_AUD' + STR_DELIMITER +System.Label.NO_TOUCH_SAMP_TRAN_AUD);
        VOD_LABLES_LIST.add('NO_TOUCH_SAMP_ORDER_TRAN_AUD' + STR_DELIMITER +System.Label.NO_TOUCH_SAMP_ORDER_TRAN_AUD);
        VOD_LABLES_LIST.add('NO_UPDATE_FIELD' + STR_DELIMITER +System.Label.NO_UPDATE_FIELD);
        VOD_LABLES_LIST.add('NO_UPD_DEA_ADDRESS' + STR_DELIMITER +System.Label.NO_UPD_DEA_ADDRESS);
        VOD_LABLES_LIST.add('NO_UPD_SUB' + STR_DELIMITER +System.Label.NO_UPD_SUB);
        VOD_LABLES_LIST.add('ONLY_ONE_FROM' + STR_DELIMITER +System.Label.ONLY_ONE_FROM);
        VOD_LABLES_LIST.add('ONLY_ONE_NAME_DT' + STR_DELIMITER +System.Label.ONLY_ONE_NAME_DT);
        VOD_LABLES_LIST.add('ONLY_ONE_TO' + STR_DELIMITER +System.Label.ONLY_ONE_TO);
        VOD_LABLES_LIST.add('PackageLabel_CreateButton_vod' + STR_DELIMITER +System.Label.PackageLabel_CreateButton_vod);
        VOD_LABLES_LIST.add('PackageLabel_ReturnTitle_vod' + STR_DELIMITER +System.Label.PackageLabel_ReturnTitle_vod);
        VOD_LABLES_LIST.add('PackageLabel_TransferTitle_vod' + STR_DELIMITER +System.Label.PackageLabel_TransferTitle_vod);
        VOD_LABLES_LIST.add('TRANSFER_TO_REQ' + STR_DELIMITER +System.Label.TRANSFER_TO_REQ);
        VOD_LABLES_LIST.add('Unable_To_Add_Event' + STR_DELIMITER +System.Label.Unable_To_Add_Event);
        VOD_LABLES_LIST.add('UPD_SAMPORDER' + STR_DELIMITER +System.Label.UPD_SAMPORDER);
        VOD_LABLES_LIST.add('User_Territory_Territory_Column_Label_vod' + STR_DELIMITER +System.Label.User_Territory_Territory_Column_Label_vod);
        VOD_LABLES_LIST.add('User_Territory_Territory_Description_Column_Label_vod' + STR_DELIMITER +System.Label.User_Territory_Territory_Description_Column_Label_vod);
        VOD_LABLES_LIST.add('User_Territory_Title_vod' + STR_DELIMITER +System.Label.User_Territory_Title_vod);
        VOD_LABLES_LIST.add('User_Territory_User_Column_Label_vod' + STR_DELIMITER +System.Label.User_Territory_User_Column_Label_vod);
        VOD_LABLES_LIST.add('USE_MULTI_SAMPLE_vod' + STR_DELIMITER +System.Label.USE_MULTI_SAMPLE_vod);
        VOD_LABLES_LIST.add('VOD_SERVER_URL' + STR_DELIMITER +System.Label.VOD_SERVER_URL);
        VOD_LABLES_LIST.add('VOD_VERSION' + STR_DELIMITER +System.Label.VOD_VERSION);
    }
    webService static List<String> getCustomLabels(){
        return VOD_LABLES_LIST;
    }
//following two methods are there to avoid recompil wsdl if we need them later on
    webService static List<String> getCustomLabelsByCat(String category){
        return VOD_LABLES_LIST;
    }

    webService static List<String> getCustomLabelsByCatLan(String category,String language){
        //to-do    
        return VOD_LABLES_LIST;
    }
    
    webService static List<String> getCustomLabelsByLan(String language){
    //test code here
    //salesforce returns translated label depened on user setting, cool!!!
        List<String> tslist = new List<String>();
//        tsList.add('test_label:::'+System.Label.test_label);
//        tsList.add('test_label2:::'+System.Label.test_label2);
        return tslist;
    }

    webService static String getCustomLabelByName(String labelName){
        //to-do    
        return VOD_LABLES_MAP.get(labelName);
    }
//following two methods are there to avoid recompil wsdl if we need them later on        
    webService static String getCustomLabelCat(String labelName,String category){
        //to-do
        return VOD_LABLES_MAP.get(labelName);
    }    
    webService static String getCustomLabelCatLan(String labelName,String category,String language){
        //to-do    
        return VOD_LABLES_MAP.get(labelName);
    }    
    
}