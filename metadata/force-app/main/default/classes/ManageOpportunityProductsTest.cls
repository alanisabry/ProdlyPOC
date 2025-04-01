/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Validates functionality exposed in ManageOpportunityProducts.cls
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author   Daniel Bailey <dbailey@opfocus.com>
 * @created  Mar 10, 2021
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
@isTest
public class ManageOpportunityProductsTest {

    /*
        Our test Opportunity property
        - automatically creates itself if not initialized
    */
    private static Opportunity TEST_OPP {
        get {
            if (TEST_OPP == null) {
                // Need an account
                Account testAccount = new Account(
                    Name = 'Test Account'
                );
                insert testAccount;

                // Create the opp
                TEST_OPP = new Opportunity(
                    AccountId = testAccount.Id,
                    Name = 'Test Opportunity',
                    StageName = 'Qualified',
                    CloseDate = Date.today(),
                    Module_Opportunity__c = 'DAM only',
                    Pricebook2Id = ([SELECT Id FROM Pricebook2 WHERE Name = 'Test PB' LIMIT 1]).Id
                );
                insert TEST_OPP;
            }
            return TEST_OPP;
        }
        private set;
    }

    /*
        Create dummy products for querying.
    */
    @TestSetup
    private static void testSetup() {

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
            Product_Type__c = 'Core & Modules',
            Netsuite_New_Business_Item_Internal_ID__c = 'TP2'
        );
         Product2 testProduct3 = new Product2(
            Name = 'Test Product 3',
            ProductCode = 'TP3',
            IsActive = true,
            Product_Type__c = 'Core & Modules',
            Netsuite_New_Business_Item_Internal_ID__c = 'TP3'
        );
        
        insert new List<Product2> { testProduct1, testProduct2, testProduct3 };

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
            Product_Rules__c pr = new Product_Rules__c(Active__c = true,Dependant_Product__c =testProduct1.Id,Dependant_Product_Type__c = 'Required',
                                                      Parent_Product__c=testProduct2.Id);

