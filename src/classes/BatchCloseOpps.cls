/* 
<class>
  <name>BatchCloseOpps</name>
  <purpose>Auto closed the open Opp which is not modified in last 90 days.</purpose>
  <created>
    <by>Tony Liu</by>
    <date>07/07/2016</date>
    <ticket>CSP-1138</ticket>
  </created>
</class>
*/
public class BatchCloseOpps implements Database.Batchable<sObject> {
    private Set<String> oppStagesToIgnore;   
    private String query;
    private dateTime ToExpire;
    public BatchCloseOpps() {
        //Opportunity_Auto_Closed_Offsets__c OppAutoClosedOffsets = Opportunity_Auto_Closed_Offsets__c.getOrgDefaults();
        String dateOffset = !Test.isRunningTest()? Label.Opportunity_Auto_Closed_Offsets:'3';
        Integer daysToExpire = Integer.valueOf(dateOffset); 
        ToExpire = DateTime.now().adddays(daysToExpire);
        oppStagesToIgnore = new Set<String>{'Closed Won', 'Closed Lost'};

        // Nick Wu Modified CSP-1306 Opp-Auto Close Extension
        // Add No_of_Times_To_Extend__c in query
        query = 'SELECT Id, StageName,CloseDate,Actual_Close_Date__c, Lost_Reason__c, No_of_Times_To_Extend__c, CreatedDate FROM Opportunity WHERE Createddate <: ToExpire AND StageName NOT IN :oppStagesToIgnore AND RecordType.Name = \'National\'';
        
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Database.QueryLocator retVal = Database.getQueryLocator(query);
        return retVal;
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        // CSP-1138 | close the Opportunity records which is opened too long
        for (Opportunity opp : scope) {

            // opp.StageName = 'Closed Lost';
            // opp.Lost_Reason__c = 'Expired';
            // opp.CloseDate = date.today();
            // opp.Lost_Reason_Details__c = 'Expired'; 

            // Nick Wu Modified CSP-1306 Opp-Auto Close Extension
            // Add logic to opp update if created date less then Number of times to extend multiple to 30 days
            // Check if No of Times to extend field if no being initialize, true then set default 0.
            if(opp.No_of_Times_To_Extend__c == null){
                opp.No_of_Times_To_Extend__c=0;
            }

            // Calculate the expireDays with adding the no of times to Extend * 30days
            Integer expireDays = Integer.valueOf(-(opp.No_of_Times_To_Extend__c*Integer.valueOf(Label.Opportunity_Auto_Closed_permanent_Day)));
            if(opp.CreatedDate <= ToExpire.addDays(expireDays)){
                opp.StageName = 'Closed Lost';
                opp.Lost_Reason__c = 'Expired';
                opp.CloseDate = date.today();
                opp.Lost_Reason_Details__c = 'Expired';
            }
        }
        
        Database.SaveResult[] dbSaveResult = Database.update(scope, false);
	    List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(dbSaveResult);
	    if(xoExceptionList.size() > 0){
	    	insert xoExceptionList;
	    }
    }

    public void finish(Database.BatchableContext BC) {
        // don't do anything
    }
}