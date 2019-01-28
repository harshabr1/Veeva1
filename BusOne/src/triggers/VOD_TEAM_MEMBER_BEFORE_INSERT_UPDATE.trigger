trigger VOD_TEAM_MEMBER_BEFORE_INSERT_UPDATE on EM_Event_Team_Member_vod__c (before insert, before update) {
    Set<String> idSet = new Set<String>();
    Set<String> groupNameSet = new Set<String>();
    Map<String, String> idToFirst = new Map<String, String>();
    Map<String, String> idToLast = new Map<String, String>();
    Map<String, String> idToName = new Map<String, String>();
    Map<String, String> groupNameToLabel = new Map<String, String>();

    RecordType teamMemberRecordType;
    RecordType groupRecordType;

    for(RecordType recordType : [SELECT Id, DeveloperName
                                 FROM RecordType
                                 WHERE SobjectType = 'EM_Event_Team_Member_vod__c'
                                 AND DeveloperName IN ('Event_Team_Member_vod', 'Group_vod')]) {
        if(recordType.DeveloperName == 'Event_Team_Member_vod') {
            teamMemberRecordType = recordType;
        } else if(recordType.DeveloperName == 'Group_vod') {
            groupRecordType = recordType;
        }
    }

    String duplicatePersonText = 'This person is already on the event team';
    String duplicateGroupText = 'This group is already on the event team';

    List<Message_vod__c> messageList;
    try {
        messageList = [SELECT Name, Text_vod__c From Message_vod__c 
                       WHERE (Name='DUPLICATE_TEAM_MEMBER_ERROR' OR Name='DUPLICATE_TEAM_MEMBER_ERROR_GROUP') 
                       AND Category_vod__c='EVENT_MANAGEMENT' AND Active_vod__c=true 
                       AND Language_vod__c=:UserInfo.getLanguage()];
    } catch(Exception e) {
        messageList = null;
    }

    if(messageList != null) {
        for(Message_vod__c message : messageList) {
            String messageText = message.Text_vod__c;
            if(message.Name == 'DUPLICATE_TEAM_MEMBER_ERROR') {
                duplicatePersonText = messageText;
            } else if(message.Name == 'DUPLICATE_TEAM_MEMBER_ERROR_GROUP') {
                duplicateGroupText = messageText;
            }
        }
    }

    Set<Id> eventIds = new Set<Id>();

    for(EM_Event_Team_Member_vod__c member: Trigger.new) {
        eventIds.add(member.Event_vod__c);
    }

    List<EM_Event_Team_Member_vod__c> existingTeamMembers = [SELECT Group_Name_vod__c, Team_Member_vod__c, Event_vod__c 
                                                             FROM EM_Event_Team_Member_vod__c 
                                                             WHERE Event_vod__c IN :eventIds];

    for (EM_Event_Team_Member_vod__c existingMember : existingTeamMembers) {
        for(EM_Event_Team_Member_vod__c newMember: Trigger.new) {
            if (newMember.RecordTypeId == teamMemberRecordType.Id && (Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(newMember.Id).Team_Member_vod__c != newMember.Team_Member_vod__c)) &&
                existingMember.Event_vod__c == newMember.Event_vod__c && existingMember.Team_Member_vod__c == newMember.Team_Member_vod__c && newMember.Team_Member_vod__c != null) {
                newMember.addError(duplicatePersonText);
            } else if(newMember.RecordTypeId == groupRecordType.Id && (Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(newMember.Id).Group_Name_vod__c != newMember.Group_Name_vod__c)) &&
                existingMember.Event_vod__c == newMember.Event_vod__c && existingMember.Group_Name_vod__c == newMember.Group_Name_vod__c && newMember.Group_Name_vod__c != null) {
                newMember.addError(duplicateGroupText);
            }
        }
    }

    for (EM_Event_Team_Member_vod__c member : trigger.new){
        String id = member.Team_Member_vod__c;
        String groupName = member.Group_Name_vod__c;
        if (id != null) {
            idSet.add(id);
        } else if(groupName != null) {
            groupNameSet.add(groupName);
        }
    }

    for (User user : [SELECT LastName, FirstName, Name
                      FROM User
                      WHERE Id IN :idSet]) {
        idToFirst.put(user.Id, user.FirstName);
        idToLast.put(user.Id, user.LastName);
        idToName.put(user.Id, user.Name);
    }

    for(Group publicGroup : [SELECT Name, DeveloperName 
                             FROM Group 
                             WHERE DeveloperName IN :groupNameSet AND Type IN ('Queue', 'Regular')]) {
        groupNameToLabel.put(publicGroup.DeveloperName, publicGroup.Name);
    }

    for (EM_Event_Team_Member_vod__c member : trigger.new){
        String type = member.Team_Member_Type_vod__c;
        String userId = member.Team_Member_vod__c;
        String groupName = member.Group_Name_vod__c;
        if (type == 'User_vod'|| userId != null) {
            String first = idToFirst.get(userId);
            String last = idToLast.get(userId);
            String name = idToName.get(userId);
            if (first != null && last != null) {
                member.Name = last + ', ' + first;
            } else {
                member.Name = name;
            }
            if(first != null) {
                member.First_Name_vod__c = first;
            }
            if(last != null) {
                member.Last_Name_vod__c = last;
            }
        } else if(type == 'Group_vod' || groupName != null) {

            String groupLabel = groupNameToLabel.get(groupName);
            if(groupLabel != null) {
                member.Name = groupLabel;
            }
        } else if (type == 'Write_In_vod') {
            String first = member.First_Name_vod__c == null ? '' : member.First_Name_vod__c;
            String last = member.Last_Name_vod__c == null ? '' : member.Last_Name_vod__c;
            member.name = last + ', ' + first;
        }
    }
}