/*
 * ContentDocumentLinkTriggerHandlerTest.cls
 * 
 * Created By: OpFocus
 * Created On: Jan 18, 2021
 */
@isTest
public class ContentDocumentLinkTriggerHandlerTest {

    @isTest
    private static void createLinkOnAccountTest() {

        // Create a test account for the opp
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        // Now create the test opp
        Opportunity testOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Qualified'
        );
        insert testOpp;

        // Insert a document and link it to the opp (The trigger should automatically link it to the Account too)
        ContentDocument doc = ContentDocumentTriggerHandlerTest.createContentDocument('Hello World');
        Test.startTest();
        insert new ContentDocumentLink(
            ContentDocumentId = doc.Id,
            LinkedEntityId = testOpp.Id
        );
        Test.stopTest();

        // Pull in content document links for the account and validate we have one
        List<ContentDocumentLink> accountDocLinks = [
            SELECT
                ContentDocumentId,
                LinkedEntityId
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId = :testAccount.Id
        ];
        System.assertEquals(1, accountDocLinks.size(), 'Only expected a single document link from Account to our test ContentDocument');
        System.assertEquals(doc.Id, accountDocLinks[0].ContentDocumentId, 'Linked document does not match our test ContentDocument');
    }
}