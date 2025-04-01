public without sharing class SPGUtillity {
    public static List<Object_Info_Setting__mdt> getObjectInfoSettings(String objectName, String recordTypeName){
        List<Object_Info_Setting__mdt> objectInfoSettings = new List<Object_Info_Setting__mdt>();
        // SOQL query is used to fetch metadata records as the getAll().Values() returns only the first 255 characters are returned for any field in a custom metadata type record, so longer text fields get truncated.
        for(Object_Info_Setting__mdt ois: [Select Id,DeveloperName,MasterLabel,Display_Columns__c,Fields__c,Record_Type__c,Section__c,Target_Object__c from Object_Info_Setting__mdt]){
        System.debug('Obj Metadata:'+ois);
            if(String.isBlank(objectName) || (ois.Target_Object__c == objectName && ois.Record_Type__c == recordTypeName)){
                objectInfoSettings.add(ois);
            }
        }
        System.debug('Obj Metadata List:'+objectInfoSettings);
        return objectInfoSettings;
    }
}