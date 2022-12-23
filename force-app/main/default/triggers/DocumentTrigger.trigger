trigger DocumentTrigger on Document__c (after insert, after update, after delete) {
    if(Trigger.isInsert && Trigger.isAfter) {
        DocumentTriggerHelper.onAfterInsert(Trigger.newMap);
    }
    
    if(Trigger.isUpdate && Trigger.isAfter) {
        DocumentTriggerHelper.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
    }

    if(Trigger.isDelete && Trigger.isAfter) {
        DocumentTriggerHelper.onAfterDelete(Trigger.oldMap);
    }
}