public with sharing class MembersBuilder {

    public MembersBuilder(ID rootSegmentID) {
        
        Set<ID> sourceCampaigns = new Set<ID>();
        Set<ID> sourceReports = new Set<ID>();
        //Retrieve all sources from all children segments of root segment
        for(Segment__c segment : [select Source_ID__c, Source_Type__c from Segment__c where Root_Segment__c = :rootSegmentID and Source_ID__c != null]) {
            if(segment.Source_Type__c == 'Campaign') {
                sourceCampaigns.add(segment.Source_ID__c);
            } else if(segment.Source_Type__c == 'Report') {
                sourceReports.add(segment.Source_ID__c);
            }
        }
        
        //Set<ID> memberLeads = new Map<ID, CampaignMember>([select Lead.ID from CampaignMember 
        //                                            where Campaign.ID in :sourceCampaigns]).keySet();
        
        //For those Leads where a Contact exists, use the Contact instead of the Lead
        //leadsToContacts(memberContacts, memberLeads);
        
        //Each member can be a Lead or a Contact
        List<Member__c> membersToInsert = new List<Member__c>();
         
        Map<ID, Member__c> contactMembersToInsert = new Map<ID, Member__c>();
        
        //Insert each Member and its sources
        for(CampaignMember contactMember : [select Contact.ID, Campaign.ID, Campaign.Name from CampaignMember where Campaign.ID in :sourceCampaigns]) {
            if(contactMembersToInsert.get(contactMember.Contact.ID) == null) {
                contactMembersToInsert.put(contactMember.Contact.ID, new Member__c(Sources__c = contactMember.Campaign.ID, 
                                                            Source_Names__c = 'Campaign:' + contactMember.Campaign.Name));
            } else {
                Member__c existingMember = contactMembersToInsert.get(contactMember.Contact.ID);
                existingMember.Sources__c = existingMember.Sources__c + ';' + contactMember.Campaign.ID;
                existingMember.Source_Names__c = existingMember.Source_Names__c + ';Campaign:' + contactMember.Campaign.Name;
            }
        }
        membersToInsert.addAll(contactMembersToInsert.values());
        
        insert membersToInsert;
    }
    
    private void leadsToContacts(Set<ID> memberContacts, Set<ID> memberLeads) {
        List<Lead> leadsWithFields = [select ConvertedContactId from Lead where ID in :memberLeads];
        for(Lead lead : leadsWithFields) {
            //If a Contact exists for the Lead, add the Contact to the list of Member Contacts.
            //Then pull the Lead from the list of Member Leads.
            if(lead.ConvertedContactId != null) {
                memberContacts.add(lead.ConvertedContactId);
                memberLeads.remove(lead.ID);
            }
        }
    }
}