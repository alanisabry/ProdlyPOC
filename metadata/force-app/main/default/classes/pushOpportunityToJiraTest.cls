@isTest public class pushOpportunityToJiraTest {
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
        Opportunity opp = new Opportunity(accountid=acc.id,Type='New Business-Enterprise Cloud',Name='Test Account - Contract 1',CloseDate =date.newInstance(2021,12,12),
                                          StageName='Signature Stage',Startdate_contract__c =date.newInstance(2021,12,25),End_date_contract__c=date.newInstance(2022,12,24),
                                          Contract_Renewal_Term__c =12.00,Invoice_period__c =12.00,Payment_Period__c ='15 days',Notice_period_months__c =2.00,New_MRR__c  =1000.00);
        insert opp;
        opp.New_MRR__c  =2000.00;
        opp.Jira_Issue__c ='BODEV-1234';
        update opp;
        
        //JCFS.JiraTriggerTestHelper.testAfterUpdate('Opportunity');
    }
}