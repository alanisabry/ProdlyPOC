/***************************************************************
* * Class Name  : upsertOpportunityARRMovements
* * Description : Trigger on opportunity which will fire only after update on the opportunity
* 				   
* *************************************************************/

trigger upsertOpportunityARRMovements on Opportunity (after update) {
    if(ConstantValues.recursiveCounter < 2){
        manageOpportunityARRMovements oppcls = new manageOpportunityARRMovements();
        oppcls.oppARRMovementsData(trigger.new,trigger.oldMap);
        ConstantValues.recursiveCounter++;
    }
}