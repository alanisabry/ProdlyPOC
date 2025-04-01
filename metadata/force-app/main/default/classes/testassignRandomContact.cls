@isTest

public class testassignRandomContact {
    @isTest static void createContact() {
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
        
        Contact c = new Contact();
        c.AccountId = acc.Id;
        c.LastName = 'Test';
        insert c;
    }
}