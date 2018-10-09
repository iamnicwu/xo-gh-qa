/*
  Class used to consume an exception and turn it into an exception record. The object being used to store the exception
  data is "XO Exception"(API Name: XO_Exception__c). This object mimics the exception constructs just in an object
  format. This is purely to turn exceptions into something tangible that can be looked at later especially when dealing
  with asynchronous processes which fail silently outside the view of users or admins.
 */ 
public without sharing class ExceptionUtility {


  /**
   *   Method/function used to consome a general exception with any exception details available about the exception.
   *   "Consumption" means specifically creating a record about the exception and optionally saving this exception into
   *   the database for future view.
   *
   *   @author Scott Yang
   *   @date   Dec/06/2016
   *   @param  {String}          errorName           The current error Name to consume
   *   @param  {String}          errorMsg            The current error to consume
   *   @param  {Boolean}            insertRecord     The boolean parameter used to determine if the method should insert
   *                                                 the exception record or not.
   *   @param  {String}             recordid         The String parameter used to record object id
   *   @return {XO_Exception__c}                     The created exception being returned to the calling source.
   */
  public static XO_Exception__c consumeException(String errorName, String errorMsg, Boolean insertRecord, String recordId) {
      XO_Exception__c newException = new XO_Exception__c();
      newException.Name = Datetime.now().format('MM/dd/yyyy') + ' ' + errorName;
      newException.Message__c = errorMsg;
      newException.Stack_Trace__c = errorMsg;
      newException.Related_Object_Id__c = recordId;
      if(insertRecord) {
        insert newException;
      }

      return newException;
    }

  /**
   *   Method/function used to consome a general exception with any exception details available about the exception.
   *   "Consumption" means specifically creating a record about the exception and optionally saving this exception into
   *   the database for future view.
   *
   *   @author Scott Yang
   *   @date   2016-11-11
   *   @param  {Exception}          currentException The current exception to consume
   *   @param  {Boolean}            insertRecord     The boolean parameter used to determine if the method should insert
   *                                                 the exception record or not.
   *   @param  {String}             recordid         The String parameter used to record object id
   *   @return {XO_Exception__c}                     The created exception being returned to the calling source.
   */
  public static XO_Exception__c consumeException(Exception currentException, Boolean insertRecord, String recordId) {
    XO_Exception__c newException = new XO_Exception__c();
    newException.Name = Datetime.now().format('MM/dd/yyyy') + ' ' + currentException.getTypeName();
    newException.Type__c = currentException.getTypeName();
    newException.Message__c = currentException.getMessage();
    newException.Line_Number__c = currentException.getLineNumber();
    newException.Stack_Trace__c = currentException.getStackTraceString();
    newException.Related_Object_Id__c = recordId;
    if(insertRecord) {
      insert newException;
    }

    return newException;
  }

  /**
   *   Method/function used to consome a general exception with any exception details available about the exception.
   *   "Consumption" means specifically creating a record about the exception and optionally saving this exception into
   *   the database for future view.
   *
   *   @author Justin
   *   @date   2016-05-12
   *   @param  {Exception}          currentException The current exception to consume
   *   @param  {Boolean}            insertRecord     The boolean parameter used to determine if the method should insert
   *                                                 the exception record or not.
   *   @return {XO_Exception__c}                     The created exception being returned to the calling source.
   */
  public static XO_Exception__c consumeException(Exception currentException, Boolean insertRecord) {
    XO_Exception__c newException = new XO_Exception__c();
    newException.Name = Datetime.now().format('MM/dd/yyyy') + ' ' + currentException.getTypeName();
    newException.Type__c = currentException.getTypeName();
    newException.Message__c = currentException.getMessage();
    newException.Line_Number__c = currentException.getLineNumber();
    newException.Stack_Trace__c = currentException.getStackTraceString();

    if(insertRecord) {
      insert newException;
    }

    return newException;
  }

  /**
   *   Method/Function used to consume a single SaveResult from DML messages.
   *
   *   @author Justin
   *   @date   2016-10-19
   *   @param  {Database.SaveResult}          dbSaveResult The SaveResult being used to generate the exception message
   *   @param  {Boolean}          insertRecord             The boolean parameter used to determine if the method should
   *                                                       insert the exception record or not.
   *   @return {XO_Exception__c}                           The created exception being returned to the calling source.
   */
  public static XO_Exception__c consumeException(Database.SaveResult dbSaveResult, Boolean insertRecord) {
    XO_Exception__c newException = new XO_Exception__c();

    if(dbSaveResult.isSuccess()) {
      return null;
    }

    List<Database.Error> currentSaveErrors = dbSaveResult.getErrors();

    String errorMessages = '';
    for(Integer i = 0, length = currentSaveErrors.size(); i < length; i++) {
      errorMessages += currentSaveErrors[i].getFields() + ': ' + currentSaveErrors[i].getMessage() + '\r\n';
    }

    newException = createExceptionRecord(dbSaveResult.getId(), errorMessages, false);

    if(insertRecord) {
      insert newException;
    }

    return newException; 
  }

  public static XO_Exception__c consumeException(Database.SaveResult dbSaveResult, String severity, String failureArea, Boolean insertRecord) {
    XO_Exception__c newException = consumeException(dbSaveResult, false);
    newException.Severity__c = severity;
    newException.Failure_Area__c = failureArea;

    if(insertRecord) {
      insert newException;
    }

    return newException;
  }

  public static List<XO_Exception__c> consumeException(List<SObject> sObjectList, List<Database.SaveResult> dbSaveResult, Boolean insertRecord) {
    List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

    for(Integer i = 0; i < dbSaveResult.size(); i++) {
      Database.SaveResult currentSaveResult = dbSaveResult[i];

      // Nothing to log
      if(currentSaveResult.isSuccess()) {
        continue;
      }

      // Get the current sobject located at the same instance
      SObject currentSObject = sObjectList[i];
      
      XO_Exception__c newException = consumeException(currentSaveResult, false);
      newException.Related_Object_Id__c = (Id)currentSObject.get('Id');

      xoExceptionList.add(newException);
    }

    if(insertRecord) {
      insert xoExceptionList;
    }

    return xoExceptionList;
  }

  public static List<XO_Exception__c> consumeException(List<SObject> sObjectList, List<Database.SaveResult> dbSaveResult, String severity, String failureArea, Boolean insertRecord) {
    List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

    for(Integer i = 0; i < dbSaveResult.size(); i++) {
      Database.SaveResult currentSaveResult = dbSaveResult[i];

      // Nothing to log
      if(currentSaveResult.isSuccess()) {
        continue;
      }

      // Get the current sobject located at the same instance
      SObject currentSObject = sObjectList[i];
      
      XO_Exception__c newException = consumeException(currentSaveResult, false);
      newException.Related_Object_Id__c = (Id)currentSObject.get('Id');
      newException.Severity__c = severity;
      newException.Failure_Area__c = failureArea;

      xoExceptionList.add(newException);
    }

    if(insertRecord) {
      insert xoExceptionList;
    }

    return xoExceptionList;
  }
    
    /**
     *   Method/function used to check if record got saved succesfully or not. If any error occur while saving,
     *   method help's to create exception record and return it to the calling source.
     *
     *   @author Shashish
     *   @date   2016-08-01
     *   @param  {Database.SaveResult}          List of Save Result.
     *   @return {XO_Exception__c}              The created exception being returned to the calling source.
     */
    public static List<XO_Exception__c> consumeException(List<Database.SaveResult> dbSaveResult) {
      List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

      for (Database.SaveResult sr : dbSaveResult) {
        String recordId = sr.getId();
        String errorMsg = '';
            if (!sr.isSuccess()) {
                System.debug(LoggingLevel.INFO, '*** sr: ' + sr);

                // Operation failed, so get all errors
                for(Database.Error err : sr.getErrors()) {
                  errorMsg = errorMsg +''+ err.getFields() +': '+err.getMessage();
                  
                }  
                XO_Exception__c newException = createExceptionRecord(recordId, errorMsg, false);
                xoExceptionList.add(newException);                  
            }
            
      }

      return xoExceptionList;
    }
    
    /**
     *   Method/function used to check if record got deleted succesfully or not. If any error occur while deleting,
     *   method help's to create exception record and return it to the calling source.
     *
     *   @author Shashish
     *   @date   2016-08-01
     *   @param  {Database.DeleteResult}          List of Delete Result.
     *   @return {XO_Exception__c}                The created exception being returned to the calling source.
     */
    public static List<XO_Exception__c> consumeException(List<Database.DeleteResult> dbDeleteResult) {
      List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
      
      for (Database.DeleteResult sr : dbDeleteResult) {
        String recordId = sr.getId();
        String errorMsg = '';
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors
                for(Database.Error err : sr.getErrors()) {
                  errorMsg = errorMsg +''+ err.getFields() +': '+err.getMessage();
                  
                }  
              XO_Exception__c newException = createExceptionRecord(recordId, errorMsg, false);
              xoExceptionList.add(newException);                  
            }
            
      }
      
      return xoExceptionList;
    }

    /**
     *   Method/function used to check if record got upserted succesfully or not. If any error occur while saving,
     *   method help's to create exception record and return it to the calling source.
     *
     *   @author Jonathan Satterfield
     *   @date   2016-09-22
     *   @param  {List<Database.UpsertResult>}
     *   @return {List<XO_Exception__c>}
     */
    public static List<XO_Exception__c> consumeException(List<Database.UpsertResult> dbUpsertResult) {
      List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
      
      for (Database.UpsertResult sr : dbUpsertResult) {
        String recordId = sr.getId();
        String errorMsg = '';
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors
                for(Database.Error err : sr.getErrors()) {
                  errorMsg = errorMsg +''+ err.getFields() +': '+err.getMessage();
                  
                }  
              XO_Exception__c newException = createExceptionRecord(recordId, errorMsg, false);
              xoExceptionList.add(newException);                  
            }
      }
      
      return xoExceptionList;
    }
    
    /**
     *   Method/function used to check if email sent succesfully or not. If any error occur while send email,
     *   method help's to create exception record and return it to the calling source.
     *
     *   @author Shashish
     *   @date   2016-08-01
     *   @param  {Messaging.SendEmailResult}     List for SendEmail Result
     *   @return {XO_Exception__c}               The created exception being returned to the calling source.
     */
    public static List<XO_Exception__c> consumeException(List<Messaging.SendEmailResult> sendEmailResult) {
      List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
      
      for (Messaging.SendEmailResult sr : sendEmailResult) {
        String errorMsg = '';
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors
                for(Database.Error err : sr.getErrors()) {
                  errorMsg = errorMsg +': '+err.getMessage();
                  
                }  
              XO_Exception__c newException = createExceptionRecord('Email Exception', errorMsg, false);
              xoExceptionList.add(newException);                  
            }
            
      }
      
      return xoExceptionList;
    }

    /**
     *   CSP-2905 Notification for Failed Emails
     *   Method used to check if email sent succesfully or not. If past due email error occur while send email,
     *   method help's to create exception record and return it to the calling source.
     *   
     *   @author Mason
     *   @date   2018-05-31
     *   @param  {Messaging.SendEmailResult}  List for SendEmail Result  {String} messagePrefix
     *   @return {XO_Exception__c}     The created exception being returned to the calling source.
     */
    public static List<XO_Exception__c> consumeException(List<Messaging.SendEmailResult> sendEmailResult, String messagePrefix) {
      List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

      for (Messaging.SendEmailResult sr : sendEmailResult) {
        String errorMsg = messagePrefix;
        String targetObjectId = '';
        if (!sr.isSuccess()) {
          // Operation failed, so get all errors
          for(Database.Error err : sr.getErrors()) {
            errorMsg += ': ' + err.getMessage();
          }
          //For get target objectid if GetErrors list is not empty   
          if(!sr.getErrors().isEmpty()) {
             targetObjectId = sr.getErrors()[0].getTargetObjectId();
          }
          XO_Exception__c newException = createExceptionRecord('Email Exception', errorMsg, false);
          newException.Related_Object_Id__c = targetObjectId;
          //Under contact when target object is contact
          if(String.isNotBlank(targetObjectId) && targetObjectId.startsWithIgnoreCase('003')) {
            newException.Contact__c = targetObjectId;
          }
          xoExceptionList.add(newException);                  
        }
      }
      return xoExceptionList;
    }
    
    /**
     *   Method/function used to create the Exception record based on given information (RecordId and Error message) 
     *   and retrun the exception to the calling source.
     *
     *   @author Shashish
     *   @date   2016-08-01
     *   @param  {String}          recordId     The Record Id for which Exception occur.
     *   @param  {String}          errorMsg     The error or reason for Exception.
     *   @param  {Boolean}         insertRecord     The boolean parameter used to determine if the method should insert
     *                                                 the exception record or not.
     *   @return {XO_Exception__c}                  The created exception being returned to the calling source.
     */
    public static XO_Exception__c createExceptionRecord(String recordId, String errorMsg, Boolean insertRecord){
      XO_Exception__c newException = new XO_Exception__c();
      newException.Name = Datetime.now().format('MM/dd/yyyy') + ' ' + recordId;
      newException.Message__c = errorMsg;
      
      if(insertRecord) {
          insert newException;
      }

      return newException;
      
    }

  public static List<XO_Exception__c> consumeException(List<SObject> sObjectList, List<Database.SaveResult> dbSaveResult, String severity, String failureArea, Boolean insertRecord, String fieldName) {
    List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

    for(Integer i = 0; i < dbSaveResult.size(); i++) {
      Database.SaveResult currentSaveResult = dbSaveResult[i];

      // Nothing to log
      if(currentSaveResult.isSuccess()) {
        continue;
      }

      // Get the current sobject located at the same instance
      SObject currentSObject = sObjectList[i];
      
      XO_Exception__c newException = consumeException(currentSaveResult, false);
      newException.Related_Object_Id__c = (Id)currentSObject.get(fieldName);
      newException.Severity__c = severity;
      newException.Failure_Area__c = failureArea;

      xoExceptionList.add(newException);
    }

    if(insertRecord) {
      insert xoExceptionList;
    }

    return xoExceptionList;
  }
}