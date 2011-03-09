public with sharing class OpportunityTriggerMethods{

    public class Test_Exception extends Exception{}
    
    //Update Relationship field
    public static void updateAccountFields(List<Opportunity> oppList)
    {
        Set<Id> accId = new Set<Id>();
        for(Opportunity opp:oppList)
        {
              if(opp.isWon || opp.isClosed)
              {   
                accId.add(opp.AccountId);
              }
        }
        if(!accId.isEmpty()) 
        {
            List<Account> updateAccount = new List<Account>();
            for(Account acc:[Select Id,Relationship__c from Account where Id IN:accId])
            {
                acc.Relationship__c = 'Trader';
                updateAccount.add(acc);
            }
            if(!updateAccount.isEmpty() )
                update updateAccount;
        }
    
    
    }
    
    
    public static void updateOpportunityFields(Map<Id,Opportunity> oppMap)
    {    
         // Set values to 0
          for(Opportunity opp:oppMap.values())
          {
              if(opp.isWon)
              {   opp.Invoiced_Total__c = 0;
                  opp.Paid_Total__c = 0;
                  opp.Credited_Total__c  = 0;
              }
          }      
            Map<Id,Double> countInvoiced = new Map<Id,Double>();
            Map<Id,Double> countQuantity = new Map<Id,Double>();
            Map<Id,Double> countPaid = new Map<Id,Double>();
            
                
            for(OpportunityLineItem lineItem:[Select UnitPrice,
                                                    Quantity_Credited__c,
                                                    Quantity_Invoiced__c,
                                                    OpportunityId, 
                                                    Quantity_Paid__c, 
                                                    Quantity from OpportunityLineItem 
                                                    where OpportunityId IN:oppMap.keySet()
                                                    ]) 
            {
                if(oppMap.containsKey(lineItem.OpportunityId))
                {
                    if(oppMap.get(lineItem.OpportunityId).isWon)
                    {       
                            if(lineItem.Quantity_Invoiced__c!=null)
                            {
                                //Sum up Opportunity Product Lines Quantity Invoiced
                                if(!countInvoiced.containsKey(lineItem.OpportunityId))
                                    countInvoiced.put(lineItem.OpportunityId,lineItem.Quantity_Invoiced__c);
                                else{
                                    Double quantity = countInvoiced.get(lineItem.OpportunityId);
                                    quantity += lineItem.Quantity_Invoiced__c;
                                    countInvoiced.put(lineItem.OpportunityId,quantity);
                                }
                                
                                //Calculate invoiced total 
                                if(lineItem.UnitPrice!=null) 
                                  oppMap.get(lineItem.OpportunityId).Invoiced_Total__c += lineItem.UnitPrice * lineItem.Quantity_Invoiced__c;                         
                            
                            }else{
                                 
                                 if(!countInvoiced.containsKey(lineItem.OpportunityId))
                                    countInvoiced.put(lineItem.OpportunityId,0);                   
                          
                            }
                                
                            if(lineItem.Quantity_Paid__c!=null)
                            {
                                //Sum up Opportunity Product Lines Quantity Paid
                                if(!countPaid.containsKey(lineItem.OpportunityId))
                                    countPaid.put(lineItem.OpportunityId,lineItem.Quantity_Paid__c);
                                else{
                                    Double quantity = countPaid.get(lineItem.OpportunityId);
                                    quantity += lineItem.Quantity_Paid__c;
                                    countPaid.put(lineItem.OpportunityId,quantity);
                                }
                                
                                //Calculate paid total  
                                if(lineItem.UnitPrice!=null) 
                                  oppMap.get(lineItem.OpportunityId).Paid_Total__c += lineItem.UnitPrice * lineItem.Quantity_Paid__c; 
                            }else{
                                
                                if(!countPaid.containsKey(lineItem.OpportunityId))
                                    countPaid.put(lineItem.OpportunityId,0);
                            
                            }
                            
                            //Sum up Opportunity Product Lines Quantity
                            if(!countQuantity.containsKey(lineItem.OpportunityId))
                                    countQuantity.put(lineItem.OpportunityId,lineItem.Quantity);
                                else{
                                    Double quantity = countQuantity.get(lineItem.OpportunityId);
                                    quantity += lineItem.Quantity;
                                    countQuantity.put(lineItem.OpportunityId,quantity);
                                }
                            
                            //Calculate credited total 
                            if(lineItem.Quantity_Credited__c!=null)
                                oppMap.get(lineItem.OpportunityId).Credited_Total__c += lineItem.UnitPrice * lineItem.Quantity_Credited__c;
                                
                       }          
                  }  
                    
              }
            
            
            for(Opportunity opp:oppMap.values())
            {    
                /**update Stage**/
                if(countInvoiced.containsKey(opp.Id))
                {   
                    if(countInvoiced.get(opp.Id) == 0)
                    {
                       opp.StageName = 'Booking Received'; 
                    }
                    if(countQuantity.containsKey(opp.Id))
                    {
                        if(countInvoiced.get(opp.Id) > 0 && countInvoiced.get(opp.Id) < countQuantity.get(opp.Id))
                        {
                            opp.StageName  = 'Part Invoiced';
                        
                        }
                    
                        if(countInvoiced.get(opp.Id) == countQuantity.get(opp.Id))
                        {
                            opp.StageName  = 'Invoiced';
                        }
                        
                        if(countPaid.containsKey(opp.Id))
                        {
                            if(countPaid.get(opp.Id)> 0 && countPaid.get(opp.Id) < countQuantity.get(opp.Id))
                            {
                                opp.StageName  = 'Part Paid';
                            }
                            
                            if(countPaid.get(opp.Id) == countQuantity.get(opp.Id))
                            {
                                opp.StageName  = 'Paid';
                                opp.Invoice_Paid_Date__c = Date.today();
                            }
                            
                        }
                    }
                }
         }
    }
   public static testMethod void TestOpportunityTriggerMethods()
   {
   		Opportunity opp = [
   			SELECT
   				Id,
   				Invoiced_Total__c,
   				Paid_Total__c,
   				Credited_Total__c,
   				PriceBook2Id,
   				CurrencyIsoCode
   			FROM
   				Opportunity
   			WHERE
   				PriceBook2Id != null
   			LIMIT 1];
                                 
       	opp.Price_Approval_Given__c = true;
       	opp.StageName = 'Qualifying';
       	System.debug('@' + opp.isWon + '@' + opp.HasOpportunityLineItem);
       	update opp;
       	System.debug('@@' + opp.isWon + '@@' + opp.HasOpportunityLineItem);
       	OpportunityLineItem lineItem = new OpportunityLineItem (
			OpportunityId= opp.Id,
			PriceBookEntryId = [
				SELECT
					Id
				FROM
					PriceBookEntry
				WHERE
					PriceBook2Id = :opp.PriceBook2Id
				AND
					CurrencyIsoCode = :opp.CurrencyIsoCode
				LIMIT 1].Id,
			UnitPrice = 500,
			Quantity = 2,
			Quantity_Invoiced__c = 5,
			Quantity_Paid__c = 1,
			Quantity_Credited__c = 2);
                                                                
        insert lineItem ;
        //System.debug('@@@'+opp.isWon+'@@@'+opp.HasOpportunityLineItem);
        //throw new Test_Exception(opp.StageName +' && '+opp.HasOpportunityLineItem);
         OpportunityTriggerMethods.updateOpportunityFields(new Map<Id,Opportunity>([Select Id,
                                                                                          Invoiced_Total__c,
                                                                                          IsWon,
                                                                                          HasOpportunityLineItem ,
                                                                                          Paid_Total__c,
                                                                                          Credited_Total__c
                                                                                          from Opportunity where Id=:opp.Id limit 1]));
   
   
   }  
    
 }