public with sharing class VOD_SObjectNewRedirectController {
    String retURL;
    String veevaModule;
    String veevaPage;
    String objectType;
    String queryParams;
    String hasRecordTypes;
    String recordType;
    String saveNewUrl;
    String saveNewUrlParams;
    String encodeRetURL;
    String useRetURL;
    Boolean encodeFlag;

    public VOD_SObjectNewRedirectController() {
        retURL = ApexPages.currentPage().getParameters().get('retURL');
        if (retURL == null) {
            retURL = '';
        }
        veevaModule= ApexPages.currentPage().getParameters().get('veevaModule');
        if (veevaModule == null) {
            veevaModule = '';
        }
        veevaPage= ApexPages.currentPage().getParameters().get('veevaPage');
        if (veevaPage == null) {
            veevaPage = '';
        }
        objectType= ApexPages.currentPage().getParameters().get('objectType');
        if (objectType == null) {
            objectType = '';
        }
        queryParams= ApexPages.currentPage().getParameters().get('queryParams');
        if (queryParams == null) {
            queryParams = '';
        }
        encodeRetURL = ApexPages.currentPage().getParameters().get('encodeRetURL');
        if (encodeRetURL == 'true') {
            encodeFlag = true;
        }else {
            encodeFlag = false;
        }
        useRetURL = ApexPages.currentPage().getParameters().get('useRetURL');
        if (useRetURL == null) {
            useRetURL = '';
        }
        if (objectType != 'Call2_vod__c') {
            hasRecordTypes = ApexPages.currentPage().getParameters().get('hasRecordTypes');
            if (hasRecordTypes == null) {
                hasRecordTypes = '';
            }
        }
        recordType = ApexPages.currentPage().getParameters().get('RecordType');
        if (recordType == null) {
            recordType = '';
        }
        saveNewUrlParams = ApexPages.currentPage().getParameters().get('saveNewUrlParams');
        if (saveNewUrlParams == null) {
            saveNewUrlParams = '';
        }
        String afterRecTypeSelector = ApexPages.currentPage().getParameters().get('saveNewUrl');
        if (afterRecTypeSelector != null && afterRecTypeSelector != '') {
            saveNewUrl = afterRecTypeSelector;
        } else {
            saveNewUrl = '/apex/SObject_New_vod';
        }
    }

    public PageReference redirect() {
        PageReference newChildPage;
        String childPageUrl;
        if(hasRecordTypes == 'true') {
            String objectId = VOD_RedirectUtil.getObjectDurableId(objectType.removeEnd('__c'));
            childPageUrl = '/setup/ui/recordtypeselect.jsp?ent=';
            if(objectType == 'Task') {
                childPageUrl += EncodingUtil.urlEncode('Task', 'UTF-8');
            } else {
                childPageUrl += EncodingUtil.urlEncode(objectId.substring(0,15), 'UTF-8');
            }
            childPageUrl += '&save_new_url=/apex/SObject_New_vod?retURL=' + EncodingUtil.urlEncode(retURL, 'UTF-8') +
                    '&veevaModule=' + veevaModule +
                    '&veevaPage=' + veevaPage +
                    '&retURL=' + retURL +
                    '&objectType=' + objectType +
                    '&queryParams=' + EncodingUtil.urlEncode(queryParams, 'UTF-8');

        } else {
            childPageUrl = '/apex/SObject_New_vod?retURL=' + EncodingUtil.urlEncode(retURL, 'UTF-8') +
                    '&veevaModule=' + veevaModule +
                    '&veevaPage=' + veevaPage +
                    '&retURL=' + retURL +
                    '&objectType=' + objectType +
                    '&queryParams=' + EncodingUtil.urlEncode(queryParams, 'UTF-8');
        }
        newChildPage = new PageReference(childPageUrl);
        return newChildPage;
    }

    public PageReference sObjectNewRedirect() {
        PageReference newChildPage;
        String childPageUrl;
        if(recordType != '') {
            return null;
        } else if(hasRecordTypes == 'true') {
            String objectId = VOD_RedirectUtil.getObjectDurableId(objectType.removeEnd('__c'));
            childPageUrl = '/setup/ui/recordtypeselect.jsp?ent=';
            if(objectType == 'Task') {
                childPageUrl += EncodingUtil.urlEncode('Task', 'UTF-8');
            } else {
                childPageUrl += EncodingUtil.urlEncode(objectId.substring(0,15), 'UTF-8');
            }
            if (encodeFlag){
                retURL = EncodingUtil.urlEncode(retURL, 'UTF-8');
            }

            childPageUrl += '&save_new_url=' + EncodingUtil.urlEncode(saveNewUrl + '?retURL=' + retURL + '&' + saveNewURLParams, 'UTF-8') +
                '&veevaModule=' + veevaModule +
                '&veevaPage=' + veevaPage +
                '&retURL=' + retURL +
                '&objectType=' + objectType +
                '&useRetURL=' + useRetURL +
                '&queryParams=' + EncodingUtil.urlEncode(queryParams, 'UTF-8');

        } else {
            return null;
        }
        newChildPage = new PageReference(childPageUrl);
        return newChildPage;
    }
}