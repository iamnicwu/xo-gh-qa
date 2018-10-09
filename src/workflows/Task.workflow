<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>XO_Group_NVM_New_Voicemail</fullName>
        <description>XO Group NVM New Voicemail</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/NVMVoicemailTaskNotification_v2</template>
    </alerts>
    <fieldUpdates>
        <fullName>Fill_in_Type_Mirror_Field</fullName>
        <field>Type_Mirror_of_Standard_field__c</field>
        <formula>TEXT(Type)</formula>
        <name>Fill in Type Mirror Field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Assignee</fullName>
        <field>OwnerId</field>
        <lookupValue>meuys@xogrp.com</lookupValue>
        <lookupValueType>User</lookupValueType>
        <name>Update Assignee</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Mirror_field_with_the_Type</fullName>
        <field>Type_Mirror_of_Standard_field__c</field>
        <formula>TEXT(Type)</formula>
        <name>Update Mirror field with the Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>123</fullName>
        <active>false</active>
        <formula>OR(
ISNEW(),
ISCHANGED(WhatId)
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Reassigning Voicemail Tasks to Customer Service Team</fullName>
        <actions>
            <name>Update_Assignee</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Task.Subject</field>
            <operation>equals</operation>
            <value>Voicemail from ContactWorld</value>
        </criteriaItems>
        <criteriaItems>
            <field>Task.Voicemail_Type__c</field>
            <operation>equals</operation>
            <value>Customer Service</value>
        </criteriaItems>
        <description>A workflow that will reassign Voicemails tasks for the customer service team to Meuy Saefong. Depricated by Process Builder - Assign Customer Service Voicemails to Meuy Saefong</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Type Mirror Filled in</fullName>
        <actions>
            <name>Fill_in_Type_Mirror_Field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task.Type</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>When Type gets populated</fullName>
        <actions>
            <name>Update_Mirror_field_with_the_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task.Type</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>XO Email Alert for NVM Voicemail</fullName>
        <actions>
            <name>XO_Group_NVM_New_Voicemail</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Task.Subject</field>
            <operation>equals</operation>
            <value>Voicemail from ContactWorld</value>
        </criteriaItems>
        <description>This WF rule will send out an email if a Task is created with the Subject line = Voicemail from ContactWorld and the Voicemail type is not Personal. Deprecated by Process Builder - Assign Customer Service Voicemails to Meuy Saefong.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
