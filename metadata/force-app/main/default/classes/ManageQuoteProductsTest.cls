@isTest
public class ManageQuoteProductsTest {

    private static Quote TEST_QUOTE {
        get {
            if (TEST_QUOTE == null) {
                // Create test Account
                Account testAccount = new Account(Name = 'Test Account');
                insert testAccount;

                // Create test Opportunity
                Opportunity testOpp = new Opportunity(
                    Name = 'Test Opportunity - ' + String.valueOf(DateTime.now().getTime()),
                    CloseDate = Date.today().addMonths(1),
                    StageName = 'Prospecting',
                    Module_Opportunity__c = 'DAM only',
                    AccountId = testAccount.Id,
                    Pricebook2Id = ([SELECT Id FROM Pricebook2 WHERE Name = 'Test Pricebook' LIMIT 1]).Id
                );
                insert testOpp;

                // Create test Quote
                TEST_QUOTE = new Quote(
                    Name = 'Test Quote',
                    OpportunityId = testOpp.Id,
                    CurrencyIsoCode = 'USD',
                    Pricebook2Id = ([SELECT Id FROM Pricebook2 WHERE Name = 'Test Pricebook' LIMIT 1]).Id
                );
                insert TEST_QUOTE;
            }
            return TEST_QUOTE;
        }
        private set;
    }

    @testSetup
    static void setupTestData() {
        // Create test Pricebook
        Pricebook2 testPricebook = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert testPricebook;

        // Create test Products
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true, Netsuite_New_Business_Item_Internal_ID__c = 'TP1');
        insert testProduct;
        
        Product2 testProduct1 = new Product2(Name = 'Test Product1', IsActive = true, Netsuite_New_Business_Item_Internal_ID__c = 'TP2');
        insert testProduct1;

