<aura:application>
    <aura:handler name="init" value="{!this}" action="{!c.doInit}" />
    <ltng:require styles="/resource/bssf1" />

	<div class="bootstrap-sf1">
        <div class="container">
			<c:SourceMultiList group="{!v.group}" />
            <h3>Excludes</h3>
            <c:SourceGroup group="{!v.excludes}" />
         </div>
    </div>
</aura:application>