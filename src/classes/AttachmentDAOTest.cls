@IsTest
private class AttachmentDAOTest {
  public static void deactivateTrigger() {
    // This is needed to get the test to pass since the Attachment trigger fires
    Deactivate_Trigger__c deactivateTrigger = new Deactivate_Trigger__c();
    deactivateTrigger.After_Delete__c = true;
    deactivateTrigger.After_Insert__c = true;
    deactivateTrigger.After_Update__c = true;
    deactivateTrigger.Before_Delete__c = true;
    deactivateTrigger.Before_Insert__c = true;
    deactivateTrigger.Before_Update__c = true;
    deactivateTrigger.Name = 'Attachment';
    insert deactivateTrigger;
  }

  @IsTest
  static void testCreateAttachment() {
    String fileName = 'test.txt';
    String base64Data = 'The data';
    String contentType = 'text/plain';

    AttachmentDAOTest.deactivateTrigger();

    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Case c = new Case();
    insert c;

    Test.startTest();
    String newAttachmentId = AttachmentDAO.getInstance().createAttachment(c.Id, fileName, base64Data, contentType);
    Test.stopTest();

    List<Attachment> attachments = [SELECT Id, ParentId, Body, Name FROM Attachment WHERE Id = :newAttachmentId LIMIT 1];
    System.assertEquals(1, attachments.size(), 'Should return 1 item.');
    System.assertEquals(c.Id, attachments.get(0).ParentId, 'Should have correct parent id.');
    System.assertEquals(fileName, attachments.get(0).Name, 'Should have correct name.');
    System.assertEquals(EncodingUtil.base64Decode('The data'), attachments.get(0).Body, 'Should have correct body.');
  }

  @IsTest
  static void testAppendToFile() {
    String fileName = 'test.txt';
    String base64Data = '';
    String contentType = 'text/plain';
    String appendedBase64Data = 'more data';

    AttachmentDAOTest.deactivateTrigger();

    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Case c = new Case();
    insert c;

    Test.startTest();
    String newAttachmentId = AttachmentDAO.getInstance().createAttachment(c.Id, fileName, base64Data, contentType);
    AttachmentDAO.getInstance().appendToFile(newAttachmentId, appendedBase64Data);
    Test.stopTest();

    List<Attachment> attachments = [SELECT Id, ParentId, Body, Name FROM Attachment WHERE Id = :newAttachmentId LIMIT 1];
    System.assertEquals(1, attachments.size(), 'Should return 1 item.');
    System.assertEquals(c.Id, attachments.get(0).ParentId, 'Should have correct parent id.');
    System.assertEquals(fileName, attachments.get(0).Name, 'Should have correct name.');
    System.assertEquals(EncodingUtil.base64Decode(base64Data + appendedBase64Data), attachments.get(0).Body, 'Should have correct body.');
  }

  @IsTest
  static void testGetAttachmentOnCase() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Case c = new Case();
    c.Origin = 'Web';
    insert c;

    AttachmentDAOTest.deactivateTrigger();

    Attachment attch = new Attachment();
    attch.Name = 'test.txt';
    attch.Body = EncodingUtil.base64Decode('stuff');
    attch.ContentType = 'text/plain';
    attch.ParentId = c.Id;
    insert attch;

    Test.startTest();
    List<Attachment> attachments = AttachmentDAO.getInstance().getAttachmentOnCase(c.Id);
    Test.stopTest();

    System.assertEquals(1, attachments.size(), 'Should return attachment.');
    System.assertEquals(attch.id, attachments.get(0).Id, 'Should have correct name.');
    System.assertEquals('test.txt', attachments.get(0).Name, 'Should have correct name.');
  }

  @IsTest
  static void testDeleteAttachment() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Case c = new Case();
    c.Origin = 'Web';
    insert c;

    AttachmentDAOTest.deactivateTrigger();

    Attachment attch = new Attachment();
    attch.Name = 'test.txt';
    attch.Body = EncodingUtil.base64Decode('stuff');
    attch.ContentType = 'text/plain';
    attch.ParentId = c.Id;
    insert attch;

    Test.startTest();
    AttachmentDAO.getInstance().deleteAttachment(attch.Id);
    Test.stopTest();

    List<Attachment> deleteAttachments = [SELECT Id FROM Attachment WHERE Id = :attch.Id];
    System.assertEquals(0, deleteAttachments.size(), 'Should have deleted attachment.');
  }
}