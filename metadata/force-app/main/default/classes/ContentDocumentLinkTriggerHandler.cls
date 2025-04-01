/*
* ContentDocumentLinkTriggerHandler.cls
* Upon insert of Opportunity Files, creates a link to the
* file on the parent Account record as well.
* 
* Created By: OpFocus
* Created On: Jan 18, 2021
*/
public class ContentDocumentLinkTriggerHandler extends TriggerHandler {
    
    /*
Called after any insert operation
*/
    protected override void afterInsert() {
        
        // Id prefix of opportunity records
        String oppPrefix = Opportunity.getSObjectType().getDescribe().keyprefix;
        
        // Find all Opportunity-related content document links
        Map<Id, List<ContentDocumentLink>> oppLinkMap = new Map<Id, List<ContentDocumentLink>>();
        for (ContentDocumentLink cdl : (List<ContentDocumentLink>) Trigger.new) {
            // If Id prefix of linked entity is oppPrefix, it is linked to an Opp
            if (cdl.LinkedEntityId != null && ((String)cdl.LinkedEntityId).startsWith(oppPrefix)) {
                if (!oppLinkMap.containsKey(cdl.LinkedEntityId)) {
                    oppLinkMap.put(cdl.LinkedEntityId, new List<ContentDocumentLink>());
                }
                oppLinkMap.get(cdl.LinkedEntityId).add(cdl);
            }
        }
        if (oppLinkMap.isEmpty()) {
            return;
        }
        // Pull in Opportunities so we get their AccountIds
        List<Opportunity> opportunities =[
            SELECT
            AccountId,
            Id
            FROM
            Opportunity
            WHERE
            Id IN :oppLinkMap.keySet() AND AccountId != null
        ];
        // Group up AccountId links to create
        List<ContentDocumentLink> accountLinks = new List<ContentDocumentLink>();
        //Store accountIds to fetch existing content document links of account linked to opportunity
        Set<Id> AccountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            AccountIds.add(opp.AccountId);
        }
        //Store the content document links related to account in a map to check if the document already exists before inserting a new document(BODEV-681)
        Map<string,ContentDocumentLink> accountDocsMap = new Map<string,ContentDocumentLink>();
        if(!AccountIds.isEmpty()){
            for(ContentDocumentLink cdl :[select id, ContentDocumentId, LinkedEntityId  from ContentDocumentLink 
                                          where LinkedEntityId IN:AccountIds] ){
                                              string mapStr = cdl.LinkedEntityId + '' + cdl.ContentDocumentId;
                                              accountDocsMap.put(mapStr,cdl);
                                              
                                          }
        }
        for (Opportunity opp : opportunities){
            for (ContentDocumentLink cdl : oppLinkMap.get(opp.Id)) {
                // Check if the document already exists(BODEV-681)
                if(!accountDocsMap.containsKey(opp.AccountId + '' + cdl.ContentDocumentId)){ 
                    ContentDocumentLink accountLink = cdl.clone();
                    accountLink.LinkedEntityId = opp.AccountId;
                    accountLinks.add(accountLink);
                }
            }
        }
        if (!accountLinks.isEmpty()) {
            insert accountLinks;
        }
    }
    
}