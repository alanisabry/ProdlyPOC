@isTest

public class LossReasonEnteredTest {
    @isTest static void UpdateLossReason() {
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Website = 'http://test.com';
        acc.CurrencyIsoCode = 'EUR';
        acc.Type = 'Prospect';
        acc.RecordTypeId = '0120P000000asyz';
        acc.BillingCountry = 'Austria';
        acc.Industry_Group__c = 'Consumer Brands';
        acc.Company_Size_New__c = 'SMB';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity name';
        opp.Type = 'New Business-Enterprise Cloud';
        opp.AccountId = acc.Id;
        opp.Next_Steps_History__c = 'Sell the product';
        opp.CloseDate = date.Today() + 90;
        opp.StageName = 'Qualified';
        opp.Sales_Office__c = 'Amsterdam';
        opp.CurrencyIsoCode = 'EUR';
        opp.Source__c = 'Outbound Sales';
        opp.RecordTypeId = '0120P000000QxSt';
        insert opp;
        
        opp.Loss_Reason_Detail__c = 'Test';
        update opp;
    }
}