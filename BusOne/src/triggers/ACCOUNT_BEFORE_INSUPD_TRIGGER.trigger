trigger ACCOUNT_BEFORE_INSUPD_TRIGGER on Account ( before insert, before update) {
            VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE ();
            String restrictedProducts = null;
            for (Integer i = 0 ;  i < Trigger.new.size(); i++)  {
            
                String territory = Trigger.new[i].Territory_vod__c;
                if(territory!=null && territory.Length() > 0)
                {
                    String[] territories = territory.split(',');
                    if(territories[0].startsWith(';')==false)
                        territory = ';';
                    else
                        territory = '';
                    for(Integer j=0;j<territories.size();j++)
                    {
                       if(territories[j].Length()==0)
                        continue;
                       territory = territory + territories[j].trim();
                       if(territories[0].endsWith(';')==false)
                        territory = territory + ';';
                    }
                    Trigger.new[i].Territory_vod__c = territory;
                }
                 
                if(Trigger.isInsert && Trigger.new[i].Enable_Restricted_Products_vod__c==true)
                {
                    if(restrictedProducts == null)
                    {
                        for (Product_vod__c product : [select name from Product_vod__c where Product_Type_vod__c='Detail' and Restricted_vod__c=true and Company_Product_vod__c=true]) 
                        {
                            if(restrictedProducts==null)
                            {
                                restrictedProducts = product.Name;
                            }
                            else
                            {
                                restrictedProducts = restrictedProducts + ';;' + product.Name;
                            }       
                        }                    
                    }
                    Trigger.new[i].Restricted_Products_vod__c = restrictedProducts;
                }
   
            }   
        }