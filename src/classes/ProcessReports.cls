public with sharing class ProcessReports {

    /*******************************************************************************************************
    * @description Calculates and returns member records for a campaign list with source reports.
    * @param rootSegmentID The ID of the root segment.
    * @param setReportIDs A set of IDs of the reports
    * @return List A list of member records in memory, ready for insert.
    ********************************************************************************************************/
    public static List<Member__c> getMemberRecords(ID rootSegmentID, set<id> setReportIDs) {
        
        map<id,Reports.reportResults> mapReportResults = new map<id,Reports.reportResults>();

        map<id,Member__c> mapMembers = new map<id,Member__c>();

        for (id reportId : setReportIDs) {
            Reports.reportResults result = Reports.ReportManager.runReport(reportId, true);
            String reportName = result.getReportMetadata().getName();
            set<id> setMemberIds = getMemberIdsFromReport(result);

            mapReportResults.put(reportId, result);
            
            for (id memberId : setMemberIds) {
                //create a new member
                if (!mapMembers.containsKey(memberId)) {
                    Member__c member = new Member__c(
                        Root_Segment__c = rootSegmentID,
                        Sources__c = reportId,
                        Source_Names__c = 'Report: ' + reportName
                    );
                    
                    if (memberId.getSObjectType() == Schema.Contact.SObjectType)
                        member.Contact__c = memberId;
                    else 
                        member.Lead__c = memberId;
                //add a new source to an existing member
                } else {
                    Member__c member = mapMembers.get(memberId);
                    member.Sources__c += ';'+reportId;
                    member.Source_Names__c += ';Report: ' + reportName;
                }
            }
        }

        return mapMembers.values();
    }

    /*******************************************************************************************************
    * @description Parses a report to extract Contact or Lead IDs.
    * @param reportId The salesforce id of the report to extract.
    * @return set A set of IDs of contacts or leads in the report.
    ********************************************************************************************************/
    public static set<id> getMemberIdsFromReport(Reports.reportResults reportResults) {
        
        map<string,Reports.ReportFactWithDetails> mapFacts = (map<string,Reports.ReportFactWithDetails>)reportResults.getFactMap();
        
        set<id> memberIds = new set<id>();

        //TBD if we need to process all ReportFacts in summery/matrix reports, 
        //we might save lots of processing time by skipping summary rows, etc.
        for (Reports.ReportFactWithDetails fact : mapFacts.values()) {
            memberIds.addAll(getMemberIdsFromRows(fact.getRows()));
        }

        return memberIds;
    }

    /*******************************************************************************************************
    * @description Parses detail rows from a report to extract Contact or Lead IDs.
    * @param listDetailRows The report detail row in which to perform the search.
    * @return integer The column number, or null if no Contact/Lead Id is found.
    ********************************************************************************************************/
    private static set<id> getMemberIdsFromRows(List<Reports.ReportDetailRow> listDetailRows) {
        set<id> members = new set<id>();
        integer memberIdCell;

        //find the column number if any for the current list of rows contains a contact or lead id
        for (Reports.ReportDetailRow row : listDetailRows) {
            
            memberIdCell = getColumnNumber(row.getDataCells());
            if (memberIdCell != null)
                break;
        }

        //if we found a column with member ids, extract them
        if (memberIdCell!=null) {
            for (Reports.ReportDetailRow row : listDetailRows) {
                string val = (string) row.getDataCells()[memberIdCell].getValue();
                if (!string.isBlank(val)) {
                    members.add((id)val);
                }
            }
        }

        return members;
    }

    /*******************************************************************************************************
    * @description Parses data cells from a report to find a column containing Contact or Lead IDs.
    * @param listDataCells The report cell data in which to perform the search.
    * @return integer The column number, or null if no Contact/Lead Id is found.
    ********************************************************************************************************/
    private static integer getColumnNumber(list<Reports.ReportDataCell> listDataCells) {
        for (integer i=0; i<listDataCells.size(); i++) {
            string val = (string)listDataCells[i].getValue();
            if (val.length() == 18) {
                //verify this is a contact or lead id in a try/catch, in case the value
                //is an 18 character string that is not an instance of ID
                try {
                    id tempId = id.valueOf(val);
                    Schema.SObjectType sobjType = tempId.getSObjectType();
                    if (sobjType == Schema.Contact.SObjectType || sobjType == Schema.Lead.SObjectType) {
                        return i;
                        break;
                    }
                } catch (Exception ex){}
            }
        }
        return null;
    }
}