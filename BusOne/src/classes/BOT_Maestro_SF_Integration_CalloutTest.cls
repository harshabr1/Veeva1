@isTest
private class BOT_Maestro_SF_Integration_CalloutTest
{
    @isTest static void testCallout()
    {
        Test.setMock(HttpCalloutMock.class, new BOT_Maestro_SF_Integration_Test());
       	HttpResponse res = BOT_Maestro_SF_Integration_CalloutClass.getResponseFromExternalService();
        String contentType = res.getHeader('Content-Type');
        System.assert(contentType == 'application/Json');
        String actualValue = res.getBody();
        String expectedValue = '{"ENTITY_ID":"5405","ENTITY_NAME":"Express Scripts Inc","ENTITY_STATE":"MO","FORMULARY_ID":"671831","FORMULARY_LIVES":"85000000","FORMULARY_NAME":"ESI National Preferred Formulary"}';
        System.assertEquals(expectedValue, actualValue);
        System.assertEquals(200, res.getStatusCode());
    }
}