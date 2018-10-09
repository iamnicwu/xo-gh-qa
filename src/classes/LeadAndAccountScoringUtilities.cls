public without sharing class LeadAndAccountScoringUtilities {
    private static final List<Lead_and_Account_Scoring__c> SCORING_RULES_LIST = Lead_and_Account_Scoring__c.getAll().values();
    private static List<Lead_and_Account_Scoring__c> leadScoringRulesList = new List<Lead_and_Account_Scoring__c>();
    private static List<Lead_and_Account_Scoring__c> accountScoringRulesList = new List<Lead_and_Account_Scoring__c>();
    private static Map<String, Pattern> leadRegexPatternsMap = new Map<String, Pattern>();
    private static Map<String, Pattern> accountRegexPatternsMap = new Map<String, Pattern>();
    private static Set<String> leadScoringFieldsNameSet = new Set<String>();
    private static Set<String> accountScoringFieldsNameSet = new Set<String>();

    static {
        // populate the lead + account scoring rules lists
        for (Integer i = 0; i < SCORING_RULES_LIST.size(); i++) {
            Lead_and_Account_Scoring__c scoringRule = SCORING_RULES_LIST[i];
            // scoring rules can apply to both Leads and Accounts (if they have the same field)
            if (scoringRule.Apply_to_Lead_Score__c) {
                leadScoringRulesList.add(scoringRule);
                leadScoringFieldsNameSet.add(scoringRule.Field_API_Name__c);
                // initialize regex Pattern if applicable and add to map
                if (scoringRule.Comparison_Type__c.equalsIgnoreCase('Regex')) {
                    leadRegexPatternsMap.put(scoringRule.Name, Pattern.compile(scoringRule.Comparison_Value__c));
                }
            }
            if (scoringRule.Apply_to_Account_Score__c) {
                accountScoringRulesList.add(scoringRule);
                accountScoringFieldsNameSet.add(scoringRule.Field_API_Name__c);
                // initialize regex Pattern if applicable and add to map
                if (scoringRule.Comparison_Type__c.equalsIgnoreCase('Regex')) {
                    accountRegexPatternsMap.put(scoringRule.Name, Pattern.compile(scoringRule.Comparison_Value__c));
                }
            }
        }
    }


    public static Set<String> getLeadScoringFieldsNameSet() {
        return leadScoringFieldsNameSet;
    }


    public static Set<String> getAccountScoringFieldsNameSet() {
        return accountScoringFieldsNameSet;
    }


    @future
    public static void scoreLeadsFutureJob(Set<Id> leadIdSet) {
        // dynamically populate query string
        String queryString = 'SELECT Id';
        for (String leadField : leadScoringFieldsNameSet) {
            queryString += (', ' + leadField);
        }
        queryString += ' FROM Lead WHERE Id IN :leadIdSet';

        // query and score lead records, then update to set the Score
        List<Lead> leadsList = scoreLeads(Database.query(queryString));
        List<Database.SaveResult> updateResultsList = Database.update(leadsList, false);
        List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(updateResultsList);
        if (!xoExceptionList.isEmpty()) {
            insert xoExceptionList;
        }
    }
    

    public static List<Lead> scoreLeads(List<Lead> leadsList) {
        for (Integer i = 0; i < leadsList.size(); i++) {
            leadsList[i] = scoreLead(leadsList[i]);
        }
        return leadsList;
    }


    public static Lead scoreLead(Lead leadRecord) {
        return (Lead)scoreLeadOrAccount((SObject)leadRecord, true);
    }


    @future
    public static void scoreAccountsFutureJob(Set<Id> accountIdSet) {
        // dynamically populate query string
        String queryString = 'SELECT Id';
        for (String accountField : accountScoringFieldsNameSet) {
            queryString += (', ' + accountField);
        }
        queryString += ' FROM Account WHERE Id IN :accountIdSet';

        // query and score account records, then update to set the Score
        List<Account> accountsList = scoreAccounts(Database.query(queryString));
        List<Database.SaveResult> updateResultsList = Database.update(accountsList, false);
        List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(updateResultsList);
        if (!xoExceptionList.isEmpty()) {
            insert xoExceptionList;
        }
    }    


    public static List<Account> scoreAccounts(List<Account> accountsList) {
        for (Integer i = 0; i < accountsList.size(); i++) {
            accountsList[i] = scoreAccount(accountsList[i]);
        }
        return accountsList;
    }


    public static Account scoreAccount(Account accountRecord) {
        return (Account)scoreLeadOrAccount((SObject)accountRecord, false);
    }


    /**
     *   CSP-2601 | "scoreLeadOrAccount" takes either a Lead or an Account cast as an SObject, then determines
     *   what it's Score__c value should be by comparing it against all the applicable Lead_and_Account_Scoring__c
     *   custom setting records. This method doesn't need to be called directly (hence why it's private) -- one of
     *   the above methods should call it instead, which handles all the necessary casting.
     *
     *   @author Jonathan Satterfield
     *   @date   2017-04-12
     *   @param  {SObject}   record
     *   @param  {Boolean}   isLead
     *   @return {SObject}
     */
    private static SObject scoreLeadOrAccount(SObject record, Boolean isLead) {
        List<Lead_and_Account_Scoring__c> scoringRulesList = isLead ? leadScoringRulesList : accountScoringRulesList;
        Map<String, Pattern> regexPatternsMap = isLead ? leadRegexPatternsMap : accountRegexPatternsMap;
        // reset score to 0
        Decimal score = 0;

        // run all rules against the SObject
        for (Integer i = 0; i < scoringRulesList.size(); i++) {
            Lead_and_Account_Scoring__c scoringRule = scoringRulesList[i];
            // Note: for checking null/empty values, can ONLY use the "Not Blank" Scoring Rule Comparison Type!
            // The reason why is a lot of Scoring Rules are "stacked" like "not empty/null, and doesn't contain fake@fake.com"
            // This means we can't have a rule like "Does Not Equal" null/empty value -- it must be "Not Blank"
            if (scoringRule.Comparison_Type__c.equalsIgnoreCase('Not Blank')) {
                // Note: as of 4-11-17 we are only doing "not blank" comparisons against text fields
                String fieldValue = (String)record.get(scoringRule.Field_API_Name__c);
                if (String.isBlank(fieldValue)) {
                    continue;
                }
                score += scoringRule.Points__c;
            }
            else if (scoringRule.Comparison_Type__c.equalsIgnoreCase('Regex')) {
                // Note: as of 4-11-17 we are only doing "regex" comparisons against text fields
                String fieldValue = (String)record.get(scoringRule.Field_API_Name__c);
                if (String.isBlank(fieldValue) || !regexPatternsMap.containsKey(scoringRule.Name)) {
                    continue;
                }
                Pattern regexPattern = regexPatternsMap.get(scoringRule.Name);
                Matcher regexMatcher = regexPattern.matcher(fieldValue);
                if (!regexMatcher.matches()) {
                    continue;
                }
                score += scoringRule.Points__c;
            }
            else if (scoringRule.Comparison_Type__c.equalsIgnoreCase('Contains')) {
                // Note: as of 4-11-17 we are only doing "contains" comparisons against text fields
                String fieldValue = (String)record.get(scoringRule.Field_API_Name__c);
                if (String.isBlank(fieldValue) || !fieldValue.containsIgnoreCase(scoringRule.Comparison_Value__c)) {
                    continue;
                }
                score += scoringRule.Points__c;
            }
            else if (scoringRule.Comparison_Type__c.equalsIgnoreCase('Does Not Contain')) {
                // Note: as of 4-11-17 we are only doing "does not contain" comparisons against text fields
                String fieldValue = (String)record.get(scoringRule.Field_API_Name__c);
                if (String.isBlank(fieldValue) || fieldValue.containsIgnoreCase(scoringRule.Comparison_Value__c)) {
                    continue;
                }
                score += scoringRule.Points__c;
            }
            else if (scoringRule.Comparison_Type__c.equalsIgnoreCase('Does Not Equal')) {
                // Note: as of 4-11-17 we are only doing "does not equal" comparisons against text fields
                String fieldValue = (String)record.get(scoringRule.Field_API_Name__c);
                if (String.isBlank(fieldValue) || fieldValue.equalsIgnoreCase(scoringRule.Comparison_Value__c)) {
                    continue;
                }
                score += scoringRule.Points__c;                
            }
            else if (scoringRule.Comparison_Type__c.equalsIgnoreCase('Equals')) {
                // Note: as of 4-11-17 we are only doing "equals" comparisons against text fields
                String fieldValue = (String)record.get(scoringRule.Field_API_Name__c);
                if (String.isBlank(fieldValue) || !fieldValue.equalsIgnoreCase(scoringRule.Comparison_Value__c)) {
                    continue;
                }
                score += scoringRule.Points__c;                
            }
            else {
                throw new ApplicationException('Scoring Rule ' + scoringRule.Name + ' has an invalid Comparison Type.');
            }
        }

        record.put('Score__c', score);
        return record;        
    }
}