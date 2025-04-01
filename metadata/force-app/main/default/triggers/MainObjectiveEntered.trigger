trigger MainObjectiveEntered on Opportunity (before update) {
    for (Opportunity opp : Trigger.new) {
        if ((opp.Main_Objective_1__c != null || opp.Main_Objective_2__c != null
           || opp.Main_Objective_3__c != null) & opp.MainObjectiveEntered__c == False) {
                opp.MainObjectiveEntered__c = True;
            }
    }
}