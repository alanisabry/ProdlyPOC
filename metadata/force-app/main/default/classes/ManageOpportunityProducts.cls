/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Provides backend functions to support the Manage Opportunity Products LWC.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author   Daniel Bailey <dbailey@opfocus.com>
* @created  Mar 10, 2021
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public class ManageOpportunityProducts {
    
    // Our serializable class of Opportunity Data
    public class OpportunityData {
        public Opportunity opportunity;
        public Boolean multipleCurrencies = UserInfo.isMultiCurrencyOrganization();
        public String defaultCurrency = UserInfo.getDefaultCurrency();
        public Boolean pricebookRequired = false;
        public Boolean pricingSuperUser = false;
        
        public OpportunityData(Id recordId) {
            opportunity = [
                SELECT
                Id,
                CurrencyIsoCode,
                Name,
                Type,
                Pricebook2Id,
                Pricebook2.Name,
                OEM__c,
                OEM__r.name,
                Account.Original_Contract_Start_Date__c,
                Account.Current_Contract_Start_Date_new__c,
                Account.Current_Contract_End_Date_New__c,
                Account.Company_Size_Grouped__c,
                Platform__c,
                Startdate_contract__c,
                End_date_contract__c,
                ARR_manual__c,
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
                    Portfolio_OLI_ID__c,
                    Quantity,
                    For_Renewal__c,
                    Recurring_Discount__c,
                    TotalPrice,
                    Default_Price_ARR__c,
                    Sales_Price_ARR__c,
                    Product2Id,
                    Parent_Solution__c,
                    Parent_Solution_Product__c,
                    Default_Price__c,
                    Part_of_a_package__c,
                    Part_of_Min_Commit__c,
                    Swap_Item__c,
                    PricebookEntry.Product2.Dependent_Product__c,
                    Product2.Dependent_Product__c,
                    Product2.of_Additional_limit_products__c, 
                    convertCurrency(TotalPrice) ConvertedTotalPrice,
                    convertCurrency(Default_Price_ARR__c) ConvertedDefaultPriceARR,
                    UnitPrice,
                    convertCurrency(UnitPrice) ConvertedUnitPrice
                    FROM
                    OpportunityLineItems
                )
                FROM
                Opportunity
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
        public OpportunityLineItem lineItem;
        
        public string dependentProductId;   
    }
    
    //Get all Open Opportunities for the respective Acount
    public static List<Opportunity> getOpenOpportunitiesForAccount(Id recordId) {
        
        List<Opportunity> openOpportunities = new List<Opportunity>();
        
        OpportunityData upsell_opportunity = getOpportunityData(recordId);
        
        System.debug('Upsell Opportunity Start Date: ' +  upsell_opportunity.opportunity.Startdate_contract__c);
        System.debug('Current Contract End Date: ' +  upsell_opportunity.opportunity.Account.Current_Contract_End_Date_New__c);
        
        if (upsell_opportunity.opportunity.Startdate_contract__c < upsell_opportunity.opportunity.Account.Current_Contract_End_Date_New__c)
        {
            // Query cuurently active contract related to the account
            openOpportunities = [
                SELECT Id, Name, StageName, CloseDate 
                FROM Opportunity 
                WHERE AccountId = :upsell_opportunity.opportunity.AccountId
                AND Contract_IsActive__c = true
            ];
        }
        else
        {
            // Get all open renewal opportunities related to the account
            openOpportunities = [
                SELECT Id, Name, StageName, CloseDate 
                FROM Opportunity 
                WHERE AccountId = :upsell_opportunity.opportunity.AccountId
                AND Type = 'Existing Business-Renewal'
                AND IsClosed = false
            ];
        }    
        
        return openOpportunities;
    }
    
    //Get Open Opportunities Line Items
    public static List<OpportunityLineItem> getOpenOpportunityLineItems (Id recordId){
        
        List<OpportunityLineItem> openOpportunityLineItems = [
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
            PricebookEntry.Product2.Product_Type__c,
            PricebookEntry.Product2.Pricing_Type__c,
            PricebookEntry.Product2.Pricing_Availability__c,
            Quantity,
            For_Renewal__c,
            Recurring_Discount__c,
            TotalPrice,
            Default_Price_ARR__c,
            Initial_Default_Price_ARR_One_off__c,
            Sales_Price_ARR__c,
            Product2Id,
            Parent_Solution__c,
            Parent_Solution_Product__c,
            Discount_Amount__c,
            Discount_Amount_ARR_One_off__c,
            Default_Price__c,
            Part_of_a_package__c,
            Part_of_Min_Commit__c,
            PricebookEntry.Product2.Dependent_Product__c,
            Product2.Dependent_Product__c,
            Product2.of_Additional_limit_products__c,
            convertCurrency(TotalPrice) ConvertedTotalPrice,
            convertCurrency(Default_Price_ARR__c) ConvertedDefaultPriceARR,
            convertCurrency(Sales_Price_ARR__c) ConvertedSalesPriceARR,
            convertCurrency(Discount_Amount__c) ConvertedDiscountAmount,
            convertCurrency(Discount_Amount_ARR_One_off__c) ConvertedARRDiscountAmount,
            UnitPrice,
            convertCurrency(UnitPrice) ConvertedUnitPrice
            FROM
            OpportunityLineItem
            Where
            OpportunityId = :recordId
            AND For_Renewal__c = true
            AND Quantity > 0
        ];
        
        return openOpportunityLineItems;
    }
    
     //Get Excluded Products
    public static List<String> getExcludedProducts (Id recordId)
    {
        List<String> excludedProductsIds = new List<String>();
        List<Opportunity> portfolioOpportunities = getOpenOpportunitiesForAccount(recordId);
        for (Opportunity portfolioOpportuntiy : portfolioOpportunities)
        {
            List<OpportunityLineItem> currentOLIs = getOpenOpportunityLineItems(portfolioOpportuntiy.Id);
            for (OpportunityLineItem oli : currentOLIs)
            {
                if (oli.PricebookEntry.Product2.Product_Type__c == 'Core & Modules')
                {
                    excludedProductsIds.add(oli.PricebookEntry.Product2.Id);
                }
            }
        }
        return excludedProductsIds;
    }
    
    public static OpportunityData getOpportunityData(Id recordId) {
        
        // Pull in our data
        OpportunityData oppData = new OpportunityData(recordId);
        
        // Do we have a PB? - limit search to 2 to see if we can auto-assign it
        if (oppData.opportunity.Pricebook2Id == null) {
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
                oppData.opportunity.Pricebook2Id = activePbs[0].Id;
                update oppData.opportunity;
            }
            // Flag the lack of a pricebook
            else {
                throw new FW_Exception('Please assign a Pricebook on the Opportunity record page before adding products');
            }
        }
        
        return oppData;
    }
    
    public static List<SelectOption> getPicklistValues(String fieldApiName) {
        List<SelectOption> pickListValuesList= new List<SelectOption>();
        if (String.isNotBlank(fieldApiName)) {
            Map<String, Schema.SObjectField> fieldsMap = OpportunityLineItem.getSobjectType().getDescribe().fields.getMap();
            List<Schema.PicklistEntry> ple = fieldsMap.get(fieldApiName).getDescribe().getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                pickListValuesList.add(new SelectOption(pickListVal.getValue(),pickListVal.getLabel()));
            }
        }
        return pickListValuesList;
    }
    
    public static List<PricebookEntry> searchProducts(Id recordId, String query) {
        
        OpportunityData oppData = new OpportunityData(recordId);
        
        // Multiple currencies is optional
        String currencyString = (oppData.multipleCurrencies ? oppData.opportunity.CurrencyIsoCode : '%%');
        String searchString = '%' + query + '%';
        if (oppData.opportunity.Type == 'Referral'){
            return [
                SELECT
                Id,
                IsActive,
                Pricebook2Id,
                Product2Id,
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
                Pricebook2Id = :oppData.opportunity.Pricebook2Id AND
                CurrencyIsoCode LIKE :currencyString AND
                (
                    Product2.Name LIKE :searchString OR
                    Product2.Family LIKE :searchString
                )
                ORDER BY Product2.Family, Product2.Product_Name__c
                LIMIT 101
            ];
        }else{
            return [
                SELECT
                Id,
                IsActive,
                Pricebook2Id,
                Product2.Conga_Family__c,
                Product2.Family,
                Product2.For_Contract_Renewals__c,
                Product2.IsActive,
                Product2.Name,
                Product2Id,
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
                Product2.Exclude_from_New_Business__c = false AND
                Pricebook2Id = :oppData.opportunity.Pricebook2Id AND
                CurrencyIsoCode LIKE :currencyString AND
                (
                    Product2.Name LIKE :searchString OR
                    Product2.Family LIKE :searchString
                )
                ORDER BY Product2.Family, Product2.Product_Name__c
                LIMIT 101
            ];
        }
        
    }
    
    public static List<PricebookEntry> searchUpsellProducts(Id recordId, String query) {
        
        List<String> itemsToExcludeFromSearch = getExcludedProducts(recordId);
        System.debug('Search Exclusion Products Count: ' + itemsToExcludeFromSearch.size());
        OpportunityData oppData = new OpportunityData(recordId);
        // Multiple currencies is optional
        String CurrentUserProfileId = UserInfo.getProfileId();
        String currencyString = (oppData.multipleCurrencies ? oppData.opportunity.CurrencyIsoCode : '%%');
        String searchString = '%' + query + '%';
        if (CurrentUserProfileId == '00eU0000000iBVCIA2'){
            return [
                SELECT
                Id,
                IsActive,
                Pricebook2Id,
                Product2.Id,
                Product2.Conga_Family__c,
                Product2.Family,
                Product2.For_Contract_Renewals__c,
                Product2.IsActive,
                Product2.Name,
                Product2Id,
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
                Pricebook2Id = :oppData.opportunity.Pricebook2Id AND
                CurrencyIsoCode LIKE :currencyString AND
                (
                    Product2.Name LIKE :searchString OR
                    Product2.Family LIKE :searchString
                )
                ORDER BY Product2.Family, Product2.Product_Name__c
                LIMIT 101
            ];
        }
        if (!itemsToExcludeFromSearch.isEmpty()) {
            return [
                SELECT
                Id,
                IsActive,
                Pricebook2Id,
                Product2.Id,
                Product2.Conga_Family__c,
                Product2.Family,
                Product2.For_Contract_Renewals__c,
                Product2.IsActive,
                Product2.Name,
                Product2Id,
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
                Product2.Exclude_from_Upsells__c = false AND
                Product2.Id NOT IN :itemsToExcludeFromSearch AND
                Pricebook2Id = :oppData.opportunity.Pricebook2Id AND
                CurrencyIsoCode LIKE :currencyString AND
                (
                    Product2.Name LIKE :searchString OR
                    Product2.Family LIKE :searchString
                )
                ORDER BY Product2.Family, Product2.Product_Name__c
                LIMIT 101
            ];
        }
        else{
            return [
                SELECT
                Id,
                IsActive,
                Pricebook2Id,
                Product2.Id,
                Product2.Conga_Family__c,
                Product2.Family,
                Product2.For_Contract_Renewals__c,
                Product2.IsActive,
                Product2.Name,
                Product2Id,
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
                Product2.Exclude_from_Upsells__c = false AND
                Pricebook2Id = :oppData.opportunity.Pricebook2Id AND
                CurrencyIsoCode LIKE :currencyString AND
                (
                    Product2.Name LIKE :searchString OR
                    Product2.Family LIKE :searchString
                )
                ORDER BY Product2.Family, Product2.Product_Name__c
                LIMIT 101
            ];
        }
        
    }
    
    public static void saveProducts(Id opportunityId, List<ItemData> itemDataList) {
        
        // We need one list to delete, the other to upsert
        List<OpportunityLineItem> toDelete = new List<OpportunityLineItem>();
        List<OpportunityLineItem> toUpsert = new List<OpportunityLineItem>();
        Set<Id> depProdIds = new Set<Id>();
        Set<Id> prodIds = new Set<Id>();
        Set<Id> deletedParentIds = new Set<Id>();
        OpportunityData oppData = new OpportunityData(opportunityId);
        Map<Id,PricebookEntry> priceMap = new Map<Id,PricebookEntry>();
        for(OpportunityLineItem item: oppData.opportunity.OpportunityLineItems){
            prodIds.add(item.Product2Id);
        }
        
        // Multiple currencies is optional
        String currencyString = (oppData.multipleCurrencies ? oppData.opportunity.CurrencyIsoCode : '%%');
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
                    data.lineItem.OpportunityId = opportunityId;
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
                                              Product2.Family,
                                              Product2.For_Contract_Renewals__c,
                                              Product2.IsActive,
                                              Product2.Name,
                                              Product2.Product_Name__c,
                                              UnitPrice,
                                              List_Price_ARR_One_off__c 
                                              from PricebookEntry where
                                              IsActive = true AND
                                              Pricebook2Id = :oppData.opportunity.Pricebook2Id AND
                                              CurrencyIsoCode LIKE :currencyString AND 
                                              Product2Id IN:depProdIds
                                             ];
            for(PricebookEntry price:priceList){
                priceMap.put(price.Product2Id,price);
            }
            for(Id dep: depProdIds){
                OpportunityLineItem item = new OpportunityLineItem();
                item.PricebookEntryId = priceMap.get(dep).Id;
                item.UnitPrice = priceMap.get(dep).UnitPrice;
                item.Quantity = 1;
                item.Product2Id = priceMap.get(dep).Product2Id;
                item.Sales_Price_ARR__c = priceMap.get(dep).List_Price_ARR_One_off__c;
                item.opportunityId = opportunityId;
                toUpsert.add(item);
            }
        }
        // Perform DML
        delete toDelete;
        upsert toUpsert;
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
    public static String searchUpsellProductsL(Id recordId, String query) {
        try {
            return FW_Helpers.serialize(searchUpsellProducts(recordId, query));
        } catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
    }
    
    @AuraEnabled
    public static String getOpportunityDataL(Id recordId) {
        try {
            return FW_Helpers.serialize(getOpportunityData(recordId));
        }
        catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
    }
    
    @AuraEnabled
    public static String getOpenOpportunitiesForAccountL(Id recordId) {
        try {
            return FW_Helpers.serialize(getOpenOpportunitiesForAccount(recordId));
        }
        catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
    }
    
    @AuraEnabled
    public static String getOpenOpportunityLineItemsL(Id recordId) {
        try {
            return FW_Helpers.serialize(getOpenOpportunityLineItems(recordId));
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
    @AuraEnabled
    public static string getAddOns(string parentProductID, string oppCurrency, string pricebookID){
        try {
            productDependancies productDependantItems = new productDependancies(parentProductID,oppCurrency,pricebookID);
            return FW_Helpers.serialize(productDependantItems.optionalChildPBList);
        }
        catch (Exception e) {
            throw FW_Helpers.newAuraHandledException(e);
        }
    }
        
    
}