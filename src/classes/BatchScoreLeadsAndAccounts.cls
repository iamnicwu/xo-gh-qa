global class BatchScoreLeadsAndAccounts implements Database.Batchable<sObject> {
    
    private String query;
    private Boolean scoreLeads;
    private Boolean scoreAccounts;
    
    /**
     *   CSP-2120 | "BatchScoreLeadsAndAccounts" is a batch job that will score
     *   local Leads and Accounts using the LeadAndAccountScoringUtilities class
     *   (originally created for ticket CSP-2061)
     *
     *   @author Jonathan Satterfield
     *   @date   2017-05-03
     *   @param  {Boolean}   scoreLeads
     *   @param  {Boolean}   scoreAccounts
     */
    global BatchScoreLeadsAndAccounts(Boolean scoreLeads, Boolean scoreAccounts) {
        this.scoreLeads = scoreLeads;
        this.scoreAccounts = scoreAccounts;
        if (this.scoreLeads) {
            Set<String> leadScoringFieldsNameSet = LeadAndAccountScoringUtilities.getLeadScoringFieldsNameSet();
            this.query = 'SELECT Id';
            for (String leadField : leadScoringFieldsNameSet) {
                this.query += (', ' + leadField);
            }
            this.query += ' FROM Lead WHERE RecordType.Name = \'Local\'';
        }
        else if (this.scoreAccounts) {
            Set<String> accountScoringFieldsNameSet = LeadAndAccountScoringUtilities.getAccountScoringFieldsNameSet();
            this.query = 'SELECT Id';
            for (String accountField : accountScoringFieldsNameSet) {
                this.query += (', ' + accountField);
            }
            this.query += ' FROM Account WHERE RecordType.Name = \'Local\'';
        }
    }

    global BatchScoreLeadsAndAccounts(Boolean scoreLeads, String leadWhereClause, Boolean scoreAccounts, String accountWhereClause) {
        this.scoreLeads = scoreLeads;
        this.scoreAccounts = scoreAccounts;
        if (this.scoreLeads) {
            Set<String> leadScoringFieldsNameSet = LeadAndAccountScoringUtilities.getLeadScoringFieldsNameSet();
            this.query = 'SELECT Id';
            for (String leadField : leadScoringFieldsNameSet) {
                this.query += (', ' + leadField);
            }
            if (String.isNotBlank(leadWhereClause)) {
            	this.query += (' FROM Lead WHERE ' + leadWhereClause);
            }
            else {
            	this.query += ' FROM Lead WHERE RecordType.Name = \'Local\'';
            }
        }
        else if (this.scoreAccounts) {
            Set<String> accountScoringFieldsNameSet = LeadAndAccountScoringUtilities.getAccountScoringFieldsNameSet();
            this.query = 'SELECT Id';
            for (String accountField : accountScoringFieldsNameSet) {
                this.query += (', ' + accountField);
            }
            if (String.isNotBlank(accountWhereClause)) {
            	this.query += (' FROM Account WHERE ' + accountWhereClause);
            }
            else {
            	this.query += ' FROM Account WHERE RecordType.Name = \'Local\'';
            }
        }
    }    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        if (this.scoreLeads) {
            List<Lead> leadUpdateList = LeadAndAccountScoringUtilities.scoreLeads((List<Lead>)scope);
            List<Database.SaveResult> updateResultsList = Database.update(leadUpdateList, false);
            List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(updateResultsList);
            if (!xoExceptionList.isEmpty()) {
                insert xoExceptionList;
            }
        }
        else if (this.scoreAccounts) {
            List<Account> accountUpdateList = LeadAndAccountScoringUtilities.scoreAccounts((List<Account>)scope);
            List<Database.SaveResult> updateResultsList = Database.update(accountUpdateList, false);
            List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(updateResultsList);
            if (!xoExceptionList.isEmpty()) {
                insert xoExceptionList;
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // if both Leads and Accounts needed to be scored, the first batch job would
        // have scored Lead records first, so we need to start a second batch job to
        // then score Account records
        if (this.scoreLeads && this.scoreAccounts) {
            Database.executeBatch(new BatchScoreLeadsAndAccounts(false, true));
        }
    }
}