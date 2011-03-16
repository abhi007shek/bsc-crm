/*   Created by Deepak Gupta 19 July 2010 */
public with sharing class SubscriptionfromOpportunityController {

	private Opportunity record;
  	public SubscriptionfromOpportunityController(ApexPages.StandardController controller){
    	record = getOpportunity(controller.getId()); 
 	}
  
  	private Opportunity getOpportunity(Id id){
    	List<Opportunity> OpportunityQuery = [Select Pricebook2Id,Subscription_Start_Date__c, Subscription_Initiating_Renewal__c, 
    	Renewal_Opportunity__c, Id, AccountId From Opportunity Where Id = :id];
    	
    	if (OpportunityQuery.size() == 1) return OpportunityQuery.get(0);
    	
    	return null;
	}  
 
	public PageReference doAction() {    
		
		Savepoint SP = Database.setSavepoint();     
        
        //Create a new Subscription Record
        Subscription__c NewSubscription=new Subscription__c();
        NewSubscription.Opportunity__c=record.id;
        NewSubscription.Account_Name__c =record.AccountId;
        NewSubscription.Status__c='Pending - Not Paid';
        NewSubscription.Start_Date__c=record.Subscription_Start_Date__c;
        NewSubscription.Previous_Subscription__c=record.Subscription_Initiating_Renewal__c;
        
        List<OpportunityContactRole> OppContRole=[Select ContactId  from OpportunityContactRole where IsPrimary=true and  OpportunityId=:record.id limit 1];
        if (!OppContRole.IsEmpty()) {
            NewSubscription.Contact__c=OppContRole[0].ContactId;
        }
        
        if (record.Renewal_Opportunity__c) { 
                NewSubscription.Type__c='Renewal';
        } else {
                NewSubscription.Type__c='New';
        }
        
        insert NewSubscription; 

		try{      
	        List<Subscription__c> Subscription4Update = [Select Id,Status__c From Subscription__c  where Id=:record.Subscription_Initiating_Renewal__c LIMIT 1 ];
	        
	        if (!Subscription4Update.IsEmpty())  {
	            Subscription4Update[0].Subsequent_Subscription__c=NewSubscription.id;
	            if(Subscription4Update[0].End_Date__c>system.today()){
	                    Subscription4Update[0].Status__c='Current - Renewed';
	            } else {
                    Subscription4Update[0].Status__c='Ended - Renewed'; 
                } 
            	Update Subscription4Update[0];
        	} 
        	
	        //Create SubscriptionLines
	        String strProductCodes='';
	        Integer iRecCnt=0;
	        List<Subscription_Line__c> NewSubscriptionLineItems = new List<Subscription_Line__c>();                                      
	        for (OpportunityLineItem OppLineItem: [Select Id,PricebookEntry.product2Id,PricebookEntry.Product2.Duration_Years__c,Quantity,
	        	PricebookEntry.Product2.ProductCode,TotalPrice,Renewal_Price__c From OpportunityLineItem 
	        	where  OpportunityId= :record.Id and PricebookEntry.Product2.Subscription_Product__c = true]) {   
	        		
	                Subscription_Line__c NewSubscriptionLineItem=new Subscription_Line__c();
	                NewSubscriptionLineItem.Subscription__c=NewSubscription.Id;
	                NewSubscriptionLineItem.Quantity__c=OppLineItem.Quantity;
	                NewSubscriptionLineItem.Quantity_Available__c=OppLineItem.Quantity;
	                NewSubscriptionLineItem.Product_Sales_Price__c=OppLineItem.TotalPrice;
	                NewSubscriptionLineItem.Product__c=OppLineItem.PricebookEntry.product2Id;
	                NewSubscriptionLineItem.Renewal_Price__c=OppLineItem.Renewal_Price__c;
	                NewSubscriptionLineItem.OPL_ID__c  = OppLineItem.Id;
	                NewSubscriptionLineItems.add(NewSubscriptionLineItem);
	                
	                strProductCodes = strProductCodes + OppLineItem.PricebookEntry.Product2.ProductCode + ',';
	                iRecCnt = iRecCnt+1;
	                if (iRecCnt==1) {
	                    if(OppLineItem.PricebookEntry.Product2.Duration_Years__c>0.0) {
	                            //NewSubscription.End_Date__c=NewSubscription.Start_Date__c.addYears((Integer)(OppLineItem.PricebookEntry.Product2.Duration_Years__c));
	                            NewSubscription.End_Date__c=NewSubscription.Start_Date__c.addYears((OppLineItem.PricebookEntry.Product2.Duration_Years__c.intValue()));
	                     }
	                }
	            }           
	            
	            update NewSubscription;
	
	            if (!NewSubscriptionLineItems.IsEmpty()){
	              strProductCodes = strProductCodes.substring(0, strProductCodes.length()-1);
	              NewSubscription.Product_Codes__c=strProductCodes;
	              update NewSubscription;
	              insert NewSubscriptionLineItems;
	            }           
		}catch(Exception e) {
            	
            	System.debug('** found exception, rolling back' + e);
            	
                // roll back everything
                Database.rollback(SP);
                Apexpages.addMessages(e);
                return null;
        }
            
        System.debug('** No exception found committing');
            
    	return new Pagereference('/'+ NewSubscription.Id);
	}  
    
    @IsTest
    private static void testNonSubscriptionProduct()
    {   
        //Create an Account
        Account NewAccount=new Account(name='Test SSCreation Account');
        insert NewAccount;       
        
        // Add a Contact to it
        Contact NewContact= new Contact(LastName='Test SSCreation Contact');
        NewContact.AccountId=NewAccount.id;
        insert NewContact;
            
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.StageName = 'Qualifying';
        opp.CloseDate = System.today();
        opp.AccountId=NewAccount.id;
        opp.Subscription_Start_Date__c = System.today();
        insert opp;
        
        Product2 prod = new Product2();
        prod.Name = 'Test  Product';
        prod.Duration__c='1 Year';
      	prod.Subscription_Product__c = true;
        insert prod;
        
        Pricebook2 stdPricebook = [Select Id From Pricebook2 Where IsStandard = true Limit 1];
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = prod.Id;
        pbe.UnitPrice = 300;
        pbe.Pricebook2Id = stdPricebook.Id;
        pbe.IsActive = true;
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.PricebookEntryId = pbe.Id;
        oli.Quantity = 3;
        oli.UnitPrice = 320;
        
        insert oli;
        
        PageReference PageRef=Page.CreateSubscriptionFromOpportunity;
        test.setCurrentPage(PageRef);
        ApexPages.currentPage().getParameters().put('id',opp.id);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        SubscriptionfromOpportunityController controller= new SubscriptionfromOpportunityController(sc);
        controller.doAction();  
        
        System.debug('** Assert looking for account: ' + NewAccount.id + ' , opp id: ' + opp.Id);
        
        List<Subscription__c> subscriptionList = [select Id from Subscription__c where Account_Name__c = :NewAccount.id and Opportunity__c = :opp.Id];
        Integer subsCount = subscriptionList.size();
        
        System.debug('** Found subscriptions count: ' + subsCount);
        
        System.assertEquals(1, subsCount);
        
        Integer subLineCount = [select count() from Subscription_Line__c where Subscription__c = :subscriptionList.get(0).Id];
        System.assertEquals(1, subLineCount);
    }
    
    @IsTest
    private static void tesSubscriptionProduct()
    {   
        //Create an Account
        Account NewAccount=new Account(name='Test SSCreation Account');
        insert NewAccount;       
        
        // Add a Contact to it
        Contact NewContact= new Contact(LastName='Test SSCreation Contact');
        NewContact.AccountId=NewAccount.id;
        insert NewContact;
            
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.StageName = 'Qualifying';
        opp.CloseDate = System.today();
        opp.AccountId=NewAccount.id;
        opp.Subscription_Start_Date__c = System.today();
        insert opp;
        
        Product2 prod = new Product2();
        prod.Name = 'Test  Product';
        prod.Duration__c='1 Year';
      	prod.Subscription_Product__c = false;
        insert prod;
        
        Pricebook2 stdPricebook = [Select Id From Pricebook2 Where IsStandard = true Limit 1];
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = prod.Id;
        pbe.UnitPrice = 300;
        pbe.Pricebook2Id = stdPricebook.Id;
        pbe.IsActive = true;
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.PricebookEntryId = pbe.Id;
        oli.Quantity = 3;
        oli.UnitPrice = 320;
        
        insert oli;
        
        PageReference PageRef=Page.CreateSubscriptionFromOpportunity;
        test.setCurrentPage(PageRef);
        ApexPages.currentPage().getParameters().put('id',opp.id);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        SubscriptionfromOpportunityController controller= new SubscriptionfromOpportunityController(sc);
        controller.doAction();  
        
        System.debug('** Assert looking for account: ' + NewAccount.id + ' , opp id: ' + opp.Id);
        
        List<Subscription__c> subscriptionList = [select Id from Subscription__c where Account_Name__c = :NewAccount.id and Opportunity__c = :opp.Id];
        Integer subsCount = subscriptionList.size();
        
        System.debug('** Found subscriptions count: ' + subsCount);
        
        System.assertEquals(1, subsCount);
        
        Integer subLineCount = [select count() from Subscription_Line__c where Subscription__c = :subscriptionList.get(0).Id];
        System.assertEquals(0, subLineCount);
    }
    
    @IsTest
    private static void testExceptionPath()
    {   
        //Create an Account
        Account NewAccount=new Account(name='Test SSCreation Account');
        insert NewAccount;       
        
        // Add a Contact to it
        Contact NewContact= new Contact(LastName='Test SSCreation Contact');
        NewContact.AccountId=NewAccount.id;
        insert NewContact;
            
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.StageName = 'Qualifying';
        opp.CloseDate = System.today();
        opp.AccountId=NewAccount.id;
        insert opp;
        
        Product2 prod = new Product2();
        prod.Name = 'Test  Product';
        prod.Duration__c='1 Year';
      	prod.Subscription_Product__c = true;
        insert prod;
        
        Pricebook2 stdPricebook = [Select Id From Pricebook2 Where IsStandard = true Limit 1];
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = prod.Id;
        pbe.UnitPrice = 300;
        pbe.Pricebook2Id = stdPricebook.Id;
        pbe.IsActive = true;
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.PricebookEntryId = pbe.Id;
        oli.Quantity = 3;
        oli.UnitPrice = 320;
        
        insert oli;
        
        PageReference PageRef=Page.CreateSubscriptionFromOpportunity;
        test.setCurrentPage(PageRef);
        ApexPages.currentPage().getParameters().put('id',opp.id);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        SubscriptionfromOpportunityController controller= new SubscriptionfromOpportunityController(sc);
        controller.doAction();  
    }
}