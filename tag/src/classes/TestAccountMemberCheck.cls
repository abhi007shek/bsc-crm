@isTest
private class TestAccountMemberCheck {

    static testMethod void testProjectUpdate() {
        Account account = new Account(
			name = 'testAcount');
		insert account;
		
		Project__c project = new Project__c();
		project.Account__c = account.Id;
		insert project;
		
		Subscription__c subs = [select Id, Status__c from 
			Subscription__c where Status__c like 'Current%' limit 1];
		
		Subscription_Site__c site = new Subscription_Site__c();
		site.Subscription__c = subs.Id;		
		insert site;
		
		Site_Product__c prod = [select Id, Membership_Product__c
		from Site_Product__c where Membership_Product__c = 'true' limit 1];
		
		prod.Subscription_Site__c = site.id;
		subs.Account_Name__c = account.Id;
		site.Site_Account__c = account.Id;
		
		update subs;
		update site;
		
		AccountMemberCheck.setAccountMemberFlag(account.Id);
    }
}