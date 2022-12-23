trigger DocumentListTrigger on DocumentList__c (after insert, after update) {
    if(Trigger.isInsert && Trigger.isAfter) {
        DocumentListTriggerHelper.onAfterInsert(Trigger.newMap);
    }

    if(Trigger.isUpdate && Trigger.isAfter) {
        DocumentListTriggerHelper.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
    }
}