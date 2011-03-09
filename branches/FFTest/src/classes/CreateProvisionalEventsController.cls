/*
    Author - Richard Durrant
    Controller for 0818-IPE development task.
    
    Modified by Ben Mansfield 6 August 2010
*/

public with sharing class CreateProvisionalEventsController {

    public Opportunity oppy                 {get; private set;}
    public List<myProduct> theProducts      {get; set;}
    public id theProductId                  {get; set;}
    private Map<Id, list<decimal>> productCosts;
    private  String recordTypeId;
    private Map<Id,Id> oppLineItemsProdMapping;
    public CreateProvisionalEventsController(ApexPages.StandardController con)
    {
        oppLineItemsProdMapping =  new Map<Id,Id>();
        oppy = (Opportunity)con.getRecord();
        theProducts = new List<myProduct>();
        productCosts = new Map<Id, list<decimal>>();
        oppy = [
            SELECT
                id,
                name,
                AccountId,
                Account.RecordType.Name,
                CloseDate,
               (
                    SELECT
                        id,
                        contactId
                    FROM
                        OpportunityContactRoles
                    WHERE
                        isPrimary=true
                ),
                (
                    SELECT
                        Id,
                        TotalPrice,
                        UnitPrice,
                        PricebookEntry.Product2Id,
                        Number_of_Delegates__c
                    FROM
                        OpportunityLineItems o
                )
            FROM
                Opportunity
            WHERE
                id =: oppy.Id];
        
        for(OpportunityLineItem o : oppy.OpportunityLineItems)
        {
            list<decimal> ds = new List<decimal>();
            ds.add(o.UnitPrice);
            ds.add(o.Number_Of_Delegates__c < 1 ? 1 : o.Number_Of_Delegates__c );
            productCosts.put(o.PricebookEntry.Product2Id, ds);
            oppLineItemsProdMapping.put(o.PricebookEntry.Product2Id,o.Id);
        }
        for(Product2 p : [
            SELECT
                id,
                name,
                Family,
                Event_Record_Type__c,
                Event_Type__c
            FROM
                Product2
            WHERE
                id in :productCosts.keySet()
            ORDER BY
                Name])
        {
            if(p.Family == 'Audit' || p.Family == 'In-Company Training' || p.Family == 'Advisory')
                theProducts.add(new myProduct(p, productCosts.get(p.id)));
        }
    }
    
    public void addRow()
    {
        for(myProduct p : theProducts)
        {
            if(p.me.Id == theProductId)
            {
                p.theEvents.add(new Special_Event__c(Venue__c = oppy.Account.RecordType.Name== 'Venue' ? oppy.AccountId :null));
                break;
            }
        }
    }
    
    public PageReference save()
    {
        List<RecordType> rts = [
            SELECT
                id,
                name
            FROM
                RecordType
            WHERE
                SObjectType = 'Special_Event__c'];
        Id recordTypeId;
        //System.SavePoint sp = Database.setSavepoint();
        List<Special_Event__c> events;
        List<Special_Event_Booking__c> bookings = new List<Special_Event_Booking__c>();
        for(myProduct p : theProducts)
        {
            events = new List<Special_Event__c>();
            recordTypeId = null;
            if(p.createable)
            {               
                for(RecordType rt : rts)
                {
                    if(rt.name == p.me.Event_Record_Type__c){
                        recordTypeId = rt.Id;
                    }
                }               
                
                for(Special_Event__c e : p.theEvents)
                {
                    if(e.StartDate__c != null && e.Latest_Start_Date__c != null)
                    {
                        //Special_Event__c e1 = e.clone(true);
                        e.RecordTypeId = recordTypeId;
                        e.type__c = p.me.Event_Type__c;
                        e.Opportunity__c = oppy.Id;
                        
                        // Changed Status to 'Confirmed' & Stage to Provisional
                        /*e.Status__c = 'Costing';*/
                        e.Status__c = 'Requested';
                        e.Stage__c = 'Provisional';
                        if (oppy.AccountId != null)
                            e.Venue__c = oppy.AccountId;
                        e.Product__c = p.myId;
                        //System.debug('*****'+e);
                        events.add(e);
                    }
                }
            
                if(events.size() > 0)
                {
                    try
                    {
                        insert events;
                        //decimal realcost = p.cost.divide(p.numberOfDelegates, 2);
                        //decimal remainder = p.cost - (realcost * p.numberOfDelegates);
                        boolean primaryBooking = true;
                        for(Special_Event__c e : events)
                        {
                            /* AB 27/09/10
                                Modified to assign booking price to primary Event, all other
                                events are set to 0.0
                            */
                            primaryBooking = true;
                            Special_Event_Booking__c booking = new Special_Event_Booking__c(
                                Opportunity__c = oppy.Id,
                                Special_Event__c = e.Id,
                                // Case 00001323
                                // Status__c='Confirmed',
                                Status__c='Provisional',
                                Type__c = 'In-Company Primary',
                                Contact__c = oppy.OpportunityContactRoles[0].contactid,
                                Company__c = oppy.AccountId,
                                Primary_Booking__c = primaryBooking,
                                Booking_Fee__c = primaryBooking ? p.cost : 0.0);
                            primaryBooking = false;
                            if(!oppLineItemsProdMapping.isEmpty())
                            {
                                if(oppLineItemsProdMapping.containsKey(e.Product__c))
                                    booking.OPL_ID__c  = oppLineItemsProdMapping.get(e.Product__c);
                            }
                            bookings.add(booking);                          
                        
                            if(p.numberOfDelegates > 1)
                            {
                                for(integer i = 1; i < p.numberOfDelegates; i++)
                                {
                                    Special_Event_Booking__c bookingAdditional = new Special_Event_Booking__c(
                                        Opportunity__c = oppy.Id,
                                        // Case 00001323
                                		// Status__c='Confirmed',
                                		Status__c='Provisional',
                                        Type__c = 'In-Company Additional',
                                        Special_Event__c = e.Id,
                                        Company__c = oppy.AccountId,
                                        Booking_Fee__c = 0.0);
                                    if(!oppLineItemsProdMapping.isEmpty())
                                    {
                                        if(oppLineItemsProdMapping.containsKey(p.myId))
                                        bookingAdditional.OPL_ID__c  = oppLineItemsProdMapping.get(p.myId);
                                    }
                                    bookings.add(bookingAdditional);
                                }
                            }
/********                   TODO: Remove after testing.                         ******************
                            bookings.add(new Special_Event_Booking__c(
                                Opportunity__c = oppy.Id,
                                Special_Event__c = e.Id,
                                Contact__c = oppy.OpportunityContactRoles[0].contactid,
                                Company__c = oppy.AccountId,
                                Booking_Fee__c = realcost + remainder));
                        
                            if(p.numberOfDelegates > 1)
                            {
                                for(integer i = 1; i < p.numberOfDelegates; i++)
                                {
                                    bookings.add(new Special_Event_Booking__c(
                                        Opportunity__c = oppy.Id,
                                        Special_Event__c = e.Id,
                                        Company__c = oppy.AccountId,
                                        Booking_Fee__c = realcost));
                                }
                            }*/
                        }
                        
                    }
                    catch(System.Exception ex)
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,ex.getMessage()));
                        //Database.rollback(sp);
                        return null;
                    }
                }
            }
        }
        try
        {
            if(bookings.size() > 0)
                insert bookings;
        }
        catch(System.Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,ex.getMessage()));
            //Database.rollback(sp);
            return null;
        }       
        return new PageReference('/'+oppy.id);      
    }
    
    
    
    public class myProduct
    {
        public List<Special_Event__c> theEvents{get; set;}
        public Product2 me{get; set;}
        public Id myId{get; private set;}
        private decimal cost;
        private decimal numberOfDelegates;
        public boolean createable{get; private set;}
        public myProduct(Product2 me, List<decimal> ds)
        {
            this.me = me;
            this.myId = me.Id;
            this.cost = ds[0];
            this.numberOfDelegates = ds[1];
            if(numberOfDelegates == null || numberOfDelegates < 1)
                numberOfDelegates = 1;
            theEvents = new List<Special_Event__c>();
            if(me.Family == 'Audit' || me.Family == 'In-Company Training' || me.Family == 'Advisory'){
                createable = true;
                // brm - 6 August 2010 - removed so no rows are created initially
                //theEvents.add(new Special_Event__c());
            }else{
                createable = false;
            }
        }
        
    }
    
    
    public static TestMethod void tester()
    {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualifying',
            IC_Price_Variation_Approved__c = true,
            CloseDate = System.today());
        insert opp;
        
        Product2 prod = new Product2(
            Name = 'Test Event Product',
            Allows_Provisional_Bookings__c = true,
            Transfer_Charge_Day_1__c = 10,
            Transfer_Charge_Day_2__c = 5,
            Transfer_Charge_Day_3__c = 2,
            family = 'Audit',
            Event_Record_Type__c = 'Audit',
            Event_Type__c = 'Audit',
            Transfer_Charge_Fee_1__c = 120,
            Transfer_Charge_Fee_2__c = 60,
            Transfer_Charge_Fee_3__c = 40,
            Transfer_Charge_Fee_Final__c = 10);
        insert prod;
        
        Pricebook2 stdPricebook = [
            SELECT
                Id
            FROM
                Pricebook2
            WHERE
                IsStandard = true Limit 1];
        
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            UnitPrice = 300,
            Pricebook2Id = stdPricebook.Id,
            IsActive = true);
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            Pricing_Exception__c = true, 
            UnitPrice = 320);
        insert oli;
        
        Contact c = [
            SELECT
                id
            FROM
                Contact
            LIMIT
                1];
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = c.Id,
            isPrimary = true);
        insert ocr;
        
        Test.startTest();
        CreateProvisionalEventsController con = new CreateProvisionalEventsController(new ApexPages.Standardcontroller(opp));
        con.theProductId = prod.Id;
        con.addRow();
        
        for(CreateProvisionalEventsController.myProduct p : con.theProducts){
            Special_Event__c ev = p.theEvents[0];
            ev.StartDate__c = System.today();
            ev.Latest_Start_Date__c = system.today();
            Account a = [
                SELECT
                    id
                FROM
                    Account
                LIMIT
                    1];
            ev.Venue__c = a.Id;
        }
    
        con.save();
        Test.stopTest();
        
    }
}