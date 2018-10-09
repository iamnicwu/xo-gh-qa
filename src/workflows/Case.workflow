<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>NotifySupportForDefaultRecordType</fullName>
        <description>NotifySupportForDefaultRecordType</description>
        <protected>false</protected>
        <recipients>
            <recipient>chhuang@xogrp.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>choffart@xogrp.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>ebourque@xogrp.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>jedeng@xogrp.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>rali@xogrp.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/NotifySupportForDefaultRecordType</template>
    </alerts>
    <alerts>
        <fullName>Notify_AE_Old_Closed_Case</fullName>
        <description>Closed Case 5 Days Old Email</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Closed_Case_Old</template>
    </alerts>
    <alerts>
        <fullName>Notify_Internal_Case_Team_Members_Case_was_Lost</fullName>
        <ccEmails>escalations@theknot.com</ccEmails>
        <description>Notify Internal Case Team Members Case was Lost</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <field>Account_SS__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Reporter_User_Name__c</field>
            <type>userLookup</type>
        </recipients>
        <senderAddress>escalations@theknot.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Notify_Internal_Case_Team_Members_Case_was_Lost</template>
    </alerts>
    <alerts>
        <fullName>Notify_Internal_Case_Team_that_Cancels_Case_Was_Won</fullName>
        <ccEmails>escalations@theknot.com</ccEmails>
        <description>Notify Internal Case Team that Cancels Case Was Won</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <field>Account_SS__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Owner_Manager__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Reporter_User_Name__c</field>
            <type>userLookup</type>
        </recipients>
        <senderAddress>escalations@theknot.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Notify_Internal_Case_Team_that_Cancels_Case_Was_Won</template>
    </alerts>
    <alerts>
        <fullName>Notify_case_contact_when_a_case_come_in</fullName>
        <ccEmails>jedeng@g-1xonzckp0tqss18usahc0yq1ddy6lwbwlw0e8qowgd9gsnomu9.3f-cq24uac.cs92.case.sandbox.salesforce.com</ccEmails>
        <description>Notify case contact when a case come in</description>
        <protected>false</protected>
        <recipients>
            <field>ContactEmail</field>
            <type>email</type>
        </recipients>
        <senderAddress>escalations@theknot.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Notify_contact_when_a_case_come</template>
    </alerts>
    <alerts>
        <fullName>Open_Cancelled_Case_Email_Alert_for_Case_Team_Contain_Acct_Owner</fullName>
        <ccEmails>jedeng@g-1xonzckp0tqss18usahc0yq1ddy6lwbwlw0e8qowgd9gsnomu9.3f-cq24uac.cs92.case.sandbox.salesforce.com</ccEmails>
        <description>Open Cancelled Case Email Alert for Case Team Contain Acct Owner</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <field>Account_SS__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Reporter_User_Name__c</field>
            <type>userLookup</type>
        </recipients>
        <senderAddress>escalations@theknot.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/New_Cancell_Case_Creation_email</template>
    </alerts>
    <alerts>
        <fullName>Open_Cancelled_Case_Email_Alert_for_Case_Team_Not_Contain_Acct_Owner</fullName>
        <ccEmails>jedeng@g-1xonzckp0tqss18usahc0yq1ddy6lwbwlw0e8qowgd9gsnomu9.3f-cq24uac.cs92.case.sandbox.salesforce.com</ccEmails>
        <description>Open Cancelled Case Email Alert for Case Team Not Contain Acct Owner</description>
        <protected>false</protected>
        <recipients>
            <field>Account_SS__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Reporter_User_Name__c</field>
            <type>userLookup</type>
        </recipients>
        <senderAddress>escalations@theknot.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/New_Cancell_Case_Creation_email</template>
    </alerts>
    <alerts>
        <fullName>Reviews_Case_Automated_Reply_Email</fullName>
        <ccEmails>reviewinquiry@theknot.com</ccEmails>
        <description>Reviews Case Automated Reply Email</description>
        <protected>false</protected>
        <recipients>
            <field>SuppliedEmail</field>
            <type>email</type>
        </recipients>
        <senderAddress>reviewinquiry@theknot.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Reviews_Case_Automated_Reply_Email</template>
    </alerts>
    <alerts>
        <fullName>XO_Group_NVM_New_Voicemail_Case</fullName>
        <description>XO Group NVM New Voicemail Case</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/NVMVoicemailTaskNotification_Case</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_Past_Due_at_Case_Open</fullName>
        <field>Past_Due_on_Case_Open__c</field>
        <formula>Account_Past_Due_Balance__c</formula>
        <name>Set Past Due at Case Open</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SubjectUpdateForReviewCase</fullName>
        <description>For CSP-2726</description>
        <field>Subject</field>
        <formula>IF(ISBLANK(text(Reason)),

IF( LEN(Subject) &gt;220 , 
LEFT(Subject, 220) &amp; &quot; [ ref:_&quot; &amp; LEFT($Organization.Id,5) &amp; SUBSTITUTE(RIGHT($Organization.Id,10), &quot;0&quot;, &quot;&quot; )&amp; &quot;._&quot; &amp; LEFT(Id,5) &amp; SUBSTITUTE(Left(RIGHT(Id,10), 5), &quot;0&quot;, &quot;&quot;) &amp; RIGHT(Id,5) &amp; &quot;:ref ]&quot; 
, Subject &amp; &quot; [ ref:_&quot; &amp; LEFT($Organization.Id,5) &amp; SUBSTITUTE(RIGHT($Organization.Id,10), &quot;0&quot;, &quot;&quot; )&amp; &quot;._&quot; &amp; LEFT(Id,5) &amp; SUBSTITUTE(Left(RIGHT(Id,10), 5), &quot;0&quot;, &quot;&quot;) &amp; RIGHT(Id,5) &amp; &quot;:ref ]&quot; 
)


,text(Reason) &amp; &quot; [ ref:_&quot; &amp; LEFT($Organization.Id,5) &amp; SUBSTITUTE(RIGHT($Organization.Id,10), &quot;0&quot;, &quot;&quot; )&amp; &quot;._&quot; &amp; LEFT(Id,5) &amp; SUBSTITUTE(Left(RIGHT(Id,10), 5), &quot;0&quot;, &quot;&quot;) &amp; RIGHT(Id,5) &amp; &quot;:ref ]&quot;
)</formula>
        <name>SubjectUpdateForReviewCase</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SubjectUpdateToAppendThreadId</fullName>
        <field>Subject</field>
        <formula>IF( LEN(Subject) &gt;220 ,

LEFT(Subject, 220) &amp; &quot; [ ref:_&quot; &amp; LEFT($Organization.Id,5) &amp; SUBSTITUTE(RIGHT($Organization.Id,10), &quot;0&quot;, &quot;&quot; )&amp; &quot;._&quot; &amp; LEFT(Id,5) &amp; SUBSTITUTE(Left(RIGHT(Id,10), 5), &quot;0&quot;, &quot;&quot;) &amp; RIGHT(Id,5) &amp; &quot;:ref ]&quot;
 ,
Subject &amp; &quot; [ ref:_&quot; &amp; LEFT($Organization.Id,5) &amp; SUBSTITUTE(RIGHT($Organization.Id,10), &quot;0&quot;, &quot;&quot; )&amp; &quot;._&quot; &amp; LEFT(Id,5) &amp; SUBSTITUTE(Left(RIGHT(Id,10), 5), &quot;0&quot;, &quot;&quot;) &amp; RIGHT(Id,5) &amp; &quot;:ref ]&quot;

)</formula>
        <name>SubjectUpdateToAppendThreadId</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Asset_Collection_Charge_Number</fullName>
        <field>Subscription_Charge_Number__c</field>
        <formula>SubscriptionProductCharge__r.Zuora__ChargeNumber__c</formula>
        <name>Update Asset Collection Charge Number</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Asset_Collection_LDE_Launch_Date</fullName>
        <field>LDE_Launch_Date__c</field>
        <formula>SubscriptionProductCharge__r.LDE_Email_Launch_Date__c</formula>
        <name>Update Asset Collection LDE Launch Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Asset_Collection_Rate_Plan_Name</fullName>
        <field>Rate_Plan_Name__c</field>
        <formula>SubscriptionProductCharge__r.Zuora__RatePlanName__c</formula>
        <name>Update Asset Collection Rate Plan Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Asset_Collection_Subscription</fullName>
        <field>Subscription_Name__c</field>
        <formula>SubscriptionProductCharge__r.Zuora__Subscription__r.Name</formula>
        <name>Update Asset Collection Subscription</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Asset_Collection_Term_End_Date</fullName>
        <field>Term_End_Date__c</field>
        <formula>SubscriptionProductCharge__r.Zuora__Subscription__r.Zuora__TermEndDate__c</formula>
        <name>Update Asset Collection Term End Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Asset_Collection_Term_Start_Date</fullName>
        <field>Term_Start_Date__c</field>
        <formula>SubscriptionProductCharge__r.Zuora__Subscription__r.Zuora__TermStartDate__c</formula>
        <name>Update Asset Collection Term Start Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_outcome_to_paid</fullName>
        <field>Outcome__c</field>
        <literalValue>Paid</literalValue>
        <name>Update outcome to paid</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Auto Reply Reviews Case Email</fullName>
        <actions>
            <name>Reviews_Case_Automated_Reply_Email</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>CSP-2212</description>
        <formula>AND( /*  PROD version Adding the crieria of Organizationid to prevent mis-sending email to vendor after UAT refresh  NOT(ISBLANK(SuppliedEmail)), RecordType.Name = &apos;3 - Reviews&apos;, Auto_Reply_Flag__c , $Organization.Id = &apos;00D3F000000Cq24&apos; */   /* UAT version*/ CONTAINS(SuppliedEmail, &apos;@xogrp.com&apos;), RecordType.Name = &apos;3 - Reviews&apos;, NOT(ISBLANK(SuppliedEmail)), Auto_Reply_Flag__c  )</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>CaseAppendThreadIdToSubject</fullName>
        <actions>
            <name>SubjectUpdateToAppendThreadId</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>1 - Cancels,2 - Onboarding,Rep Billing,Inbound</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Email Notification at 5 days</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>notEqual</operation>
            <value>Closed</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Type</field>
            <operation>equals</operation>
            <value>Cancel Request</value>
        </criteriaItems>
        <description>Send Email when closed case is 5 days old.</description>
        <triggerType>onCreateOnly</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Notify_AE_Old_Closed_Case</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Case.CreatedDate</offsetFromField>
            <timeLength>5</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Notify Contact when has been associated to case</fullName>
        <actions>
            <name>Notify_case_contact_when_a_case_come_in</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>CSP-2926</description>
        <formula>AND(
 RecordType.Name=&quot;1 - Cancels&quot;,  
 NOT(ISBLANK(ContactId)), 
   OR(     
    ISNEW(),     
    ISCHANGED(ContactId) 
         )
  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Internal Case Team Members Case was Lost</fullName>
        <actions>
            <name>Notify_Internal_Case_Team_Members_Case_was_Lost</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>CSP-2213</description>
        <formula>AND(
    OR(
        ISCHANGED(Status),
        AND(
            NOT(ISPICKVAL(PRIORVALUE(Outcome__c), &quot;Cancelled&quot;)),
            NOT(ISPICKVAL(PRIORVALUE(Outcome__c), &quot;Max attempts no contact&quot;))              
        )
    ),
    OR(
       ISPICKVAL(Outcome__c, &quot;Cancelled&quot;),
       ISPICKVAL(Outcome__c, &quot;Max attempts no contact&quot;)
    ),
    NOT(ISBLANK(AccountId)),
    ISPICKVAL(Status, &quot;Closed&quot;),
    RecordType.Name=&quot;1 - Cancels&quot;
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Notify Internal Case Team that Cancels Case Was Won</fullName>
        <actions>
            <name>Notify_Internal_Case_Team_that_Cancels_Case_Was_Won</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>CSP-2221</description>
        <formula>AND(     OR(         ISCHANGED(Status),         AND(             NOT(ISPICKVAL(PRIORVALUE(Outcome__c), &quot;Saved Hard Concessions&quot;)),             NOT(ISPICKVAL(PRIORVALUE(Outcome__c), &quot;Saved No Concessions&quot;)),             NOT(ISPICKVAL(PRIORVALUE(Outcome__c), &quot;Saved Soft Concessions&quot;)),             NOT(ISPICKVAL(PRIORVALUE(Outcome__c), &quot;Max Attempts - No Written Request&quot;))         )     ),     OR(         ISPICKVAL(Outcome__c, &quot;Saved Hard Concessions&quot;),         ISPICKVAL(Outcome__c, &quot;Saved No Concessions&quot;),         ISPICKVAL(Outcome__c, &quot;Saved Soft Concessions&quot;),         ISPICKVAL(Outcome__c, &quot;Max Attempts - No Written Request&quot;)     ),     NOT(ISBLANK(AccountId)),     ISPICKVAL(Status, &quot;Closed&quot;),     RecordType.Name=&quot;1 - Cancels&quot; )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>NotifySupportForDefaultRecordType</fullName>
        <actions>
            <name>NotifySupportForDefaultRecordType</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>Default</value>
        </criteriaItems>
        <description>CSP-2261 New case record type &quot;default&quot; to handle the records of none record type case record</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Open Cancelled Case Email Alert For Case Team VIP</fullName>
        <actions>
            <name>Open_Cancelled_Case_Email_Alert_for_Case_Team_Not_Contain_Acct_Owner</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>The origin of CSP-2220 
Update by CSP-2484</description>
        <formula>AND(  	RecordType.Name=&quot;1 - Cancels&quot;,  	NOT(ISBLANK(AccountId)),  	OR(  		ISNEW(),  		ISCHANGED(AccountId),  		AND(  			ISPICKVAL(PRIORVALUE( Status ),&apos;CLOSED&apos;),        ISPICKVAL(PRIORVALUE( Status ),&apos;Canceled Waiting on Payment&apos;),        ISPICKVAL(PRIORVALUE( Status ),&apos;Saved Waiting for Payment&apos;),        NOT(ISPICKVAL( Status ,&apos;CLOSED&apos;)),       NOT(ISPICKVAL( Status ,&apos;Canceled Waiting on Payment&apos;)),       NOT(ISPICKVAL( Status ,&apos;Saved Waiting for Payment&apos;))  		)  	),  	Account.VIP_Program__c  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Open Cancelled Case Email Alert for Case Team</fullName>
        <actions>
            <name>Open_Cancelled_Case_Email_Alert_for_Case_Team_Contain_Acct_Owner</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>CSP-2220</description>
        <formula>AND(   RecordType.Name=&quot;1 - Cancels&quot;,   NOT(ISBLANK(AccountId)),   OR(     ISNEW(),     ISCHANGED(AccountId),     AND(       ISPICKVAL(PRIORVALUE( Status ),&apos;CLOSED&apos;) ,        ISPICKVAL(PRIORVALUE( Status ),&apos;Canceled Waiting on Payment&apos;) ,        ISPICKVAL(PRIORVALUE( Status ),&apos;Saved Waiting for Payment&apos;) ,        NOT(ISPICKVAL( Status ,&apos;CLOSED&apos;)),       NOT(ISPICKVAL( Status ,&apos;Canceled Waiting on Payment&apos;)) ,       NOT(ISPICKVAL( Status ,&apos;Saved Waiting for Payment&apos;))       )   ),   NOT(Account.VIP_Program__c)  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Populate the Subs Charge Inf%2E for Asset Collection</fullName>
        <actions>
            <name>Update_Asset_Collection_Charge_Number</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Asset_Collection_LDE_Launch_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Asset_Collection_Rate_Plan_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Asset_Collection_Subscription</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Asset_Collection_Term_End_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Asset_Collection_Term_Start_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>CSP-2942 Populate the Subs Charge Inf. for Asset Collection Case</description>
        <formula>And(
$User.Casesafe_ID__c &lt;&gt; &apos;005j000000DUJM4AAP&apos;,
RecordType.Name = &apos;Asset Collection&apos;,
NOT(ISPICKVAL(Origin,&apos;Auto-Generated&apos;)),
NOT(ISBLANK(SubscriptionProductCharge__c ))
)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Review Case Subject Updated</fullName>
        <actions>
            <name>SubjectUpdateForReviewCase</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>For CSP-2726</description>
        <formula>And(
	RecordType.Name = &quot;3 - Reviews&quot;,
	Or(
		ISNEW(),
		AND(
			ISCHANGED(Reason),
			NOT(ISBLANK(text(Reason)))
			)
		)
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Past Due on Case Open</fullName>
        <actions>
            <name>Set_Past_Due_at_Case_Open</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This will take the amount in Account Past Due Balance, and set this field so we have a stamped, static value that reflects what it was when the case was created.</description>
        <formula>AND(
NOT(ISBLANK(AccountId)) ,
Account.Past_Due_Balance__c&gt;0,
OR(ISNEW(),ISCHANGED(AccountId))
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update outcome when IHC case closed</fullName>
        <actions>
            <name>Update_outcome_to_paid</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>In House Collections</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>Closed</value>
        </criteriaItems>
        <description>ES-9048</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
