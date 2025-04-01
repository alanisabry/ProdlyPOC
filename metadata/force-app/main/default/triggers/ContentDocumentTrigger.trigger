trigger ContentDocumentTrigger on ContentDocument (before insert, after insert, before update, after update, before delete, after delete) {
    new ContentDocumentTriggerHandler().run();
}