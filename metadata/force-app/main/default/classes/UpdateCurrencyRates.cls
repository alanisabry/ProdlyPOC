public class UpdateCurrencyRates implements Queueable, Database.AllowsCallouts {
    private List<String> currencyCodes;

    public UpdateCurrencyRates(List<String> currencyCodes) {
        this.currencyCodes = new List<String>(new Set<String>(currencyCodes)); // Ensure uniqueness
    }

    public void execute(QueueableContext context) {
        Map<String, Decimal> latestRates = new Map<String, Decimal>();
        Map<String, Decimal> latestDatedRates = new Map<String, Decimal>();
        
        // Query the CurrencyType Id based on the IsoCode
        CurrencyType currency_type = [SELECT Id FROM CurrencyType WHERE IsoCode = : currencyCodes[0] LIMIT 1];

        // Fetch latest exchange rates
        for (Custom_Exchange_Rates__c rate : [
            SELECT CurrencyIsoCode, Conversion_Rate__c FROM Custom_Exchange_Rates__c 
            WHERE CurrencyIsoCode IN :currencyCodes
        ]) {
            latestRates.put(currency_type.Id, rate.Conversion_Rate__c);
            latestDatedRates.put(rate.CurrencyIsoCode, rate.Conversion_Rate__c);
        }

        // Update CurrencyType via REST API
        for (String isoCode : latestRates.keySet()) {
            CurrencyTypeService.updateCurrencyType(isoCode, latestRates.get(isoCode));
        }

        // Create DatedConversionRate via REST API
        for (String isoCode : latestDatedRates.keySet()) {
            CurrencyTypeService.createDatedConversionRate(isoCode, latestDatedRates.get(isoCode), Date.today());
        }
    }
}