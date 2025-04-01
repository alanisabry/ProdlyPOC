@isTest public class pushAccountToJiraTest {
    @isTest static void testTriggerAfterUpdate() {
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Website = 'http://test.com';
        acc.CurrencyIsoCode = 'EUR';
        acc.Type = 'Prospect';
        acc.RecordTypeId = '0120P000000asyz';
        acc.BillingCountry = 'Austria';
        acc.Industry_Group__c = 'Consumer Brands';
        acc.Company_Size_New__c = 'SMB';
        insert acc;
        
        acc.Jira_Issue__c ='BODEV-1234';
        update acc;
        
        //JCFS.JiraTriggerTestHelper.testAfterUpdate('Account');
    }
}