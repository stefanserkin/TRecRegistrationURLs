public with sharing class TRecRegistrationUrlBuilderCtrl {
    
    private static final String SESSION_STATUS_AVAILABLE = 'Available';

    @AuraEnabled(cacheable=true)
    public static String getBaseUrl() {
        TREX1__App_Config__c appConfig = TREX1__App_Config__c.getOrgDefaults();
        String communityUrl = appConfig.TREX1__Self_Reg_Redirect__c;
        String baseUrl = communityUrl != null ? communityUrl + '/s' : '/s';
        return baseUrl;
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getAvailableSessions() {
        try {
            List<PicklistOption> options = new List<PicklistOption>();
            for (TREX1__Session__c session : [SELECT Id, Name 
                                                FROM TREX1__Session__c
                                               WHERE TREX1__Status__c = :SESSION_STATUS_AVAILABLE
                                                WITH USER_MODE
                                               ORDER BY TREX1__Start_Date__c DESC
                                               LIMIT 10000])
            {
                PicklistOption po = new PicklistOption();
                po.label = session.Name;
                po.value = session.Id;
                options.add(po);
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getAvailableLocations() {
        try {
            List<PicklistOption> options = new List<PicklistOption>();
            for (TREX1__Location__c location : [SELECT Id, Name 
                                                FROM TREX1__Location__c
                                               WHERE TREX1__Available_for_Location_Filter_Community__c = true
                                                WITH USER_MODE
                                               ORDER BY Name ASC
                                               LIMIT 10000])
            {
                PicklistOption po = new PicklistOption();
                po.label = location.Name;
                po.value = location.Name;
                options.add(po);
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getAvailableInstructors(Id recordId) {
        try {
            List<PicklistOption> options = new List<PicklistOption>();

            Set<String> instructors = new Set<String>();
            List<TREX1__Course_Option__c> courseOptions = queryForCourseOptionsWithInstructors(recordId);
            for (TREX1__Course_Option__c co : courseOptions) {
                instructors.add(co.TREX1__Instructor__c);
            }
            
            for (String instructor : instructors) {
                PicklistOption po = new PicklistOption();
                po.label = instructor;
                po.value = instructor;
                options.add(po);
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<TREX1__Course_Option__c> queryForCourseOptionsWithInstructors(
        Id recordId
    ) {
        String csoToRecordPath;
        String objectApiName = recordId.getSObjectType().getDescribe().getName();
        if (objectApiName == 'TREX1__Program__c') {
            csoToRecordPath = 'TREX1__Course_Session__r.TREX1__Course__r.TREX1__Program__c';
        } else if (objectApiName == 'TREX1__Course__c') {
            csoToRecordPath = 'TREX1__Course_Session__r.TREX1__Course__c';
        } else {
            return new List<TREX1__Course_Option__c>();
        }

        String query = 'SELECT TREX1__Instructor__c FROM TREX1__Course_Option__c WHERE TREX1__Instructor__c != null' + 
                       ' AND Id IN (SELECT TREX1__Course_Option__c FROM TREX1__Course_Session_Option__c' + 
                       ' WHERE ' + String.escapeSingleQuotes(csoToRecordPath) + ' = :recordId)' + 
                       ' WITH USER_MODE ORDER BY Name ASC LIMIT 10000';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getAvailableGrades() {
        List<PicklistOption> options = new List<PicklistOption>();
        
        Schema.SObjectType sobjectType = TREX1__Course_Option__c.SObjectType;
        Schema.DescribeFieldResult fieldResult = sobjectType.getDescribe().fields.getMap().get('TREX1__Grade_Range__c').getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            PicklistOption option = new PicklistOption();
            option.label = entry.getLabel();
            option.value = entry.getValue();
            options.add(option);
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getCourseOptions(
        Id courseSessionId, 
        Boolean showUnavailable
    ) {
        try {
            List<PicklistOption> options = new List<PicklistOption>();
            for (TREX1__Course_Option__c co : queryForCourseOptionsByCourseSessionId(courseSessionId, showUnavailable)) {
                PicklistOption option = new PicklistOption();
                option.label = co.Name;
                option.value = co.Id;
                options.add(option);
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<TREX1__Course_Option__c> queryForCourseOptionsByCourseSessionId(
        Id courseSessionId, 
        Boolean showUnavailable
    ) {
        String query = 'SELECT Id, Name FROM TREX1__Course_Option__c' + 
                       ' WHERE Id IN (SELECT TREX1__Course_Option__c FROM TREX1__Course_Session_Option__c' +
                       ' WHERE TREX1__Course_Session__c = :courseSessionId';
        if (!showUnavailable) {
            query += ' AND (TREX1__Course_Online_Availability__c = \'\' OR TREX1__Course_Option__r.TREX1__Visible_External_Users__c = true)';
        }
        query += ') WITH USER_MODE ORDER BY Name ASC LIMIT 10000';
        System.debug(query);
        return Database.query(query);
    }

    public class PicklistOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    }

}