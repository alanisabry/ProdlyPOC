public class CurrencyTypeService {
     private static final String API_VERSION = 'v59.0';
    
    // Method to update CurrencyType
    @future(callout=true)
    public static void updateCurrencyType(String currencyIsoCode, Decimal conversionRate) {
        try {
            String orgUrl = URL.getOrgDomainUrl().toExternalForm();
            String endpoint = orgUrl + '/services/data/' + API_VERSION + '/sobjects/CurrencyType/' + currencyIsoCode;
            

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('PATCH');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            req.setBody('{"ConversionRate": ' + conversionRate + '}');

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('CurrencyType Update - Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Error updating CurrencyType: ' + e.getMessage());
        }
    }

    // Method to create DatedConversionRate
    @future(callout=true)
    public static void createDatedConversionRate(String currencyIsoCode, Decimal conversionRate, Date startDate) {
        try {
            String orgUrl = URL.getOrgDomainUrl().toExternalForm();
            String endpoint = orgUrl + '/services/data/' + API_VERSION + '/sobjects/DatedConversionRate/';

            // Convert date to YYYY-MM-DD
            //String formattedDate = startDate.format();
			String formattedDate = String.valueOf(startDate.year()) + '-' + 
                           (startDate.month() < 10 ? '0' + String.valueOf(startDate.month()) : String.valueOf(startDate.month())) + '-' + 
                           (startDate.day() < 10 ? '0' + String.valueOf(startDate.day()) : String.valueOf(startDate.day()));

            String requestBody = JSON.serialize(new Map<String, Object>{
        						'IsoCode' => currencyIsoCode,
                                'ConversionRate' => conversionRate,
                                'StartDate' => formattedDate
                            });

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('DatedConversionRate Creation - Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Error creating DatedConversionRate: ' + e.getMessage());
        }
    }
}