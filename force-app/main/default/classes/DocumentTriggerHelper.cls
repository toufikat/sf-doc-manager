public without sharing class DocumentTriggerHelper {
    
    public static void onAfterInsert(Map<Id, Document__c> newDocuments) {
        setParentCheckboxValues(newDocuments, null);
    }

    public static void onAfterUpdate(Map<Id, Document__c> newDocuments, Map<Id, Document__c> oldDocuments) {
        setParentCheckboxValues(newDocuments, oldDocuments);
    }

    public static void onAfterDelete(Map<Id, Document__c> oldDocuments) {
        setParentCheckboxValues(null, oldDocuments);
    }


    // check values on parent when doc is approved
    private static void setParentCheckboxValues(Map<Id, Document__c> newDocuments, Map<Id, Document__c> oldDocuments) {
        Set<Id> recordIdsToUpdate = new Set<Id>();
        if(newDocuments != null) {
            if(oldDocuments != null) {
                for(Document__c newDoc : newDocuments.values()) {
                    if(oldDocuments.containsKey(newDoc.Id)) {
                        Document__c oldDoc = oldDocuments.get(newDoc.Id);
                        if(newDoc.Status__c <> oldDoc.Status__c ||  newDoc.RecordId__c <> oldDoc.RecordId__c) {
                            if(newDoc.RecordId__c != null) {
                                recordIdsToUpdate.add(newDoc.RecordId__c);
                            }
                            if(oldDoc.RecordId__c != null) {
                                recordIdsToUpdate.add(oldDoc.RecordId__c);
                            }
                        }
                    }
                }
            } else {
                for(Document__c newDoc : newDocuments.values()) {
                    if(newDoc.RecordId__c != null) {
                        recordIdsToUpdate.add(newDoc.RecordId__c);
                    }
                }
            }
        } else {
            if(oldDocuments != null) {
                for(Document__c oldDoc : oldDocuments.values()) {
                    if(oldDoc.RecordId__c != null) {
                        recordIdsToUpdate.add(oldDoc.RecordId__c);
                    }
                }
            }
        }

        if(recordIdsToUpdate.size() > 0) {
            DocumentService.setParentCheckboxValues(recordIdsToUpdate);
        }
    }

}