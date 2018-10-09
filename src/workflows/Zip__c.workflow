<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Zip_set_zip_code_from_name</fullName>
        <field>ZipCode__c</field>
        <formula>Name</formula>
        <name>Zip - set zip code from name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Zip - Copy code to external ID</fullName>
        <actions>
            <name>Zip_set_zip_code_from_name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
