trigger pushOpportunityToJira on Opportunity (after update) {
    List<Opportunity> toBePushedToJira = new List<Opportunity>();
    for(Opportunity op : Trigger.new){
        if(string.isNotBlank(op.Jira_Issue__c)){
            toBePushedToJira.add(op);
        }
    }
    if(toBePushedToJira !=null && toBePushedToJira.size()>0 && !System.IsBatch() && !System.isFuture()){
        JCFS.API.pushUpdatesToJira(toBePushedToJira, Trigger.old);   
    }
}