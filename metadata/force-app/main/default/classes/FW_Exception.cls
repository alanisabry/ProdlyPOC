/*
    For throwing custom exceptions.
*/
public with sharing virtual class FW_Exception extends System.Exception {

    //Indicates exception is directed towards end-user.
    public Boolean isUserException;

    //Stack and other technical details.
    public String details;

    public FW_Exception(String message, Boolean isUserException) {
        this.setMessage(message);
        this.isUserException = isUserException;
    }

    public FW_Exception(String message, Boolean isUserException, String details) {
        this.setMessage(message);
        this.isUserException = isUserException;
        this.details = details;
    }
}