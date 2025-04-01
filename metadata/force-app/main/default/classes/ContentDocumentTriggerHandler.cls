/*
 * ContentDocumentTriggerHandler.cls
 * Upon insert of any new files, automatically assigns the "File Collaborators"
 * public group as a collaborator on the file.
 * 
 * Created By: OpFocus
 * Created On: Jan 18, 2021
 */
public class ContentDocumentTriggerHandler extends TriggerHandler {

    // Name of the "File Collaborators" Chatter group
    @TestVisible private static final String FILE_COLLABORATORS_NAME = 'File Collaborators';

    /*
        Retrieves the Id of the File Collaborators Chatter group
        - creates the group if it doesn't already exist
    */
    public static Id FILE_COLLABORATORS_GROUP_ID {
        get {
            // Return cached Id
            if (FILE_COLLABORATORS_GROUP_ID != null) {
                return FILE_COLLABORATORS_GROUP_ID;
            }

            // For unit tests - we create a new test-context group
            String groupName = (Test.isRunningTest() ? ContentDocumentTriggerHandlerTest.FILE_COLLABORATORS_TEST_NAME : FILE_COLLABORATORS_NAME);

            // Attempt to retrieve the chatter group first
            List<CollaborationGroup> groupList = [
                SELECT
                    Id
                FROM
                    CollaborationGroup
                WHERE
                    Name = :groupName
            ];
            if (!groupList.isEmpty()) {
                FILE_COLLABORATORS_GROUP_ID = groupList[0].Id;
                return groupList[0].Id;
            }

            // No group found, create one
            CollaborationGroup fileCollaborators = new CollaborationGroup(
                Name                = groupName,
                CollaborationType   = 'Private'
            );
            insert fileCollaborators;
            FILE_COLLABORATORS_GROUP_ID = fileCollaborators.Id;
            return fileCollaborators.Id;
        }
        private set;
    }

    /*
        Called after any insert operation
    */
    protected override void afterInsert() {
        createCollaborationLinksFuture(new List<Id>(Trigger.newMap.keySet()));
    }

    /*
        To avoid CROSS_REFERENCE_KEY errors, this must be run in
        future context.
    */
    @Future
    private static void createCollaborationLinksFuture(List<Id> contentDocumentIds) {

        // For each new file, automatically create a ContentDocumentLink to the group
        List<ContentDocumentLink> groupLinks = new List<ContentDocumentLink>();
        for (Id docId : contentDocumentIds) {
            groupLinks.add(new ContentDocumentLink(
                ContentDocumentId   = docId,
                LinkedEntityId      = FILE_COLLABORATORS_GROUP_ID,
                ShareType           = 'C'   // Collaborator Permissions (View/Edit)
            ));
        }
        insert groupLinks;
    }
}