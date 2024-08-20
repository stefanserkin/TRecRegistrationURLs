@IsTest
private class TRecRegistrationUrlBuilderCtrl_Test {

    private static final String SESSION_STATUS_AVAILABLE = 'Available';
    private static final String SESSION_STATUS_DRAFT = 'Draft';
    private static final String COURSE_OPTION_TYPE_STANDARD = 'Standard Course Option';

    private static Date startDate = Date.today();
    private static Date endDate = Date.today().addDays(30);

    @TestSetup
    static void makeData() {
        loadData();
    }

    @IsTest
    static void testGetBaseUrl() {
        Test.startTest();
        String baseUrl = TRecRegistrationUrlBuilderCtrl.getBaseUrl();
        Test.stopTest();

        TREX1__App_Config__c appConfig = TREX1__App_Config__c.getOrgDefaults();
        String expectedUrl = appConfig.TREX1__Self_Reg_Redirect__c + '/s';

        Assert.areEqual(expectedUrl, baseUrl, 'Did not receive the expected url');
    }

    @IsTest
    static void testGetBaseUrlWithoutAppConfig() {
        delete [SELECT Id FROM TREX1__App_Config__c];
        Test.startTest();
        String baseUrl = TRecRegistrationUrlBuilderCtrl.getBaseUrl();
        Test.stopTest();
        Assert.areEqual('/s', baseUrl, 'Should have received a relative url');
    }

    @IsTest
    static void testGetSessions() {
        TREX1__Session__c availableSession = [
            SELECT Id, Name, TREX1__Status__c 
              FROM TREX1__Session__c 
             WHERE TREX1__Status__c = :SESSION_STATUS_AVAILABLE 
             LIMIT 1
        ];

        Test.startTest();
        List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getAvailableSessions();
        Test.stopTest();

        Assert.isTrue(options.size() == 1, 'Should have received only the active session');
        Assert.areEqual(availableSession.Id, options[0].value, 'Should have received the active session id for a value');
        Assert.areEqual(availableSession.Name, options[0].label, 'Should have received the active session name for a label');
    }

    @IsTest
    static void testNoAvailableSessions() {
        TREX1__Session__c availableSession = [
            SELECT Id
              FROM TREX1__Session__c 
             WHERE TREX1__Status__c = :SESSION_STATUS_AVAILABLE 
             LIMIT 1
        ];
        availableSession.TREX1__Status__c = SESSION_STATUS_DRAFT;
        update availableSession;

        Test.startTest();
        List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getAvailableSessions();
        Test.stopTest();

        Assert.isTrue(options.isEmpty(), 'Should have received an empty list');
    }

