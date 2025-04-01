@isTest(SeeAllData = TRUE)
public class LeanDataCTATest{
    static testMethod void testCTARoundRobin(){
    
        Id userId = UserInfo.getUserId();
        User thisUser = [SELECT Id FROM User Where Id = :userId];
    
        Account testAccount = new Account();
        testAccount.Name = 'Test Class Test Account';
        testAccount.OwnerId = userId;
        
        insert testAccount;
    
        /*LeanData_Custom_Interface_Settings__c customSetting = [SELECT Id, WHERE_Clause__c FROM LeanData_Custom_Interface_Settings__c];
        customSetting.Round_Robin_Field__c = 'JBCXM__Assignee__c';
        customSetting.Name = 'test custom setting';
        
        //Business Review SABR Level 1
        JBCXM__CTA__c testCTA0 = new JBCXM__CTA__c();
        testCTA0.JBCXM__Account__c = testAccount.Id;
        testCTA0.JBCXM__Type__c = 'a0XU0000009iuDqMAI';
        testCTA0.Name = 'Level 1';
        insert testCTA0;

        LeanData__Round_Robin_Pool__c pool0 = new LeanData__Round_Robin_Pool__c();
        pool0.LeanData__Grouping_Name__c = 'Level 1 SABRs';
        insert pool0;


        //Business Review SABR Level 2
        JBCXM__CTA__c testCTA = new JBCXM__CTA__c();
        testCTA.JBCXM__Account__c = testAccount.Id;
        testCTA.JBCXM__Type__c = 'a0XU0000009iuDqMAI';
        testCTA.Name = 'Level 2';
        insert testCTA;

        LeanData__Round_Robin_Pool__c pool = new LeanData__Round_Robin_Pool__c();
        pool.LeanData__Grouping_Name__c = 'Level 2 - 6mo SABR';
        insert pool;


        //Activity 3 Month Check-In
        JBCXM__CTA__c testCTA2 = new JBCXM__CTA__c();
        testCTA2.JBCXM__Account__c = testAccount.Id;
        testCTA2.JBCXM__Type__c = 'a0XU0000009iuDqMAI';
        testCTA2.Name = 'Level 2';
        insert testCTA2;

        LeanData__Round_Robin_Pool__c pool2 = new LeanData__Round_Robin_Pool__c();
        pool.LeanData__Grouping_Name__c = 'Level 2 - 3mo check-in';
        insert pool2;

        //14 Day QAs
        JBCXM__CTA__c testCTA3 = new JBCXM__CTA__c();
        testCTA3.JBCXM__Account__c = testAccount.Id;
        testCTA3.JBCXM__Type__c = 'a0XU0000009iuDqMAI';
        testCTA3.Name = 'Level 2';
        insert testCTA3;

        LeanData__Round_Robin_Pool__c pool3 = new LeanData__Round_Robin_Pool__c();
        pool3.LeanData__Grouping_Name__c = '14 Day QAs';
        insert pool3;

        customSetting.Where_Clause__c = 'Id = \'' + testCTA0.Id + '\' OR Id = \'' + testCTA.Id + '\' OR Id = \'' + testCTA2.Id + '\' OR Id = \'' + testCTA3.Id + '\'';
        update customSetting;
    
        LeanDataCTABatch ctaBatch = new LeanDataCTABatch();
        Database.executeBatch(ctaBatch, 5);*/
    }
    
    static testMethod void testScheduable(){
        Test.StartTest();
        LeanData_Custom_Interface_Settings__c customSetting = [SELECT Id, WHERE_Clause__c FROM LeanData_Custom_Interface_Settings__c];
        //customSetting.Round_Robin_Field__c = 'JBCXM__Assignee__c';
        customSetting.Where_Clause__c = 'Id = null';
        update customSetting;
        
        String sch = '0 0 0 * * ?';
        System.schedule('LeanData Custom Object RR scheduleable', sch, new LeanDataCTASchedulable());
        Test.StopTest();
    }
}