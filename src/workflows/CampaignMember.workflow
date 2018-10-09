<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_AE_Campaign_Member</fullName>
        <ccEmails>hotprospects@xogrp.com.uat</ccEmails>
        <ccEmails>okang+001@xogrp.com</ccEmails>
        <description>Notify AE Campaign Member</description>
        <protected>false</protected>
        <recipients>
            <type>campaignMemberDerivedOwner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Campaign_Member_Paid_Media</template>
    </alerts>
    <alerts>
        <fullName>Paid_Media_Notification</fullName>
        <ccEmails>hotprospects@xogrp.com.uat</ccEmails>
        <ccEmails>paidmediaalerts@xogrp.com.uat</ccEmails>
        <ccEmails>okang+001@xogrp.com</ccEmails>
        <description>Paid Media Notification</description>
        <protected>false</protected>
        <recipients>
            <recipient>rali@xogrp.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Campaign_Member_Paid_Media</template>
    </alerts>
    <alerts>
        <fullName>Response_Email_Notification_To_Sales_Rep</fullName>
        <description>Response Email Notification To Sales Rep</description>
        <protected>false</protected>
        <recipients>
            <type>campaignMemberDerivedOwner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Campaign_Response_Notification</template>
    </alerts>
    <alerts>
        <fullName>Send_Hot_Prospect_Notification</fullName>
        <description>Send Hot Prospect Notification</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <type>campaignMemberDerivedOwner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>System_Template/Campaign_Response_Notification</template>
    </alerts>
    <fieldUpdates>
        <fullName>Email_Sent_Date</fullName>
        <field>Email_Sent_Date__c</field>
        <formula>NOW()</formula>
        <name>Email Sent Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Campaign Response Email Notification</fullName>
        <actions>
            <name>Response_Email_Notification_To_Sales_Rep</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Email_Sent_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>CSP-2788 Campaign Response Email Notification</description>
        <formula>AND(    ISPICKVAL(Status,&apos;Responded&apos;),    OR(      ISCHANGED(Status),      ISNEW()     ),    ISPICKVAL(Campaign.Type,&apos;Internal Referral&apos;) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>CampaignMember Notification</fullName>
        <actions>
            <name>Notify_AE_Campaign_Member</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>CSP-1939 - When a CampaignMember is created for a Lead or Contact that is associated to a Campaign which has the flag notify AE checked then an email should send.
Updated for SS-5437</description>
        <formula>AND(
  Campaign.Notify_Sales_Team__c = True,
    OR( 
       DateValue(CreatedDate) &gt; DateValue(Lead.CreatedDate),
       CreatedDate  &lt;&gt;  Contact.CreatedDate
    )
)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Paid Media Notification</fullName>
        <actions>
            <name>Paid_Media_Notification</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISPICKVAL(Campaign.Type, &apos;Paid Media&apos;)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
