/* 
<Class>
  <name>BatchTask</name>
  <purpose>To handle deletion of expired tasks</purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>09/16/2015</date>
    <ticket>SF-1223</ticket>
  </created>
</Class>
*/

global class BatchTask implements Database.Batchable<sObject> {

    // Added by Nick for CSP-1359
    // below values are from custom label BatchTask_Settings
    global Integer interval;      // how many days for the range
    global Integer batchSize;     // batch size
    global Date startDate;        // Start date of the range
    global Date endDate;          // End date of the range
    global Date batchFinishDate;  // The date of the batch finished

    global Database.QueryLocator start(Database.BatchableContext BC){

        // Modified by Nick for CSP-1359
        // Enhance the query to query the range of activityDate for each batch
        String startDateStr = DateTime.newInstance(startDate.year(),
                                                    startDate.month(),
                                                    startDate.day()).format('YYYY-MM-dd');
        String endDateStr = DateTime.newInstance(endDate.year(),
                                                    endDate.month(),
                                                    endDate.day()).format('YYYY-MM-dd');

        // use the formula on the task record to determine if it needs to be deleted
        String query = 'SELECT Id, Subject, Marked_For_Deletion__c FROM Task WHERE';
                query += ' Delete_After_Due_Date__c = true AND IsClosed = false';
                query += ' AND ActivityDate >= ' + startDateStr;
                query += ' AND ActivityDate < ' + endDateStr;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Task> scope){
        // delete the tasks
        // Modified by Nick for CSP-1359, added exception handling
        try {
            delete scope;
        }
        catch (DMLException ex) {
            ExceptionUtility.consumeException(ex, true);
        }
    }

    global void finish(Database.BatchableContext BC){

        // Added by Nick for CSP-1359
        // update the start date / end date of new job
        // Label.BatchTask_Settings is the custom setting to store the default values of these settings, and each values splited by comma
        // Label.BatchTask_Settings [0] year of startDate
        // Label.BatchTask_Settings [1] month of startDate
        // Label.BatchTask_Settings [2] day of startDate
        // Label.BatchTask_Settings [3] interval days
        // Label.BatchTask_Settings [4] batch size
        // Label.BatchTask_Settings [5] it is switcher for is used today() or using custom label setting
        // Label.BatchTask_Settings [6] year of batch finish date
        // Label.BatchTask_Settings [7] month of batch finish date
        // Label.BatchTask_Settings [8] day of batch finish date
        if(endDate < batchFinishDate){
            try {
                BatchTask bt = new BatchTask();
                bt.interval = Integer.valueOf(Label.BatchTask_Settings.split(',')[3]);
                bt.batchSize = Integer.valueOf(Label.BatchTask_Settings.split(',')[4]);
                bt.startDate = endDate;
                bt.endDate = endDate.addDays(interval);
                
                if(Boolean.valueOf(Label.BatchTask_Settings.split(',')[5])){
                    bt.batchFinishDate = System.TODAY();
                }else{
                    bt.batchFinishDate = Date.newInstance(Integer.valueOf(Label.BatchTask_Settings.split(',')[6]),
                                                      Integer.valueOf(Label.BatchTask_Settings.split(',')[7]),
                                                      Integer.valueOf(Label.BatchTask_Settings.split(',')[8]));
                }
                
                Id batchId = Database.executeBatch(bt,Integer.valueOf(bt.batchSize));
            }
            catch (Exception ex) {
                ExceptionUtility.consumeException(ex, true);
            }
        }
    }
}