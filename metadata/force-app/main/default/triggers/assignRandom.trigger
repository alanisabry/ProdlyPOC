trigger assignRandom on Lead (before insert, before update) {
    for (Lead lead : Trigger.new) {
        if (lead.abRandom__c    == NULL) {
            lead.abRandom__c    = ( (Math.random() * (100-1) + 1));
            lead.abRandom__c    = lead.abRandom__c    .setscale(0);
            }
    }
}