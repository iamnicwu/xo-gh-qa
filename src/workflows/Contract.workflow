<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>FU_StatusDraft</fullName>
        <description>Phase 1</description>
        <field>Status</field>
        <literalValue>Draft</literalValue>
        <name>FU_StatusDraft</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Updating_Days</fullName>
        <description>This is a Field update on Days Contract Open Field on contract when ever contract is Signed</description>
        <field>Days_Contract_Open__c</field>
        <formula>Now()- CreatedDate</formula>
        <name>Updating Days Contract Open</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Update on Days Contract Open</fullName>
        <actions>
            <name>Updating_Days</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contract.Status</field>
            <operation>equals</operation>
            <value>Signed</value>
        </criteriaItems>
        <description>This workflow Updates the Days Contract is open to Get Signed Field</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WF_ContractStatDraft</fullName>
        <actions>
            <name>FU_StatusDraft</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contract.ContractType__c</field>
            <operation>equals</operation>
            <value>Concierge Venue</value>
        </criteriaItems>
        <description>Phase 1 - during contract creation, status is defaulted to Draft</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
