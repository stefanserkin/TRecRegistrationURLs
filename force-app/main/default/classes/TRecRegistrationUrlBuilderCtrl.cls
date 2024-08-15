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
    public static List<TREX1__Session__c> getAvailableSessions() {
        try {
            return [
                SELECT Id, Name 
                  FROM TREX1__Session__c
                 WHERE TREX1__Status__c = :SESSION_STATUS_AVAILABLE
                  WITH USER_MODE
                 ORDER BY TREX1__Start_Date__c DESC
                 LIMIT 10000
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<TREX1__Location__c> getAvailableLocations() {
        try {
            return [
                SELECT Id, Name 
                  FROM TREX1__Location__c
                 WHERE TREX1__Available_for_Location_Filter_Community__c = true
                  WITH USER_MODE
                 ORDER BY Name ASC
                 LIMIT 10000
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<TREX1__Course_Option__c> getCourseOptions(String courseSessionId, Boolean showUnavailable) {
        try {
            String query = 'SELECT Id, Name FROM TREX1__Course_Option__c' + 
                ' WHERE Id IN (SELECT TREX1__Course_Option__c FROM TREX1__Course_Session_Option__c WHERE TREX1__Course_Session__c = :courseSessionId';
            if (!showUnavailable) {
                query += ' AND (TREX1__Course_Online_Availability__c = \'\' OR TREX1__Course_Option__r.TREX1__Visible_External_Users__c = true)';
            }
            query += ') WITH USER_MODE ORDER BY Name ASC LIMIT 10000';
            System.debug(query);
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}