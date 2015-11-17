public with sharing class CampaignList_CTRL {
    
    public Campaign cmp { get; set; }
    
    public CampaignList_CTRL(ApexPages.StandardController controller) {
        cmp = (Campaign)controller.getRecord();
        
    }

}