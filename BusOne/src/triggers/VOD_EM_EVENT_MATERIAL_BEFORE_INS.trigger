trigger VOD_EM_EVENT_MATERIAL_BEFORE_INS on EM_Event_Material_vod__c (before insert) {
    Set<String> catalogExclude = new Set<String>{'id', 'name', 'recordtypeid', 'external_id_vod__c', 'createdbyid', 'ownerid',
    'createddate', 'isdeleted', 'islocked', 'lastmodifieddate', 'lastmodifiedbyid', 'mayedit', 'systemmodstamp', 'connectionreceivedid', 'connectionsentid'};
    
        Set<String> documentExclude = new Set<String>{'id', 'recordtypeid', 'external_id_vod__c', 'createdbyid', 'ownerid',
    'createddate', 'isdeleted', 'islocked', 'lastmodifieddate', 'lastmodifiedbyid', 'mayedit', 'systemmodstamp', 'connectionreceivedid', 'connectionsentid'};

    Set<String> clmPresentationExclude = new Set<String>{ 'id', 'recordtypeid', 'external_id_vod__c', 'createdbyid', 'ownerid',
            'createddate', 'isdeleted', 'islocked', 'lastmodifieddate', 'lastmodifiedbyid',
            'mayedit', 'systemmodstamp', 'connectionreceivedid', 'connectionsentid' };

    Set<String> materials = new Set<String>();
    Set<String> approvedDocuments = new Set<String>();
    Set<String> clmPresentations = new Set<String>();
    for (EM_Event_Material_vod__c material : Trigger.new) {
        if (material.Material_vod__c != null) {
            materials.add(material.Material_vod__c);
        } else if (material.Email_Template_vod__c != null) {
            approvedDocuments.add(material.Email_Template_vod__c);
        }
        else if (material.CLM_Presentation_vod__c != null) {
            clmPresentations.add(material.CLM_Presentation_vod__c);
        }
    }

    String query = 'SELECT RecordType.Name';
    Set<String> include = new Set<String>();
    Set<String> materialFields = Schema.getGlobalDescribe().get('EM_Event_Material_vod__c').getDescribe().fields.getMap().keySet();
    Set<String> catalogFields = Schema.getGlobalDescribe().get('EM_Catalog_vod__c').getDescribe().fields.getMap().keySet();
    Map<String, Schema.SObjectField> catalogDescribes = Schema.getGlobalDescribe().get('EM_Catalog_vod__c').getDescribe().fields.getMap();
    for (String field : catalogFields) {
        if (!catalogExclude.contains(field) && !catalogDescribes.get(field).getDescribe().isCalculated() && catalogDescribes.get(field).getDescribe().isCustom()) {
            include.add(field);
            query = query + ',' + field;
        }
    }
    query += ' FROM EM_Catalog_vod__c WHERE Id IN : materials';
    Map<Id, EM_Catalog_vod__c> catalogMap = new Map<Id, EM_Catalog_vod__c>();
    if(include != null && !include.isEmpty()) {
        catalogMap = new Map<Id, EM_Catalog_vod__c>((List<EM_Catalog_vod__c>) Database.query(query));
    }

    String documentQuery = 'SELECT RecordType.Name';
    Set<String> documentInclude = new Set<String>();
    Set<String> documentFields = Schema.getGlobalDescribe().get('Approved_Document_vod__c').getDescribe().fields.getMap().keySet();
    Map<String, Schema.SObjectField> documentDescribes = Schema.getGlobalDescribe().get('Approved_Document_vod__c').getDescribe().fields.getMap();
    for (String field : documentFields) {
        if (!documentExclude.contains(field) && !documentDescribes.get(field).getDescribe().isCalculated() && documentDescribes.get(field).getDescribe().isCustom()) {
            documentInclude.add(field);
            documentQuery = documentQuery + ',' + field;
        }
    }
    documentQuery += ' FROM Approved_Document_vod__c WHERE Id IN : approvedDocuments';
    Map<Id, Approved_Document_vod__c> documentMap = new Map<Id, Approved_Document_vod__c>();
    if(documentInclude != null && !documentInclude.isEmpty()) {
        documentMap = new Map<Id, Approved_Document_vod__c>((List<Approved_Document_vod__c>) Database.query(documentQuery));
    }

    String clmPresentationQuery = 'SELECT ';
    Set<String> clmPresentationInclude = new Set<String>();
    Set<String> clmPresentationFields = Schema.getGlobalDescribe().get('CLM_Presentation_vod__c').getDescribe().fields.getMap().keySet();
    Map<String, Schema.SObjectField> clmPresentationDescribes = Schema.getGlobalDescribe().get('CLM_Presentation_vod__c').getDescribe().fields.getMap();
    for (String field : clmPresentationFields) {
        if (!clmPresentationExclude.contains(field) && !clmPresentationDescribes.get(field).getDescribe().isCalculated() && clmPresentationDescribes.get(field).getDescribe().isCustom()) {
            clmPresentationInclude.add(field);
        }
    }
    clmPresentationQuery += String.join(new List<String>(clmPresentationInclude), ', ');
    clmPresentationQuery += ' FROM CLM_Presentation_vod__c WHERE Id IN : clmPresentations';
    Map<Id, CLM_Presentation_vod__c> clmPresentationMap = new Map<Id, CLM_Presentation_vod__c>();
    if(clmPresentationInclude != null && !clmPresentationInclude.isEmpty()) {
        clmPresentationMap = new Map<Id, CLM_Presentation_vod__c>((List<CLM_Presentation_vod__c>) Database.query(clmPresentationQuery));
    }


    for (EM_Event_Material_vod__c material : Trigger.new) {
        if (material.Material_vod__c != null) {
            EM_Catalog_vod__c catalog = catalogMap.get(material.Material_vod__c);
            if (catalog != null) {
                material.Material_Type_vod__c = catalog.RecordType.Name;
                for (String field : include) {
                    if (materialFields.contains(field)) {
                        material.put(field, catalog.get(field));
                    }
                }
            }
        } else if (material.Email_Template_vod__c != null) {
            Approved_Document_vod__c document = documentMap.get(material.Email_Template_vod__c);
            if (document != null) {
                material.Material_Type_vod__c = document.RecordType.Name;
                for (String field : documentInclude) {
                    if (materialFields.contains(field) || (field == 'document_description_vod__c' && materialFields.contains('description_vod__c'))
                                    || (field == 'name' && materialFields.contains('name_vod__c'))
                                    || (field == 'events_management_subtype_vod__c' && materialFields.contains('subtype_vod__c'))) {
                    	if(field == 'document_description_vod__c') {
                        	material.put('description_vod__c', document.get(field));                    
                        } else if (field == 'name') {
                        	material.put('name_vod__c', document.get(field));      
                        } else if (field == 'events_management_subtype_vod__c') {
                        	material.put('subtype_vod__c', document.get(field));      
                        } else {
                            material.put(field, document.get(field));		    
                        }                                                                            
                    }
                }
            }
        }
        else if (material.CLM_Presentation_vod__c != null) {
            CLM_Presentation_vod__c clmPresentation = clmPresentationMap.get(material.CLM_Presentation_vod__c);
            if (clmPresentation != null) {
                material.Material_Type_vod__c = 'CLM_Presentation_vod'; // hard coded because CLM Presentation doesn't have record types
                for (String field : clmPresentationInclude) {
                    Boolean mustMapNameField = field == 'name' && materialFields.contains('name_vod__c');

                    if (materialFields.contains(field) || mustMapNameField) {
                        if(field == 'name') {
                            material.put('name_vod__c', clmPresentation.get(field));
                        }
                        else {
                            material.put(field, clmPresentation.get(field));
                        }
                    }
                }
            }
        }
    }
}