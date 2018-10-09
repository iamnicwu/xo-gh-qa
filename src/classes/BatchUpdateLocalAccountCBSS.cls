global class BatchUpdateLocalAccountCBSS implements Database.Batchable<sObject> {
    public Set<Id> userIdSet;
    public String query;
    public Id localAccountRecordTypeId;

    global BatchUpdateLocalAccountCBSS(Set<Id> userIdSet) {
        this.userIdSet = userIdSet;
        this.localAccountRecordTypeId = getLocalAccountRecordTypeId();
        // CSP-2315 Update CBSS Information on Account and Billing Account
        // if userIdSet.size() > 0, means this batch class is called by UserTrigger or Admin run batch one user on demand.
        this.query = 'SELECT Id, CBBS__c, Owner.ARR__c, CBBS__r.Email, CBBS__r.Phone, Owner.ARR__r.Email, Owner.ARR__r.Phone, Override_Account_CBSS__c FROM Account WHERE RecordTypeId = :localAccountRecordTypeId ';
        if(userIdSet.size() > 0){
            this.query += ' AND (CBBS__c IN :userIdSet OR OwnerId IN :userIdSet)';
        }else{
            this.query += ' AND CBSS_Email_Is_Matched__c = False';
        }
        System.debug('querystring');
        System.debug(this.query);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug(LoggingLevel.INFO, '*** start query: ' + query);
        Database.QueryLocator retVal = Database.getQueryLocator(query);
        return retVal;
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        System.debug(LoggingLevel.INFO, '***execute scope: ' + scope);
        for (Account accRec : scope) {
            // CSP-2315 Update CBSS Information on Account and Billing Account
            // accRec.CBBS__c = accRec.Owner.ARR__c;
            if(!accRec.Override_Account_CBSS__c){
                accRec.CBBS__c = accRec.Owner.ARR__c;
                accRec.CBSS_Email__c = accRec.Owner.ARR__r.Email;
                accRec.CBSS_Phone__c = accRec.Owner.ARR__r.Phone;
            }else{
                accRec.CBSS_Email__c = accRec.CBBS__r.Email;
                accRec.CBSS_Phone__c = accRec.CBBS__r.Phone;
            }

        }
        // CSP-2315 Update CBSS Information on Account and Billing Account
        Database.SaveResult[] updateResults = Database.update(scope, false);
        List<XO_Exception__C> exceptionList = ExceptionUtility.consumeException(updateResults);
        if(exceptionList != null && exceptionList.size() > 0){
            insert exceptionList;
        } 
        // update scope;
    }

    global void finish(Database.BatchableContext BC) {
        // CSP-1659 | run BatchZuoraDataUpdater job if needed
        Set<String> asyncJobInProgressStatusSet = new Set<String>{'Holding', 'Queued', 'Preparing', 'Processing'};
        Integer runningBatchZuoraDataUpdaterJobCount = [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'BatchZuoraDataUpdater' AND Status IN :asyncJobInProgressStatusSet LIMIT 1];
        if (runningBatchZuoraDataUpdaterJobCount == 0 && !Test.isRunningTest()) {
            Database.executebatch(new BatchZuoraDataUpdater());
        }
    }

    private Id getLocalAccountRecordTypeId() {
        Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Account.getRecordTypeInfosById();
        Id localAccountRecordTypeId;
        for (Schema.RecordTypeInfo rti : rtMapById.values()) {
            if (rti.getName().containsIgnoreCase('Local')) {
                localAccountRecordTypeId = rti.getRecordTypeId();
                break;
            }
        }
        return localAccountRecordTypeId;
    }
}