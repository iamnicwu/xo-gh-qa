public abstract with sharing class AttachmentDAOMock extends AbstractMock {
  private List<Object> listOfArgs;

  protected override Object callMockedMethod(String stubbedMethodName, List<Object> listOfArgs) {
    this.listOfArgs = listOfArgs;

    if (stubbedMethodName == 'createAttachment') {
      System.assertEquals(4, listOfArgs.size());
      return createAttachment((String) listOfArgs[0], (String) listOfArgs[1], (String) listOfArgs[2], (String) listOfArgs[3]);
    } else if (stubbedMethodName == 'appendToFile') {
      System.assertEquals(2, listOfArgs.size());
      appendToFile((String) listOfArgs[0], (String) listOfArgs[1]);
      return null;
    } else if (stubbedMethodName == 'deleteAttachment') {
      System.assertEquals(1, listOfArgs.size());
      deleteAttachment((String) listOfArgs[0]);
      return null;
    } else if (stubbedMethodName == 'getAttachmentOnCase') {
      System.assertEquals(1, listOfArgs.size());
      return getAttachmentOnCase((String) listOfArgs[0]);
    }

    throw new Exceptions.MockException('Failed to find method for ' + stubbedMethodName);

  }

  public List<Object> getListOfArgs() {
    return this.listOfArgs;
  }

  public virtual String createAttachment(String parentId, String fileName, String base64Data, String contentType) {
    throw newUnsupportedMethodException('createAttachment');
  }

  public virtual void appendToFile(String attachmentId, String base64Data) {
    throw newUnsupportedMethodException('appendToFile');
  }

  public virtual void deleteAttachment(String attachmentId) {
    throw newUnsupportedMethodException('deleteAttachment');
  }

  public virtual List<Attachment> getAttachmentOnCase(String attachmentId) {
    throw newUnsupportedMethodException('getAttachmentOnCase');
  }
}