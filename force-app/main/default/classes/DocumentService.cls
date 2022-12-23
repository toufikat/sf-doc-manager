public without sharing class DocumentService {
    
    public class DocumentServiceException extends Exception {}

    /**
     * @description generates documents related to records.
     * @param  mapRecordToList map with <RecordId, ListId> structure
     * @param reset delete existing docs when true
     * @return void
     */
    public static void generateDocuments(Set<Id> recordIds, Boolean reset, Id docListId) {
        
        // for each record id, get the list id
        Map<Id, Set<Id>> mapRecordIdListIds = new Map<Id, Set<Id>>();
        
        if(docListId == null) {
            // all lists 
            mapRecordIdListIds = DocumentService.getRecordIdListIdMap(recordIds);
        } else {
            // list id is defined
            for(Id recordId : recordIds) {
                mapRecordIdListIds.put(recordId, new Set<Id> {docListId});
            }
        }
        
        // list of docs to create
        List<Document__c> docsToCreate = new List<Document__c>();

        Set<Id> allListIds = new Set<Id>();
        for(Id recId : mapRecordIdListIds.keySet()) {
            allListIds.addAll(mapRecordIdListIds.get(recId));
        }

        // get all the document lists with items of each list
        Map<Id, DocumentList__c> mapListsWithItems = new Map<Id, DocumentList__c>([
                SELECT Id, Name,
                    (
                        SELECT ID, Name, Required__c, DocumentList__c, Order__c
                        FROM ListItems__r 
                        WHERE IsActive__c = true 
                        ORDER BY Order__c ASC NULLS LAST, 
                        CreatedDate ASC
                    ) 
                FROM DocumentList__c 
                WHERE Id IN : allListIds
                AND IsActive__c = true
        ]);    
        
        // get existing docs
        String existingDocsQuery = 'SELECT Id, RecordId__c, DocumentListItem__c FROM Document__c WHERE RecordId__c IN :recordIds ';
        if(docListId != null) {
            existingDocsQuery += ' AND DocumentList__c = :docListId ';
        }
        List<Document__c> existingDocs = Database.query(existingDocsQuery);
        
        // if reset is true, delete existing documents
        if(reset) {    
            delete existingDocs;
        }

        // for each record
        for(Id recordId : mapRecordIdListIds.keySet()) {
            // get the document list id
            Set<Id> listIds = mapRecordIdListIds.get(recordId);
            
            for(Id listId : listIds) {
                // get the items of the documents list
                DocumentList__c docList = mapListsWithItems.get(listId);

                // generate a new document related to the record
                Set<String> fields = Document__c.getSObjectType().getDescribe().fields.getMap().keySet();
                
                for(DocumentListItem__c item : docList.ListItems__r) {

                    boolean alreadyExists = false;
                    for(Document__c existingDoc : existingDocs) {
                        if(existingDoc.RecordId__c == recordId && existingDoc.DocumentListItem__c == item.Id) {
                            alreadyExists = true;
                            break;
                        }
                    }

                    // document not already exists
                    if(!alreadyExists) {
                        Document__c doc = new Document__c();
                        doc.Name = item.Name; // document name = item name
                        doc.RecordId__c = recordId; // related to the record
                        doc.Status__c = 'Missing'; // status is missing by default
                        doc.Document_Order__c = item.Order__c;
                        doc.DocumentList__c = docList.Id;
                        doc.DocumentListItem__c = item.Id;
                        String fieldName = recordId.getSobjectType().getDescribe().getName().toLowerCase();
                        if(!fieldName.endsWith('__c')) { // standard object
                            fieldName = fieldName + '__c'; 
                        }
                        if(fields.contains(fieldName)) {
                            doc.put(fieldName, recordId);
                        }
                        docsToCreate.add(doc); // add to the list of docs to create
                    }
                }
            }
        }

        // create the new docs
        if(docsToCreate.size() > 0) {
            insert docsToCreate;
        }
    }

    /**
     * Get the document lists relevant to records
     */
    public static Map<Id, Set<Id>> getRecordIdListIdMap(Set<Id> recordIds) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
        
        // group record ids by object name
        Map<String, Set<Id>> mapObjNameIdSet = new Map<String, Set<Id>>();
        for(Id recordId : recordIds) {
            String objName = recordId.getSobjectType().getDescribe().getName();
            if(objName != null) {
                Set<Id> objRecords = new Set<Id> {recordId}; // new set with the record id
                if(mapObjNameIdSet.containsKey(objName)) {
                    objRecords.addAll(mapObjNameIdSet.get(objName));
                }
                mapObjNameIdSet.put(objName.toLowerCase(), objRecords);
            }
        }
        
        // get assignments
        List<DocumentListAssignment__c> assignments = [
            SELECT 
            Id, 
            DocumentList__c,
            DocumentList__r.ObjectApiName__c,
            Criteria__c
            FROM DocumentListAssignment__c
            WHERE DocumentList__r.ObjectApiName__c IN : mapObjNameIdSet.keySet()
            AND IsActive__c = true
        ];                                                                                                                                                           
        System.debug('>>>'+mapObjNameIdSet);
        System.debug('>>>'+assignments);
        
        
        for(DocumentListAssignment__c assi : assignments) {
            // get the ids for the object
            Set<Id> ids = mapObjNameIdSet.get(assi.DocumentList__r.ObjectApiName__c.toLowerCase());
            Id docListId = assi.DocumentList__c;

            // filter the ids that have the good criteria for the assignment
            String query = 'SELECT Id FROM '+ String.escapeSingleQuotes(assi.DocumentList__r.ObjectApiName__c) + ' WHERE Id IN :ids ';
            if(assi.Criteria__c != null) {
                query += ' AND ( '+assi.Criteria__c+ ' ) ';
            }
            
            List<sObject> lSobj = Database.query(query);
            
            for(sObject obj : lSobj) {
                Id recId = (Id) obj.get('Id');
                Set<Id> docLists = new Set<Id>();
                if(result.containsKey(recId)) {
                    docLists.addAll(result.get(recId));
                }
                docLists.add(docListId);
                result.put(recId, docLists);
            }
        }       
        return result;
    }

    // check values on parent when doc is approved
    public static void setParentCheckboxValues(Set<Id> recordIds) {
        List<Document__c> docs = [SELECT Id, Status__c, RecordId__c, DocumentListItem__r.Required__c, DocumentListItem__r.CheckboxField__c, DocumentList__r.CheckboxField__c FROM Document__c WHERE RecordId__c IN : recordIds];
        
        if(docs.size() == 0) {
            return;
        }

        // fill map <record id, list of docs>
        Map<Id, List<Document__c>> mapRecordIdDocs = new Map<Id, List<Document__c>>();
        for(Document__c doc : docs) {
            if(doc.RecordId__c != null) {    
                List<Document__c> recordDocs = new List<Document__c>();
                if(mapRecordIdDocs.containsKey(doc.RecordId__c)) {
                    recordDocs.addAll(mapRecordIdDocs.get(doc.RecordId__c));
                }
                recordDocs.add(doc);
                mapRecordIdDocs.put((Id) doc.RecordId__c, recordDocs);
            }
        }              

        // set checkbox values
        List<sObject> recordsToUpdate = new List<sObject>();

        for(Id recordId : mapRecordIdDocs.keySet()) {
            Map<String, boolean> checkboxValues = new Map<String, boolean>();
            String objName = recordId.getSobjectType().getDescribe().getName();    
            sObject rec = Schema.getGlobalDescribe().get(objName).newSObject(); // Creation of the record.  
            rec.Id = recordId; // set id value

            List<Document__c> recordDocs = mapRecordIdDocs.get(recordId);
            if(recordDocs.size() > 0) {
                
                // by default, all docs are approved
                for(Document__c doc : recordDocs) {
                    if(doc.DocumentList__r.CheckboxField__c != null) {
                        checkboxValues.put(doc.DocumentList__r.CheckboxField__c, true);
                    }
                }

                // for each doc related to record
                for(Document__c doc : recordDocs) {

                    // checkbox value for the specific doc
                    if(doc.DocumentListItem__r.CheckboxField__c != null) {
                        if(doc.Status__c == 'Approved') {
                            checkboxValues.put(doc.DocumentListItem__r.CheckboxField__c, true);
                        } else {
                            checkboxValues.put(doc.DocumentListItem__r.CheckboxField__c, false);
                        }
                    }
                    
                    // checkbox value for the whole doc list
                    if(doc.DocumentList__r.CheckboxField__c != null) {
                        if(doc.DocumentListItem__r.Required__c && doc.Status__c != 'Approved') {
                            checkboxValues.put(doc.DocumentList__r.CheckboxField__c, false); // non approved required doc
                        }
                    }

                }
            }

            // put checkbox values on record
            for(String checkboxField : checkboxValues.keySet()) {
                rec.put(checkboxField, checkboxValues.get(checkboxField));
            }

            recordsToUpdate.add(rec);
        }

        if(recordsToUpdate.size() > 0) {
            update recordsToUpdate;
        }
    }
}