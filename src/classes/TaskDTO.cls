/**
 * Task Data Transfer object
 */
public with sharing class TaskDTO {
  @AuraEnabled public String id { get; set; }
  @AuraEnabled public String taskName { get; set; }

  public TaskDTO(String id, String name) {
    this.id = id;
    this.taskName = name;
  }
}