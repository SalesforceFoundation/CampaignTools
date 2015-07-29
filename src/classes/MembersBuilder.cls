public with sharing class MembersBuilder {

    public MembersBuilder(ID rootSegmentID) {
        
        Set<ID> sourceCampaigns = new Set<ID>();
        Set<ID> sourceReports = new Set<ID>();
        //Retrieve all sources from all children segments of root segment
        for(Segment__c segment : [select Source_ID__c, Source_Type__c from Segment__c where Root_Segment__c = :rootSegmentID 
        and Source_ID__c != null]) {
            if(segment.Source_Type__c == 'Campaign') {
                sourceCampaigns.add(segment.Source_ID__c);
            } else if(segment.Source_Type__c == 'Report') {
                sourceReports.add(segment.Source_ID__c);
            }
        }
 
        //Each member can be a Lead or a Contact
        List<Member__c> membersToInsert = new List<Member__c>();
        Map<ID, CampaignMember> members = new Map<ID, CampaignMember>([select Contact.ID, Lead.ID, Campaign.ID, Campaign.Name 
                                                                from CampaignMember where Campaign.ID in :sourceCampaigns]);

        //Insert each Member and its sources
        membersToInsert.addAll(getMemberRecords(rootSegmentID, members));
        insert membersToInsert;
    }
    
    private List<Member__c> getMemberRecords(ID rootSegmentID, Map<ID, CampaignMember> campaignMembers) {
        Map<ID, Member__c> membersToInsert = new Map<ID, Member__c>();
        for(CampaignMember member : campaignMembers.values()) {
            //The member is a Contact and it's not in our map
            if(member.Contact.ID != null && membersToInsert.get(member.Contact.ID) == null) {
                membersToInsert.put(member.Contact.ID, new Member__c(Sources__c = member.Campaign.ID, 
                                                            Root_Segment__c = rootSegmentID, Contact__c = member.Contact.ID,
                                                            Source_Names__c = 'Campaign:' + member.Campaign.Name));
             //The member is a Lead and it's not in our map
            } else if(member.Lead.ID != null && membersToInsert.get(member.Lead.ID) == null) {
                membersToInsert.put(member.Lead.ID, new Member__c(Sources__c = member.Campaign.ID, 
                                                            Root_Segment__c = rootSegmentID, Lead__c = member.Lead.ID,
                                                            Source_Names__c = 'Campaign:' + member.Campaign.Name));
            } else {
                Member__c existingMember;
                //The member is a Contact and it's already in our map
                if(member.Contact.ID != null && membersToInsert.get(member.Contact.ID) != null) {
                    existingMember = membersToInsert.get(member.Contact.ID);
                //The member is a Lead and it's already in our map
                } else if(member.Lead.ID != null && membersToInsert.get(member.Lead.ID) != null) {
                    existingMember = membersToInsert.get(member.Lead.ID);
                }
                existingMember.Sources__c = existingMember.Sources__c + ';' + member.Campaign.ID;
                existingMember.Source_Names__c = existingMember.Source_Names__c + ';Campaign:' + member.Campaign.Name;
            }
        }
        return membersToInsert.values();
    }
}