@isTest
public class manageOpportunityARRMovementsTest {
    
    @testSetup static void createTestData(){
        Account acc = new Account(Name ='Test Account',Type ='Prospect',Website='www.C-a.com',Industry_Group__c ='Consumer Brands',
                                  Company_Size_New__c ='SMB');
        insert acc;
        Opportunity opp = new Opportunity(accountid=acc.id,Type='New Business-Enterprise Cloud',Name='Test Account - Contract 1',CloseDate =date.newInstance(2021,12,12),
                                          StageName='Signature Stage',Startdate_contract__c =date.newInstance(2021,12,25),End_date_contract__c=date.newInstance(2022,12,24),
                                          Contract_Renewal_Term__c =12.00,Invoice_period__c =12.00,Payment_Period__c ='15 days',Notice_period_months__c =2.00,New_MRR__c  =1000.00);
        insert opp;     
    }
    
    static testmethod void testOppMovements(){
        Opportunity testOpp = [Select id,stagename, New_MRR__c from opportunity where name ='Test Account - Contract 1'];
        testOpp.New_MRR__c  =2000.00;
        update testOpp;
        list<Opportunity_ARR_Movement__c> mvmtsList = [select id from Opportunity_ARR_Movement__c where opportunity__c =:testOpp.Id];
        system.assertNotEquals(0, mvmtsList.size());
    }
    
}