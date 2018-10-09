public with sharing class UpdateActivityDateController {

    private Integer taskLimit = 25;
    private Set<Id> subordinateIdSet = new Set<Id>();

    public List<Task> noDateTaskList {get; set;}
    public Integer pageNumber {get; set;}
    public Integer totalTasks {get; set;}
    public Integer totalFilteredTasks {get; set;}
    public Task filterTask {get; set;}
    public Boolean assignedToFilter {get; set;}

    public UpdateActivityDateController() {
        filterTask = new Task();
        pageNumber = 1;
        totalTasks = 0;
        totalFilteredTasks = 0;

        subordinateIdSet.addAll(RoleUtils.getRoleSubordinateUsers(UserInfo.getUserId()));
        subordinateIdSet.add(UserInfo.getUserId());

        assignedToFilter = subordinateIdSet.size() > 1;

        taskListBuilder();
        countTasks();
        countFilteredTasks();
    }

    private void taskListBuilder(){
        pageNumber = (pageNumber < 1) ? 1 : pageNumber;

        Integer offsetValue = taskLimit * (pageNumber - 1);     

        String queryString = 'select Id, What.Name, ActivityDate, WhatId, Subject, Purpose__c, Type, OwnerId, Status from Task where';
        //queryString = (String.isNotBlank(filterTask.Purpose__c)) ? queryString + ' Purpose__c = \'' + filterTask.Purpose__c + '\' and' : queryString;
        queryString = (String.isNotBlank(filterTask.CallObject)) ? queryString + ' Owner.Name like \'%' + String.escapeSingleQuotes(filterTask.CallObject) + '%\' and' : queryString;
        queryString = (String.isNotBlank(filterTask.Type)) ? queryString + ' Type = \'' + filterTask.Type + '\' and' : queryString;
        queryString = (String.isNotBlank(filterTask.Subject)) ? queryString + ' Subject like \'%' + String.escapeSingleQuotes(filterTask.Subject) + '%\' and' : queryString;
        //queryString +=' ActivityDate = null and OwnerId =\'' + UserInfo.getUserId() + '\' order by Purpose__c limit :taskLimit offset :offsetValue';
        queryString +=' ActivityDate = null and OwnerId in : subordinateIdSet and Status != \'Completed\' order by Purpose__c limit :taskLimit offset :offsetValue';

        noDateTaskList = Database.query(queryString);
    }

    private void countTasks(){

        totalTasks = [select Count() from Task where ActivityDate = null and OwnerId in: subordinateIdSet and Status != 'Completed'];
    }

    private void countFilteredTasks(){

        String queryString = 'select Count() from Task where';
        //queryString = (String.isNotBlank(filterTask.Purpose__c)) ? queryString + ' Purpose__c = \'' + filterTask.Purpose__c + '\' and' : queryString;
        queryString = (String.isNotBlank(filterTask.CallObject)) ? queryString + ' Owner.Name like \'%' + String.escapeSingleQuotes(filterTask.CallObject) + '%\' and' : queryString;
        queryString = (String.isNotBlank(filterTask.Type)) ? queryString + ' Type = \'' + filterTask.Type + '\' and' : queryString;
        queryString = (String.isNotBlank(filterTask.Subject)) ? queryString + ' Subject like \'%' + String.escapeSingleQuotes(filterTask.Subject) + '%\' and' : queryString;
        queryString +=' ActivityDate = null and OwnerId in : subordinateIdSet and Status != \'Completed\'';
        totalFilteredTasks = Database.countQuery(queryString);
    }

    public void filterAction(){
        countFilteredTasks();
        if(pageNumber * taskLimit > totalFilteredTasks){
            pageNumber = totalFilteredTasks / taskLimit;
        }

        taskListBuilder();
    }

    public void saveDate(){
        List<Task> saveList = new List<Task>();
        for(Task record : noDateTaskList){
            if(record.ActivityDate != null){
                saveList.add(record);
            }
        }

        update saveList;
        countTasks();
        filterAction();
    }

    public void nextPage(){
        pageNumber += 1;
        taskListBuilder();
    }

    public void previousPage(){
        pageNumber -= 1;
        taskListBuilder();
    }

    public Boolean getHasNext(){
        return (!noDateTaskList.isEmpty() && (pageNumber * taskLimit) < totalFilteredTasks) ? true : false;
    }

}