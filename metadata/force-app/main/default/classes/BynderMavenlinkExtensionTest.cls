/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
public class BynderMavenlinkExtensionTest {
    
     //public static Account sAcc = null;
     //public static Opportunity sOpp = null;
     //public static mavenlink__Mavenlink_Project__c sProject = null;
    
    /*@isTest public static Account seedAccount(){
        Account seedAcc = new Account(
                name='Test Account',
                BillingCity='Boston');
        insert seedAcc;
    return seedAcc;        
    }*/
    
    /*@isTest public static Opportunity seedOpportunity(){
            Opportunity seedOpp = new Opportunity(
            name = 'opp',
            AccountId = sAcc.id,
            stageName = 'Closed Won', //Internal Testing 
            Probability = 50,
            Amount = 100000,
            closeDate = Date.today() 
            );
            insert seedOpp;
        
        return seedOpp;        
    }*/
    
   	/*@isTest public static mavenlink__Mavenlink_Project__c seedOppProject(){
        mavenlink__Mavenlink_Project__c oppProject = null;
        try{
            oppProject = new mavenlink__Mavenlink_Project__c(
                Name = 'Test Opp Project',
                mavenlink__Project_Title__c = 'Test Opp Project',
                mavenlink__Account__c = sAcc.id,
                mavenlink__Opportunity__c = sOpp.Id,
                mavenlink__Automatically_Created__c = true,
                mavenlink__Project_Type__c = 'Execution',
                mavenlink__Object_Type__c = 'Opportunity',
                mavenlink__Mavenlink_Id__c = '20014595');
            insert oppProject;
        }catch(Exception e){}
    return oppProject;        
    }*/
    
    /*@isTest public static void seedAfterProjectChain(){
      //TestFactory.disableTriggers();
        sAcc = seedAccount();
        sOpp = seedOpportunity();
        sProject = seedOppProject();
    
    }*/
    
    @isTest public static void executeAfterProjectChain(){
        
        Account seedAcc = new Account(
                name='Test Account',
                BillingCity='Boston');
        insert seedAcc;
        
        Opportunity seedOpp = new Opportunity(
            name = 'opp',
            AccountId = seedAcc.id,
            stageName = 'Closed Won', //Internal Testing 
            Probability = 50,
            Amount = 100000,
            closeDate = Date.today() 
            );
            insert seedOpp;
            
        mavenlink__Mavenlink_Project__c oppProject = null;
           oppProject = new mavenlink__Mavenlink_Project__c(
                Name = 'Test Opp Project',
                mavenlink__Project_Title__c = 'Test Opp Project',
                mavenlink__Account__c = seedAcc.id,
                mavenlink__Opportunity__c = seedOpp.Id,
                mavenlink__Automatically_Created__c = true,
                mavenlink__Project_Type__c = 'Execution',
                mavenlink__Object_Type__c = 'Opportunity',
                mavenlink__Mavenlink_Id__c = '20014595');
            insert oppProject;
        
        //seedAfterProjectChain();
        
        Test.startTest();

        mavenlink.MavenlinkExtensionPointData inputData = new mavenlink.MavenlinkExtensionPointData();
        inputData.putData('Project Type','Execution');
        inputData.putData('Object Type','Opportunity');
        
        List<Id> objectIds = new List<Id>();
        objectIds.add(seedAcc.Id);
        objectIds.add(seedOpp.Id);
        objectIds.add(oppProject.Id); 
        
        seedOpp.Amount = 100;
        update seedOpp;
        
        //Unique match
        mavenlink.MavenlinkExtensionPointState inputState = new mavenlink.MavenlinkExtensionPointState('AfterProjectChain','TestClass','TestMethod');
        Object obj = BynderMavenlinkExtension.execute(inputState,inputData,objectIds);
        
        seedOpp.StageName='Won';
        update seedOpp;
        obj = BynderMavenlinkExtension.execute(inputState,inputData,objectIds);
        
        seedOpp.Amount = 200;
        update seedOpp;
        inputState = new mavenlink.MavenlinkExtensionPointState('UpdateProject','TestClass','TestMethod');
        obj = BynderMavenlinkExtension.execute(inputState,inputData,objectIds);
        inputState = new mavenlink.MavenlinkExtensionPointState('AfterProjectChain','TestClass','TestMethod');
        obj = BynderMavenlinkExtension.execute(inputState,inputData,objectIds);
        Test.stopTest();
    }
    
}