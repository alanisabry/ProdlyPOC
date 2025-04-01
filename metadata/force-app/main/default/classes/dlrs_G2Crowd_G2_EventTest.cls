/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_G2Crowd_G2_EventTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_G2Crowd_G2_EventTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new G2Crowd__G2_Event__c());
    }
}