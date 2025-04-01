@IsTest
public class SPGUtillityTest {
    @IsTest
    static void getObjectInfoSettings(){
        Schema.DescribeSObjectResult[] accountResult = Schema.describeSObjects(new String[]{'Account'});
        Map<String, Schema.RecordTypeInfo> accountRecordTypeInfo = accountResult[0].getRecordTypeInfosByDeveloperName();

        Schema.DescribeSObjectResult[] opportunityResult = Schema.describeSObjects(new String[]{'Account'});
        Map<String, Schema.RecordTypeInfo> opportunityRecordTypeInfo = opportunityResult[0].getRecordTypeInfosByDeveloperName();
        Test.startTest();
        
        List<Object_Info_Setting__mdt> accountSettings = SPGUtillity.getObjectInfoSettings('Account', accountRecordTypeInfo.values().get(0).getDeveloperName());

        List<Object_Info_Setting__mdt> opportunitySettings = SPGUtillity.getObjectInfoSettings('Opportunity', opportunityRecordTypeInfo.values().get(0).getDeveloperName());

        Test.stopTest();
    }
}