/* 
<class>
  <name>BatchAccountAcitveHierarchy</name>
  <purpose>Batch class to calculate the active hierarchy for the account which should update</purpose>
  <created>
    <by>Tony Liu</by>
    <date>7/1/2018</date>
    <ticket>CSP-2906</ticket>
  </created>
</class>
*/

global class BatchAccountAcitveHierarchy implements Database.Batchable<sObject> {
    private String query;

    global BatchAccountAcitveHierarchy() {
        this.query = ' SELECT '
                        +   'Id, '
                        +   'Account_Status__c, '
                        +   'Active_Hierarchy__c, '
                        +   'Active_Hierarchy_Date__c, '
                        +   'Need_to_Recalculate_Active_Hierarchy__c, '
                        +   'ParentId , '
                        +   'Parent.Account_Status__c , '
                        +   'Parent.ParentId, '
                        +   'Parent.Parent.Account_Status__c , '
                        +   'Parent.Parent.ParentId, '
                        +   'Parent.Parent.Parent.Account_Status__c , '
                        +   'Parent.Parent.Parent.ParentId '
                    +   ' FROM '
                        +   ' Account '
                    +   ' WHERE '
                        +   'Need_to_Recalculate_Active_Hierarchy__c = \'Yes\' '
                    +   ' AND '
                        +   'RecordType.Name = \'Local\' ';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        // CSP-2906 Paid Status Across the Parent-Child Hierarchy
        // Stored the highest level account id and the all account in same hierarchy
        Map<Id,List<Account>> hierarchyAccountMap = new Map<Id,List<Account>>();

        // CSP-2906 Paid Status Across the Parent-Child Hierarchy
        // Stored the highest leve account id and the account Status(if Any one's status is Acitve, set the account Status to active),
        Map<Id, String> hierarchyAccStatusMap = new Map<Id, String>();

        // to retrive the highest level account on the same hierarchy
        for(Account acc: scope) {
            List<Account> hierarchyAccList = new List<Account>();
            if (String.isBlank(acc.ParentId)) {

                if (!hierarchyAccountMap.containsKey(acc.Id)) {
                    hierarchyAccList.add(acc);
                    hierarchyAccountMap.put(acc.Id, hierarchyAccList);
                    hierarchyAccStatusMap.put(acc.Id, acc.Account_Status__c);
                }

            }else if (String.isBlank(acc.Parent.ParentId)) {

                if (!hierarchyAccountMap.containsKey(acc.ParentId)) {
                    hierarchyAccList.add(acc.Parent);
                    hierarchyAccountMap.put(acc.ParentId, hierarchyAccList);
                    hierarchyAccStatusMap.put(acc.ParentId, acc.Parent.Account_Status__c);
                }

            }else if (String.isBlank(acc.Parent.Parent.ParentId)) {

                if (!hierarchyAccountMap.containsKey(acc.Parent.ParentId)) {
                    hierarchyAccList.add(acc.Parent.Parent);
                    hierarchyAccountMap.put(acc.Parent.ParentId, hierarchyAccList);
                    hierarchyAccStatusMap.put(acc.Parent.ParentId, acc.Parent.Parent.Account_Status__c);
                }

            }else if(String.isBlank(acc.Parent.Parent.Parent.ParentId)){
                if (!hierarchyAccountMap.containsKey(acc.Parent.Parent.ParentId)) {
                    hierarchyAccList.add(acc.Parent.Parent.Parent);
                    hierarchyAccountMap.put(acc.Parent.Parent.ParentId, hierarchyAccList);
                    hierarchyAccStatusMap.put(acc.Parent.Parent.ParentId, acc.Parent.Parent.Parent.Account_Status__c);
                }

            }
        }
        // calculate the account's active hierarchy in the account's hierarchy
        List<Account> udpateAccList = calculateActiveHierarchy(hierarchyAccountMap,hierarchyAccStatusMap);

        Database.SaveResult[] saveResults = Database.update(udpateAccList, false);

        List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(saveResults);
        if(xoExceptionList.size() >0){
            insert xoExceptionList;
        }
    }

    global void finish(Database.BatchableContext BC) {
        // CSP-404 | run the BatchAccountPastDueBalanceEmailsAndTasks job
        BatchAccountPastDueBalanceEmailsAndTasks emailAndTasksBatchJob = new BatchAccountPastDueBalanceEmailsAndTasks();
        // CSP-2032
        // Set batch size from 2000 to 50. The sendEmail method is inserting a task in a FOR loop for every successful email
        // that is sent. This is causing the Task trigger to fire for every email that is sent.
        Database.ExecuteBatch(emailAndTasksBatchJob, 50);

    }

    private static List<Account> calculateActiveHierarchy(Map<Id,List<Account>> hierarchyAccountMap, Map<Id, String> hierarchyAccStatusMap){

        Set<Id> parentAccIdSet = new Set<Id>();
        parentAccIdSet.addAll(hierarchyAccountMap.keySet());
        // the key is the account Id, the value is the highest level account id
        Map<Id, Id> accParentIdMap = new Map<Id,Id>();
        Integer levelCount = 0;
        //CSP-2906 Paid Status Across the Parent-Child Hierarchy
        // retrieve all account in same hierarchy to put in the map "hierarchyAccountMap" that the key is the highest level account id, value is the account list
        do{
            List<Account> accountList = [Select id, Name,Active_Hierarchy__c,Account_Status__c, ParentId from Account where parentId in: parentAccIdSet];
            parentAccIdSet.clear();
            if (!accountList.isEmpty()) {
                for (Account acc: accountList) {
                    if (hierarchyAccountMap.containsKey(acc.ParentId)) {

                        hierarchyAccountMap.get(acc.ParentId).add(acc);
                        accParentIdMap.put(acc.Id,acc.ParentId);

                        if (acc.Account_Status__c == 'Active') {
                            hierarchyAccStatusMap.put(acc.ParentId,'Active');
                        }

                    }else if (accParentIdMap.containsKey(acc.ParentId)) {

                        Id parentAccId = accParentIdMap.get(acc.ParentId);

                        hierarchyAccountMap.get(parentAccId).add(acc);

                        accParentIdMap.put(acc.Id,parentAccId);

                        if (acc.Account_Status__c == 'Active') {
                            hierarchyAccStatusMap.put(parentAccId,'Active');
                        }
                    }
                    parentAccIdSet.add(acc.Id);
                }
            }
            levelCount++;
        }while(!parentAccIdSet.isEmpty() && levelCount < 5);

        // for the all account, reset the flag and assign the value to the Active_Hierarchy__c
        // if the hierarchy only have one account ,set the Active_Hierarchy__c to 'Not Applicable'
        // otherwise if the status of any account in same hierarchy is active, assign "Yes" to Active_Hierarchy__c
        List<Account> acclist = new List<Account>();
        for (Id accId:  hierarchyAccountMap.keySet()) {
            String accStatus = 'No';
            if (hierarchyAccStatusMap.containsKey(accId) && hierarchyAccStatusMap.get(accId) == 'Active') {
                accStatus = 'Yes';
            }

            if (hierarchyAccountMap.get(accId).size() == 1) {
                Account currentAcc = hierarchyAccountMap.get(accId)[0];
                currentAcc.Active_Hierarchy__c = 'Not Applicable';
                currentAcc.Need_to_Recalculate_Active_Hierarchy__c = 'No';
                acclist.add(currentAcc);
            }else{
                for (Account currentAcc: hierarchyAccountMap.get(accId)) {
                    currentAcc.Active_Hierarchy__c = accStatus;
                    currentAcc.Need_to_Recalculate_Active_Hierarchy__c = 'No';
                    acclist.add(currentAcc);
                }
            }
        }
        return acclist;
    }
}