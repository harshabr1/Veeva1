public without sharing class VOD_RedirectUtil {
	/*Object name needs to be the developer name of the object (aka remove the __c from custom objects)*/
    public static String getObjectDurableId(String objectName) {
        EntityDefinition objectDefinition = [SELECT DurableId 
                                             FROM EntityDefinition
                                             WHERE DeveloperName =: objectName];
        return objectDefinition.DurableId;
    }
}