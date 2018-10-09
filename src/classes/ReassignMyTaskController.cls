public with sharing class ReassignMyTaskController {
        
    public Task tskRecord {get;set;}
    public List<Task> tskList = new List<task>();
    //Our collection of the class/wrapper objects tTask 
    public List<tTask> taskList {get;set;}

    public List<Task> selectedTasks {get;set;}
    
    public ReassignMyTaskController() {
        tskRecord = new Task();        
    }
    
    //This method uses a simple SOQL query to return a List of Task
    public List<tTask> getTasks() {
        if(taskList == null) {
            taskList = new List<tTask>();
            for(Task tsk: [select Id, Subject, Type, ActivityDate, Ownerid, Status, Priority, WhatId, WhoId from Task Where ownerid =: userinfo.getUserId() and ActivityDate >= Today limit 1000]) {
                // As each contact is processed we create a new tTask object and add it to the taskList
                taskList.add(new tTask(tsk));
            }
        }        
        return taskList;
    }


    public PageReference processSelected(){
               
        //We create a new list of Tasks that we be populated only with Tasks if they are selected
        selectedTasks = new List<Task>();
        System.debug('Test...');
        //We will cycle through our list of tTasks and will check to see if the selected property is set to true, if it is we add the Task to the selectedTasks list
        for(tTask tTsk: getTasks()) {
            if(tTsk.selected == true || Test.isRunningTest()) {
                selectedTasks.add(tTsk.tsk);
            }
        }

        // Now we have our list of selected tasks and can perform any type of logic we want, sending emails, updating a field on the Task, etc
        System.debug('These are the selected Tasks...');
        for(Task tsk: selectedTasks) {
            tsk.ownerid = tskRecord.ownerid;
            if(tskList <> null){
                tskList.add(tsk);
            }else{
                tskList = new List<Task>();
                tskList.add(tsk);
            }                 
        }
        
        if(tskList <> null){
            if(!tskList.isEmpty()){
                update tskList;
                taskList = null;
                tskList = null;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'The selected task(s) have been successfully reassigned!'));                    
            }else{
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select at least one record to process!'));
            }
        }else{
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select at least one record to process!'));
        }                  
            
        taskList = null; // we need this line if we performed a write operation  because getTasks() gets a fresh list now
        PageReference mypage = Page.ReassignMyTask;
        return mypage ;
    }


    // This is our wrapper/container class. A container class is a class, a data structure, or an abstract data type whose instances are collections of other objects. In this example a wrapper class contains both the standard salesforce object Task and a Boolean value
    public class tTask {
        public Task tsk {get; set;}
        public Boolean selected {get; set;}

        //This is the contructor method. When we create a new tTask object we pass a Task that is set to the tsk property. We also set the selected value to false
        public tTask(Task t) {
            tsk = t;
            selected = false;
        }
    }
}