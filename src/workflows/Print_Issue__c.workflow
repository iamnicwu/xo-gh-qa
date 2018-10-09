<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Copy_Publication_ID_Number</fullName>
        <description>Copy Publication ID Number into Publication ID External ID field</description>
        <field>Publication_Id_External_ID__c</field>
        <formula>TEXT(VALUE(Publication_ID_Number__c) + 5000)</formula>
        <name>Copy Publication ID Number</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Copy Publication ID Number</fullName>
        <actions>
            <name>Copy_Publication_ID_Number</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Print_Issue__c.Publication_Id_External_ID__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