    @IsTest
    static void testGetSessionsWithException() {
        User u = createMinimumAccessUser();
        Test.startTest();
        System.runAs(u) {
            try {
                List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getAvailableSessions();
                Assert.fail('Should have received an exception for insufficient permissions');
            } catch (Exception e) {
                Assert.areEqual('System.AuraHandledException', e.getTypeName(), 'Should have received an aura handled exception');
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetLocations() {
        List<TREX1__Location__c> availableLocations = [
            SELECT Id, Name
              FROM TREX1__Location__c
             WHERE TREX1__Available_for_Location_Filter_Community__c = true
        ];

        Test.startTest();
        List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getAvailableLocations();
        Test.stopTest();

        Assert.isTrue(options.size() == 1, 'Should have received only one location');
        Assert.areEqual(availableLocations[0].Name, options[0].value, 'Should have received the correct location name for a value');
        Assert.areEqual(availableLocations[0].Name, options[0].label, 'Should have received the correct location name for a label');
    }

    @IsTest
    static void testGetLocationsWithException() {
        User u = createMinimumAccessUser();
        Test.startTest();
        System.runAs(u) {
            try {
                List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getAvailableLocations();
                Assert.fail('Should have received an exception for insufficient permissions');
            } catch (Exception e) {
                Assert.areEqual('System.AuraHandledException', e.getTypeName(), 'Should have received an aura handled exception');
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetInstructorsForCourse() {
        TREX1__Course__c course = [SELECT Id FROM TREX1__Course__c LIMIT 1];
        Test.startTest();
        List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getAvailableInstructors(course.Id);
        Test.stopTest();
        Assert.isFalse(options.isEmpty(), 'Should have received instructors for related course options');
    }

    @IsTest
    static void testGetInstructorsForProgram() {
        TREX1__Program__c program = [SELECT Id FROM TREX1__Program__c LIMIT 1];
        Test.startTest();
        List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getAvailableInstructors(program.Id);
        Test.stopTest();
        Assert.isFalse(options.isEmpty(), 'Should have received instructors for related course options');
    }

    @IsTest
    static void testGetInstructorsForUnrecognizedObject() {
        TREX1__Location__c location = [SELECT Id FROM TREX1__Location__c LIMIT 1];
        Test.startTest();
        List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getAvailableInstructors(location.Id);
        Test.stopTest();
        Assert.isTrue(options.isEmpty(), 'Should have received an empty list for the unsupported object');
    }

    @IsTest
    static void testGetInstructorsWithException() {
        Id courseId = [SELECT Id FROM TREX1__Course__c LIMIT 1].Id;
        User u = createMinimumAccessUser();
        Test.startTest();
        System.runAs(u) {
            try {
                List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getAvailableInstructors(courseId);
                Assert.fail('Should have received an exception for insufficient permissions');
            } catch (Exception e) {
                Assert.areEqual('System.AuraHandledException', e.getTypeName(), 'Should have received an aura handled exception');
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetGrades() {
        Test.startTest();
        List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getAvailableGrades();
        Test.stopTest();

        Assert.isFalse(options.isEmpty(), 'Should have received a list of picklist options');

        Set<String> gradeValues = new Set<String>();
        for (TRecRegistrationUrlBuilderCtrl.PicklistOption po : options) {
            gradeValues.add(po.value);
        }

        Schema.SObjectType sobjectType = TREX1__Course_Option__c.SObjectType;
        Schema.DescribeFieldResult fieldResult = sobjectType.getDescribe().fields.getMap().get('TREX1__Grade_Range__c').getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            Assert.isTrue(gradeValues.contains(entry.getValue()), 'Should have received the valid grade value ' + entry.getValue());
        }
    }

    @IsTest
    static void testGetAvailableCourseOptions() {
        TREX1__Course_Session__c courseSession = [SELECT Id FROM TREX1__Course_Session__c LIMIT 1];
        List<TREX1__Course_Option__c> courseOptions = [
            SELECT Id 
              FROM TREX1__Course_Option__c
             WHERE Id IN (SELECT TREX1__Course_Option__c 
                            FROM TREX1__Course_Session_Option__c
                           WHERE TREX1__Course_Session__c = :courseSession.Id
                             AND (TREX1__Course_Option__r.TREX1__Visible_External_Users__c = true
                              OR TREX1__Course_Online_Availability__c = ''))
        ];

        Test.startTest();
        List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getCourseOptions(
            courseSession.Id, 
            false
        );
        Test.stopTest();

        Assert.areEqual(courseOptions.size(), options.size(), 'Should have received only available course options');
    }

    @IsTest
    static void testGetAllCourseOptions() {
        TREX1__Course_Session__c courseSession = [SELECT Id FROM TREX1__Course_Session__c LIMIT 1];
        List<TREX1__Course_Option__c> courseOptions = [
            SELECT Id 
              FROM TREX1__Course_Option__c
             WHERE Id IN (SELECT TREX1__Course_Option__c 
                            FROM TREX1__Course_Session_Option__c
                           WHERE TREX1__Course_Session__c = :courseSession.Id)
        ];

        Test.startTest();
        List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getCourseOptions(
            courseSession.Id, 
            true
        );
        Test.stopTest();

        Assert.areEqual(courseOptions.size(), options.size(), 'Should have received all course options for the course session');
    }

    @IsTest
    static void testGetCourseOptionsWithException() {
        TREX1__Course_Session__c courseSession = [SELECT Id FROM TREX1__Course_Session__c LIMIT 1];

        User u = createMinimumAccessUser();
        Test.startTest();
        System.runAs(u) {
            try {
                List<TRecRegistrationUrlBuilderCtrl.PicklistOption> options = TRecRegistrationUrlBuilderCtrl.getCourseOptions(
                    courseSession.Id, 
                    true
                );
                Assert.fail('Should have received an exception for insufficient permissions');
            } catch (Exception e) {
                Assert.areEqual('System.AuraHandledException', e.getTypeName(), 'Should have received an aura handled exception');
            }
        }
        Test.stopTest();
    }

    /**
     * Test Data Setup
     */

    private static void loadData() {
        loadAppConfig();
        loadProgramStack();
    }

    private static void loadAppConfig() {
        TREX1__App_Config__c appConfig = TREX1__App_Config__c.getOrgDefaults();
        appConfig.TREX1__Self_Reg_Redirect__c = 'https://my-test-community.com';
        upsert appConfig;
    }

    private static void loadProgramStack() {
        TREX1__Location__c availableLocation = loadLocations();
        TREX1__Session__c availableSession = loadSessions();

        TREX1__Program__c program = new TREX1__Program__c(
            Name = 'Test Program',
            TREX1__Available__c = true,
            TREX1__Available_Online__c = true
        );
        insert program;

        TREX1__Course__c course = new TREX1__Course__c(
            TREX1__Program__c = program.Id,
            Name = 'Test Course',
            TREX1__Available__c = true, 
            TREX1__Available_Online__c = true
        );
        insert course;

        TREX1__Course_Session__c courseSession = new TREX1__Course_Session__c(
            TREX1__Course__c = course.Id,
            TREX1__Session__c = availableSession.Id,
            Name = 'Test Course Session',
            TREX1__Status__c = 'Approved'
        );
        insert courseSession;

        Set<String> daysOfWeek = new Set<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'};

        List<TREX1__Course_Option__c> courseOptions = new List<TREX1__Course_Option__c>();
        Boolean isAvailable = false;
        for (String day : daysOfWeek) {
            courseOptions.add(
                new TREX1__Course_Option__c(
                    Name = 'Test Course Option - ' + day, 
                    TREX1__Available__c = isAvailable,
                    TREX1__Available_Online__c = isAvailable,
                    TREX1__Type__c = COURSE_OPTION_TYPE_STANDARD, 
                    TREX1__Start_Date__c = startDate, 
                    TREX1__End_Date__c = endDate, 
                    TREX1__Start_Time__c = '1:00 PM', 
                    TREX1__End_Time__c = '2:00 PM', 
                    TREX1__Day_of_Week__c = day, 
                    TREX1__Setup_Time_Required__c = 0, 
                    TREX1__Tear_Down_Time_Required__c = 0, 
                    TREX1__Capacity__c = 100, 
                    TREX1__Register_From_Date__c = startDate, 
                    TREX1__Register_From_Time__c = '8:30 AM', 
                    TREX1__Register_To_Date__c = endDate, 
                    TREX1__Register_To_Time__c = '10:30 PM', 
                    TREX1__Register_Online_From_Date__c = startDate, 
                    TREX1__Register_Online_From_Time__c = '8:30 AM', 
                    TREX1__Register_Online_To_Date__c = endDate, 
                    TREX1__Register_Online_To_Time__c = '10:30 PM',
                    TREX1__Instructor__c = 'Test Instructor'
                )
            );
            isAvailable = true;
        }
        insert courseOptions;

        List<TREX1__Course_Session_Option__c> csos = new List<TREX1__Course_Session_Option__c>();
        for (TREX1__Course_Option__c co : courseOptions) {
            csos.add(
                new TREX1__Course_Session_Option__c(
                    TREX1__Course_Option__c = co.Id,
                    TREX1__Course_Session__c = courseSession.Id,
                    TREX1__Option_Available__c = co.TREX1__Available__c,
                    TREX1__Available_Online__c = co.TREX1__Available_Online__c
                )
            );
        }
        insert csos;
    }

    private static TREX1__Location__c loadLocations() {
        List<TREX1__Location__c> locations = new List<TREX1__Location__c>();

        TREX1__Location__c availableLocation = new TREX1__Location__c(
            Name = 'Available Location',
            TREX1__Available_for_Location_Filter_Community__c = true
        );
        locations.add(availableLocation);

        TREX1__Location__c unavailableLocation = new TREX1__Location__c(
            Name = 'Unavailable Location',
            TREX1__Available_for_Location_Filter_Community__c = false
        );
        locations.add(unavailableLocation);

        insert locations;
        return availableLocation;
    }

    private static TREX1__Session__c loadSessions() {
        List<TREX1__Session__c> sessions = new List<TREX1__Session__c>();
        TREX1__Session__c availableSession = new TREX1__Session__c(
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
        );
        sessions.add(availableSession);

        TREX1__Session__c unavailableSession = new TREX1__Session__c(
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
        );
        sessions.add(unavailableSession);
        insert sessions;
        return availableSession;
    }

    private static User createMinimumAccessUser() {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'];
        User u = new User();
        u.IsActive = true;
        u.TimeZoneSidKey = UserInfo.getTimeZone().toString();
        u.LocaleSidKey = UserInfo.getLocale();
        u.LanguageLocaleKey = UserInfo.getLocale();
        u.EmailEncodingKey = 'ISO-8859-1';
        u.Username = uniqueName + '@test' + orgId + '.org';
        u.Email = uniqueName + '@test' + orgId + '.org';
        u.FirstName = 'Tester';
        u.LastName = 'Testerooni';
        u.Alias = uniqueName.substring(18, 23);
        u.ProfileId = profile.Id;
        insert u;
        return u;
    }

}