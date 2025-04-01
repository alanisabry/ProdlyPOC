trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert, after insert, before update, after update, before delete, after delete) {
    new ContentDocumentLinkTriggerHandler().run();
}