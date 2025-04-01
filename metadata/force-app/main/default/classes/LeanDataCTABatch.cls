public class LeanDataCTABatch implements Database.Batchable<SObject>,Database.Stateful{
    

    public Database.QueryLocator start(Database.BatchableContext ctx){
        List<LeanData_Custom_Interface_Settings__c> result = [SELECT Round_Robin_Field__c, WHERE_Clause__c FROM LeanData_Custom_Interface_Settings__c];
        LeanData_Custom_Interface_Settings__c settings;
        if(result.size() > 0){
            settings = result[0];
        }
        
        if(settings != null)
            System.debug(settings);
        
        String query ='';
        //String roundRobinField = settings.Round_Robin_Field__c;
        String whereClause =  'name like'+ ' %Test';
        
        if(whereClause != null)
            System.debug(whereClause);
            query = 'Select' + ' Id,name from account limit ' + 1; 
        
        //query = 'SELECT ' + settings.Round_Robin_Field__c + ', Id FROM JBCXM__CTA__C Where (' + settings.WHERE_Clause__c + ')';
        
        if(query != null)
            System.debug(query);
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext ctx, List<SObject> sobjectScope){
       List<Id> objectIds = new List<Id>();
        for(Account cta : (List<Account>) sobjectScope){
            objectIds.add(cta.Id);
        }
        LeanDataCTARR.roundRobinCTAs(objectIds);
    }

    public void finish(Database.BatchableContext ctx){

    }
}