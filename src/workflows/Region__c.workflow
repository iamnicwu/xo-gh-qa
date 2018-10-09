<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Region_Reference_Name</fullName>
        <field>Region_Name_External_Reference__c</field>
        <formula>Name</formula>
        <name>Set Region Reference Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Region Reference Name</fullName>
        <actions>
            <name>Set_Region_Reference_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Region_Name_External_Reference__c = &apos;&apos;</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
