public without sharing class DocumentManagerTestFactory {

    // generate a doc list
    public static DocumentList__c getDocumentList(String sObjectName, String checkboxField, boolean doInsert) {
        DocumentList__c dl = new DocumentList__c();
        dl.Name = 'Test doc list '+Datetime.now();
        dl.IsActive__c = true;
        dl.ObjectApiName__c = sObjectName;
        dl.CheckboxField__c = checkboxField;
        dl.Description__c = 'Document list test';
        if(doInsert) {
            insert dl;
        }
        return dl;
    }

    // generate a doc list item
    public static DocumentListItem__c getDocumentListItem(Id docListId, boolean isRequired, Integer docOrder, String checkboxField, boolean doInsert) {
        DocumentListItem__c dli = new DocumentListItem__c();
        dli.Name = 'Test doc list '+Datetime.now();
        dli.DocumentList__c = docListId;
        dli.IsActive__c = true;
        dli.Required__c = isRequired;
        dli.CheckboxField__c = checkboxField;
        dli.Description__c = 'Test doc list item';
        dli.Order__c = docOrder;
        if(doInsert) {
            insert dli;
        }
        return dli;
    }

    // generate a doc list assignment
    public static DocumentListAssignment__c getDocumentListAssignment(Id docListId, boolean doInsert) {
        DocumentListAssignment__c dla = new DocumentListAssignment__c();
        dla.DocumentList__c = docListId;
        dla.IsActive__c = true;
        dla.Criteria__c = 'Id != null';
        if(doInsert) {
            insert dla;
        }
        return dla;
    }

    // Campaign
    public static Campaign getCampaign(boolean doInsert) {
        Campaign c = new Campaign();
        c.Name = 'random campaign '+Datetime.now();
        
        if(doInsert) {
            insert c;
        }
        return c;
    }
}