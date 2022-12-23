public without sharing class DocumentListTriggerHelper {

    public class DocumentListException extends Exception {}

    public static void onAfterInsert(Map<Id, DocumentList__c> newLists) {
        validateObjectAndCheckboxField(newLists);
    }

    public static void onAfterUpdate(Map<Id, DocumentList__c> newLists, Map<Id, DocumentList__c> oldLists) {
        validateObjectAndCheckboxField(newLists);
    }

    // check values on parent when doc is approved
    private static void validateObjectAndCheckboxField(Map<Id, DocumentList__c> newLists) {
        for(DocumentList__c dl : newLists.values()) {
            if(dl.ObjectApiName__c != null) {

                if(!DocumentManagerUtils.isValidObjectStr(dl.ObjectApiName__c)) {
                    throw new DocumentListException('The object name '+dl.ObjectApiName__c+' is not valid.');
                }

                if(dl.CheckboxField__c != null) {
                    if(!DocumentManagerUtils.hasField(dl.ObjectApiName__c, dl.CheckboxField__c)) {
                        throw new DocumentListException('The object '+dl.ObjectApiName__c+' has no field with name '+dl.CheckboxField__c+'.');
                    }

                    if(String.valueOf(DocumentManagerUtils.getFieldType(dl.ObjectApiName__c, dl.CheckboxField__c)) != 'BOOLEAN' ) {
                        throw new DocumentListException('The field '+dl.CheckboxField__c+ ' is not a checkbox.');
                    }
                }
            }
        }
    }
}