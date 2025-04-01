trigger assignRandomAccount on Account (before insert, before update) {
    for (Account acc : Trigger.new) {
        if (acc.abRandom__c    == NULL) {
            acc.abRandom__c    = ((Math.random() * (100-1) + 1));
            acc.abRandom__c    = acc.abRandom__c    .setscale(0);
            }
    }
}