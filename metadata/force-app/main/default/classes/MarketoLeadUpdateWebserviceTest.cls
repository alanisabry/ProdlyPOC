@isTest
public class MarketoLeadUpdateWebserviceTest {

    @isTest
    public static void runPositiveTest(){
        MarketoLeadUpdateWebservice deprecated = new MarketoLeadUpdateWebservice();
        /* Lead l = new Lead(firstname='test',lastname='test',Status='Marketing 1: Not assessed',Company='test',LeadSource='hj',Inferred_Postal_Code__c='23',Most_Recent_Source_Detailed__c='test',Most_Recent_Source__c='test',Lead_Source_Description__c='test',Industry='Chemical and Energy and Agriculture',Lead_Source_Detailed__c='HOW Design Live 2014',Most_Recent_Source_Description__c='test',Number_of_Employees__c='12',Original_Lead_Source__c='test',Original_Referrer__c='wtest',Industry_from_Form__c='t', Industry_from_G2Crowd__c='test',Original_Source_Type__c='test',Other_Phone__c='test',Inferred_State_Region__c='test',Marketo_State_Value__c='test',Inferred_Country__c='test',Lead_Score__c=4,Phone='2333',Original_Search_Phrase__c='df');
        insert l;
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestUri = '/services/apexrest/updatelead';
        req.httpMethod = 'GET';
        req.addParameter('lead_id', l.id);
        req.addParameter('industry', l.Industry);
        req.addParameter('Industry_from_G2Crowd', l.Industry_from_Form__c);
        req.addParameter('Industry_from_Form', l.Industry_from_G2Crowd__c);
        req.addParameter('Lead_Source_Description', l.Lead_Source_Description__c);
        req.addParameter('LeadSource', l.LeadSource);
        req.addParameter('Lead_Source_Detailed', l.Lead_Source_Detailed__c);
        req.addParameter('Most_Recent_Source_Description', l.Most_Recent_Source_Description__c);
        req.addParameter('numberOfEmployees', l.Number_of_Employees__c);
        req.addParameter('Original_Lead_Source', l.Original_Lead_Source__c);
        req.addParameter('phone', l.Phone);
        req.addParameter('inferredStateRegion', l.Inferred_State_Region__c);
        req.addParameter('statecode', l.Inferred_Postal_Code__c);
        req.addParameter('country', l.Inferred_Country__c);
        req.addParameter('Original_Search_Phrase', l.Original_Search_Phrase__c);
        req.addParameter('leadScore', String.valueOf(l.Lead_Score__c));
        req.addParameter('Most_Recent_Source_Detailed', l.Most_Recent_Source_Detailed__c);
        req.addParameter('Most_Recent_Source', l.Most_Recent_Source__c);
        req.addParameter('Original_Referrer', l.Original_Referrer__c);
        req.addParameter('Original_Source_Type', l.Original_Source_Type__c);

        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        MarketoLeadUpdateWebservice.doGet();
        Test.stopTest(); */
    }
    /*
    @isTest
    public static void runNegativeTest(){
                
        Lead l = new Lead(firstname='test',lastname='test',Status='Marketing 1: Not assessed',Company='test',LeadSource='hj',Inferred_Postal_Code__c='23',Most_Recent_Source_Detailed__c='test',Most_Recent_Source__c='test',Lead_Source_Description__c='test',Industry='Chemical and Energy and Agriculture',Lead_Source_Detailed__c='HOW Design Live 2014',Most_Recent_Source_Description__c='test',Number_of_Employees__c='12',Original_Lead_Source__c='test',Original_Referrer__c='wtest',Industry_from_Form__c='t', Industry_from_G2Crowd__c='test',Original_Source_Type__c='test',Other_Phone__c='test',Inferred_State_Region__c='test',Marketo_State_Value__c='test',Inferred_Country__c='test',Lead_Score__c=4,Phone='2333',Original_Search_Phrase__c='df');
        insert l;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.addParameter('lead_id', l.id+'d');
        req.requestUri = '/services/apexrest/updatelead';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        MarketoLeadUpdateWebservice.doGet();
        Test.stopTest();
    }*/
}