<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Email_to_Salessupport_to_create_a_Jira_Ticket</fullName>
        <ccEmails>salessupport@xogrp.com</ccEmails>
        <description>Email to Salessupport to create a Jira Ticket</description>
        <protected>false</protected>
        <recipients>
            <recipient>ebourque@xogrp.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/XO_Exception_Email_ZuoraTCVAndPaymentSchedule_tcvException</template>
    </alerts>
    <outboundMessages>
        <fullName>XOExceptionCreated</fullName>
        <apiVersion>43.0</apiVersion>
        <description>XO Exception Message</description>
        <endpointUrl>https://collectors.sumologic.com/receiver/v1/http/ZaVnC4dhaV012YIKpSMdPK958xSR6rs_H9davmIV6WJcSs9ce5hbTqlI95tQIxF5Fl_V8ykqP1iAlwP2kANVqgJ1JlONJo_v4xKkvZWR03CBNzCJEb0P2A==</endpointUrl>
        <fields>Contact__c</fields>
        <fields>CreatedDate</fields>
        <fields>Failure_Area__c</fields>
        <fields>Id</fields>
        <fields>LastActivityDate</fields>
        <fields>LastModifiedDate</fields>
        <fields>Line_Number__c</fields>
        <fields>Message__c</fields>
        <fields>Name</fields>
        <fields>Related_Object_Id__c</fields>
        <fields>Severity__c</fields>
        <fields>Stack_Trace__c</fields>
        <fields>SystemModstamp</fields>
        <fields>Type__c</fields>
        <includeSessionId>true</includeSessionId>
        <integrationUser>khong@xogrp.com</integrationUser>
        <name>XOExceptionCreated</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <rules>
        <fullName>SumoLogger</fullName>
        <actions>
            <name>XOExceptionCreated</name>
            <type>OutboundMessage</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>XO_Exception__c.Message__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Log XO Exception to sumologic</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>ZuoraTCVAndPaymentSchedule Errors</fullName>
        <actions>
            <name>Email_to_Salessupport_to_create_a_Jira_Ticket</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>XO_Exception__c.Type__c</field>
            <operation>equals</operation>
            <value>ZuoraTCVAndPaymentSchedule.tcvException</value>
        </criteriaItems>
        <description>This should send an email when the ZuoraTCVAndPaymentSchedule has an exception created/</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
