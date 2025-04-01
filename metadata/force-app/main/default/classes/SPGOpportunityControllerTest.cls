@IsTest
public with sharing class SPGOpportunityControllerTest {
    @IsTest
    private static void testGetModel() {
        Account account = new Account(Name = 'Unit Test Opportunity Controller');
        insert account;
        
        Test.startTest();
        Opportunity opp = new Opportunity(AccountId = account.Id, Name = 'Unit Test Opportunity Controller', StageName = 'Demo', CloseDate = Date.today());
        insert opp;
        SPGOpportunityController.Model model = new SPGOpportunityController.Model();
        model = SPGOpportunityController.getModel(opp.Id);
        System.assert(model != null, 'Expected class to be initialized.');
        System.assertEquals(opp.Id, model.opportunityId, 'Expected values to match.');
        Test.stopTest();
    }
}