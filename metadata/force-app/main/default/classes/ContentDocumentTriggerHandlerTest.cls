/*
 * ContentDocumentTriggerHandlerTest.cls
 * 
 * Created By: OpFocus
 * Created On: Jan 18, 2021
 */
@isTest
public class ContentDocumentTriggerHandlerTest {

    // Test-class specific group name
    public static String FILE_COLLABORATORS_TEST_NAME = ContentDocumentTriggerHandler.FILE_COLLABORATORS_NAME + ' UNIT_TEST';

    @TestVisible
    private static ContentDocument createContentDocument(String title) {

        // Create the document via ContentVersion
        ContentVersion cv = new ContentVersion(
            Title           = title,
            PathOnClient    = title + '.txt',
            VersionData     = Blob.valueOf(title),
            IsMajorVersion  = true
        );
        insert cv;

        // Return the ContentDocument record via version id
        return [
            SELECT
                Id,
                Title
            FROM
                ContentDocument
            WHERE
                LatestPublishedVersionId = :cv.Id
        ];
    }

    /*
        Ensures that if the File Collaborators chatter group does
        not exist, that our trigger automatically creates it when
        it is referenced.
    */
    @isTest
    private static void createCollaboratorGroupTest() {

        // Attempt to pull in the collab group prior to using our trigger property
        List<CollaborationGroup> groupList = [
            SELECT
                Id
            FROM
                CollaborationGroup
            WHERE
                Name = :FILE_COLLABORATORS_TEST_NAME
        ];
        System.assertEquals(0, groupList.size(), 'There should be no pre-existing chatter groups with name: ' + FILE_COLLABORATORS_TEST_NAME);

        // Use the public property to create the group
        Test.startTest();
        Id collabGroupId = ContentDocumentTriggerHandler.FILE_COLLABORATORS_GROUP_ID;
        Test.stopTest();

        // Re-query and verify the group was created
        groupList = [
            SELECT
                Id
            FROM
                CollaborationGroup
            WHERE
                Name = :FILE_COLLABORATORS_TEST_NAME
        ];
        System.assertEquals(1, groupList.size(), 'The test file collaborators group was not automatically created');

    }

    /*
        Ensures that the Trigger uses the existing File Collaborators
        group if one already has been created.
    */
    @isTest
    private static void useExistingCollaboratorGroupTest() {

        // Create the group manually
        CollaborationGroup collabGroup = new CollaborationGroup(
            Name                = FILE_COLLABORATORS_TEST_NAME,
            CollaborationType   = 'Public'
        );
        insert collabGroup;

        // Now validate that the same Id is returned by the Trigger Property
        System.assertEquals(collabGroup.Id, ContentDocumentTriggerHandler.FILE_COLLABORATORS_GROUP_ID);
    }

    /*
        Validates that all new Files created automatically
        add a link to the Chatter Group "File Collaborators"
    */
    @isTest
    private static void addCollaboratorTest() {

        // Create the document
        Test.startTest();
        ContentDocument doc = createContentDocument('Hello World');
        Test.stopTest();

        // Pull in its Content Links and verify it has one to the group
        List<ContentDocumentLink> docLinks = [
            SELECT
                ContentDocumentId,
                LinkedEntityId
            FROM
                ContentDocumentLink
            WHERE
                ContentDocumentId   = :doc.Id AND
                LinkedEntityId      = :ContentDocumentTriggerHandler.FILE_COLLABORATORS_GROUP_ID
        ];
        System.assertEquals(1, docLinks.size(), 'Expected a content document link to the File Collaborators Chatter group');
    }
}