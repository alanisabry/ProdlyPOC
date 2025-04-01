public with sharing class OpportunityProductsController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRenewalProducts(Id opportunityId) {
        Decimal usdToEurRate = getExchangeRate('USD'); 
        System.debug('Exchange Rate (USD to EUR): ' + usdToEurRate);
        
        List<OpportunityLineItem> lineItems = [
            SELECT Id, Quantity, Product2.Id, Product2.Name, 
                   Default_Price_ARR__c, Price_Change__c, Recurring_Discount__c, 
                   Sales_Price_ARR__c, Total_Sales_Price_ARR__c, Description, 
                   For_Renewal__c, Part_of_a_package__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId AND Product2.For_Contract_Renewals__c = true
        ];
        return serializeLineItems(lineItems, usdToEurRate);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getNonRenewalProducts(Id opportunityId) {
        Decimal usdToEurRate = getExchangeRate('USD'); 
        System.debug('Exchange Rate (USD to EUR): ' + usdToEurRate);
        
        List<OpportunityLineItem> lineItems = [
            SELECT Id, Quantity, Product2.Id, Product2.Name, 
                   Default_Price_ARR__c, Price_Change__c, Recurring_Discount__c, 
                   Sales_Price_ARR__c, Total_Sales_Price_ARR__c, Description, 
                   For_Renewal__c, Part_of_a_package__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId AND (Product2.For_Contract_Renewals__c = false OR Product2.For_Contract_Renewals__c = null)
        ];
        return serializeLineItems(lineItems, usdToEurRate);
    }

    private static Decimal getExchangeRate(String targetCurrencyIsoCode) {
        try {
            CurrencyType currency1 = [
                SELECT ConversionRate
                FROM CurrencyType
                WHERE IsoCode = :targetCurrencyIsoCode
                LIMIT 1
            ];
            return currency1.ConversionRate;
        } catch (Exception e) {
            System.debug('Error fetching exchange rate: ' + e.getMessage());
            return 1; 
        }
    }

    private static List<Map<String, Object>> serializeLineItems(List<OpportunityLineItem> lineItems, Decimal exchangeRate) {
        List<Map<String, Object>> serializedItems = new List<Map<String, Object>>();
        for (OpportunityLineItem item : lineItems) {
            Map<String, Object> mapItem = new Map<String, Object>();
            Decimal defaultPriceARR = item.Default_Price_ARR__c != null ? item.Default_Price_ARR__c : 0;
            Decimal salesPriceARR = item.Sales_Price_ARR__c != null ? item.Sales_Price_ARR__c : 0;
            Decimal totalSalesPriceARR = item.Total_Sales_Price_ARR__c != null ? item.Total_Sales_Price_ARR__c : 0;

            mapItem.put('Id', item.Id);
            mapItem.put('ProductId', item.Product2.Id);
            mapItem.put('ProductName', item.Product2.Name);
            mapItem.put('Quantity', item.Quantity);

            System.debug('Default Price ARR (USD): ' + defaultPriceARR);
            System.debug('Sales Price ARR (USD): ' + salesPriceARR);
            System.debug('Total Sales Price ARR (USD): ' + totalSalesPriceARR);

            mapItem.put('DefaultPriceARR', 'USD ' + defaultPriceARR.setScale(2) 
                + ' (EUR ' + (defaultPriceARR / exchangeRate).setScale(2) + ')');
            mapItem.put('SalesPriceARR', 'USD ' + salesPriceARR.setScale(2) 
                + ' (EUR ' + (salesPriceARR / exchangeRate).setScale(2) + ')');
            mapItem.put('TotalSalesPriceARR', 'USD ' + totalSalesPriceARR.setScale(2) 
                + ' (EUR ' + (totalSalesPriceARR / exchangeRate).setScale(2) + ')');

            mapItem.put('PriceChange', item.Price_Change__c);
            mapItem.put('RecurringDiscount', item.Recurring_Discount__c);
            mapItem.put('Description', item.Description);
            mapItem.put('ForRenewal', item.For_Renewal__c);
            mapItem.put('PartOfAPackage', item.Part_of_a_package__c);
            serializedItems.add(mapItem);
        }
        return serializedItems;
    }
}