        // Create test Pricebook Entries
        insert new List<PricebookEntry> {
            new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct.Id,
                IsActive = true,
                UnitPrice = 100.00
            ),
            new PricebookEntry(
                Pricebook2Id = testPricebook.Id,
                Product2Id = testProduct.Id,
                IsActive = true,
                UnitPrice = 100.00
            ),
            new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct1.Id,
                IsActive = true,
                UnitPrice = 200.00
            ),
            new PricebookEntry(
                Pricebook2Id = testPricebook.Id,
                Product2Id = testProduct1.Id,
                IsActive = true,
                UnitPrice = 200.00
            )
        };

        // Create test QuoteLineItem
        PricebookEntry pbEntry = [
            SELECT Id, UnitPrice FROM PricebookEntry
            WHERE Pricebook2Id = :testPricebook.Id
            LIMIT 1
        ];

        QuoteLineItem testQuoteLineItem = new QuoteLineItem(
            QuoteId = TEST_QUOTE.Id,
            PricebookEntryId = pbEntry.Id,
            Quantity = 1,
            Sales_Price_ARR_One_off__c = 1200.00,
            UnitPrice = 100.00
        );
        insert testQuoteLineItem;
           Product_Rules__c pr = new Product_Rules__c(Active__c = true,Dependant_Product__c =testProduct1.Id,Dependant_Product_Type__c = 'Required',
                                                      Parent_Product__c=testProduct.Id);

        Product_Rules__c pr1 = new Product_Rules__c(Active__c = true,Dependant_Product__c =testProduct1.Id,Dependant_Product_Type__c = 'Optional',
                                                      Parent_Product__c=testProduct.Id);
       insert new List<Product_Rules__c> { pr,pr1};
    }

    @isTest
    static void testGetQuoteData() {
        Test.startTest();
        // Test with valid data
        ManageQuoteProducts.QuoteData result = ManageQuoteProducts.getQuoteData(TEST_QUOTE.Id);
        System.assertNotEquals(null, result);
        System.assertEquals(TEST_QUOTE.Id, result.quote.Id);

        // Test with Quote without Pricebook2Id
        Quote quoteWithoutPB = new Quote(
            Name = 'Quote without PB',
            OpportunityId = TEST_QUOTE.OpportunityId,
            CurrencyIsoCode = 'USD'
        );
        insert quoteWithoutPB;

        result = ManageQuoteProducts.getQuoteData(quoteWithoutPB.Id);
        System.assertNotEquals(null, result);

        // Ensure Pricebook2Id is assigned
        System.assertNotEquals(null, result.quote.Pricebook2Id);

        // Test with multiple pricebooks
        Pricebook2 anotherPricebook = new Pricebook2(Name = 'Another Pricebook', IsActive = true);
        insert anotherPricebook;

        Test.stopTest();
    }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        // Test valid field API name
        List<SelectOption> options = ManageQuoteProducts.getPicklistValues('Discount');
        System.assertNotEquals(null, options);

        // Test with a field that has no picklist values
        List<SelectOption> options1;
        try {
            options1 = ManageQuoteProducts.getPicklistValues('NonExistingField');
        } catch (NullPointerException e) {
            options1 = new List<SelectOption>();
        }
        System.assertEquals(0, options1.size());
        
        Test.stopTest();
    }

    @isTest
    static void testSearchProducts() {
        Test.startTest();
        // Test with valid search keyword
        List<PricebookEntry> products = ManageQuoteProducts.searchProducts(TEST_QUOTE.Id, 'Test Product');
        System.assertNotEquals(null, products);
        System.assert(products.size() > 0, 'At least one product should be returned');
    
        // Test with empty keyword
        List<PricebookEntry> products1 = ManageQuoteProducts.searchProducts(TEST_QUOTE.Id, '');
        System.assertNotEquals(null, products1);
        System.assert(products1.size() > 0, 'Products should be returned for empty search term');
    
        // Test with no matching products
        List<PricebookEntry> products2 = ManageQuoteProducts.searchProducts(TEST_QUOTE.Id, 'NonExistingProduct');
        System.assertNotEquals(null, products2);
        System.assert(products2.size() == 0, 'No products should be returned for non-existing keyword');

        // Test with invalid quote Id
        List<PricebookEntry> products3 = new List<PricebookEntry>();
        try {
            products3 = ManageQuoteProducts.searchProducts('001000000000000AAA', 'Test Product');
        } catch (Exception e) {
            // Handle exception if thrown
            System.assertEquals('List has no rows for assignment to SObject', e.getMessage());
        }
        System.assertEquals(0, products3.size());

        Test.stopTest();
    }

    @isTest
    static void testGetRemovedQuoteLineItems() {
        Test.startTest();
        List<Removed_Quote_line_Item__c> removedItems = ManageQuoteProducts.getRemovedQuoteLineItems(TEST_QUOTE.Id);
        System.assertNotEquals(null, removedItems);

        // Test with invalid quote Id
        removedItems = ManageQuoteProducts.getRemovedQuoteLineItems('001000000000000AAA');
        System.assertEquals(0, removedItems.size());

        Test.stopTest();
    }

    @isTest
    static void testSaveProducts() {
        PricebookEntry pbEntry = [
            SELECT Id FROM PricebookEntry
            WHERE Pricebook2Id = :TEST_QUOTE.Pricebook2Id
            LIMIT 1
        ];

        List<ManageQuoteProducts.ItemData> itemDataList = new List<ManageQuoteProducts.ItemData>();
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product1'];
        ManageQuoteProducts.ItemData itemData = new ManageQuoteProducts.ItemData();
        itemData.lineItem = new QuoteLineItem(Quantity = 1, Sales_Price_ARR_One_off__c = 1200.00, UnitPrice = 100, PricebookEntryId = pbEntry.Id);
        itemData.dependentProductId = prod.Id;
        itemData.isDeleted = false;
        itemDataList.add(itemData);

        Test.startTest();
        ManageQuoteProducts.saveProducts(TEST_QUOTE.Id, itemDataList);

        List<QuoteLineItem> items = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :TEST_QUOTE.Id];
        System.assertNOTEquals(1, items.size());
        
        Test.stopTest();
    }

    @isTest
    static void testGetPriceBookEntryDetails() {
        PricebookEntry testPbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        Test.startTest();
        PricebookEntry result = ManageQuoteProducts.getPriceBookEntryDetails(testPbe.Id);
        System.assertNotEquals(null, result);
        System.assertEquals(testPbe.Id, result.Id);

        // Test with invalid PricebookEntry Id
        try {
            result = ManageQuoteProducts.getPriceBookEntryDetails('001000000000000AAA');
            System.assert(false, 'Exception should have been thrown for invalid ID');
        } catch (Exception e) {
            System.assert(true, 'Exception was thrown as expected');
        }

        Test.stopTest();
    }

    @isTest
    static void testDeleteRemovedQuoteLineItems() {
        Removed_Quote_line_Item__c removedItem = new Removed_Quote_line_Item__c(
            Line_Item_Description__c = 'Test',
            Quote__c = TEST_QUOTE.Id
        );
        insert removedItem;

        List<Removed_Quote_line_Item__c> items = [SELECT Id FROM Removed_Quote_line_Item__c WHERE Id = :removedItem.Id];
        System.assertEquals(1, items.size());

        Test.startTest();
        ManageQuoteProducts.deleteRemovedQuoteLineItems(new List<Removed_Quote_line_Item__c>{removedItem});
       

        items = [SELECT Id FROM Removed_Quote_line_Item__c WHERE Id = :removedItem.Id];
        System.assertEquals(0, items.size());

        // Test with null list
    
        ManageQuoteProducts.deleteRemovedQuoteLineItems(null);
      

        // Test with empty list
     
        ManageQuoteProducts.deleteRemovedQuoteLineItems(new List<Removed_Quote_line_Item__c>());
        Test.stopTest();
    }

    @isTest
    static void testAuraEnabledMethods() {
        Test.startTest();

        // Test AuraEnabled methods with Cacheable=true
        String picklistValues = ManageQuoteProducts.getPicklistValuesL('Discount');
        System.assertNotEquals(null, picklistValues);

        String quoteData = ManageQuoteProducts.getQuoteDataL(TEST_QUOTE.Id);
        System.assertNotEquals(null, quoteData);

        String searchResults = ManageQuoteProducts.searchProductsL(TEST_QUOTE.Id, 'Test');
        System.assertNotEquals(null, searchResults);

        String removedItems = ManageQuoteProducts.getRemovedQuoteLineItemsL(TEST_QUOTE.Id);
        System.assertNotEquals(null, removedItems);

        String priceBookEntry = ManageQuoteProducts.getPriceBookEntryDetailsL([SELECT Id FROM PricebookEntry LIMIT 1].Id);
        System.assertNotEquals(null, priceBookEntry);

        ManageQuoteProducts.saveProductsL(TEST_QUOTE.Id, '[]');
        ManageQuoteProducts.deleteRemovedQuoteLineItemsL('[]');

        Test.stopTest();
    }

    @isTest
    static void testProductDependancies(){
        Test.startTest();
        string parentId = [select id from product2 where name ='Test Product' limit 1].id;
        string pbid = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Pricebook' LIMIT 1].Id;
        string dependancies = ManageQuoteProducts.getProductDependancies(parentId,'EUR',pbid);
         Test.stopTest();
    }
    
}