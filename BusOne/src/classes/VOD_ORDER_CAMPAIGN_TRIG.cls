public class VOD_ORDER_CAMPAIGN_TRIG{
            static Boolean inOrderCampaignTrig = false;
        
            public static void setCampaignTrig (Boolean p_inCampaignTrig) {
                inOrderCampaignTrig = p_inCampaignTrig;
            }
            
           public static Boolean getCampaignTrig ()  {
                return inOrderCampaignTrig ;
           }
        }