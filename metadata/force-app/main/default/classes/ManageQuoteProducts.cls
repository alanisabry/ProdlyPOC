/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Provides backend functions to support the Manage Quote Products LWC.
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author   Sabry Alani <sabry.alani@bynder.com>
 * @created  May 6, 2024
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */


public with sharing class ManageQuoteProducts {

    public class QuoteData{
        public Quote quote;
        public Boolean multipleCurrencies = UserInfo.isMultiCurrencyOrganization();
        public String defaultCurrency = UserInfo.getDefaultCurrency();
        public Boolean pricebookRequired = false;
        public Boolean pricingSuperUser = false;

        public QuoteData(Id recordId) {
            quote = [
                SELECT
                    Id,
                    CurrencyIsoCode,
                    Name,
                    Pricebook2Id,
                    Pricebook2.Name,
                    Contract_Start_Date__c,
                    Contract_End_Date__c,
                    ARR__c,
                    Opportunity.OEM__c,
                    Opportunity.Type,
                    Opportunity.OEM__r.name,
                    Account.Original_Contract_Start_Date__c,
                    Account.Current_Contract_Start_Date_new__c,
                    Account.Current_Contract_End_Date_New__c,
                    Account.Company_Size_Grouped__c,
                    Opportunity.Platform__c,
                    AccountId,
                    (
                        SELECT
                            Id,
                            Description,
                            Discount,
                            PricebookEntry.Id,
                            PricebookEntry.IsActive,
                            PricebookEntry.Name,
                            PricebookEntry.Pricebook2Id,
                            PricebookEntry.Product2Id,
                            PricebookEntry.Product2.Name,
                            PricebookEntry.Product2.Product_Name__c,
                            PricebookEntry.Product2.Pricing_Availability__c,
                            Product2.Pricing_Type__c,
                            Parent_Solution_Product__c,
                            Product2.of_Additional_limit_products__c,
                            Quantity,
                            For_Renewal__c,
                            Pricing_Factors_to_be_Applied__c,
                            Recurring_Discount__c,
                            TotalPrice,
                            Default_Price_ARR_One_off__c,
                            Sales_Price_ARR_One_off__c,
                            Initial_Default_Price_ARR_One_off__c,
                            Product2Id,
                            Part_of_Package__c,
                            Part_of_Min_Commit__c,
                            Swap_Item__c,
                            Renewal_OLI_ID__c,
                            Upsell_OLI_ID__c,
                            Upsell_OLI_ID__r.Quantity,
                            Upsell_OLI_ID__r.Swap_Item__c,
                            PricebookEntry.Product2.Dependent_Product__c,
                            Product2.Dependent_Product__c,
                            convertCurrency(TotalPrice) ConvertedTotalPrice,
                            convertCurrency(Default_Price_ARR_One_off__c) ConvertedDefaultPriceARR,
                            UnitPrice,
                            convertCurrency(UnitPrice) ConvertedUnitPrice
                        FROM
                            QuoteLineItems
                    )
                FROM
                    Quote
                WHERE
                    Id = :recordId
            ];
            Id userRoleGroupId = [Select id from Group where relatedID = :UserInfo.getUserRoleID() and Type = 'Role'].ID;
           pricingSuperUser =  [Select id from GroupMember where GroupId = :system.label.Enterprise_Pricing_Super_Users_Group_ID and (UserOrGroupId = :UserInfo.getUserID() or UserOrGroupId = :userRoleGroupId)].size()>0?True:False;
        }
    }

    // Input deserialization class
    public class ItemData {

        // Optional
        public Boolean isDeleted;

        // Upsert/New Item Fields stored inside the SObject
        public QuoteLineItem lineItem;

        public string dependentProductId;
        
        public string iconName;

        public string iconVariant;
    }

    public static QuoteData getQuoteData(Id recordId) {

        // Pull in our data
        QuoteData quoteData = new QuoteData(recordId);

        // Do we have a PB? - limit search to 2 to see if we can auto-assign it
        if (quoteData.quote.Pricebook2Id == null) {
            List<Pricebook2> activePbs = [
                SELECT
                    Id,
                    Name
                FROM
                    Pricebook2
                WHERE
                    IsActive = true
                LIMIT 2
            ];

            // Only one available, auto-assign it to the Opportunity
            if (activePbs.size() == 1) {
                quoteData.quote.Pricebook2Id = activePbs[0].Id;
                update quoteData.quote;
            }
            // Flag the lack of a pricebook
            else {
                throw new FW_Exception('Please assign a Pricebook on the Quote record page before adding products');
            }
        }

        return quoteData;
    }

    public static List<SelectOption> getPicklistValues(String fieldApiName) {
        List<SelectOption> pickListValuesList= new List<SelectOption>();
        if (String.isNotBlank(fieldApiName)) {
            Map<String, Schema.SObjectField> fieldsMap = QuoteLineItem.getSobjectType().getDescribe().fields.getMap();
            List<Schema.PicklistEntry> ple = fieldsMap.get(fieldApiName).getDescribe().getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                pickListValuesList.add(new SelectOption(pickListVal.getValue(),pickListVal.getLabel()));
            }
        }
        return pickListValuesList;
    }

    public static List<PricebookEntry> searchProducts(Id recordId, String query) {

        QuoteData quoteData = new QuoteData(recordId);

        // Multiple currencies is optional
        String currencyString = (quoteData.multipleCurrencies ? quoteData.quote.CurrencyIsoCode : '%%');
        String searchString = '%' + query + '%';
        return [
            SELECT
                Id,
                IsActive,
                Pricebook2Id,
                Product2.Conga_Family__c,
                Product2.For_Contract_Renewals__c,
                Product2.IsActive,
                Product2.Name,
                Product2.Product_Name__c,
                Product2.Pricing_Availability__c,
                Product2.Dependent_Product__c,
                Product2.of_Additional_limit_products__c,
                Product2.Pricing_Type__c,
                UnitPrice,
                List_Price_ARR_One_off__c,
                Workfront_List_Price__c,
                Workfront_List_Price_ARR_One_off__c,
                Workfront_Renewal_Price__c,
                Workfront_Renewal_Price_ARR_One_off__c,
                Acquia_List_Price__c,
                Acquia_List_Price_ARR_One_off__c,
                convertCurrency(UnitPrice) ConvertedUnitPrice,
                convertCurrency(List_Price_ARR_One_off__c) ConvertedUnitPriceARR,
                convertCurrency(Workfront_List_Price_ARR_One_off__c) ConvertedWorkfrontPriceARR,
                convertCurrency(Acquia_List_Price_ARR_One_off__c) ConvertedAcquiaPriceARR,
                convertCurrency(Workfront_Renewal_Price_ARR_One_off__c) ConvertedWorkfrontRenewalPriceARR
            FROM
                PricebookEntry
            WHERE
                IsActive = true AND
                Product2.IsActive = true AND
                Product2.Exclude_from_Upsells__c = false AND
                Pricebook2Id = :quoteData.quote.Pricebook2Id AND
                CurrencyIsoCode LIKE :currencyString AND
                (
                    Product2.Name LIKE :searchString OR
                    Product2.Conga_Family__c LIKE :searchString
                )
            ORDER BY Product2.Conga_Family__c, Product2.Product_Name__c
            LIMIT 101
        ];
    }

    public static List<Removed_Quote_line_Item__c> getRemovedQuoteLineItems (Id recordId){

        List<Removed_Quote_line_Item__c> removedQuoteLineItems = [
            SELECT
                Id,
                Line_Item_Description__c,
                Price_Book_Entry_ID__c,
                Quantity__c,
                For_Renewal__c,
                Discount_percentage__c,
                Recurring_Discount__c,
                TotalPrice__c,
                Default_Price_ARR_One_off__c,
                Initial_Default_Price_ARR_One_off__c,
                Sales_Price_ARR_One_off__c,
                Product__c,
                Product__r.Product_Name__c,
                Part_of_Package__c,
                Part_of_Min_Commit__c,
                Pricing_Factors_to_be_Applied__c,
                Swap_Item__c,
                Renewal_OLI_ID__c,
                Upsell_OLI_ID__c,
                CurrencyIsoCode,
                convertCurrency(TotalPrice__c) ConvertedTotalPrice,
                convertCurrency(Default_Price_ARR_One_off__c) ConvertedDefaultPriceARR,
                convertCurrency(Sales_Price_ARR_One_off__c) ConvertedSalesPriceARR,
                UnitPrice__c,
                convertCurrency(UnitPrice__c) ConvertedUnitPrice
            FROM
                Removed_Quote_line_Item__c
            Where
                Quote__c = :recordId
        ];

        return removedQuoteLineItems;
    }

    public static void saveProducts(Id quoteId, List<ItemData> itemDataList) {

        // We need one list to delete, the other to upsert
        List<QuoteLineItem> toDelete = new List<QuoteLineItem>();
        List<QuoteLineItem> toUpsert = new List<QuoteLineItem>();
        Set<Id> depProdIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        Set<Id> deletedParentIds = new Set<Id>();
        QuoteData quoteData = new QuoteData(quoteId);
        Map<Id,PricebookEntry> priceMap = new Map<Id,PricebookEntry>();
        for(QuoteLineItem item: quoteData.quote.QuoteLineItems){
            prodIds.add(item.Product2Id);
        }

        // Multiple currencies is optional
        String currencyString = (quoteData.multipleCurrencies ? quoteData.quote.CurrencyIsoCode : '%%');
        // Process each item
        for (ItemData data : itemDataList) {

            // Flagged for deletion
            if (data.isDeleted == true) {
                system.debug('Itemdata:'+data.lineItem);
                if(data.lineItem.Parent_Solution_Product__c ==null || !deletedParentIds.contains(data.lineItem.Parent_Solution_Product__c)){
                    system.debug('Item data 1:'+data.lineItem);
                    deletedParentIds.add(data.lineItem.Product2Id);
                    toDelete.add(data.lineItem);
                }
                system.debug('Deleted Parents:'+deletedParentIds);
            }
            // To insert/update
            else {
                // New records need oppId
                if (data.lineItem.Id == null) {
                    data.lineItem.QuoteId = quoteId;
                    system.debug('Item data:'+data.dependentProductId+data.lineItem);
                    if(data.dependentProductId !=null){
                        depProdIds.add(data.dependentProductId);
                    }
                    prodIds.add(data.lineItem.Product2Id);
                }
                toUpsert.add(data.lineItem);
            }
        }
        if(depProdIds.size()>0){
            for(Id prod:depProdIds){
                if(prodIds.contains(prod))
                depProdIds.remove(prod);
            }
        }
        if(depProdIds.size()>0){
            List<PricebookEntry> priceList = [Select Id,IsActive,
            Pricebook2Id,
            Product2.Conga_Family__c,
            Product2.For_Contract_Renewals__c,
            Product2.IsActive,
            Product2.Name,
            Product2.Product_Name__c,
            UnitPrice,
            List_Price_ARR_One_off__c 
            from PricebookEntry where
            IsActive = true AND
            Pricebook2Id = :quoteData.quote.Pricebook2Id AND
            CurrencyIsoCode LIKE :currencyString AND 
            Product2Id IN:depProdIds
            ];
            for(PricebookEntry price:priceList){
                priceMap.put(price.Product2Id,price);
            }
            for(Id dep: depProdIds){
                QuoteLineItem item = new QuoteLineItem();
                item.PricebookEntryId = priceMap.get(dep).Id;
                item.UnitPrice = priceMap.get(dep).UnitPrice;
                item.Quantity = 1;
                item.Product2Id = priceMap.get(dep).Product2Id;
                item.Sales_Price_ARR_One_off__c = priceMap.get(dep).List_Price_ARR_One_off__c;
                item.QuoteId = quoteId;
                toUpsert.add(item);
            }
        }
        // Perform DML
        delete toDelete;
        upsert toUpsert;
    }

    public static PricebookEntry getPriceBookEntryDetails (String preiceBookEntryId){
        System.debug('Pricebook Entry ID: ' + preiceBookEntryId);
        PricebookEntry entry = [
            SELECT  Id,
            IsActive,
            Pricebook2Id,
            Product2.Conga_Family__c,
            Product2.For_Contract_Renewals__c,
            Product2.IsActive,
            Product2.Name,
            Product2.Product_Name__c,
            Product2.Dependent_Product__c,
            Product2.Pricing_Availability__c,
            Product2.of_Additional_limit_products__c,
            Product2.Pricing_Type__c,
            UnitPrice,
            List_Price_ARR_One_off__c,
            Workfront_List_Price__c,
            Workfront_List_Price_ARR_One_off__c,
            Workfront_Renewal_Price__c,
            Workfront_Renewal_Price_ARR_One_off__c,
            Acquia_List_Price__c,
            Acquia_List_Price_ARR_One_off__c,
            convertCurrency(UnitPrice) ConvertedUnitPrice,
            convertCurrency(List_Price_ARR_One_off__c) ConvertedUnitPriceARR,
            convertCurrency(Workfront_List_Price_ARR_One_off__c) ConvertedWorkfrontPriceARR,
            convertCurrency(Acquia_List_Price_ARR_One_off__c) ConvertedAcquiaPriceARR,
            convertCurrency(Workfront_Renewal_Price_ARR_One_off__c) ConvertedWorkfrontRenewalPriceARR
            FROM PricebookEntry
            WHERE Id =: preiceBookEntryId
            LIMIT 1
        ];
        return entry;
    }

    public static void deleteRemovedQuoteLineItems (List<Removed_Quote_line_Item__c> removedQuoteLineItemsToDelete){
        if (removedQuoteLineItemsToDelete != null){
            delete removedQuoteLineItemsToDelete;
        }
    }

    @AuraEnabled
    public static String searchProductsL(Id recordId, String query) {
        try {
            return FW_Helpers.serialize(searchProducts(recordId, query));
        } catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
    }

    @AuraEnabled
    public static String getQuoteDataL(Id recordId) {
        try {
            return FW_Helpers.serialize(getQuoteData(recordId));
        }
        catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
    }

    @AuraEnabled
    public static String getRemovedQuoteLineItemsL(Id recordId) {
        try {
            return FW_Helpers.serialize(getRemovedQuoteLineItems(recordId));
        }
        catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
    }

    @AuraEnabled
    public static String getPriceBookEntryDetailsL(String preiceBookEntryId) {
        try {
            return FW_Helpers.serialize(getPriceBookEntryDetails(preiceBookEntryId));
        }
        catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
    }

    @AuraEnabled(Cacheable=true)
    public static String getPicklistValuesL(String fieldApiName) {
        try {
            List<Map<String, String>> optionList = new List<Map<String, String>>();
            for (SelectOption option : getPicklistValues(fieldApiName)) {
                optionList.add(new Map<String, String> {
                    'value' => option.getValue(),
                    'label' => option.getLabel()
                });
            }
            return FW_Helpers.serialize(optionList);
        }
        catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
    }

    @AuraEnabled
    public static void saveProductsL(Id recordId, String dataJson) {
        try {
            saveProducts(recordId, (List<ItemData>)JSON.deserialize(dataJson, List<ItemData>.class));
            
        }
        catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
    }

    @AuraEnabled
    public static void deleteRemovedQuoteLineItemsL(String removedQLIsToDelete) {
        try {
            deleteRemovedQuoteLineItems((List<Removed_Quote_line_Item__c>)JSON.deserialize(removedQLIsToDelete, List<Removed_Quote_line_Item__c>.class));
        }
        catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
    }
    
     //Wrapper class to store dependent or add on products associated to the parent product
    public class productDependancies{
        public string parentProductID; // Product with product rules
        public List<PricebookEntry> requiredChildPBList; // Required child product(One off) to be added when parent is added
        public List<PricebookEntry> optionalChildPBList; // Optional child product(Add Ons) to be added when parent is added
        
        public productDependancies(string parentProductID, string oppCurrency, string pricebookID){
            List<PricebookEntry> requiredPBList = new List<PricebookEntry>();
            List<PricebookEntry> optionalPBList = new List<PricebookEntry>();
            Set<string> requiredProductIDs = new Set<string>();
            Set<string> optionalProductIDs = new Set<string>();
            Set<string> dependantProductIDs = new Set<string>();
            // Query product rules associated to the parent product
            List<Product_Rules__c>  productRulesList = [ 
                SELECT 
                ID,
                Active__c,
                Dependant_Product__c,
                Dependant_Product_Type__c,
                Parent_Product__c
                FROM
                Product_Rules__c
                WHERE
                Active__c = True AND Parent_Product__c = :parentProductID ];
            // loop product rules of parent product
            for(Product_Rules__c pr: productRulesList){
                if(pr.Dependant_Product__c != null && pr.Dependant_Product_Type__c == 'Required'){
                    requiredProductIDs.add(pr.Dependant_Product__c);
                    dependantProductIDs.add(pr.Dependant_Product__c);
                }else if(pr.Dependant_Product__c != null && pr.Dependant_Product_Type__c == 'Optional'){
                    optionalProductIDs.add(pr.Dependant_Product__c);
                    dependantProductIDs.add(pr.Dependant_Product__c);
                }
                
            }
            if(dependantProductIDs.size()>0){
                List<PricebookEntry> dependantPBList = [
                    SELECT
                    Id,
                    IsActive,
                    Pricebook2Id,
                    Product2.Conga_Family__c,
                    Product2.Family,
                    Product2.For_Contract_Renewals__c,
                    Product2.IsActive,
                    Product2.Name,
                    Product2.Product_Name__c,
                    Product2.Dependent_Product__c,
                    Product2.Pricing_Availability__c,
                    Product2.of_Additional_limit_products__c,
                    Product2.Pricing_Type__c,
                    UnitPrice,
                    List_Price_ARR_One_off__c,
                    Workfront_List_Price__c,
                    Workfront_List_Price_ARR_One_off__c,
                    Workfront_Renewal_Price__c,
                    Workfront_Renewal_Price_ARR_One_off__c,
                    Acquia_List_Price__c,
                    Acquia_List_Price_ARR_One_off__c,
                    convertCurrency(UnitPrice) ConvertedUnitPrice,
                    convertCurrency(List_Price_ARR_One_off__c) ConvertedUnitPriceARR,
                    convertCurrency(Workfront_List_Price_ARR_One_off__c) ConvertedWorkfrontPriceARR,
                    convertCurrency(Acquia_List_Price_ARR_One_off__c) ConvertedAcquiaPriceARR,
                    convertCurrency(Workfront_Renewal_Price_ARR_One_off__c) ConvertedWorkfrontRenewalPriceARR
                    FROM
                    PricebookEntry
                    WHERE
                    IsActive = true AND
                    Product2.IsActive = true AND
                    Pricebook2Id = :pricebookID AND
                    CurrencyIsoCode = :oppCurrency AND
                    Product2Id IN :dependantProductIDs
                ];
                for(PricebookEntry pb: dependantPBList){
                    if(requiredProductIDs.size()>0 && requiredProductIDs.contains(pb.product2id)){
                        requiredPBList.add(pb);
                    }else if(optionalProductIDs.size()>0 && optionalProductIDs.contains(pb.product2id)){
                        optionalPBList.add(pb);
                    }
                }
                parentProductID = parentProductID;
                requiredChildPBList = requiredPBList;
                optionalChildPBList = optionalPBList;
            }
        } 
    }
    
    
    @AuraEnabled
    public static string getProductDependancies(string parentProductID, string oppCurrency, string pricebookID){
        try {
            productDependancies productDependantItems = new productDependancies(parentProductID,oppCurrency,pricebookID);
            return FW_Helpers.serialize(productDependantItems);
        }
        catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
       
        
    }
  

}