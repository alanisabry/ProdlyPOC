/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Removed_Quote_line_ItemTrigger on Removed_Quote_line_Item__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Removed_Quote_line_Item__c.SObjectType);
}