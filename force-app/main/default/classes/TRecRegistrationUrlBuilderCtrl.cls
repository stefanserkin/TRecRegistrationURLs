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
        return [
            SELECT Id, Name 
              FROM TREX1__Session__c
             WHERE TREX1__Status__c = :SESSION_STATUS_AVAILABLE
              WITH USER_MODE
             ORDER BY TREX1__Start_Date__c DESC
             LIMIT 10000
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<TREX1__Location__c> getAvailableLocations() {
        return [
            SELECT Id, Name 
              FROM TREX1__Location__c
             WHERE TREX1__Available_for_Location_Filter_Community__c = true
              WITH USER_MODE
             ORDER BY Name ASC
             LIMIT 10000
        ];
    }

}