trigger VEEVA_CALL2_SAMPLE_CANCEL_AFTER_INSERT on Call2_Sample_Cancel_vod__c (after insert) {
	String ProfileId = Userinfo.getProfileId();
	Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :ProfileId];
	boolean modAllData = false;
	if (pr != null && pr.PermissionsModifyAllData)
		modAllData = true;
	VEEVA_SAMPLE_CANCEL.isSampleCancel = true;
	Set<Id> owners = new Set<Id> ();

	Map <Id, Call2_Sample_Cancel_vod__c> sampleCancelMap =
			new Map<Id, Call2_Sample_Cancel_vod__c>
					([Select Id,
					Call2_Sample_vod__c,
					Call2_Sample_vod__r.Call2_vod__c,
					Call2_Sample_vod__r.Call2_vod__r.OwnerId,
					Call2_Sample_vod__r.Product_vod__r.Product_Type_vod__c,
					Call2_Sample_vod__r.Product_vod__c,
					Call2_Sample_vod__r.Name,
					Call2_Sample_vod__r.Delivery_Status_vod__c,
					Mobile_ID_vod__c
					FROM Call2_Sample_Cancel_vod__c
					WHERE Id in :Trigger.new]);


	List<Call2_vod__c> touchCallList = new List<Call2_vod__c> ();
	List<Call2_Sample_vod__c> touchCallSampList = new List<Call2_Sample_vod__c> ();
	Set<Id> callIds = new Set<Id>();
	Set<Id> callSampTouch = new Set<Id>();

	for (Call2_Sample_Cancel_vod__c cSCan : sampleCancelMap.values()) {
		callIds.add(cSCan.Call2_Sample_vod__r.Call2_vod__c);
		callSampTouch.add(cSCan.Call2_Sample_vod__c);
	}

	for (Id callIdtoTouch : callIds) {
		Call2_vod__c callObj = new Call2_vod__c(Id = callIdtoTouch);
		touchCallList.add(callObj);
	}
	for (Id callSampIdtoTouch : callSampTouch) {
		Call2_Sample_vod__c callSampObj = new Call2_Sample_vod__c(Id = callSampIdtoTouch);
		touchCallSampList.add(callsampObj);
	}


	try {
		update touchCallList;
		update touchCallSampList;
	} catch (System.Dmlexception e) {
	}


	List<String> callSampleList = new List<String>();
	for (Call2_Sample_Cancel_vod__c cSCan : sampleCancelMap.values()) {
		callIds.add(cSCan.Call2_Sample_vod__r.Call2_vod__c);
		System.Debug(cSCan.Call2_Sample_vod__r.Product_vod__r.Product_Type_vod__c);
		if (cSCan.Call2_Sample_vod__r.Product_vod__r.Product_Type_vod__c != 'BRC')
		{
			//This is all or nothing.
			if (cSCan.Mobile_ID_vod__c == null) {
				for (Call2_Sample_Cancel_vod__c cError : Trigger.new) {
					cError.Id.addError(System.label.CANCEL_SAMPLE_ORDER_NOT_BRC, false);
				}
			}
			return;
		}

		if ((modAllData == true || cSCan.Call2_Sample_vod__r.Call2_vod__r.OwnerId == UserInfo.getUserId()) &&
				(cSCan.Call2_Sample_vod__r.Delivery_Status_vod__c == null ||
								cSCan.Call2_Sample_vod__r.Delivery_Status_vod__c == 'In_Progress_vod')) {
			callSampleList.add(cSCan.Call2_Sample_vod__c);
			owners.add(cSCan.Call2_Sample_vod__r.Call2_vod__r.OwnerId);
		} else {
			if (cSCan.Call2_Sample_vod__r.Delivery_Status_vod__c == null ||
							cSCan.Call2_Sample_vod__r.Delivery_Status_vod__c == 'In_Progress_vod')

			if (cSCan.Mobile_ID_vod__c == null) {
				cSCan.Id.addError(System.label.CANCEL_SAMPLE_ORDER_NOT_OWNER, false);
			}
		}
	}


	Map<Id, Id> callSampToOrderMap = new Map<Id, Id> ();

	for (Sample_Order_Transaction_vod__c sampOrder
			:
	[SELECT Id,Call_Id_vod__c, Call_Sample_Id_vod__c, Delivery_Status_vod__c
			FROM Sample_Order_Transaction_vod__c
			WHERE Call_Sample_Id_vod__c in :callSampleList
	AND OwnerID in :owners
	AND Delivery_Status_vod__c IN (NULL,'In_Progress_vod') ]) {
		callSampToOrderMap.put(sampOrder.Call_Sample_Id_vod__c, sampOrder.Id);
		callIds.add(sampOrder.Call_Id_vod__c);

	}

	List<Call2_Sample_vod__c> updCallSamples = new List<Call2_Sample_vod__c>();
	List <Sample_Order_Transaction_vod__c> updSampOrder = new List <Sample_Order_Transaction_vod__c> ();

	Set <Id> processedCallSamp = new Set<Id> ();
	for (Id callSamp : callSampToOrderMap.keySet()) {
		Id orderId = callSampToOrderMap.get(callSamp);
		//Call2_Sample_vod__c newcs = new Call2_Sample_vod__c (Id =callSamp,Delivery_Status_vod__c = 'Cancel_Request_vod' );
		Call2_Sample_vod__c newcs =
				new Call2_Sample_vod__c (Id = callSamp, Delivery_Status_vod__c = 'Cancel_Request_vod');
		Sample_Order_Transaction_vod__c neword =
				new Sample_Order_Transaction_vod__c (Id = orderId, Delivery_Status_vod__c = 'Cancel_Request_vod');
		if (processedCallSamp.contains(callSamp) == false) {
			updCallSamples.add(newcs);
			updSampOrder.add(neword);
			processedCallSamp.add(callSamp);
		}
	}

	// validate we got all the sample orders
	for (Call2_Sample_Cancel_vod__c cSend : Trigger.new) {
		if (processedCallSamp.contains(cSend.Call2_Sample_vod__c) == false) {
			for (Call2_Sample_Cancel_vod__c cError : Trigger.new) {
				if (cError.Mobile_ID_vod__c == null)
					cError.Id.addError(System.label.CANCEL_SAMPLE_ORDER_NO_ORDER_ERROR, false);
			}
			return;
		}
	}


	if (updCallSamples.size() > 0) {
		try {
			update updCallSamples;
			update updSampOrder;
			CallSampleManagement.onCallSampleCancelled(callIds, processedCallSamp);
			VEEVA_SAMPLE_CANCEL.isSampleCancel = false;
		} catch (System.DmlException e) {
			VEEVA_SAMPLE_CANCEL.isSampleCancel = false;
			String error = '';
			Integer numErrors = e.getNumDml();
			for (Integer i = 0; i < numErrors; i++) {
				Id thisId = e.getDmlId(i);
				if (thisId != null) {
					error += thisId + ' - ' + e.getDmlMessage(i) + '<br>';
				}
			}

			for (Call2_Sample_Cancel_vod__c errorRec : Trigger.new) {
				errorRec.Id.addError(error, false);
			}
		}
	}
}