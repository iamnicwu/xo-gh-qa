<aura:application description="CancelCaseApp"
                  extends="ltng:outApp"
                  implements="force:appHostable,flexipage:availableForAllPageTypes,forceCommunity:availableForAllPageTypes"
                  access="GLOBAL">
    <!-- Load the navigation events in the force namespace. -->
    <aura:dependency resource="markup://force:*" type="EVENT"/>
    <aura:dependency resource="c:CancelCase"/>
</aura:application>