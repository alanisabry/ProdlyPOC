global class BynderMavenlinkExtension implements mavenlink.MavenlinkExtensionPoint {
    
    private static string c = 'BynderMavenlinkExtension';
    //Method executed from within Mavenlink for SalesForce
    global static Object execute(
                mavenlink.MavenlinkExtensionPointState inputState,
                mavenlink.MavenlinkExtensionPointData inputData,
                List<Id> objectIds) 
    {
        String m='execute';
        
        //Get the extension point type, project type, and object type from input data
        String extensionPointType = inputState.getExtensionPointType();
        String projectType = (String)inputData.getData('Project Type');
        String objectType = (String)inputData.getData('Object Type'); 
        
        mavenlink.MavenlinkLogExternal.Write(c,m,'Reached with extensionPointType='+extensionPointType);
        
        //Based on extension point type, call the appropriate method
        if (extensionPointType=='AfterProjectChain'){
            Boolean afterProjectChain = AfterProjectChain(objectType,projectType,objectIds);
            return afterProjectChain;
        }
        else return null; 
    }
    
    
    private static Boolean AfterProjectChain(String objectType,String projectType,List<Id> objectIds)
    {
            
            
            String m = 'AfterProjectChain';
            
            try{
                
                mavenlink.MavenlinkLogExternal.Write(c,m,'Reached AfterProjectChain for objectType='+objectType);
                
                //Id oppId = mavenlink.MavenlinkExternalExtensionPointHelper.getIdofType(objectIds,'Opportunity');
                //mavenlink.MavenlinkLogExternal.Write(c,m,'oppId='+oppId);
                
                                    
                Id projId = mavenlink.MavenlinkExternalExtensionPointHelper.getIdofType(objectIds,'mavenlink__Mavenlink_Project__c');
                //mavenlink.MavenlinkLogExternal.Write(c,m,'projId='+projId);
                mavenlink__Mavenlink_Project__c MLProj = [select mavenlink__Mavenlink_Id__c,Milestone_weight_complete__c from mavenlink__Mavenlink_Project__c where Id=:projId];
                
                String workspace_id = MLProj.mavenlink__Mavenlink_Id__c;
                Integer mlPercent = getMLPercentComplete(workspace_id);
                //Integer mlPercent = 80;
               
                //Disable the trigger before updating the Project Object
                    mavenlink.MavenlinkExternal.disableProjectTrigger();
                    MLProj.Milestone_weight_complete__c = mlPercent;
                    update MLProj;
                    mavenlink.MavenlinkExternal.enableProjectTrigger();
                
                
            } 
            catch(Exception e){
                    mavenlink.MavenlinkLogExternal.Write(c,m,'Error caught '+e.getMessage());
            }
            
            
            return false;
            
    }
    
    private static Integer getMLPercentComplete(String worskpaceId){
            String m = 'getMLPercentComplete';
            Map<String,Object> apiJSON = new Map<String,Object>();
            
            Integer totalCount=0;
            Integer totalPages=0;
            Integer mlWeight=0; 
            Integer mlWeightTemp=0; 
            
            if (!Test.isRunningTest()){
                apiJSON = mavenlink.MavenlinkExternalAPI.callAPI('/stories.json?workspace_id='+worskpaceId+'&parents_only=true&per_page=1&story_type=milestone&by_status=completed','GET',null);
            
                totalCount=Integer.valueOf(apiJSON.get('count'));
            }
                //mavenlink.MavenlinkLogExternal.Write(c,m,'Total count='+totalCount);
                totalPages=(totalCount/200)+1;
            
                //mavenlink.MavenlinkLogExternal.Write(c,m,'Total Pages='+totalPages);
                
                for(Integer j=1;j<=totalPages;j++){ //1
                    if (!Test.isRunningTest()){
                        apiJSON = mavenlink.MavenlinkExternalAPI.callAPI('/stories.json?workspace_id='+worskpaceId+'&parents_only=true&story_type=milestone&by_status=completed&per_page=200','GET',null);
                    
                        Map<String,Object> storiesJSON = (Map<String,Object>)apiJSON.get('stories');
                    
                    
                        for(Object key:storiesJSON.keySet()){ //2
                            Map<String,Object> taskidJSON = (Map<String,Object>)storiesJSON.get((String)key);
                            
                            mlWeightTemp =  (Integer)taskidJSON.get('weight');
                            //mavenlink.MavenlinkLogExternal.Write(c,m,'mlWeightTemp='+mlWeightTemp);
                            if  (mlWeightTemp != null) {
                               mlWeight = mlWeight + mlWeightTemp;
                            }
                            //mavenlink.MavenlinkLogExternal.Write(c,m,'mlWeight='+mlWeight);
                            
                        }
                      }
                    }
                
        
        return mlWeight;
    }
    
}