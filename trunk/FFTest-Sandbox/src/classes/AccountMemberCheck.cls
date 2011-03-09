public with sharing class AccountMemberCheck {
	
	/**
	* Method: isAccountMember
	* New trigger, we need to update the checkbox "Member" 
    * on the account based on whether the account has a subscription site, 
    * which has a site product, where "Membership Product" = TRUE
    * but only when the subscription to which the subscription site is linked has
    * a status that starts with current
    *
    * acc.Subscription_Site__c.Membership_Product__c = true
    * acc.Subscription_Site__c.Subscription__c.Status like 'Current%'
	**/
	public static void setAccountMemberFlag(Id accId){
		System.debug('** isAccountMember start');
		
		boolean isAccountMember = false;
		
		//Do we have any site products for the current account
		//with a membership product
		List<Site_Product__c> siteProductList = [select Subscription_Site__r.Id,
		Subscription__r.Id from Site_Product__c 
		where Subscription_Site__r.Site_Account__c = :accId
		and Membership_Product__c = 'true'
		and Subscription__r.Status__c like 'Current%'];
		
		System.debug('** Site product list size: ' + siteProductList.size());
		
		if(siteProductList.size() > 0){
			isAccountMember = true;
		}
		
		System.debug('** isAccountMember: ' + isAccountMember);
		
		//Update the account
		Account acc = [select Id, Member__c from Account
			where Id = :accId];
		acc.Member__c = isAccountMember;
				
		update acc;
	}

}