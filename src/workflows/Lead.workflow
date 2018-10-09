<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Hot_Campaign</fullName>
        <description>Hot Campaign</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <recipient>lewu@xogrp.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Campaign_Member_Paid_Media</template>
    </alerts>
    <alerts>
        <fullName>New_Lead_Assignment_Notification</fullName>
        <description>New Lead Assignment Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>System_Template/LeadsNewassignmentnotification</template>
    </alerts>
    <alerts>
        <fullName>Other_Tier_Lead_Received</fullName>
        <description>Other Tier Lead Received</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/LeadOtherTierTemplateCSP2044</template>
    </alerts>
    <alerts>
        <fullName>Standard_Tier_Lead_Received</fullName>
        <description>Standard Tier Lead Received</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/LeadStandardTierTemplateCSP2044</template>
    </alerts>
    <alerts>
        <fullName>XO_Group_Internal_Freemium_Featured</fullName>
        <description>Inbound Paid Media Lead - contact immediately</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Inbound_Paid_Media_Lead_contact_immediately</template>
    </alerts>
    <alerts>
        <fullName>XO_Group_Internal_Freemium_Limited</fullName>
        <description>XO Group Internal - Freemium - Limited</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/LeadLimitedTierTemplateCSP2044</template>
    </alerts>
    <alerts>
        <fullName>XO_Group_Internal_Hubspot_Paid_Advertising</fullName>
        <description>XO Group Internal - Hubspot_Paid Advertising</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/PaidMediaTemplateLeadCSP2044</template>
    </alerts>
    <fieldUpdates>
        <fullName>FU_LeadBUNational</fullName>
        <description>Phase 1 National</description>
        <field>LeadBU__c</field>
        <literalValue>National</literalValue>
        <name>FU_LeadBUNational</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FU_LeadEmailAccount</fullName>
        <description>Phase 1 National</description>
        <field>EmailAccount__c</field>
        <formula>Email</formula>
        <name>FU_LeadEmailAccount</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FU_LeadSourceAcc</fullName>
        <description>Phase 1 National</description>
        <field>LeadSourceAcc__c</field>
        <formula>TEXT ( LeadSource )</formula>
        <name>FU_LeadSourceAcc</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Source_Acc_Update</fullName>
        <field>LeadSourceAcc__c</field>
        <formula>TEXT( LeadSource )</formula>
        <name>Lead Source Acc Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_BDR_BP_test</fullName>
        <field>BDR_BP_test__c</field>
        <literalValue>1</literalValue>
        <name>Update BDR BP test</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Owner</fullName>
        <field>OwnerId</field>
        <lookupValue>Distributable</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>Update Owner</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>testray</fullName>
        <field>testray__c</field>
        <formula>&apos;1&apos;</formula>
        <name>testray</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Core AE Self Prospecting Secondary</fullName>
        <actions>
            <name>Update_Owner</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>CSP-2791</description>
        <formula>AND(Record_Type_Name__c = &apos;Local&apos;,    ISPICKVAL(LeadSource , &apos;Self Prospecting&apos;),    CONTAINS(CreatedBy.UserRole.Name, &apos;Sales Representative&apos;),      !ISBLANK(Category_Group__c ),    Category_Group__c  = &apos;Secondary&apos;,    !ISPICKVAL(Lead_Creator_Type__c, &apos;Skip Assignment Rule&apos;),    ISPICKVAL(Status, &apos;Valid&apos;) )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Fill Lead Source Acc Field</fullName>
        <actions>
            <name>Lead_Source_Acc_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>TEXT(LeadSource) !=  LeadSourceAcc__c</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Has the Paid Media Moved to Valid</fullName>
        <actions>
            <name>Update_Owner</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>csp-2791</description>
        <formula>AND(Record_Type_Name__c = &apos;Local&apos;, ISPICKVAL( LeadSource, &apos;Paid Media&apos;),ISPICKVAL(Status, &apos;Valid&apos;))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Hot Lead Notification</fullName>
        <actions>
            <name>XO_Group_Internal_Freemium_Featured</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <description>CSP-2791</description>
        <formula>AND(            ISPICKVAL(LeadSource , &quot;Website&quot;),            BEGINS(OwnerId, &quot;005&quot;),            TODAY() = DATEVALUE(CreatedDate),            OR(ISCHANGED(LeadSource),                   ISCHANGED(OwnerId),                   ISNEW()             )   )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Is this a SSE Portfolio Lead</fullName>
        <actions>
            <name>Update_Owner</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>CSP-2791</description>
        <formula>AND(RecordType.Name = &apos;Local&apos;, ISPICKVAL(Status, &apos;Valid&apos;), Portfolio__c = &apos;Senior Sales Executive&apos;, !ISPICKVAL(LeadSource , &apos;Paid Media&apos;), !ISPICKVAL(Lead_Creator_Type__c, &apos;Skip Assignment Rule&apos;), OR( AND(!CONTAINS(CreatedBy.UserRole.Name, &apos;Inside Sales&apos;),!CONTAINS(CreatedBy.UserRole.Name, &apos;Sales Representative&apos;)), !ISPICKVAL(LeadSource , &apos;Self Prospecting&apos;), ISNULL(Primary_Category__c), AND( !ISBLANK(Category_Group__c), !(Category_Group__c = &apos;Primary&apos;), !(Category_Group__c = &apos;Secondary&apos;) ) ) )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>New Lead Assignment Notification</fullName>
        <actions>
            <name>A_new_lead_has_been_assigned_to_you</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <formula>AND(  OwnerId != PRIORVALUE( OwnerId ),  RecordType.DeveloperName = &quot;Local&quot; )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>SSE Self Prospecting Secondary</fullName>
        <actions>
            <name>Update_Owner</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>CSP-2791</description>
        <formula>AND(RecordType.Name = &apos;Local&apos;,               ISPICKVAL(LeadSource , &apos;Self Prospecting&apos;),              CONTAINS(CreatedBy.UserRole.Name, &apos;Inside Sales SSE&apos;),              !ISBLANK(Category_Group__c ),              Category_Group__c  = &apos;Secondary&apos;,              !ISPICKVAL(Lead_Creator_Type__c, &apos;Skip Assignment Rule&apos;),              ISPICKVAL(Status, &apos;Valid&apos;)            )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>TEST SS-6092</fullName>
        <actions>
            <name>Hot_Campaign</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>Id = &apos;&apos;</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WF_LeadBUNational</fullName>
        <actions>
            <name>FU_LeadBUNational</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Phase 1 National</description>
        <formula>IF(RecordType.Name == &quot;National&quot;, TRUE, FALSE) &amp;&amp; ( ISNEW() || ISCHANGED( RecordTypeId ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WF_LeadEmailAcc</fullName>
        <actions>
            <name>FU_LeadEmailAccount</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FU_LeadSourceAcc</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>SS-7555
Phase 1 National - populate EmailAccount__c with Email</description>
        <formula>OR(
        ISNEW(),
        ISCHANGED(Email),
        ISCHANGED(LeadSource)
       )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>XO Group Internal - Freemium %E2%80%93 Featured Lead</fullName>
        <actions>
            <name>XO_Group_Internal_Freemium_Featured</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>CSP - 2044
Lead_Source__r.Name == &quot;XO Group Internal - Freemium&quot;
&amp;&amp;
CONTAINS(Fulfillment_Data__c, &quot;Featured&quot;)</description>
        <formula>False</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>XO Group Internal - Freemium %E2%80%93 Limited Lead</fullName>
        <actions>
            <name>XO_Group_Internal_Freemium_Limited</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>CSP - 2044
Lead_Source__r.Name == &quot;XO Group Internal - Freemium&quot;
&amp;&amp;
CONTAINS(Fulfillment_Data__c, &quot;Limited&quot;)</description>
        <formula>False</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>XO Group Internal - Freemium %E2%80%93 Other Lead</fullName>
        <actions>
            <name>Other_Tier_Lead_Received</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>CSP - 2044
Lead_Source__r.Name == &quot;XO Group Internal - Freemium&quot;
&amp;&amp;
NOT(CONTAINS(Fulfillment_Data__c, &quot;Standard&quot;))
&amp;&amp;
NOT(CONTAINS(Fulfillment_Data__c, &quot;Limited&quot;))
&amp;&amp;
NOT(CONTAINS(Fulfillment_Data__c, &quot;Featured&quot;))</description>
        <formula>False</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>XO Group Internal - Freemium %E2%80%93 Standard Lead</fullName>
        <actions>
            <name>Standard_Tier_Lead_Received</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>CSP - 2044
Lead_Source__r.Name == &quot;XO Group Internal - Freemium&quot;
&amp;&amp; 
CONTAINS(Fulfillment_Data__c, &quot;Standard&quot;)</description>
        <formula>False</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>XO Group Internal - Hubspot_Paid Advertising</fullName>
        <actions>
            <name>XO_Group_Internal_Hubspot_Paid_Advertising</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>(Lead_Source__r.Name = &apos;XO Group Internal - Hubspot_Paid Advertising-A&apos;)||(Lead_Source__r.Name = &apos;XO Group Internal - Hubspot_Paid Advertising-B&apos;)</description>
        <formula>False</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <tasks>
        <fullName>A_new_lead_has_been_assigned_to_you</fullName>
        <assignedToType>owner</assignedToType>
        <description>A new lead has been assigned to you.</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>A new lead has been assigned to you.</subject>
    </tasks>
</Workflow>
