trigger ZIP_TO_TERR_BEFORE_INSUPD_TRIGGER on Zip_to_Terr_vod__c (before insert, before update) {
        
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
        		
        	}	
        }