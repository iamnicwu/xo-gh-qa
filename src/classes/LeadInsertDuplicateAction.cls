/*

*/
global without sharing class LeadInsertDuplicateAction implements CRMfusionDBR101.DB_CustomMatchHandler
{
    // Custom match handler for scenarios.
    // This is passed a DB_Api.Matches object which contains scenario info
    // and a list of matches detected.
    global void handleMatches( CRMfusionDBR101.DB_Api.Matches matches, String triggeringObjectType, Boolean isInsert,
        Boolean isUpdate, Boolean isUndelete )
    {
        // Query data for the leads in the match set.
        List<Lead> leads = [SELECT Id, FirstName, LastName, Company, Email FROM Lead
            WHERE Id IN :matches.matchedIds];
        
        // Exit if there are no results, this shouldn't happen.
        if ( leads == null || leads.isEmpty() ){
        	return;
        }
        
        System.debug(LoggingLevel.INFO, '***matches.scenarioId : ' + matches.scenarioId);
        // Generate an e-mail message to send.
        String messageBody = 'DupeBlocker detected this possible duplicate set: \r\n\r\n';
        for ( Lead lead : leads ){
        	messageBody += lead.Id + ' - ' + lead.Email + ' at ' + lead.Company + '\r\n';
        }
        System.debug(LoggingLevel.INFO, '***messageBody : ' + messageBody); 
        CRMfusionDBR101__Duplicate_Warning__c testdata = new CRMfusionDBR101__Duplicate_Warning__c();
        // testdata.
        // // Set the message options.
        // Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        // message.setTargetObjectId( UserInfo.getUserId() );
        // message.setSaveAsActivity( false );
        // message.setSubject( 'DupeBlocker Detected Duplicates' );
        // message.setUseSignature( false );
        // message.setPlainTextBody( messageBody );
        // // Send the message.
        // Messaging.sendEmail( new Messaging.Email[] { message } );

        XO_Exception__c newException = new XO_Exception__c();
	      newException.Name = Datetime.now().format('MM/dd/yyyy');
	      newException.Message__c = triggeringObjectType;
        // insert newException;
    }
}