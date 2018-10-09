/* 
<class>
  <name>BatchTaskScheduledJob</name>
  <purpose>Used to schedule the BatchTask class</purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>9/16/2015</date>
    <ticket>SF-1223</ticket>
  </created>
</class>
*/
global class BatchTaskScheduledJob implements Schedulable{
    
    global void execute(SchedulableContext sc) {
        
        // Modified by Nick for CSP-1359
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
        BatchTask bt = new BatchTask();
        bt.interval = Integer.valueOf(Label.BatchTask_Settings.split(',')[3]);
        bt.batchSize = Integer.valueOf(Label.BatchTask_Settings.split(',')[4]);
        bt.startDate = Date.newInstance(Integer.valueOf(Label.BatchTask_Settings.split(',')[0]),
                                        Integer.valueOf(Label.BatchTask_Settings.split(',')[1]),
                                        Integer.valueOf(Label.BatchTask_Settings.split(',')[2]));

        bt.endDate = bt.startDate.addDays(bt.interval);
        if(Boolean.valueOf(Label.BatchTask_Settings.split(',')[5])){
            bt.batchFinishDate = System.TODAY();
        }else{
            bt.batchFinishDate = Date.newInstance(Integer.valueOf(Label.BatchTask_Settings.split(',')[6]),
                                              Integer.valueOf(Label.BatchTask_Settings.split(',')[7]),
                                              Integer.valueOf(Label.BatchTask_Settings.split(',')[8]));
        }
        ID batchprocessid = Database.executeBatch(bt, bt.batchSize);
    }
}