public without sharing class GetDocumentListsInvoc {
    
    public class GetDocumentListsException extends Exception {}

    @InvocableMethod
    public static List<Response> getDocumentLists(List<Request> requests) {

        List<Response> result = new List<Response>();
            
        Savepoint sp = Database.setSavepoint();    
                
            for(Request req : requests) {
                Response res = new Response();
                Id recId = req.recordId;

                try {
                    Set<Id> recordIds = new Set<Id>{recId};
                    Map<Id, Set<Id>> mapRecordIdListIds = DocumentService.getRecordIdListIdMap(recordIds);
                    
                    List<DocumentList__c> docLists = new List<DocumentList__c>();
                    if(mapRecordIdListIds.containsKey(recId) && mapRecordIdListIds.get(recId) != null && mapRecordIdListIds.get(recId).size() > 0) {
                        docLists = [SELECT Id, Name FROM DocumentList__c WHERE Id IN :mapRecordIdListIds.get(recId)];
                    }

                    // success
                    res.isSuccess = true;
                    res.message = '';
                    res.documentLists = docLists;

                } catch(Exception e) {
                    Database.rollback(sp); // rollback everything in case of an exception
                    res.isSuccess = false;
                    res.message = e.getMessage() + '\n' + e.getStackTraceString()+ '\n' +e.getLineNumber();
                    res.documentLists = new List<DocumentList__c>();
                }

                result.add(res);
            }
        return result;
    }


    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;
    }

    public class Response {
        
        @InvocableVariable
        public List<DocumentList__c> documentLists;

        @InvocableVariable
        public Boolean isSuccess;

        @InvocableVariable
        public String message;
    }
}