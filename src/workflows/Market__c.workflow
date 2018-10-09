<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Upd_Zuora_Desc_with_Short_Desc_Market</fullName>
        <field>Zuora_Description__c</field>
        <formula>Short_Description__c</formula>
        <name>Upd Zuora Desc with Short Desc - Market</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>WF to Upd Zuora Des with the Short Des -  Market</fullName>
        <actions>
            <name>Upd_Zuora_Desc_with_Short_Desc_Market</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Market__c.Short_Description__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Market__c.Zuora_Description__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