        Product_Rules__c pr1 = new Product_Rules__c(Active__c = true,Dependant_Product__c =testProduct3.Id,Dependant_Product_Type__c = 'Optional',
                                                      Parent_Product__c=testProduct2.Id);
       insert new List<Product_Rules__c> { pr,pr1};

    }

    /*
        Verifies that all the expected data is
        returned when our helper class is instantiated.
    */
    @isTest
    private static void getOpportunityDataTest() {

        // Call our method originally
        ManageOpportunityProducts.OpportunityData oppData = ManageOpportunityProducts.getOpportunityData(TEST_OPP.Id);

        // Get a ref to the current PB
        Pricebook2 testPB = new Pricebook2(
            Id = TEST_OPP.Pricebook2Id
        );

        // Unassign it
        TEST_OPP.Pricebook2Id = null;
        update TEST_OPP;

        // Desctive the PB too
        testPB.IsActive = false;
        update testPB;

        // Now we should fail to retrieve the Opportunity Data - use the wrapper
        Test.startTest();
        try {
            oppData = (ManageOpportunityProducts.OpportunityData)JSON.deserialize(ManageOpportunityProducts.getOpportunityDataL(TEST_OPP.Id), ManageOpportunityProducts.OpportunityData.class);
            System.assert(false, 'Get Opportunity Data should fail with no Pricebook assigned to the Opportunity');
        }
        catch (Exception e) {} // Expected an exception

        // Re-activate the PB and ensure it auto-updates the Opp to use it
        testPB.IsActive = true;
        update testPB;
        oppData = ManageOpportunityProducts.getOpportunityData(TEST_OPP.Id);
        System.assertEquals(testPB.Id, oppData.opportunity.Pricebook2Id);
    }

    /*
        Ensures the get picklist values
        method returns values.
    */
    @isTest
    private static void getPicklistValuesTest() {
        List<Map<String, String>> picklistValues = (List<Map<String, String>>)JSON.deserialize(ManageOpportunityProducts.getPicklistValuesL('Recurring_Discount__c'), List<Map<String, String>>.class);
        System.assertNotEquals(0, picklistValues.size());
    }

    /*
        Tests the search functionality
    */
    @isTest
    private static void searchProductsTest() {

        // Searching for Test Product should give us both products back
        List<PricebookEntry> pbEntries = (List<PricebookEntry>)JSON.deserialize(ManageOpportunityProducts.searchProductsL(TEST_OPP.Id, 'Test Product'), List<PricebookEntry>.class);
        System.assertEquals(2, pbEntries.size());

        // Now refine the query to just return the first one
        pbEntries = ManageOpportunityProducts.searchProducts(TEST_OPP.Id, 'Test Product 1');
        System.assertEquals(1, pbEntries.size());
        System.assertEquals('Test Product 1', pbEntries[0].Product2.Product_Name__c);
    }

    // New Test Method
    @isTest
    private static void searchUpsellProductsTest() {

        // Searching for Test Product should give us both products back
        List<PricebookEntry> pbEntries = (List<PricebookEntry>)JSON.deserialize(ManageOpportunityProducts.searchProductsL(TEST_OPP.Id, 'Test Product'), List<PricebookEntry>.class);
        System.assertEquals(2, pbEntries.size());

        // Now refine the query to just return the first one
        pbEntries = ManageOpportunityProducts.searchUpsellProducts(TEST_OPP.Id, 'Test Product 1');
        System.assertEquals(1, pbEntries.size());
        System.assertEquals('Test Product 1', pbEntries[0].Product2.Product_Name__c);
        
        //Now add items to Excluded Products and Search the Price Book Items
        List<String> itemsToExcludeFromSearch = ManageOpportunityProducts.getExcludedProducts(TEST_OPP.Id);
        if (itemsToExcludeFromSearch.isEmpty()){
            pbEntries = ManageOpportunityProducts.searchUpsellProducts(TEST_OPP.Id, 'Test Product 1');
        	System.assertEquals(1, pbEntries.size());
        	System.assertEquals('Test Product 1', pbEntries[0].Product2.Product_Name__c);
        }
        else{
             pbEntries = ManageOpportunityProducts.searchUpsellProducts(TEST_OPP.Id, 'Test Product 2');
        	 System.assertEquals(1, pbEntries.size());
        	 System.assertEquals('Test Product 2', pbEntries[0].Product2.Product_Name__c);
        }
    }

    /*
        Tests deleting and creating line items
        in the same transaction.
    */
    @isTest
    private static void saveProductsTest() {

        // Get PB entry data
        PricebookEntry pbEntry = [
            SELECT
                Id,
                UnitPrice,
                Product2.Product_Name__c
            FROM
                PricebookEntry
            WHERE
                Pricebook2Id = :TEST_OPP.Pricebook2Id AND
                Product2.Product_Name__c = 'Test Product 1'
            LIMIT 1
        ];
		Product2 prod = [select id from Product2 where Name = 'Test Product 1'];
        // First insert a single product
        ManageOpportunityProducts.ItemData itemData = new ManageOpportunityProducts.ItemData();
        itemData.isDeleted = false;
        itemData.dependentProductId = prod.id;
        itemData.lineItem = new OpportunityLineItem(
            PricebookEntryId = pbEntry.Id,
            UnitPrice  = 123.45,
            Quantity = 2
        );

        // Perform the save
        ManageOpportunityProducts.saveProductsL(TEST_OPP.Id, JSON.serialize(
            new List<ManageOpportunityProducts.ItemData> { itemData }
        ));

        // Ensure we now have one line item on the opp
        List<OpportunityLineItem> lineItems = [
            SELECT
                Id,
                Quantity,
                UnitPrice
            FROM
                OpportunityLineItem
            WHERE
                OpportunityId = :TEST_OPP.Id
        ];
        System.assertEquals(2, lineItems.size());
        System.assertEquals(itemData.lineItem.Quantity, lineItems[0].Quantity);
        System.assertEquals(itemData.lineItem.UnitPrice, lineItems[0].UnitPrice);

    }

    /*
        New Test Method
        Tests the get excluded products functionality
    */
    @isTest
    private static void getExcludedProductsTest() {

        List<String> excludedProdIds = ManageOpportunityProducts.getExcludedProducts(TEST_OPP.Id);
        System.assertEquals(0, excludedProdIds.size());
    }

    /*
        New Test Method
        Test getting the Account Open Opportunities
    */
    @isTest
    private static void getOpenOpportunitiesForAccountTest(){
       List<Opportunity> openOpps = ManageOpportunityProducts.getOpenOpportunitiesForAccount(TEST_OPP.Id);
       System.assertNotEquals(1, openOpps.size());
    } 


   /*
       New Test Method
       Test getting the OLIs of an Open Opportunity
   */
   @isTest
   static void getOpenOpportunityLineItemsTest() {

    
        // Get PB entry data
        PricebookEntry pbEntry = [
            SELECT
                Id,
                UnitPrice,
                Product2.Product_Name__c
            FROM
                PricebookEntry
            WHERE
                Pricebook2Id = :TEST_OPP.Pricebook2Id AND
                Product2.Product_Name__c = 'Test Product 1'
            LIMIT 1
        ];
    
        // Create test Opportunity Line Item
       OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = TEST_OPP.Id, Quantity = 1, UnitPrice = 100, PricebookEntryId = pbEntry.Id);
       insert oli;
       
       // Call the method being tested
       List<OpportunityLineItem> result = ManageOpportunityProducts.getOpenOpportunityLineItems(TEST_OPP.Id);
       
       // Assert the results
       System.assertEquals(0, result.size());
   }
    
        @isTest
    static void testAuraEnabledMethods() {
        Test.startTest();

        // Test AuraEnabled methods with Cacheable=true
        String picklistValues = ManageOpportunityProducts.getPicklistValuesL('Discount');
        System.assertNotEquals(null, picklistValues);

        String searchResults = ManageOpportunityProducts.searchUpsellProductsL(TEST_OPP.Id, 'Test');
        System.assertNotEquals(null, searchResults);
        
        String lineItems = ManageOpportunityProducts.getOpenOpportunityLineItemsL(TEST_OPP.Id);
        System.assertNotEquals(null, lineItems);
        
        String openOpportunities = ManageOpportunityProducts.getOpenOpportunitiesForAccountL(TEST_OPP.Id);
        System.assertNotEquals(null, openOpportunities);

        Test.stopTest();
    }
    
    @isTest
    static void testProductDependancies(){
        Test.startTest();
        string parentId = [select id from product2 where name ='Test Product 2' limit 1].id;
        string pbid = [SELECT Id FROM Pricebook2 WHERE Name = 'Test PB' LIMIT 1].Id;
        string dependancies = ManageOpportunityProducts.getProductDependancies(parentId,'EUR',pbid);
         Test.stopTest();
    }
      @isTest
    static void testAddOns(){
        Test.startTest();
        string parentId = [select id from product2 where name ='Test Product 2' limit 1].id;
        string pbid = [SELECT Id FROM Pricebook2 WHERE Name = 'Test PB' LIMIT 1].Id;
        string dependancies = ManageOpportunityProducts.getAddOns(parentId,'EUR',pbid);
         Test.stopTest();
    }


}