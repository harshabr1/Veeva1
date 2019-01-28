public class VOD_ANALYTIC_FILES {
        
            public static boolean isMatchingColumnNames (String trigColumn_Label_vod, String trigSecond_Column_Label_vod, String selColumn_Label_vod, String selSecond_Column_Label_vod ) {
                System.debug('\ntrigColumn_Label_vod = ' + trigColumn_Label_vod + '\n' + 
                             'trigSecond_Column_Label_vod = ' + trigSecond_Column_Label_vod + '\n' +
                             'selColumn_Label_vod = ' + selColumn_Label_vod + '\n' +
                             'selSecond_Column_Label_vod = ' + selSecond_Column_Label_vod + '\n');
                if (trigColumn_Label_vod == selColumn_Label_vod) {
                    return true;
                    
                    }
            
                if (trigColumn_Label_vod == selSecond_Column_Label_vod) {
                    return true;
                }
                if (trigSecond_Column_Label_vod != null && trigSecond_Column_Label_vod.length () > 0) {
                     System.debug(trigSecond_Column_Label_vod  + '==' + selSecond_Column_Label_vod);
                    if (trigSecond_Column_Label_vod  == selSecond_Column_Label_vod) {
                        return true;
                    }
                   
                   System.debug(trigSecond_Column_Label_vod  + '==' + selColumn_Label_vod);
        
                    if (trigSecond_Column_Label_vod  == selColumn_Label_vod) {
                        return true;
                    }
                }
            return false;
            }
            
        }