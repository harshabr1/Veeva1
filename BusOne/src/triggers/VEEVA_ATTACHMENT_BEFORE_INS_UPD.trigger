trigger VEEVA_ATTACHMENT_BEFORE_INS_UPD on Attachment (before insert, before update) {
    Set<String> catalogIds = new Set<String>();
    for(Attachment att : trigger.New) {
        if(att.ParentId.getSobjectType() == EM_Catalog_vod__c.SobjectType && att.Name != 'Catalog_Preview.jpg'
          && att.Name != 'GENERATING_Catalog_Preview.txt' && att.Name != 'ERROR_Catalog_Preview.txt') {
        	catalogIds.add(att.ParentId);
        }
    }
    
    String commaSepCatalogIds = '';
    for(String catalogId : catalogIds) {
        if(commaSepCatalogIds.length() == 0) {
            commaSepCatalogIds += catalogId;
        } else {
            commaSepCatalogIds += ',' + catalogId;
        }
    }
    
    if(commaSepCatalogIds.length() > 0) {
    	String auth = VOD_EMBED_CONTROLLER.getSfdcAuth();
    	String sfSession = VOD_EMBED_CONTROLLER.getSfSession();
	    String sfEndpoint = VOD_EMBED_CONTROLLER.getSfEndpoint();
    	VEEVA_PREVIEW_GENERATION_PROCESS.generatePreview(auth, sfSession, sfEndpoint, commaSepCatalogIds);    
    }

}