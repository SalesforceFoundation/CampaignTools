@isTest
public with sharing class MembersBuilder_TEST {

    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    
    @isTest
    public static void contactCampaignMembers() {
        if (strTestOnly != '*' && strTestOnly != 'contactCampaignMembers') return;
        
        //One root segment, with two children segments. One has camp1 source, and the 
        //other one camp2 source. The first child also has a child, with camp3 source.
        //The Contact in camp3 is also in camp2.
        
        Campaign camp1 = new Campaign(Name = 'Test 1');
        Campaign camp2 = new Campaign(Name = 'Test 2');
        Campaign camp3 = new Campaign(Name = 'Test 3');
        insert new Campaign[] {camp1, camp2, camp3};
        
        Contact c1_1 = new Contact(LastName = 'Testerson1');
        Contact c2_1 = new Contact(LastName = 'Testerson2');
        Contact c3_2 = new Contact(LastName = 'Testerson3');
        Contact c4_2 = new Contact(LastName = 'Testerson4');
        Contact c5_2 = new Contact(LastName = 'Testerson5');
        insert new Contact[]{c1_1, c2_1, c3_2, c4_2, c5_2};
        
        CampaignMember m1_1 = new CampaignMember(CampaignId = camp1.ID, ContactId = c1_1.ID, Status = 'Sent');
        CampaignMember m2_1 = new CampaignMember(CampaignId = camp1.ID, ContactId = c2_1.ID, Status = 'Sent');
        CampaignMember m3_2 = new CampaignMember(CampaignId = camp2.ID, ContactId = c3_2.ID, Status = 'Sent');
        CampaignMember m4_2 = new CampaignMember(CampaignId = camp2.ID, ContactId = c4_2.ID, Status = 'Sent');
        CampaignMember m5_2 = new CampaignMember(CampaignId = camp2.ID, ContactId = c5_2.ID, Status = 'Sent');
        CampaignMember m6_3 = new CampaignMember(CampaignId = camp3.ID, ContactId = c2_1.ID, Status = 'Sent');
        insert new CampaignMember[]{m1_1, m2_1, m3_2, m4_2, m5_2, m6_3};
        
        //Root
        Segment__c root = new Segment__c(Root_Segment__c = null, Parent_Segment__c = null, 
                            Source_ID__c = null, Source_Type__c = null);
        insert root;
        //Level 1 segments
        Segment__c seg1_1 = new Segment__c(Root_Segment__c = root.ID, Parent_Segment__c = root.ID, 
                            Source_ID__c = camp1.ID, Source_Type__c = 'Campaign');
        Segment__c seg1_2 = new Segment__c(Root_Segment__c = root.ID, Parent_Segment__c = root.ID, 
                            Source_ID__c = camp2.ID, Source_Type__c = 'Campaign');
        insert new Segment__c[]{seg1_1, seg1_2};
        //Level 2 segments                    
        Segment__c seg1_1_1 = new Segment__c(Root_Segment__c = root.ID, Parent_Segment__c = seg1_1.ID, 
                            Source_ID__c = camp3.ID, Source_Type__c = 'Campaign');
        insert seg1_1_1;
        
        Test.startTest();
        new MembersBuilder(root.ID);
        Test.stopTest();
        
        List<Member__c> membersInserted = [select Contact__c, Sources__c, Source_Names__c from Member__c order by Contact__c];
        System.assertEquals(5, membersInserted.size());
        
        System.assertEquals(camp1.ID, membersInserted[0].Sources__c);
        System.assertEquals('Campaign:' + camp1.Name, membersInserted[0].Source_Names__c);
        
        System.assertEquals(camp1.ID + ';' + camp3.ID, membersInserted[1].Sources__c);
        System.assertEquals('Campaign:' + camp1.Name + ';Campaign:' + camp3.Name, membersInserted[1].Source_Names__c);
        
        System.assertEquals(camp2.ID, membersInserted[2].Sources__c);
        System.assertEquals('Campaign:' + camp2.Name, membersInserted[2].Source_Names__c);
        
        System.assertEquals(camp2.ID, membersInserted[3].Sources__c);
        System.assertEquals('Campaign:' + camp2.Name, membersInserted[3].Source_Names__c);
        
        System.assertEquals(camp2.ID, membersInserted[4].Sources__c);
        System.assertEquals('Campaign:' + camp2.Name, membersInserted[4].Source_Names__c);
    }
    
    @isTest
    public static void contactAndLeadsMembers() {
        if (strTestOnly != '*' && strTestOnly != 'contactAndLeadsMembers') return;
        
        //One root segment, with two children segments. One has camp1 source, and the 
        //other one camp2 source. The first child also has a child, with camp3 source.
        //The Contact in camp3 is also in camp2.
        
        Campaign camp1 = new Campaign(Name = 'Test 1');
        Campaign camp2 = new Campaign(Name = 'Test 2');
        Campaign camp3 = new Campaign(Name = 'Test 3');
        insert new Campaign[] {camp1, camp2, camp3};
        
        Contact c1_1 = new Contact(LastName = 'Testerson1');
        Lead c2_1 = new Lead(LastName = 'Testerson2', Company = 'Acme Inc');
        Contact c3_2 = new Contact(LastName = 'Testerson3');
        Contact c4_2 = new Contact(LastName = 'Testerson4');
        Lead c5_2 = new Lead(LastName = 'Testerson5', Company = 'Acme Inc');
        insert new Contact[]{c1_1, c3_2, c4_2};
        insert new Lead[]{c2_1, c5_2};
        
        CampaignMember m1_1 = new CampaignMember(CampaignId = camp1.ID, ContactId = c1_1.ID, Status = 'Sent');
        CampaignMember m2_1 = new CampaignMember(CampaignId = camp1.ID, LeadId = c2_1.ID, Status = 'Sent');
        CampaignMember m3_2 = new CampaignMember(CampaignId = camp2.ID, ContactId = c3_2.ID, Status = 'Sent');
        CampaignMember m4_2 = new CampaignMember(CampaignId = camp2.ID, ContactId = c4_2.ID, Status = 'Sent');
        CampaignMember m5_2 = new CampaignMember(CampaignId = camp2.ID, LeadId = c5_2.ID, Status = 'Sent');
        CampaignMember m6_3 = new CampaignMember(CampaignId = camp3.ID, LeadId = c2_1.ID, Status = 'Sent');
        insert new CampaignMember[]{m1_1, m2_1, m3_2, m4_2, m5_2, m6_3};
        
        //Root
        Segment__c root = new Segment__c(Root_Segment__c = null, Parent_Segment__c = null, 
                            Source_ID__c = null, Source_Type__c = null);
        insert root;
        //Level 1 segments
        Segment__c seg1_1 = new Segment__c(Root_Segment__c = root.ID, Parent_Segment__c = root.ID, 
                            Source_ID__c = camp1.ID, Source_Type__c = 'Campaign');
        Segment__c seg1_2 = new Segment__c(Root_Segment__c = root.ID, Parent_Segment__c = root.ID, 
                            Source_ID__c = camp2.ID, Source_Type__c = 'Campaign');
        insert new Segment__c[]{seg1_1, seg1_2};
        //Level 2 segments                    
        Segment__c seg1_1_1 = new Segment__c(Root_Segment__c = root.ID, Parent_Segment__c = seg1_1.ID, 
                            Source_ID__c = camp3.ID, Source_Type__c = 'Campaign');
        insert seg1_1_1;
        
        Test.startTest();
        new MembersBuilder(root.ID);
        Test.stopTest();
        
        List<Member__c> membersInserted = [select Contact__c, Lead__c, Sources__c, Source_Names__c from Member__c order by Contact__c, Lead__c];
        System.assertEquals(5, membersInserted.size());
        
        System.assertEquals(camp1.ID, membersInserted[0].Sources__c);
        System.assertEquals('Campaign:' + camp1.Name, membersInserted[0].Source_Names__c);
        
        System.assertEquals(camp1.ID + ';' + camp3.ID, membersInserted[1].Sources__c);
        System.assertEquals('Campaign:' + camp1.Name + ';Campaign:' + camp3.Name, membersInserted[1].Source_Names__c);
        
        System.assertEquals(camp2.ID, membersInserted[2].Sources__c);
        System.assertEquals('Campaign:' + camp2.Name, membersInserted[2].Source_Names__c);
        
        System.assertEquals(camp2.ID, membersInserted[3].Sources__c);
        System.assertEquals('Campaign:' + camp2.Name, membersInserted[3].Source_Names__c);
        
        System.assertEquals(camp2.ID, membersInserted[4].Sources__c);
        System.assertEquals('Campaign:' + camp2.Name, membersInserted[4].Source_Names__c);   
    }
    
    @isTest
    public static void campaignsAndReports() {
        if (strTestOnly != '*' && strTestOnly != 'campaignsAndReports') return;
        
    }
}