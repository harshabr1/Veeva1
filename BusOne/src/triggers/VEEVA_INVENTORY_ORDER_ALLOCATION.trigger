trigger VEEVA_INVENTORY_ORDER_ALLOCATION on Inventory_Order_Allocation_vod__c (before insert, before update) {
    Set<String> userIds = new Set<String>();
    /* userIds.add(null);
    Set<String> groups = new Set<String>();
    groups.add(null); */
    Set<String> productIds = new Set<String>();

    for (Integer i  = 0; i < Trigger.new.size(); i++) {
        if (Trigger.new[i].Active_vod__c == false)
            continue;

        /* if (Trigger.new[i].User_Allocation_Group_vod__c != null)
            groups.add(Trigger.new[i].User_Allocation_Group_vod__c); */

        userIds.add(Trigger.new[i].User_vod__c);
        if (Trigger.new[i].User_vod__c != null) {
            //#13681
            Trigger.new[i].OwnerId = Trigger.new[i].User_vod__c;
        }

        productIds.add(Trigger.new[i].Product_vod__c);
    }

    String query = 'SELECT Id, Product_vod__c, User_vod__c, ';
    query += 'User_Allocation_Group_vod__c, Allocation_Start_Date_vod__c, Allocation_End_Date_vod__c';
    query += ' FROM Inventory_Order_Allocation_vod__c';
    query += ' WHERE Product_vod__c IN :productIds AND Active_vod__c = true';
    query += ' AND User_vod__c IN :userIds';
  //  query += ' AND User_Allocation_Group_vod__c IN :groups';

    Set<String> modifiedIds = new Set<String>();
    if(Trigger.old != null) {
        for (Inventory_Order_Allocation_vod__c modifiedAllocation: Trigger.old) {
            modifiedIds.add(modifiedAllocation.Id);
        }
    }
    for (Inventory_Order_Allocation_vod__c modifiedAllocation: Trigger.new) {
        if(modifiedAllocation.Id != null) {
            modifiedIds.add(modifiedAllocation.Id);
        }
    }

    // presentAllocations contains the Allocation objects to check against for Date range overlaps
    List<Inventory_Order_Allocation_vod__c> presentAllocations = new List<Inventory_Order_Allocation_vod__c>();
    presentAllocations.addAll(Trigger.new);
    for(Inventory_Order_Allocation_vod__c savedAllocation : Database.query(query)) {
        if(!modifiedIds.contains(savedAllocation.Id)) {
            presentAllocations.add(savedAllocation);
        }
    }

    Map<String, Set<Inventory_Order_Allocation_vod__c>> allocationMap = new Map<String, Set<Inventory_Order_Allocation_vod__c>>();
    for (Inventory_Order_Allocation_vod__c each : Trigger.new) {
        String key = each.Product_vod__c + ':' + each.User_vod__c + ':' + each.User_Allocation_Group_vod__c;
        Set<Inventory_Order_Allocation_vod__c> allocations = allocationMap.get(key);
        if (allocations == null) {
            allocations = new Set<Inventory_Order_Allocation_vod__c>();
            allocationMap.put(key, allocations);
        }
        allocations.add(each);
    }

    for (Integer i = 0; i < presentAllocations.size(); ++i) {
        Inventory_Order_Allocation_vod__c presentAllocation = presentAllocations.get(i);
        Set<Inventory_Order_Allocation_vod__c> upserts = allocationMap.get(presentAllocation.Product_vod__c + ':' + presentAllocation.User_vod__c + ':' + presentAllocation.User_Allocation_Group_vod__c);
        if (upserts != null) {
            for (Inventory_Order_Allocation_vod__c upsertedAllocation : upserts) {
                if (upsertedAllocation == presentAllocation) {
                    continue;
                }
                String overlapErrorMsg = 'Overlap detected with ';
                if(presentAllocation.id != null) {
                    overlapErrorMsg += presentAllocation.Id;
                }
                else {
                    overlapErrorMsg += ('record ' + String.valueOf(i + 1));
                }
                if ((upsertedAllocation.Allocation_Start_Date_vod__c >= presentAllocation.Allocation_Start_Date_vod__c) && (upsertedAllocation.Allocation_Start_Date_vod__c <= presentAllocation.Allocation_End_Date_vod__c))
                    upsertedAllocation.addError(overlapErrorMsg, false);
                if ((upsertedAllocation.Allocation_End_Date_vod__c >= presentAllocation.Allocation_Start_Date_vod__c) && (upsertedAllocation.Allocation_End_Date_vod__c <= presentAllocation.Allocation_End_Date_vod__c))
                    upsertedAllocation.addError(overlapErrorMsg, false);
                if ((upsertedAllocation.Allocation_Start_Date_vod__c <= presentAllocation.Allocation_Start_Date_vod__c) && (upsertedAllocation.Allocation_End_Date_vod__c >= presentAllocation.Allocation_End_Date_vod__c))
                    upsertedAllocation.addError(overlapErrorMsg, false);
            }
        }
    }
}