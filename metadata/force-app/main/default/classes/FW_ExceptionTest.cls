@isTest
public with sharing class FW_ExceptionTest {

    static testmethod void FW_ExceptionTest() {
        FW_Exception fw = new FW_Exception('Test Exception',true);
        FW_Exception fw1 = new FW_Exception('Test Exception',true,'Error occurred');
    }
}