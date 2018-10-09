<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_email_to_Account_owner_when_add_service_to_waitlist</fullName>
        <description>Send email to Account owner when add service to waitlist</description>
        <protected>false</protected>
        <recipients>
            <recipient>jedeng@xogrp.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Notify_Account_Owner_When_waitlist_created</template>
    </alerts>
    <rules>
        <fullName>Send email to rep when add to waitlist</fullName>
        <actions>
            <name>Send_email_to_Account_owner_when_add_service_to_waitlist</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>SS-8097</description>
        <formula>TRUE</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
