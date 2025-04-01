public class LeanDataCTARR{
    //Created by Kurt Jurgens From LeanData Inc. 05/16/19
    public Static void roundRobinCTAs(List<Id> objectList){
    
      List<Account> accList = [Select Id,name from account where name like '%Test']; 
        /*List<LeanData_Custom_Interface_Settings__c> result = [SELECT Round_Robin_Field__c, WHERE_Clause__c FROM LeanData_Custom_Interface_Settings__c];
        LeanData_Custom_Interface_Settings__c settings;
        if(result.size() > 0){
            settings = result[0];
        }
        String query;
        if(!TEST.IsRunningTest()){
            query = 'SELECT ' + settings.Round_Robin_Field__c + ', Id FROM JBCXM__CTA__C Where Id IN :objectList AND (' + settings.WHERE_Clause__c + ')';
        } else {
            query = 'SELECT ' + settings.Round_Robin_Field__c + ', Id FROM JBCXM__CTA__C Where Id IN :objectList';
        }
        List<JBCXM__CTA__C> scope = Database.query(query);
        Map<String, List<JBCXM__CTA__C>> conditionToObjectMap = new Map<String, List<JBCXM__CTA__C>>();
        
        Map<String, Object> results = new Map<String, Object>();
        Map<String, Object> paramsMap = new Map<String, Object>();

        Map<String, Object> conditionToPoolMap = new Map<String, Object>();

        List<LeanData_Custom_Interface_Setting__c> conditionSettings = [Select Id, Name, Condition__c, Priority__c, Round_Robin_Pool_Name__c From LeanData_Custom_Interface_Setting__c Order By Priority__c ASC];

        for(LeanData_Custom_Interface_Setting__c conditionSetting : conditionSettings){
            conditionToPoolMap.put(conditionSetting.Condition__c, conditionSetting.Round_Robin_Pool_Name__c);
        }

        for(JBCXM__CTA__C cta : scope){

            List<JBCXM__CTA__C> matchedCTA = new List<JBCXM__CTA__C>();

            for(LeanData_Custom_Interface_Setting__c conditionSetting : conditionSettings){
                System.debug('conditionSetting');
                System.debug(conditionSetting);

                 String specificQuery = 'SELECT ' + settings.Round_Robin_Field__c + ', Id FROM JBCXM__CTA__C Where Id = \'' + cta.Id + '\' AND (' + conditionSetting.Condition__c + ')';

                 System.debug('specificQuery');
                 System.debug(specificQuery);

                 matchedCTA = Database.query(specificQuery);

                 String conditionString = conditionSetting.Condition__c;

                 System.debug('matchedCTA');
                 System.debug(matchedCTA);

                 if(matchedCTA.size() > 0){
                    if(conditionToObjectMap.get(conditionString) != null){
                        conditionToObjectMap.get(conditionString).add(cta);
                    } else {
                        conditionToObjectMap.put(conditionString, new List<JBCXM__CTA__C>{cta});
                    }
                    break;
                 }
            }
        }

        String groupingName;

        for(String mapKey : conditionToObjectMap.keySet()){
            System.debug('anything here?');
            System.debug(mapKey);

            String keyValue = (String)conditionToPoolMap.get(mapKey);
            groupingName = keyValue;
            System.debug('groupingName');
            System.debug(groupingName);

            List<LeanData__Round_Robin_Pool__c> roundRobinPool = [SELECT Id From LeanData__Round_Robin_Pool__c WHERE LeanData__Grouping_Name__c = :groupingName];
            System.debug('roundRobinPool');
            System.debug(roundRobinPool);
            paramsMap.put('objects',conditionToObjectMap.get(mapKey));
            if(roundRobinPool.size()>0){
                paramsMap.put('roundRobinGroupId',roundRobinPool[0].Id);
            }
            paramsMap.put('roundRobinField',settings.Round_Robin_Field__c);
            System.debug('paramsMap');
            System.debug(paramsMap);
            results = LeanData.LeanDataAPI.RoundRobinApi(paramsMap);
            System.debug(results);
        }*/
        
        return;
    }
}