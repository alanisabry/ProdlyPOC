public class FW_Helpers {

    /*************************************************************************
     JSON                                                              
    **************************************************************************/

    /*
        Remove all null properties from JSON
    */
    public static String stripNulls(String inputJson, Boolean pretty) {
        
        JSONParser parser = JSON.createParser(inputJson);
        JSONGenerator generator = JSON.createGenerator(pretty);

        JSONToken nextToken = parser.nextToken();

        while (nextToken != null) {

            if (nextToken == JSONToken.FIELD_NAME) {

                nextToken = parser.nextToken();
                if (nextToken == JSONToken.VALUE_NULL)
                    continue;
                else
                    generator.writeFieldName(parser.getCurrentName());
            }
            
            if (nextToken == JSONToken.START_OBJECT)
                generator.writeStartObject();
            else if (nextToken == JSONToken.END_OBJECT)
                generator.writeEndObject();
            else if (nextToken == JSONToken.START_ARRAY)
                generator.writeStartArray();
            else if (nextToken == JSONToken.END_ARRAY)
                generator.writeEndArray();
            else if (nextToken == JSONToken.VALUE_TRUE)
                generator.writeBoolean(true);
            else if (nextToken == JSONToken.VALUE_FALSE)
                generator.writeBoolean(false);
            else if (nextToken == JSONToken.VALUE_STRING)
                generator.writeString(parser.getText());	
            else if (nextToken == JSONToken.VALUE_NUMBER_INT)
                generator.writeNumber(parser.getIntegerValue());	
            else if (nextToken == JSONToken.VALUE_NUMBER_FLOAT)
                generator.writeNumber(parser.getDecimalValue());

            nextToken = parser.nextToken();
        }

        return generator.getAsString();
    }

    /*
        Serialize pretty but strip nulls.
    */
    public static String serializePretty(Object objectToSerialize) {
        return stripNulls(JSON.serialize(objectToSerialize), true);		
    }

    /*
        Serialize but strip nulls.
    */
    public static String serialize(Object objectToSerialize) {
        return JSON.serialize(objectToSerialize, true);
    }

    /*************************************************************************
     Exceptions                                                              
    **************************************************************************/

    /*
        Exception to throw specific to an entity that was not found.
    */
    public class NotFoundException extends FW_Exception {
    }

    /*
        Exception to throw specific to an failure to have a required permission.
    */
    public class PrivilegeException extends FW_Exception {
    }

    /*
        Serializable System.Exception
    */
    public class ExceptionSerializable {

        //Transient stops serialization, exception cannot be serialized which is purpose of this wrapper class.
        private transient System.Exception wrappedException;

        public Integer lineNumber {get {return wrappedException.getLineNumber();}}
        public String stackTraceString {get {return wrappedException.getStackTraceString();}}
        public String typeName {get {return wrappedException.getTypeName();}}
        public ExceptionSerializable cause {get {return wrappedException.getCause() == null ? null : new ExceptionSerializable(wrappedException.getCause());}}

        public String message {
            get {

                if (wrappedException instanceof System.DmlException) {
                    System.DmlException dmlException = (System.DmlException)wrappedException;
                    if (dmlException.getDmlType(0) == System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
                        return dmlException.getDmlMessage(0);
                    }
                    else {
                        return wrappedException.getMessage();
                    }
                }

                return wrappedException.getMessage();

            }
        }

        public Boolean isUserException {
            get {
                if (wrappedException instanceof FW_Exception) {
                    return ((FW_Exception)wrappedException).isUserException;
                }
                else if (wrappedException instanceof System.DmlException) {
                    System.DmlException dmlException = (System.DmlException)wrappedException;
                    if (dmlException.getDmlType(0) == System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
                        return true;
                    }
                    else {
                        return false;
                    }
                }
                else {
                    return false;
                }
            }
        }

        public String details {
            get {

                if (this.wrappedException instanceof FW_Exception) {
                    return ((FW_Exception)this.wrappedException).details;
                }
                else {
                    return '';
                }

            }
        }

        public ExceptionSerializable(System.Exception e) {
            this.wrappedException = e;
        }

    }

    /*
        Construct AuraHandledException having all info from the exception
    */
    public static System.Exception newAuraHandledException(System.Exception e) {

        //If in a test, just throw the actual exception so it comes through in unit test stacktrace.
        if (Test.isRunningTest()) {
            throw e;
        }
        else {
            return new AuraHandledException(JSON.serialize(new ExceptionSerializable(e)));
        }
    }

}