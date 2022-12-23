@isTest
public without sharing class DocumentManagerTest {

    @isTest
    public static void testDocManager() {

        DocumentList__c docList = DocumentManagerTestFactory.getDocumentList('Campaign', 'IsActive', true); // creae a doc list
        DocumentListItem__c requiredDocListItem = DocumentManagerTestFactory.getDocumentListItem(docList.Id, true, 1, null, true); // create an item
        DocumentListItem__c optionalDocListItem = DocumentManagerTestFactory.getDocumentListItem(docList.Id, false, 2, null, true); // create an item
        DocumentListAssignment__c docListAssignment = DocumentManagerTestFactory.getDocumentListAssignment(docList.Id, true); // create a doc list assignment
        
        Campaign c = DocumentManagerTestFactory.getCampaign(true); // create a task

        Test.startTest();

            // get doc lists
            GetDocumentListsInvoc.Request request = new GetDocumentListsInvoc.Request();
            request.recordId = c.Id;
            List<GetDocumentListsInvoc.Request> requests = new List<GetDocumentListsInvoc.Request>();
            requests.add(request);
            List<GetDocumentListsInvoc.Response> responses = GetDocumentListsInvoc.getDocumentLists(requests);
            System.debug('>>> responses '+responses);
            System.assertEquals(responses.size(), 1);
            System.assertEquals(responses[0].isSuccess, true, responses[0].message);
            System.assertEquals(responses[0].documentLists.size(), 1);
            System.assertEquals(responses[0].documentLists[0].Id, docList.Id);
            
            // generate docs for a specific list
            InitDocumentsInvoc.Request req = new InitDocumentsInvoc.Request();
            req.listId = docList.Id;
            req.recordId = c.Id;
            req.reset = true;

            List<InitDocumentsInvoc.Request> reqs = new List<InitDocumentsInvoc.Request>();
            reqs.add(req);

            List<InitDocumentsInvoc.Response> initResponses = InitDocumentsInvoc.initDocuments(reqs);
            System.debug('>>> responses '+initResponses);
            
            System.assertEquals(initResponses.size(), 1); // assert 1 response
            System.assertEquals(initResponses[0].isSuccess, true, initResponses[0].message); // assert success true or show message
            
        Test.stopTest();
        
        // check that docs were created
        List<Document__c> docs = [SELECT Id, Status__c, Document_Order__c, DocumentList__c, DocumentListItem__c FROM Document__c WHERE RecordId__c =: c.Id];
        System.assertEquals(docs.size(), 2);

        // verify that the checkbox is not set to true
        Campaign cUp = [SELECT Id, IsActive FROM Campaign WHERE Id = :c.Id];
        System.assertEquals(cUp.IsActive, false);

        // approve required doc
        Document__c requiredDoc = [SELECT Id FROM Document__c WHERE DocumentListItem__r.Required__c = true];
        requiredDoc.Status__c = 'Approved';
        update requiredDoc;
        
        // vertify that the checkbox is now true, since the doc is approved
        Campaign cUp2 = [SELECT Id, IsActive FROM Campaign WHERE Id = :c.Id];
        System.assertEquals(cUp2.IsActive, true);

        // approve required doc
        Document__c optionalDoc = [SELECT Id FROM Document__c WHERE DocumentListItem__r.Required__c = false];
        delete optionalDoc;
        
        // vertify that the checkbox is still true 
        Campaign cUp3 = [SELECT Id, IsActive FROM Campaign WHERE Id = :c.Id];
        System.assertEquals(cUp3.IsActive, true);
    }
}
