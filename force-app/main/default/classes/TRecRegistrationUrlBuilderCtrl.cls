/*****************************************************
 * @date 2024
 *****************************************************/
public with sharing class TRecRegistrationUrlBuilderCtrl {
    
    private static final String SESSION_STATUS_AVAILABLE = 'Available';

    @AuraEnabled(cacheable=true)
    public static String getBaseUrl() {
        TREX1__App_Config__c appConfig = TREX1__App_Config__c.getOrgDefaults();
        String selfRegRedirect = appConfig.TREX1__Self_Reg_Redirect__c;
        return parseToBaseUrl(selfRegRedirect);
    }

    private static String parseToBaseUrl(String url) {
        String communityUrl = url ?? '';
        Integer thirdSlashIndex = communityUrl.indexOf('/', communityUrl.indexOf('/', communityUrl.indexOf('/') + 1) + 1);
        if (thirdSlashIndex != -1) {
            communityUrl = communityUrl.substring(0, thirdSlashIndex);
        }
        return communityUrl + '/s';
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
                options.add( new PicklistOption(session.Name, session.Id) );
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
                options.add( new PicklistOption(location.Name) );
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
                options.add( new PicklistOption(instructor) );
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
            options.add( new PicklistOption(entry.getLabel(), entry.getValue()) );
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
                options.add( new PicklistOption(co.Name, co.Id) );
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

        public PicklistOption(String value) {
            this(value, value);
        }

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

}