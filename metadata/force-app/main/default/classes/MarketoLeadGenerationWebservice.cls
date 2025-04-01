/* 
* - Site name:          https://full-bynder.cs14.force.com/
* - Relative endpoint:  /services/apexrest/<urlMapping>
*/
public class MarketoLeadGenerationWebservice {
      public MarketoLeadGenerationWebservice (){}
    // Class deprecated. No longer in use.

/* @RestResource(urlMapping='/createlead/*')
global class MarketoLeadGenerationWebservice {
    @HttpGet
    global static void doGet(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        String resBody = '';
        try{
            String firstname = req.params.get('firstname');
            String lastname = req.params.get('lastname'); 
            String email = req.params.get('email');
            String company = req.params.get('company');
            String jobtitle = req.params.get('jobtitle');
            String state = req.params.get('state');
            String country = req.params.get('country');
            
            insert new Lead(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                Company = company,
                Title = jobtitle,
                Marketo_State_Value__c = state,
                Inferred_Country__c = country,
                Status = 'Open',
                LeadSource = '',
                CurrencyIsoCode = 'USD'            );
            res.statusCode = 200;
            resBody = '{"success": true}';
        }catch (Exception e){
            res.statusCode = 500;
            resBody = '{"success": false,"Exception:": '+e+'}';
            System.debug('Exception: '+e);
        }
        res.responseBody = Blob.valueOf(resBody);
    }
    

} */
}