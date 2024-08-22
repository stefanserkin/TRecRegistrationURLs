TREX1__App_Config__c config = TREX1__App_Config__c.getOrgDefaults();
config.TREX1__Self_Reg_Redirect__c = 'https://www.mets.com';
System.debug(config);
upsert config;