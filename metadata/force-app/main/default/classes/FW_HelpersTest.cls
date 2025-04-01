@isTest
public with sharing class FW_HelpersTest {
    @TestSetup
    private static void testSetup() {
        // Create an account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
         // First create a test pricebook
         Pricebook2 testPB = new Pricebook2(
            Name = 'Test PB',
            IsActive = true
        );
        insert testPB;

        // Next create a couple of products
        Product2 testProduct1 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TP1',
            IsActive = true,
            Netsuite_New_Business_Item_Internal_ID__c = 'TP1'
        );
        Product2 testProduct2 = new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TP2',
            IsActive = true,
            Netsuite_New_Business_Item_Internal_ID__c = 'TP2'
        );
        insert new List<Product2> { testProduct1, testProduct2 };

        // And insert them into our pricebook (And the standard pb)
        insert new List<PricebookEntry> {
            new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct1.Id,
                IsActive = true,
                UnitPrice = 100.00
            ),
            new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct2.Id,
                IsActive = true,
                UnitPrice = 200.00
            ),
            new PricebookEntry(
                Pricebook2Id = testPB.Id,
                Product2Id = testProduct1.Id,
                IsActive = true,
                UnitPrice = 100.00
            ),
            new PricebookEntry(
                Pricebook2Id = testPB.Id,
                Product2Id = testProduct2.Id,
                IsActive = true,
                UnitPrice = 200.00
            )
        };


        // Create the opp
        Opportunity TEST_OPP = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Test Opportunity',
            StageName = 'Qualified',
            CloseDate = Date.today(),
            Pricebook2Id = testPB.Id
        );
        insert TEST_OPP;

    }
    static testmethod void serializeTest(){
        Opportunity opp = [select id from opportunity where Name='Test Opportunity'];
        FW_Helpers.serializePretty(ManageOpportunityProducts.getOpportunityData(opp.Id));
        FW_Helpers.serialize(ManageOpportunityProducts.getOpportunityData(opp.Id));
        try{
            opportunity op = new opportunity();
            insert op;
        FW_Exception fw = new FW_Exception('Test Exception',true,'Error occured');
        FW_Helpers.newAuraHandledException(fw);
            
        }
        catch(system.exception e){
            FW_Helpers.ExceptionSerializable exp = new FW_Helpers.ExceptionSerializable(e);
            string msg = exp.message;
            boolean userException = exp.isUserException;
            string details = exp.details;
            Integer lineNumber = exp.lineNumber;
            String stackTraceString = exp.stackTraceString;
            String typeName = exp.typeName;
            system.assertNotEquals(null, lineNumber);
        }
        
    }
}