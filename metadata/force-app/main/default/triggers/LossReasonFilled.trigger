trigger LossReasonFilled on Opportunity (before update) {
    for (Opportunity opp : Trigger.new) {
        if (opp.Loss_Reason_Detail__c != null & opp.Loss_Reason_Entered__c == False) {
            opp.Loss_Reason_Entered__c = True;
        }
    }
}