/* 
* - Site name:          https://full-bynder.cs14.force.com/
* - Relative endpoint:  /services/apexrest/<urlMapping>
*/
public class MarketoLeadUpdateWebservice {
    public MarketoLeadUpdateWebservice (){}
    // Class deprecated. No longer in use.
/* @RestResource(urlMapping='/updatelead/*')
global class MarketoLeadUpdateWebservice {
    
    @HttpGet
    global static void doGet(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        String resBody = '';
        try{
            ID leadId = req.params.get('lead_id');
            
            List<Lead> l = [SELECT Industry,Lead_Scoring__c, Lead_Source_Description__c,Lead_Source_Detailed__c,Most_Recent_Source_Description__c,Inferred_Postal_Code__c,LeadSource,
                     Most_Recent_Source_Detailed__c,Most_Recent_Source__c,Number_of_Employees__c,Original_Lead_Source__c,Original_Referrer__c,Industry_from_Form__c,Industry_from_G2Crowd__c,
                     Original_Source_Type__c,Phone,Inferred_State_Region__c,Marketo_State_Value__c,Inferred_Country__c,Lead_Score__c ,Original_Search_Phrase__c FROM LEAD WHERE id=:leadId LIMIT 1];
            
            if(l.size()>0){
            l[0].Industry = req.params.get('industry');
            l[0].Industry_from_G2Crowd__c = req.params.get('Industry_from_Form'); 
            l[0].Industry_from_Form__c = req.params.get('Industry_from_G2Crowd');
            l[0].Original_Search_Phrase__c = req.params.get('Original_Search_Phrase');
            l[0].Lead_Score__c = Decimal.valueOf(req.params.get('leadScore'));
            l[0].LeadSource= req.params.get('leadSource');
            l[0].Lead_Source_Description__c = req.params.get('Lead_Source_Description');
            l[0].Lead_Source_Detailed__c = req.params.get('Lead_Source_Detailed');
            l[0].Most_Recent_Source_Description__c = req.params.get('Most_Recent_Source_Description');
            l[0].Most_Recent_Source_Detailed__c = req.params.get('Most_Recent_Source_Detailed');
            l[0].Most_Recent_Source__c = req.params.get('Most_Recent_Source');
            //String Most_Recent_Source_contact = req.params.get('Most_Recent_Source_contact');
            l[0].Number_of_Employees__c = req.params.get('numberOfEmployees');
            l[0].Original_Lead_Source__c = req.params.get('Original_Lead_Source');
            l[0].Original_Referrer__c = req.params.get('Original_Referrer');
            l[0].Original_Source_Type__c = req.params.get('Original_Source_Type');
            l[0].Phone = req.params.get('phone');
            l[0].Inferred_Postal_Code__c= req.params.get('statecode');
            l[0].Inferred_Country__c = req.params.get('country');
            l[0].Inferred_State_Region__c = req.params.get('inferredStateRegion');

            update l;
            res.statusCode = 200;
            resBody = '{"success": true}';
            }

        }catch (Exception e){
            res.statusCode = 500;
            resBody = '{"success": false,"Exception:": '+e+'}';
            System.debug('Exception: '+e);
        }
        res.responseBody = Blob.valueOf(resBody);
    }
    
}*/}