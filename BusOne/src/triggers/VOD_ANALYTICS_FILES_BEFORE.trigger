trigger VOD_ANALYTICS_FILES_BEFORE on Analytics_Files_vod__c (before update, before insert) {
    VOD_ERROR_MSG_BUNDLE  errBundle = new VOD_ERROR_MSG_BUNDLE ();
    
    List <Analytics_Files_vod__c> files = 
    [SELECT Id, Scale_vod__c, Second_Column_Label_vod__c, Market_vod__c,Column_Label_vod__c, Payer_Plan_Mapped_vod__c,Territory_Names_Included_vod__c, Contains_Goals_vod__c 
     FROM Analytics_Files_vod__c
      WHERE Status_vod__c = 'Moved_To_Production_vod'];
      
    for (Analytics_Files_vod__c trigFile :Trigger.new) {
        if (trigFile.Status_vod__c == 'Moved_To_Production_vod' && trigFile.Incremental_vod__c == false) {
            for (Analytics_Files_vod__c filesToCheck : files) {
                
                System.debug('filesToCheck.Column_Label_vod__c = ' + filesToCheck.Column_Label_vod__c);    
                System.debug('trigFile.Column_Label_vod__c = ' + trigFile.Column_Label_vod__c);
                System.debug('filesToCheck.Payer_Plan_Mapped_vod__c = ' + filesToCheck.Payer_Plan_Mapped_vod__c);    
                System.debug('trigFile.Payer_Plan_Mapped_vod__c = ' + trigFile.Payer_Plan_Mapped_vod__c);
                System.debug('trigFile.Contains_Goals_vod__c = ' + trigFile.Contains_Goals_vod__c);
               
                if (VOD_ANALYTIC_FILES.isMatchingColumnNames (trigFile.Column_Label_vod__c, trigFile.Second_Column_Label_vod__c, filesToCheck.Column_Label_vod__c, filesToCheck.Second_Column_Label_vod__c) &&
                    filesToCheck.Payer_Plan_Mapped_vod__c == trigFile.Payer_Plan_Mapped_vod__c  &&
                    trigFile.Payer_Plan_Mapped_vod__c  == true &&
                    filesToCheck.Scale_vod__c   == trigFile.Scale_vod__c    &&
                    filesToCheck.Contains_Goals_vod__c == trigFile.Contains_Goals_vod__c &&
                    filesToCheck.Id != trigFile.Id && filesToCheck.Market_vod__c == trigFile.Market_vod__c) {
                    String Payer_Plan_Mapped_Error_MSG = VOD_GET_ERROR_MSG.getErrorMsg('ConfirmPayerFileError', 'Analytics');
    
                    trigFile.addError(String.format(Payer_Plan_Mapped_Error_MSG,
                        new string[] {
                            trigFile.File_Name_vod__c
                        }
                    ));
                    //trigFile.addError('The '+ trigFile.File_Name_vod__c+' file cannot be moved to Production as a file has been previously moved to Production using a different Data Template where the Payer Plan Mapped field has been checked for the corresponding Column Label.');
                    break;  
                } else if (VOD_ANALYTIC_FILES.isMatchingColumnNames (trigFile.Column_Label_vod__c, trigFile.Second_Column_Label_vod__c, filesToCheck.Column_Label_vod__c, filesToCheck.Second_Column_Label_vod__c) &&
                    filesToCheck.Territory_Names_Included_vod__c   == trigFile.Territory_Names_Included_vod__c    &&
                    filesToCheck.Scale_vod__c   == trigFile.Scale_vod__c    &&
                    trigFile.Territory_Names_Included_vod__c    == true 
                    && filesToCheck.Market_vod__c == trigFile.Market_vod__c
                    && filesToCheck.Contains_Goals_vod__c == trigFile.Contains_Goals_vod__c 
                    && filesToCheck.Id != trigFile.Id) {
                    String Territory_Name_Included_Error_MSG = VOD_GET_ERROR_MSG.getErrorMsg('ConfirmTerritoryFileError', 'Analytics');
                    trigFile.addError(String.format(Territory_Name_Included_Error_MSG,
                        new string[] {
                            trigFile.File_Name_vod__c
                        }
                    ));
                    //trigFile.addError('The '+ trigFile.File_Name_vod__c+' file cannot be moved to Production as a file has been previously moved to Production using a different Data Template where the Territory Name Included field has been checked for the corresponding Column Label.');
                    break;  
                } else if (VOD_ANALYTIC_FILES.isMatchingColumnNames (trigFile.Column_Label_vod__c, trigFile.Second_Column_Label_vod__c, filesToCheck.Column_Label_vod__c, filesToCheck.Second_Column_Label_vod__c) &&                  
                    filesToCheck.Payer_Plan_Mapped_vod__c == trigFile.Payer_Plan_Mapped_vod__c  &&
                    filesToCheck.Scale_vod__c   == trigFile.Scale_vod__c    &&
                    filesToCheck.Market_vod__c == trigFile.Market_vod__c &&
                    filesToCheck.Contains_Goals_vod__c == trigFile.Contains_Goals_vod__c &&
                    trigFile.Payer_Plan_Mapped_vod__c  == false &&
                    filesToCheck.Territory_Names_Included_vod__c   == trigFile.Territory_Names_Included_vod__c    &&
                    trigFile.Territory_Names_Included_vod__c    == false &&
                    filesToCheck.Id != trigFile.Id) {
                    String Column_Label_Error_MSG = VOD_GET_ERROR_MSG.getErrorMsg('ConfirmFileError', 'Analytics');
                    trigFile.addError(String.format(Column_Label_Error_MSG,
                        new string[] {
                            trigFile.File_Name_vod__c
                        }
                    ));
                    //trigFile.addError('The '+ trigFile.File_Name_vod__c+'  file cannot be moved to Production as a file has been previously moved to Production using a different Data Template for the corresponding Column Label.');
                    break;  
                }
            }    
        }        
    }                  
}