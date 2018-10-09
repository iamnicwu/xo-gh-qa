/**
 * Attachment Data Transfer object
 */
public with sharing class AttachmentDTO {
  @AuraEnabled public String id { get; set; }
  @AuraEnabled public String attachmentName { get; set; }

  public AttachmentDTO(String id, String name) {
    this.id = id;
    this.attachmentName = name;
  }
}