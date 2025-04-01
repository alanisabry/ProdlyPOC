@IsTest
public with sharing class SPGAccountControllerTest {

    @IsTest
    private static void getModel() {
        Account account = new Account(Name = 'Unit Test Account Controller');
        insert account;

        Test.startTest();
        SPGAccountController.Model model = new SPGAccountController.Model();
        model = SPGAccountController.getModel(account.Id);
        Test.stopTest();

        System.assert(model != null, 'Expected class to be initialized.');
        System.assertEquals(account.Id, model.accountId, 'Expected values to match.');
    }
}