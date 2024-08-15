@IsTest
private class TRecRegistrationUrlBuilderCtrl_Test {

    private static final String SESSION_STATUS_AVAILABLE = 'Available';
    private static final String SESSION_STATUS_DRAFT = 'Draft';

    @TestSetup
    static void makeData() {
        TREX1__App_Config__c appConfig = TREX1__App_Config__c.getOrgDefaults();
        appConfig.TREX1__Self_Reg_Redirect__c = 'https://my-test-community.com';
        upsert appConfig;

        List<TREX1__Session__c> sessions = new List<TREX1__Session__c>();
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(30);
        sessions.add(
            new TREX1__Session__c(
                Name = 'Available Session',
                TREX1__Available__c = true,
                TREX1__Available_Online__c = true,
                TREX1__Available_Online_From__c = startDate,
                TREX1__Available_Online_To__c = endDate,
                TREX1__Register_From_Date__c = startDate,
                TREX1__Register_To_Date__c = endDate,
                TREX1__Register_Online_From_Date__c = startDate,
                TREX1__Register_Online_To_Date__c = endDate,
                TREX1__Start_Date__c = startDate,
                TREX1__End_Date__c = endDate,
                TREX1__Status__c = SESSION_STATUS_AVAILABLE
            )
        );
        sessions.add(
            new TREX1__Session__c(
                Name = 'Draft Session',
                TREX1__Available__c = true,
                TREX1__Available_Online__c = true,
                TREX1__Available_Online_From__c = startDate,
                TREX1__Available_Online_To__c = endDate,
                TREX1__Register_From_Date__c = startDate,
                TREX1__Register_To_Date__c = endDate,
                TREX1__Register_Online_From_Date__c = startDate,
                TREX1__Register_Online_To_Date__c = endDate,
                TREX1__Start_Date__c = startDate,
                TREX1__End_Date__c = endDate,
                TREX1__Status__c = SESSION_STATUS_DRAFT
            )
        );
        insert sessions;

        List<TREX1__Location__c> locations = new List<TREX1__Location__c>();
        locations.add(
            new TREX1__Location__c(
                Name = 'Available Location',
                TREX1__Available_for_Location_Filter_Community__c = true
            )
        );
        locations.add(
            new TREX1__Location__c(
                Name = 'Unavailable Location',
                TREX1__Available_for_Location_Filter_Community__c = false
            )
        );
        insert locations;
    }

    @IsTest
    static void testGetBaseUrl() {
        Test.startTest();
        String baseUrl = PublicUrlBuilderController.getBaseUrl();
        Test.stopTest();

        TREX1__App_Config__c appConfig = TREX1__App_Config__c.getOrgDefaults();
        String expectedUrl = appConfig.TREX1__Self_Reg_Redirect__c + '/s';

        Assert.areEqual(expectedUrl, baseUrl, 'Did not receive the expected url');
    }

    @IsTest
    static void testGetBaseUrlWithoutAppConfig() {
        delete [SELECT Id FROM TREX1__App_Config__c];
        Test.startTest();
        String baseUrl = PublicUrlBuilderController.getBaseUrl();
        Test.stopTest();
        Assert.areEqual('/s', baseUrl, 'Should have received a relative url');
    }

    @IsTest
    static void testGetSessions() {
        TREX1__Session__c availableSession = [
            SELECT Id, TREX1__Status__c 
              FROM TREX1__Session__c 
             WHERE TREX1__Status__c = :SESSION_STATUS_AVAILABLE 
             LIMIT 1
        ];

        Test.startTest();
        List<TREX1__Session__c> returnedSessions = PublicUrlBuilderController.getAvailableSessions();
        Test.stopTest();

        Assert.isTrue(returnedSessions.size() == 1, 'Should have received only the active session');
        Assert.areEqual(availableSession.Id, returnedSessions[0].Id, 'Should have received the active session id');
    }

    @IsTest
    static void testNoAvailableSessions() {
        TREX1__Session__c availableSession = [
            SELECT Id, TREX1__Status__c 
              FROM TREX1__Session__c 
             WHERE TREX1__Status__c = :SESSION_STATUS_AVAILABLE 
             LIMIT 1
        ];
        availableSession.TREX1__Status__c = SESSION_STATUS_DRAFT;
        update availableSession;

        Test.startTest();
        List<TREX1__Session__c> returnedSessions = PublicUrlBuilderController.getAvailableSessions();
        Test.stopTest();

        Assert.isTrue(returnedSessions.isEmpty(), 'Should have received an empty list');
    }

    @IsTest
    static void testGetLocations() {
        List<TREX1__Location__c> availableLocations = [
            SELECT Id, Name
              FROM TREX1__Location__c
             WHERE TREX1__Available_for_Location_Filter_Community__c = true
        ];

        Test.startTest();
        List<TREX1__Location__c> returnedLocations = PublicUrlBuilderController.getAvailableLocations();
        Test.stopTest();

        Assert.isTrue(returnedLocations.size() == 1, 'Should have received only one location');
        Assert.areEqual(availableLocations[0].Id, returnedLocations[0].Id, 'Should have received the correct location id');
    }

}