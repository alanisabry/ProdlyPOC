/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_G2Crowd_G2_EventTrigger on G2Crowd__G2_Event__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(G2Crowd__G2_Event__c.SObjectType);
}