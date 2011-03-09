/*
  Created by Deepak Gupta 19 July 2010
  
  Description:
  Todo:
    * Test Methods 
*/
public with sharing class OpportunitySplitController{
private Opportunity record;
  public OpportunitySplitController(ApexPages.StandardController controller)
  {
    record = getOpportunity(controller.getId());
  }
  private Opportunity getOpportunity(Id id)
  {
    List<Opportunity> OpportunityQuery = [Select  Pricing_Notes__c, Decision_Making_Process__c, Customer_Service_notes__c,IsClosed,RecordTypeId,AccountId,CampaignId,Project__c,Renewal_Opportunity__c, OwnerId, Name, Description, Amount,CloseDate From Opportunity where Id = :id];
    if (OpportunityQuery.size() == 1) return OpportunityQuery.get(0);
    return null;   
  } 
 public PageReference doAction()
  {
    //if (record != null)
    //{
        Savepoint SP = Database.setSavepoint(); 
        Id OppId=record.Id;
        //original opportunity is cloned 
        Opportunity NewOpp =  record.clone(false);  
        NewOpp.Name=record.Name+'-R'; 
        NewOpp.Rollover_Opportunity__c=true;
        NewOpp.StageName='Qualifying'; 
        NewOpp.Original_Opportunity__c=record.Id; 
        insert NewOpp;   
        TRY 
        {
            
            List<OpportunityContactRole> copyContactRole = new List<OpportunityContactRole>(); 
            for(OpportunityContactRole contactRole:[Select o.Role, o.OpportunityId, o.IsPrimary, o.ContactId From OpportunityContactRole o where o.OpportunityId=:OppId ])
            {
               OpportunityContactRole newContactRole = new OpportunityContactRole(OpportunityId = NewOpp.Id,
                                                                                  ContactId = contactRole.ContactId,
                                                                                  IsPrimary = contactRole.IsPrimary,
                                                                                  Role = contactRole.Role);
               copyContactRole.add(newContactRole);
            }
            if(!copyContactRole.isEmpty())
                insert copyContactRole;
                
            // Clone BSC Event bookings except where status is equal to Provisional
            List<Special_Event_Booking__c> OppNewEventBookings =new List<Special_Event_Booking__c>();
            List<Special_Event_Booking__c> OppOrigEventBookings =[Select Special_Event__r.Product__c, Transferred_To__c, Transferred_From__c, Transfer_Cancellation_Date__c, Status__c, Special_Event__c, PK_CB_ELEM_ID__c,  Name, Fee_Date__c, FK_CB_COURSE_ID__c, FK_CB_BOOK_ID__c, Event_end_Date__c, Event_Start_Date__c, Contact__c, ConnectionSentId, ConnectionReceivedId, Company__c, Booking_Fee__c From Special_Event_Booking__c  where Status__c='Provisional' and  Opportunity__c= :(string) (OppId)];
            //List<Special_Event_Booking__c> OppOrigConfirmedEventBookings =[Select Special_Event__r.Product__c, Transferred_To__c, Transferred_From__c, Transfer_Cancellation_Date__c, Status__c, Special_Event__c, PK_CB_ELEM_ID__c,  Name, Fee_Date__c, FK_CB_COURSE_ID__c, FK_CB_BOOK_ID__c, Event_end_Date__c, Event_Start_Date__c, Contact__c, ConnectionSentId, ConnectionReceivedId, Company__c, Booking_Fee__c From Special_Event_Booking__c  where Status__c='Confirmed' and  Opportunity__c= :(string) (OppId)];
            //Map<Id, Id> m = new Map<Id, Id>(); // Define a new map
            Map<String, decimal> n = new Map<String, decimal>(); // Define a new map
                string PcodePrice;
                Decimal CurrentValue;   
                Decimal CurrentValue1;          
                if (OppOrigEventBookings.size()>0)
                {  
                  for (Special_Event_Booking__c OppEventBooking:OppOrigEventBookings )          
                    {
                        Special_Event_Booking__c NewEventBooking=OppEventBooking.clone(false);
                        NewEventBooking.Opportunity__c=NewOpp.Id;
                        OppNewEventBookings.add(NewEventBooking);
                    } 
                    
                    if (OppNewEventBookings.size()>0)
                    {
                        insert OppNewEventBookings; 
                    }                                       
                    //BSC Event Bookings where the status is equal to “Provisional” are deleted from the old opportunity
                    if (OppOrigEventBookings.size()>0)
                    {
                        Delete  OppOrigEventBookings;
                    }        
                }

            for (Special_Event_Booking__c ConfirmedBooking :[Select Special_Event__r.Product__c, Transferred_To__c, Transferred_From__c, Transfer_Cancellation_Date__c, Status__c, Special_Event__c, PK_CB_ELEM_ID__c,  Name, Fee_Date__c, FK_CB_COURSE_ID__c, FK_CB_BOOK_ID__c, Event_end_Date__c, Event_Start_Date__c, Contact__c, ConnectionSentId, ConnectionReceivedId, Company__c, Booking_Fee__c From Special_Event_Booking__c  where Status__c='Confirmed' and  Opportunity__c= :(string) (OppId)])
            {
                PcodePrice=(string) ConfirmedBooking.Special_Event__r.Product__c + ConfirmedBooking.Booking_Fee__c.toPlainString();
                if (!n.containsKey(PcodePrice))
                {
                    n.put(PcodePrice, 1.00);
                }               
                else
                {
                    CurrentValue=n.get(PcodePrice);
                    CurrentValue1=n.Remove(PcodePrice);
                    n.put(PcodePrice,(CurrentValue + 1.00) );
                }           
            }   
            //List<OpportunityLineItem> OppLineItemsOrig =[Select PricebookEntry.product2Id,UnitPrice, T_C_Price__c, ListPrice,Quantity,PricebookEntryId  From OpportunityLineItem  where OpportunityId= :OppId];
            
            List<OpportunityLineItem> OppNewLineItems     =new List<OpportunityLineItem>();
            List<OpportunityLineItem> OppLineItems2Delete =new List<OpportunityLineItem>();
            List<OpportunityLineItem> OppLineItems2Update =new List<OpportunityLineItem>();
            for (OpportunityLineItem OppLineItemOrig :[Select PricebookEntry.product2Id,UnitPrice, T_C_Price__c, ListPrice,Quantity,PricebookEntryId  From OpportunityLineItem  where OpportunityId= :OppId])
            {
                PcodePrice=(string) OppLineItemOrig.PricebookEntry.product2Id + OppLineItemOrig.UnitPrice.toPlainString();
                if (!n.containsKey(PcodePrice))
                {
                    //Add to New Opp, a new Opp Lineitem with number as Original
                     OpportunityLineItem NewLineItem=OppLineItemOrig.clone(false);
                     NewLineItem.OpportunityId=  NewOpp.id;
                     OppNewLineItems.add(NewLineItem);                  
                    // Delete Opp LineItem from Original Opp
                    OppLineItems2Delete.add(OppLineItemOrig);
                }               
                else
                {
                    //Add to New Opp, a new Opp Lineitem with number as (Original-in Map) if that is > 0
                    if ((OppLineItemOrig.Quantity -n.get(PcodePrice))>0.0)
                    {
                     OpportunityLineItem NewLineItem=OppLineItemOrig.clone(false);
                     NewLineItem.OpportunityId=  NewOpp.id;
                     NewLineItem.Quantity=OppLineItemOrig.Quantity -n.get(PcodePrice);
                     OppNewLineItems.add(NewLineItem);                                      
                    }
                    //Update Original OppLineItem with Number as in Map                 
                    OppLineItemOrig.Quantity=n.get(PcodePrice);
                    OppLineItems2Update.add(OppLineItemOrig);                                       
                }                           
            }   
                if  (OppNewLineItems.size()>0)
                {
                    insert OppNewLineItems;
                }

                if  (OppLineItems2Delete.size()>0)
                {
                    Delete OppLineItems2Delete;
                }

                if  (OppLineItems2Update.size()>0)
                {
                    Update OppLineItems2Update ;    
                }
                                                  
                        

        }
        CATCH (Exception e)
            {
                // roll back everything
                Database.rollback(SP);
                Apexpages.addMessages(e);
                return null;
            }       
        return new Pagereference('/'+ NewOpp.Id);
  }  
}