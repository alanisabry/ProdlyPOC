trigger assignRandomContact on Contact (before insert, before update) {
    for (Contact c : Trigger.new) {
        if (c.abRandom__c == NULL) {
            c.abRandom__c = ( (Math.random() * (100-1) + 1));
            c.abRandom__c = c.abRandom__c    .setscale(0);
        }
    }
}