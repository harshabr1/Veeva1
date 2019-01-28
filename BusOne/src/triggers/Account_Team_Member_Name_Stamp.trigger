trigger Account_Team_Member_Name_Stamp on Account_Team_Member_vod__c (before update, before insert) {
    for(Account_Team_Member_vod__c member : Trigger.new) {
        if(member.Team_Member_vod__c != null) {
            User user = [select Name FROM User where id = :member.Team_Member_vod__c];
            member.Team_Member_Name_vod__c = user.Name;
        }    
    }
}