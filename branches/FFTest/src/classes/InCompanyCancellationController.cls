/*
    Code Coverage - 99% 07-10-10
    Created by Ben Mansfield 16 July 2010
    Modified by Ben Mansfield 4 August 2010 
    
    Description:
    
    Changes:
    
        4 August 2010
        * Changed Opportunity and Opportunity Product creation by adding Pricebook from original Opportunity
    
*/
public with sharing class InCompanyCancellationController {

    private Special_Event__c record;
    
    

    public InCompanyCancellationController(ApexPages.StandardController controller)
    {
        record = getEvent(controller.getId());
    }
    
    private Special_Event__c getEvent(Id id)
    {
        List<Special_Event__c> eventQuery = [
            SELECT
                Name,
                Id,
                Product__c,
                Opportunity__c, 
                Opportunity__r.Name,
                Opportunity__r.AccountId,
                Opportunity__r.OwnerId,
                Opportunity__r.Pricebook2Id
            FROM
                Special_Event__c
            WHERE
                Id = :id];
                                            
        if (eventQuery.size() == 1)
            return eventQuery.get(0);
        
        return null;
    }
    
    public PageReference doAction()
    {
        
        
        List<Product2> products = [
            SELECT
                Id,
                Cancellation_Charge_Day_1__c,
                Cancellation_Charge_Day_2__c, 
                Cancellation_Charge_Day_3__c,
                Cancellation_Charge_Fee_1__c, 
                Cancellation_Charge_Fee_2__c,
                Cancellation_Charge_Fee_3__c, 
                Cancellation_Charge_Fee_Final__c,
                Description 
            FROM
                Product2
            WHERE
                Id = :record.Product__c];
        
        if (products.size() == 1)
        {
            Double totalCost = 0;
            List<Special_Event_Booking__c> eventBookings = new List<Special_Event_Booking__c>();
            for (Special_Event_Booking__c booking : [
                SELECT
                    Id,
                    Booking_Fee__c,
                    Event_Start_Date__c
                FROM
                    Special_Event_Booking__c
                WHERE
                    Special_Event__c = :record.Id])
            {
                Double cancellationCost = BookingHelper.calculateCancellationCost(booking, products.get(0));
                booking.Booking_Fee__c = cancellationCost;
                booking.Status__c = 'Cancelled';
                booking.Transfer_Cancellation_Date__c = System.today();
                totalCost += cancellationCost;
                
                eventBookings.add(booking);
            }
            
            update eventBookings;
            
            List<RecordType> recordTypes = [
                SELECT
                    Id
                FROM
                    RecordType
                WHERE
                    SObjectType = 'Opportunity'
                AND
                    Name = 'In-Company Event'
                LIMIT
                    1];
            
            Opportunity opp = new Opportunity(
                AccountId = record.Opportunity__r.AccountId,
                OwnerId = record.Opportunity__r.OwnerId,
                Name = record.Opportunity__r.Name + ' - Cancellation Fee',
                RecordTypeId = recordTypes.isEmpty() ? null : recordTypes.get(0).Id,                
                // brm - 4 August 2010 - set pricebook in new opp
                Pricebook2Id = record.Opportunity__r.Pricebook2Id,
                Type = 'In-Company Course',
                CloseDate = System.Today(),
                StageName = 'Quote/Negotiation',
                IC_Price_Variation_Approved__c = true,
                Rollover_Opportunity__c = true,
                Original_Opportunity__c = record.Opportunity__c);
                
            insert opp;
            // brm - 4 August 2010 - now using pricebook when finding pricebook entries
            Map<String, PricebookEntry> entries = BookingHelper.getPricebookEntries(record.Opportunity__r.Pricebook2Id,
                new String[] {'Cancellation Fees (In-Company)', 'Reconciliation (In-Company)'});
            
            List<OpportunityLineItem> olisToInsert = new List<OpportunityLineItem>();
            
            if (entries.containsKey('Cancellation Fees (In-Company)'))
            {
                OpportunityLineItem oli = new OpportunityLineItem(
                    PricebookEntryId = entries.get('Cancellation Fees (In-Company)').Id,
                    OpportunityId = opp.Id,
                    Quantity = 1,
                    Sales_Manager_Price__c = totalCost,
                    UnitPrice = totalCost,
                    Pricing_Exception__c = true,
                    T_C_Price__c = totalCost); 
                
                olisToInsert.add(oli);
            }
            
            List<OpportunityLineItem> originalOlis = [
                SELECT
                    c2g__CODAUnitOfWork__c,
                    UnitPrice,
                    TotalPrice,
                    T_C_Price__c,
                    T_C_Price_Variation__c,
                    SystemModstamp, 
                    Subscription_Start_Date__c,
                    Subscription_Product__c, 
                    SortOrder,
                    ServiceDate,
                    Sales_Manager_Price__c, 
                    SM_Price_Needed__c,
                    Quantity,
                    Pricing_Exception__c, 
                    PricebookEntryId,
                    OpportunityId,
                    ListPrice, 
                    LastModifiedDate,
                    LastModifiedById,
                    IsDeleted,
                    Id, 
                    IC_Price_Difference__c,
                    HasSchedule,
                    HasRevenueSchedule, 
                    HasQuantitySchedule,
                    Duration_Years__c,
                    Discounted__c, 
                    Description,
                    CurrencyIsoCode,
                    CreatedDate,
                    CreatedById, 
                    ConnectionSentId,
                    ConnectionReceivedId 
                FROM
                    OpportunityLineItem
                WHERE
                    PricebookEntry.Product2Id = :products.get(0).Id
                AND
                    OpportunityId = :record.Opportunity__c];
            
            if (originalOlis.size() == 1)
            {
                // Step 6
                OpportunityLineItem clonedOli = originalOlis.get(0).clone(false, true);
                clonedOli.UnitPrice = -clonedOli.UnitPrice;
                clonedOli.TotalPrice = null;
                clonedOli.Pricing_Exception__c = true;
                clonedOli.Sales_Manager_Price__c = originalOlis.get(0).TotalPrice;
                olisToInsert.add(clonedOli);
                
                // Step 7 - 9
                if (entries.containsKey('Reconciliation (In-Company)'))
                {
                    OpportunityLineItem reconOrigOli = new OpportunityLineItem(
                        PricebookEntryId = entries.get('Reconciliation (In-Company)').Id,
                        OpportunityId = record.Opportunity__c,
                        Sales_Manager_Price__c = originalOlis.get(0).TotalPrice,
                        Quantity = 1,
                        UnitPrice = originalOlis.get(0).TotalPrice,
                        Pricing_Exception__c = true
                        );
                    olisToInsert.add(reconOrigOli);
                    
                    OpportunityLineItem reconNewOli = new OpportunityLineItem(
                        PricebookEntryId = entries.get('Reconciliation (In-Company)').Id,
                        OpportunityId = opp.Id,
                        Quantity = 1,
                        Sales_Manager_Price__c = originalOlis.get(0).TotalPrice,
                        UnitPrice = -originalOlis.get(0).TotalPrice,
                        Pricing_Exception__c = true);
                    olisToInsert.add(reconNewOli);
                }
            }
            
            insert olisToInsert;
            if (entries.containsKey('Cancellation Fees (In-Company)'))
            {
                for(Special_Event_Booking__c booking:eventBookings)
                {
                    booking.OPL_ID__c = olisToInsert.get(0).Id;
                }
                
                update eventBookings;
            }
            
            
            // brm - 20 July 2010 - change event status to 'to be cancelled'
            record.Status__c = 'To be cancelled';
            
            update record;
            products.get(0).Description =  record.Name;
            update products;
            if(record.RecordTypeId == '012200000001W3h')
                return new PageReference('/'+opp.Id);
        }
        
        return new PageReference('/' + record.Id);
    }
    
    @IsTest
    private static void test()
    {
        Product2 prod = new Product2(Name = 'Product Test');
        prod.Cancellation_Charge_Day_1__c = 32;
        prod.Cancellation_Charge_Day_2__c = 16;
        prod.Cancellation_Charge_Day_3__c = 4;
        
        prod.Cancellation_Charge_Fee_1__c = 10;
        prod.Cancellation_Charge_Fee_2__c = 20;
        prod.Cancellation_Charge_Fee_3__c = 50;
        prod.Cancellation_Charge_Fee_Final__c = 100;
        insert prod;
        
        Pricebook2 stdPricebook = [Select Id From Pricebook2 Where IsStandard = true Limit 1];
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = stdPricebook.Id;
        pbe.Product2Id = prod.Id;
        pbe.UnitPrice = 360;
        pbe.IsActive = true;
        insert pbe;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'In-Company Event Test';
        opp.StageName = 'Qualifying';
        opp.CloseDate = System.today();
        insert opp;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.PricebookEntryId = pbe.Id;
        oli.UnitPrice = 360;
        oli.Quantity = 1;
        insert oli;
        
        Special_Event__c event = new Special_Event__c();
        event.StartDate__c = System.today() + 5;
        event.Product__c = prod.Id;
        event.Opportunity__c = opp.Id;
        insert event;
        
        Special_Event_Booking__c booking = new Special_Event_Booking__c();
        booking.Booking_Fee__c = 200;
        booking.Special_Event__c = event.Id;
        insert booking;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(event);
        InCompanyCancellationController controller = new InCompanyCancellationController(stdController);
        controller.doAction();
    }
}