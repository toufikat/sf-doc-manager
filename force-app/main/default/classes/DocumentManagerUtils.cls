public without sharing class DocumentManagerUtils {

    /**
     * @description check if on object has a field
     * @param  sourceObject source sObject
     * @param  lookupField  field to find
     * @return true if the object has the field
     */
    public static Boolean hasField(String sourceObject, String fieldApiName) {
        return Schema.getGlobalDescribe()
            .get(sourceObject)
            .getDescribe()
            .fields
            .getMap()
            .keySet()
            .contains(fieldApiName.toLowerCase());
    }

    /**
     * @description check if valid object name
     */
    public static Boolean isValidObjectStr(String objectStr) {
        // Convert to schema.sObjectType
        Schema.SObjectType convertType = Schema.getGlobalDescribe().get(objectStr);
        if(convertType != null) {
            return true;
        }
        return false;
    }

    /**
     * @description returns the field display typ
     */
    public static Schema.DisplayType getFieldType(String sourceObject, String fieldApiName) {
        return Schema.getGlobalDescribe()
            .get(sourceObject)
            .getDescribe()
            .fields
            .getMap()
            .get(fieldApiName.toLowerCase()).getDescribe().getType();
    }
}