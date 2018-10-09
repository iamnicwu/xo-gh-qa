public with sharing class EmailUtility {
	
  private static final String SF_BASE_URL = URL.getSalesforceBaseUrl().toExternalForm();

  public static Messaging.SingleEmailMessage createTwoDayContractEmail(Opportunity currentOpp) {
    Messaging.SingleEmailMessage twoDayEmail = new Messaging.SingleEmailMessage();

    String subtitle = Label.Echo_Sign_Notification_Subtitle;
    String title = Label.Echo_Sign_Two_Day_Title;
    String bodyText = Label.Echo_Sign_Two_Day_Body.replace('{OPPLINK}', '<a href="' + SF_BASE_URL + '/' + currentOpp.Id + '">here</a>');

    twoDayEmail.setSubject(Label.Echo_Sign_Two_Day_Subject);
    twoDayEmail.setHTMLBody(createEmailBody(subtitle, title, bodyText));
    twoDayEmail.setTargetObjectId(currentOpp.OwnerId);
    twoDayEmail.saveAsActivity = false;

    return twoDayEmail;
  }

  public static Messaging.SingleEmailMessage createExpiredContractEmail(Opportunity currentOpp) {
    Messaging.SingleEmailMessage expiredEmail = new Messaging.SingleEmailMessage();

    String subtitle = Label.Echo_Sign_Notification_Subtitle;
    String title = Label.Echo_Sign_Expired_Title;
    String bodyText = Label.Echo_Sign_Expired_Body.replace('{OPPLINK}', '<a href="' + SF_BASE_URL + '/' + currentOpp.Id + '" target="_blank">here</a>');

    expiredEmail.setSubject(Label.Echo_Sign_Expired_Subject);
    expiredEmail.setHTMLBody(createEmailBody(subtitle, title, bodyText));
    expiredEmail.setTargetObjectId(currentOpp.OwnerId);
    expiredEmail.saveAsActivity = false;

    return expiredEmail;
  }

  public static Messaging.SingleEmailMessage createWaitListOnDeckEmail(Inventory__c currentInventory) {

    String formattedDate = currentInventory.Inventory_Hold_Expiry_Date__c.Month() + '/' + currentInventory.Inventory_Hold_Expiry_Date__c.Day() + '/' + currentInventory.Inventory_Hold_Expiry_Date__c.Year();

    Messaging.SingleEmailMessage onDeckEmail = new Messaging.SingleEmailMessage();

    String subtitle = Label.Waitlist_Notifications_Subtitle;
    String title = Label.Waitlist_Move_On_Deck_Notifications_Title;
    // csp-1992
    String bodyText = '<a href="' + SF_BASE_URL + '/' + currentInventory.Waitlist_Account__c + '">' + currentInventory.Waitlist_Account__r.Name + '</a>' + ' has moved to the top of the list for ' + 
                      currentInventory.Product_Rate_Plan__r.zqu__Product__r.Name + ' - ' + currentInventory.Product_Rate_Plan__r.Name + '.' + 
                      '<br/><br/>They will be available to sell until ' + formattedDate +
                      ' to create a quote, after which the next Account on the waitlist will be notified.';

    onDeckEmail.setSubject(Label.Waitlist_Move_On_Deck_Notifications_Subject);
    onDeckEmail.setHTMLBody(createEmailBody(subtitle, title, bodyText));
    onDeckEmail.setTargetObjectId(currentInventory.Waitlist_Account__r.OwnerId);
    onDeckEmail.saveAsActivity = false;

    return onDeckEmail;
  }

  public static String createEmailBody(String subtitle, String title, String bodyText) {
    String htmlBody;

    htmlBody = '<div style="text-align: center; background-color: grey; padding: 20px 0px;">'
                + '<div style="display: inline-block; width: 70%; background-color: white; border-radius: 4px 4px 4px 4px; -moz-border-radius: 4px 4px 4px 4px; -webkit-border-radius: 4px 4px 4px 4px;">'
                  /* HEADER SECTION */
                  + '<div style="background-color: black; padding: 20px 10px 15px 20px; border-radius: 4px 4px 0px 0px; -moz-border-radius: 4px 4px 0px 0px; -webkit-border-radius: 4px 4px 0px 0px;">'
                    /* SUB TITLE SECTION */
                    + '<div style="color: white; text-align: left; letter-spacing: 1px; font-family: sans-serif; font-weight: 100;">'
                      + subtitle
                    + '</div>'
                    /* TITLE SECTION */
                    + '<div style="color: rgb(178,204,133); text-align: left; font-size: 24px; letter-spacing: 0.75px; font-family: sans-serif;">'
                      + title
                    + '</div>'
                  + '</div>'
                /* BODY SECTION */
                + '<div style="text-align: left; padding: 20px;">'
                  + bodyText
                + '</div>'
              + '</div>'
            + '</div>';

    System.debug(htmlBody);
    return htmlBody;
  }

  public static String createEmailBody(String title, String bodyText) {
    String htmlBody;

    htmlBody = '<div style="text-align: center; background-color: grey; padding: 20px 0px;">'
                + '<div style="display: inline-block; width: 70%; background-color: white; border-radius: 4px 4px 4px 4px; -moz-border-radius: 4px 4px 4px 4px; -webkit-border-radius: 4px 4px 4px 4px;">'
                  /* HEADER SECTION */
                  + '<div style="background-color: black; padding: 20px 10px 15px 20px; border-radius: 4px 4px 0px 0px; -moz-border-radius: 4px 4px 0px 0px; -webkit-border-radius: 4px 4px 0px 0px;">'
                    /* TITLE SECTION */
                    + '<div style="color: rgb(178,204,133); text-align: left; font-size: 24px; letter-spacing: 0.75px; font-family: sans-serif;">'
                      + title
                    + '</div>'
                  + '</div>'
                /* BODY SECTION */
                + '<div style="text-align: left; padding: 20px;">'
                  + bodyText
                + '</div>'
              + '</div>'
            + '</div>';

    return htmlBody;
  }
}