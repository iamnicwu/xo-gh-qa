@isTest
private class UpdateActivityDateControllerTest {
    
    @isTest static void test_method_one() {
        List<Task> newTaskList = new List<Task>();
        for(Integer i = 0; i < 50; i++){
            Task newTask = new Task();
            newTask.Subject = 'Test';
            newTaskList.add(newTask);
        }
        insert newTaskList;

        UpdateActivityDateController newController = new UpdateActivityDateController();
        newController.filterTask.Subject = 'Test';
        newController.filterAction();
        newController.getHasNext();
        newController.nextPage();
        newController.previousPage();

        newController.noDateTaskList[0].ActivityDate = Date.today();
        newController.saveDate();

        newController.filterTask.Subject = 'TASDADSA';
        newController.filterAction();
    }
    
}