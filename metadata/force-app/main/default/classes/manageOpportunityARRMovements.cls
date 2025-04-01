/***************************************************************
* * Class Name  : manageOpportunityARRMovements
* * Description : Class created for implementing the logic for creating or updating
* 				   Opportunity ARR Movements and this class is triggered from 'upsertOpportunityARRMovements' trigger
* 				   Opportunity
* *************************************************************/
public class manageOpportunityARRMovements {
    public Set<Id> oppIds = new set<id>();
    public Map<Id,Map<string,Opportunity_ARR_Movement__c>> mvmtsMap = new Map<Id,Map<string,Opportunity_ARR_Movement__c>>();
    public List<Sales_KPI_Conditions__mdt> salesKPIMdt = new List<Sales_KPI_Conditions__mdt>();
    public List<Opportunity_ARR_Movement__c> mvmtsToCreate = new List<Opportunity_ARR_Movement__c>();
    public List<Opportunity_ARR_Movement__c> mvmtsToUpdate = new List<Opportunity_ARR_Movement__c>();
    public Map<Id,string> oemMap = new Map<Id,string>();
    public Set<Id> oemIds = new Set<Id>();
    public List<Opportunity> dateChangedOpps = new List<Opportunity>();
    public boolean reportingConditions;
    public boolean condition;
    public string fieldName;
    public boolean updateDates;
    public boolean isOEM;
    /********************************
* Method to prepare the data required for creating or updating opportunity ARR Movements
********************************/    
    public void oppARRMovementsData(List<Opportunity> opps,Map<Id,Opportunity> oppMap){
        //Iterate through list of oportunities updated to store opp Id's in a set
        for(opportunity op: opps){
            oppIds.add(op.Id);
            if(op.OEM__c!=null)
                oemIds.add(op.OEM__c); 
        }
        if(oemIds.size()>0){
            for(account acc:[select id,name from account where id IN:oemIds]){
                oemMap.put(acc.id,acc.name);
            }
        }
            
        //Query the opportunity ARR movements of all updated opportunities
        List<Opportunity_ARR_Movement__c> mvmtsList = [Select id,Opportunity__c,Amount__c,Movement_Type__c,Reporting_Date__c,Status__c from Opportunity_ARR_Movement__c where Opportunity__c IN:oppIds and Status__c = 'Active'];
        //Iterate through list of oportunities and opportunity ARR movements to create a map for storing movements associated with each opportunity.
        for(opportunity op: opps){
            for(Opportunity_ARR_Movement__c mvmt: mvmtsList){
                if(mvmt.Opportunity__c == op.Id){
                    if(!mvmtsMap.containsKey(op.Id)){
                        mvmtsMap.put(op.Id,new Map<string,Opportunity_ARR_Movement__c>());
                        mvmtsMap.get(op.Id).put(mvmt.Movement_Type__c,mvmt);
                    }else{
                        mvmtsMap.get(op.Id).put(mvmt.Movement_Type__c,mvmt);
                    }
                }
            }
        }
        system.debug('Existing movements:'+mvmtsMap);
        //Query custom metadata records storing sales KPI conditions for movements and reporting date
        salesKPIMdt = [select id,Movement_Field__c,Opportunity_Type__c,Movement_Type__c,Movement_Field__r.QualifiedAPIName,Reporting_Date_Criteria_Field_1__r.QualifiedAPIName,Criteria_logical_operator__c,Reporting_Date_Criteria_Field_2__r.QualifiedAPIName,Reporting_Date__r.QualifiedAPIName,Parent_Object__c,Reporting_Date__c,Reporting_Date_to_Close_Date__r.QualifiedAPIName,ARR_Movement_Field__r.QualifiedAPIName from Sales_KPI_Conditions__mdt];
        if(salesKPIMdt.size()>0){
            manageARRMovementChanges(opps,oppMap);
        }
        
    }
    /********************************
* Method for creating or updating opportunity ARR Movements when ARR movements on opportunity are changed is implemented
********************************/  
    public void manageARRMovementChanges(List<Opportunity> opps,Map<Id,Opportunity> oppMap){
        system.debug('Conditions:'+salesKPIMdt);
        for(opportunity op: opps){
            for(Sales_KPI_Conditions__mdt cdns: salesKPIMdt){//Iterate through the list of Sales KPI Conditions metadata records
                system.debug('Condition:'+cdns);
                //Check if the opportunity type mentioned in Sales KPI conditions is matching with the opportunity type
                if((cdns.Opportunity_Type__c).contains(op.Type)){
                    fieldName = cdns.Movement_Field__r.QualifiedAPIName;
                    reportingConditions = false;
                    condition = false;
                    updateDates = false;
                    isOEM = false;
                    boolean mvmtExist = mvmtsMap.containsKey(op.id) && mvmtsMap.get(op.id).get(cdns.Movement_Type__c) != null;
                    //Logic to create or update Opportunity ARR movements when ARR movements on opportunities are changed
                    system.debug('New Movement value:'+(Decimal)(op.get(fieldName)));
                    system.debug('Old Movement value:'+(Decimal)(oppMap.get(op.id).get(fieldName)));
                    if(( (Decimal)(op.get(fieldName)) != (Decimal)(oppMap.get(op.id).get(fieldName))) || ( (Decimal)(op.get(fieldName)) == (Decimal)(oppMap.get(op.id).get(fieldName)) && !mvmtExist)){
                        if(!mvmtsMap.containsKey(op.id) || mvmtsMap.get(op.id).get(cdns.Movement_Type__c) == null ){
                            if((Decimal)(op.get(fieldName)) != 0 && (Decimal)(op.get(fieldName)) != null){
                                createARRMovements(op,cdns,true,false,false);
                            }
                        }else if(mvmtExist){
                            if((Decimal)(op.get(fieldName)) != 0 && (Decimal)(op.get(fieldName)) != null){
                                createARRMovements(op,cdns,true,false,false);
                            }
                            updateARRMovements(op,cdns);                     
                        }
                    }
                    //Logic to update Opportunity ARR movements when opportunity is reopened
                    if((op.StageName !=oppMap.get(op.id).StageName && oppMap.get(op.id).StageName == 'Closed Won') && mvmtExist){
                        updateARRMovements(op,cdns);
                    }
                    //Logic to create or update Opportunity ARR movements when close date or contract start date are changed
                    if(((op.CloseDate !=oppMap.get(op.id).CloseDate) || ((op.Startdate_contract__c !=oppMap.get(op.id).Startdate_contract__c)&&!op.Reporting_Date_to_Close_Date__c)
                       || (((boolean)op.get(cdns.Reporting_Date_to_Close_Date__r.QualifiedAPIName) !=oppMap.get(op.id).Reporting_Date_to_Close_Date__c) && !(boolean)op.get(cdns.Reporting_Date_to_Close_Date__r.QualifiedAPIName)))
                       && mvmtExist){
                        system.debug('Inside Close date');
                        createARRMovements(op,cdns,false,true,false);
                        if(updateDates){
                            updateARRMovements(op,cdns);
                        }
                    }
                    //Logic to create or update Opportunity ARR movements when reporting date to close date is checked on opportunity
                    if(((boolean)op.get(cdns.Reporting_Date_to_Close_Date__r.QualifiedAPIName) !=oppMap.get(op.id).Reporting_Date_to_Close_Date__c) &&(boolean)op.get(cdns.Reporting_Date_to_Close_Date__r.QualifiedAPIName) && mvmtExist && (mvmtsMap.get(op.id).get(cdns.Movement_Type__c).Reporting_Date__c != op.CloseDate)){
                        createARRMovements(op,cdns,false,false,true);
                        updateARRMovements(op,cdns);
                    }
                }
            }
        }
        //Create Opportunity ARR Movements
        if(mvmtsToCreate.size() > 0)
            insert mvmtsToCreate;
        //Update Opportunity ARR Movements
        system.debug('Update Movements:'+mvmtsToUpdate);
        if(mvmtsToUpdate.size() > 0)
            update mvmtsToUpdate;
    }
    /********************************
* Method for creating opportunity ARR Movements 
********************************/  
    public void createARRMovements(opportunity op,Sales_KPI_Conditions__mdt cdns,boolean mvmtsChanged,boolean datesChanged,boolean closeDateAsReporting){
        //Check if reporting date to close date is checked on opportunity
        if((boolean)op.get(cdns.Reporting_Date_to_Close_Date__r.QualifiedAPIName) && !closeDateAsReporting){
            closeDateAsReporting = true;
        }else{
            // Compare the dates based on conditions in sales KPI conditions metadata to map the reporting date
            if(cdns.Reporting_Date_Criteria_Field_1__c !=null && cdns.Reporting_Date_Criteria_Field_2__c !=null && cdns.Criteria_logical_operator__c !=null){
                reportingConditions = true;
                object value1 = op.get(cdns.Reporting_Date_Criteria_Field_1__r.QualifiedAPIName);
                object value2 = op.get(cdns.Reporting_Date_Criteria_Field_2__r.QualifiedAPIName); 
                if(cdns.Criteria_logical_operator__c == '>'?(Date)(value1) >= (Date)(value2):(Date)(value1) < (Date)(value2)){
                    condition =true;
                }
            }
        }
        // Check when dates are changed on opportunity, existing reporting date is matching with new reporting date or not
        if(datesChanged && (condition || !reportingConditions) && (mvmtsMap.get(op.id).get(cdns.Movement_Type__c).Reporting_Date__c !=(Date)(op.get(cdns.Reporting_Date__r.QualifiedAPIName)))){
            updateDates = true;
        }
        if((cdns.Movement_Type__c =='New ARR' && op.OEM__c !=null && (oemMap.get(op.OEM__c) ==system.label.OEM_Workfront || oemMap.get(op.OEM__c) ==system.label.OEM_Acquia))
           ||(cdns.Movement_Type__c =='New ARR: OEM' && (op.OEM__c ==null||(op.OEM__c !=null && oemMap.get(op.OEM__c) !=system.label.OEM_Workfront && oemMap.get(op.OEM__c) !=system.label.OEM_Acquia)))){
            isOEM = true;
        }
        system.debug('Conditionsss:'+condition+';'+reportingConditions+op.OEM__r.name+system.label.OEM_Workfront);
        if(((mvmtsChanged && (condition || !reportingConditions)) || updateDates || closeDateAsReporting) && !isOEM){
            Opportunity_ARR_Movement__c mvmt = new Opportunity_ARR_Movement__c();
            mvmt.Amount__c = (Decimal)(op.get(cdns.ARR_Movement_Field__r.QualifiedAPIName));
            mvmt.Movement_Type__c = cdns.Movement_Type__c;
            mvmt.Opportunity__c = op.Id;
            mvmt.CurrencyIsoCode = op.CurrencyIsoCode;
            // Update close date as reporting date when reporting date to close date is checked, otherwise reporting date based on conditions
            mvmt.Reporting_Date__c = closeDateAsReporting?op.CloseDate:(Date)(op.get(cdns.Reporting_Date__r.QualifiedAPIName));
                if(!mvmtsToCreate.contains(mvmt))
                mvmtsToCreate.add(mvmt);
        }     
    }
    /********************************
* Method for updating opportunity ARR Movements 
********************************/ 
    public void updateARRMovements(opportunity op,Sales_KPI_Conditions__mdt cdns){
        mvmtsMap.get(op.id).get(cdns.Movement_Type__c).Status__c = 'Obsolete';
        mvmtsMap.get(op.id).get(cdns.Movement_Type__c).Status_Modified_Date__c = system.today();
        if(!mvmtsToUpdate.contains(mvmtsMap.get(op.id).get(cdns.Movement_Type__c)))
            mvmtsToUpdate.add(mvmtsMap.get(op.id).get(cdns.Movement_Type__c));  
    }
}