<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Local_Sales_Rep_Assignment_Name</fullName>
        <field>Name</field>
        <formula>MID(
(
IF(NOT(ISBLANK(Zip_Code__c)), Zip_Code__r.ZipCode__c + &apos; - &apos;, &apos;&apos;) + 
IF(NOT(ISBLANK(Market__c)), Market__r.Name + &apos; - &apos;, &apos;&apos;) + 
IF(NOT(ISBLANK(Category__c)), Category__r.Name + &apos; - &apos;, &apos;&apos;) + 
Sales_Rep__r.FirstName + &apos; &apos; + Sales_Rep__r.LastName
)
,1
,80
)</formula>
        <name>Local Sales Rep Assignment Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Local Sales Rep Assignment Name</fullName>
        <actions>
            <name>Local_Sales_Rep_Assignment_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR( ISNEW(), ISCHANGED( Sales_Rep__c ), ISCHANGED( Category__c ), ISCHANGED( Market__c ), ISCHANGED( Zip_Code__c ) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
