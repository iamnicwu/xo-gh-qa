/**
 * Attachment object data access object
 */
public with sharing class AttachmentDAO {
  private static AttachmentDAO instance;

  @TestVisible
  private static void setMock(AttachmentDAO mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The dao was already mocked or accessed.');
    }
    instance = mock;
  }

  public static AttachmentDAO getInstance() {
    if (instance == null) {
      instance = new AttachmentDAO();
    }
    return instance;
  }

  /*
   * Method to attachment for case
   *
   * @param String parentId The parent id for the attachment.
   * @return Attachment The Attachment or null.
   */
  public List<Attachment> getAttachmentOnCase(String parentId) {
    List<Attachment> attachments = [
        SELECT Id,
            Name
        FROM Attachment
        WHERE ParentId = :parentId
    ];

    return attachments;
  }

  /*
   * Method to create a new attachment
   *
   * @param String parentId The parent the attachment belongs to.
   * @param String fileName The name of the file.
   * @param String base64Data The file contents.
   * @param String contentType The file type.
   * @return String The Id of the attachment.
   */
  public String createAttachment(String parentId, String fileName, String base64Data, String contentType) {
    Attachment a = new Attachment();
    a.ParentId = parentId;
    a.Body = EncodingUtil.base64Decode(base64Data);
    a.Name = fileName;
    a.ContentType = contentType;
    insert a;

    return a.Id;
  }

  /**
   * Append content to file
   *
   * @param String attachmentId The attachment id.
   * @param String base64Data The file contents.
   * @return void.
   */
  public void appendToFile(String attachmentId, String base64Data) {
    List<Attachment> attachments = [
        SELECT
            Id,
            Body
        FROM Attachment
        WHERE Id = :attachmentId
        LIMIT 1
    ];
    Attachment a = attachments.size() == 1 ? attachments.get(0) : null;

    if (a != null) {
      String existingBody = EncodingUtil.base64Encode(a.Body);
      a.Body = EncodingUtil.base64Decode(existingBody + base64Data);
      update a;
    }
  }

  /**
   * Delete attachment
   *
   * @param String attachmentId The attachment id.
   * @return void.
   */
  public void deleteAttachment(String attachmentId) {
    List<Attachment> attachments = [
        SELECT
            Id
        FROM Attachment
        WHERE Id = :attachmentId
        LIMIT 1
    ];
    Attachment a = attachments.size() == 1 ? attachments.get(0) : null;

    if (a != null) {
      delete a;
    }
  }
}