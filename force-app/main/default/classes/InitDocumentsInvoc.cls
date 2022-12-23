public without sharing class InitDocumentsInvoc {
    
    public class InitDocumentsException extends Exception {}

    @InvocableMethod
    public static List<Response> initDocuments(List<Request> requests) {
        
        List<Response> result = new List<Response>();
        Savepoint sp = Database.setSavepoint();

        for(Request req : requests) {

            Response res = new Response();
            
            try {

                Set<Id> recordIds = new Set<Id>{req.recordId};
                DocumentService.generateDocuments(recordIds, true, req.listId);

                res.isSuccess = true;
                res.message = 'Successfully generated documents';
                
            } catch(Exception e) {
                Database.rollback(sp); // rollback everything in case of an exception
                res.isSuccess = false;
                res.message = e.getMessage() + '\n' + e.getStackTraceString()+ '\n' +e.getLineNumber();
            }
            
            result.add(res);
        }

        return result;
    }


    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;
        
        @InvocableVariable(required=true)
        public Id listId;

        @InvocableVariable
        public Boolean reset;
    }

    public class Response {
        @InvocableVariable
        public Boolean isSuccess;

        @InvocableVariable
        public String message;
    }
}