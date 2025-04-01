trigger pushAccountToJira on Account (after update) {
    List<Account> toBePushedToJira = new List<Account>();
    for(Account acc : Trigger.new){
        if(string.isNotBlank(acc.Jira_Issue__c)){
            toBePushedToJira.add(acc);
        }
    }
    if(toBePushedToJira !=null && toBePushedToJira.size()>0 && !System.IsBatch() && !System.isFuture()){
        JCFS.API.pushUpdatesToJira(toBePushedToJira, Trigger.old);
    }
}