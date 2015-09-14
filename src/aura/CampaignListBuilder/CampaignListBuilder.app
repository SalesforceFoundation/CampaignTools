<aura:application controller="CampaignListBuilder_CTRL">
	<aura:attribute name="campaign" type="Campaign"/>
    <aura:attribute name="csegRoot" type="CSegment"/>
    <aura:attribute name="csegRootOriginal" type="CSegment"/>
    <aura:attribute name="csegExcludes" type="CSegment"/>
    <aura:handler name="init" value="{!this}" action="{!c.doInit}" />
    <aura:handler event="c:addCSegmentEvent" action="{!c.handleAddCSegmentEvent}"/>    
    <ltng:require styles="/resource/bssf1" />

    <!-- only needed by autocomplete component, but lightning bug fails to load it there -->
    <ltng:require scripts="/resource/jquery,/resource/jqueryui/jqueryui/jquery-ui.js," 
                  styles="/resource/jqueryui/jqueryui/jquery-ui.css" />

	<div class="bootstrap-sf1">
        <div class="container">
            <div class="navbar navbar-inverse">
                <div class="navbar-header">
		            <a href="#" class="navbar-brand">Campaign List for {!v.campaign.Name}</a>
                </div>
            </div>
            <ui:button aura:id="button" buttonTitle="Click to save and return to campaign" class="btn btn-default" label="Save &amp; Close" press="{!c.saveAndClose}" />
            <ui:button aura:id="button" buttonTitle="Click to return to campaign" class="btn btn-default" label="Close" press="{!c.close}" />
            <hr/>
            <p/>
			<c:SourceMultiList group="{!v.csegRoot}" />
            <h3>Excludes</h3>
            <c:SourceMultiList group="{!v.csegExcludes}" />
         </div>
    </div>
</aura:application>