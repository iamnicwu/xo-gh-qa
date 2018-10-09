/* 
<class>
  <name>BatchMoveCustToCreditHoldScheduledJob</name>
  <purpose>Scheduled class for "BatchMoveCustomerToCreditHold" batch class</purpose>
  <created>
    <by>Hari Mohan</by>
    <date>10/2/2015</date>
    <ticket>SF-1095, SF-1172, SF-1174, SF-1175, SF-1176, SF-1177</ticket>
  </created>
</class>
*/
global class BatchMoveCustToCreditHoldScheduledJob implements Schedulable {    
    global void execute(SchedulableContext sc) {
        BatchMoveCustomerToCreditHold b = new BatchMoveCustomerToCreditHold();
        database.executebatch(b, 200);
    }
}