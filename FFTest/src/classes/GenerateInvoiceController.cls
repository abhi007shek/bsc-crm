public with sharing class GenerateInvoiceController {

    public static boolean isTest = false;

    public class Test_Exception extends Exception{}
    public List<AccountExt> accontExtList {get; set;}
    public String stage {get;set;}
    public List<OpportunityExt> defaultOppExtList;
    public AccountExt currentAcc{get;set;}
    public GenerateInvoiceController()
    {

        GenerateInvoiceController.isTest = false;
        String sObjectid = ApexPages.currentPage().getParameters().get('id');
        stage = 'Default';
        defaultOppExtList = new List<OpportunityExt>();
        if(sObjectid!=null)
        {
            accontExtList = new List<AccountExt>();
            
            Set<String> oppLineId = new  Set<String>();
            if(isOpportunity(sObjectid))
            {
                
                
                //Current record is an opportunity. It should be on top of the list
                //***************************************************************************
                //Change done by Navin Muneesamy on 09/02/2011 
                //Change to the SOQL query to retrieve non zero Unit Prices on OpportunityLineItems.
                //This was causing the error: Aggregate query has too many rows for direct assignment, use FOR loop
                //***************************************************************************                 
                Opportunity currentOpp = [Select o.Id,
                                                o.Name,
                                                o.CloseDate, 
                                                o.Owner.Name,
                                                o.OwnerId,
                                                o.Purchase_Order_Reference__c,
                                                (Select l.Id,
                                                  l.OpportunityId,
                                                  l.PriceBookEntry.Product2.Name,
                                                  l.PriceBookEntry.Product2Id, 
                                                  l.Quantity,
                                                  l.Set_an_Invoice_Quantity__c, 
                                                  l.Quantity_Invoiced__c,
                                                  l.Quantity_Credited__c,
                                                  l.UnitPrice from OpportunityLineItems l
                                                  Where l.UnitPrice <> 0 ), 
                                                o.AccountId from Opportunity o
                                                where o.Id=:sObjectid limit 1];
                
                currentAcc = new AccountExt([Select Id,
                                                    Name,
                                                    (Select Id,
                                                            Name,
                                                            CloseDate, 
                                                            Owner.Name,
                                                            OwnerId,
                                                            AccountId 
                                                            from Opportunities),
                                                    Ultimate_Parent__c from Account where Id=:currentOpp.AccountId]);
                                                    
                
                //First opportunity wihtin the list
                currentAcc.opportunityExtList.add(new OpportunityExt(currentOpp));
                
                //Opportunities list
                //***************************************************************************
                //Change done by Navin Muneesamy on 09/02/2011 
                //Change to the SOQL query to retrieve non zero Unit Prices on OpportunityLineItems.
                //This was causing the error: Aggregate query has too many rows for direct assignment, use FOR loop
                //***************************************************************************                 
                for(Opportunity opp:[Select o.Id,
                                          o.Name,
                                          o.CloseDate, 
                                          o.Owner.Name,
                                          o.OwnerId,
                                          o.Purchase_Order_Reference__c, 
                                          (Select l.Id,
                                                  l.OpportunityId,
                                                  l.PriceBookEntry.Product2.Name,
                                                  l.PriceBookEntry.Product2Id,
                                                  l.Set_an_Invoice_Quantity__c, 
                                                  l.Quantity, 
                                                  l.Quantity_Invoiced__c,
                                                  l.Quantity_Credited__c,
                                                  l.UnitPrice from OpportunityLineItems l
                                                  Where l.UnitPrice <> 0),
                                          o.AccountId from Opportunity o where o.AccountId=:currentAcc.acc.Id
                                          and (o.IsClosed = true or o.StageName = 'Part Invoiced')
                                          and o.Id!=:currentOpp.Id])
                {
                    
                    currentAcc.opportunityExtList.add(new OpportunityExt(opp));
                }
                
                
                
            }
            
            if(isAccount(sObjectid))
            {
                //Current record is an account
                currentAcc = new AccountExt([Select Id,
                                                    Name,
                                                    (Select Id,
                                                            Name,
                                                            OwnerId,
                                                            CloseDate, 
                                                            Owner.Name,
                                                            Purchase_Order_Reference__c,
                                                            AccountId 
                                                            from Opportunities
                                                            where(IsClosed = true or StageName = 'Part Invoiced')),
                                                    Ultimate_Parent__c from Account where Id=:sObjectid]);
                
                //Opportunities list
                //***************************************************************************
                //Change done by Navin Muneesamy on 09/02/2011 
                //Change to the SOQL query to retrieve non zero Unit Prices on OpportunityLineItems.
                //This was causing the error: Aggregate query has too many rows for direct assignment, use FOR loop
                //***************************************************************************                                 
                for(Opportunity opp:[Select o.Id,
                                            o.Name,
                                            o.CloseDate, 
                                            o.Owner.Name,
                                            o.OwnerId,
                                            o.Purchase_Order_Reference__c,
                                            (Select l.Id,
                                                    l.PriceBookEntry.Product2.Name, 
                                                    l.PriceBookEntry.Product2Id,
                                                    l.Quantity,
                                                    l.Set_an_Invoice_Quantity__c, 
                                                    l.Quantity_Invoiced__c,
                                                    l.Quantity_Credited__c,
                                                    l.UnitPrice from OpportunityLineItems l
                                             Where l.UnitPrice <> 0), 
                                            o.AccountId from Opportunity o where o.AccountId=:currentAcc.acc.Id
                                            and (o.IsClosed = true or o.StageName = 'Part Invoiced')
                                          ])
                {
                    System.debug('@@@@'+opp.OpportunityLineItems);
                    currentAcc.opportunityExtList.add(new OpportunityExt(opp));
                }
                    
             }
            
            //Opportunity Line Items list
            if(!currentAcc.opportunityExtList.isEmpty())
            {
                for(OpportunityExt oppExt :currentAcc.opportunityExtList)   
                {
                     
                        for(OpportunityLineItem oppLineItem: oppExt.opp.OpportunityLineItems)
                        {
                            //Can be invoiced
                            //throw new Test_Exception('Quantity_Invoiced__c'+oppLineItem.Quantity_Invoiced__c+'@@'+oppLineItem.Quantity);
                            if(oppLineItem.Quantity_Invoiced__c == null)
                            {
                                
                                oppLineId.add(oppLineItem.Id);
                                oppExt.oppLineItemExtList.add(new oppLineItemExt(oppLineItem));
                            }
                            else
                            {
                                if(oppLineItem.Quantity - oppLineItem.Quantity_Invoiced__c > 0)
                                {
                                    oppLineId.add(oppLineItem.Id);
                                    oppExt.oppLineItemExtList.add(new oppLineItemExt(oppLineItem));
                                }
                            }
                            //Credited opportunity line item
                            if(oppLineItem.Quantity_Credited__c!=null && oppLineItem.Quantity_Credited__c>0)
                            {   
                                oppExt.creditOppLineItemExtList.add(new oppLineItemExt(oppLineItem));
                                if(!oppLineId.contains(oppLineItem.Id)) 
                                    oppLineId.add(oppLineItem.Id);
                                
                            }   
                        } 
                  
                }
                System.debug('@@'+oppLineId);
                //Booking events list
                for(Special_Event_Booking__c booking : [Select s.Status__c, 
                                                               s.Special_Event__r.Status__c,
                                                               s.Special_Event__c, 
                                                               s.Name,
                                                               s.Special_Event__r.Name,
                                                               s.Special_Event__r.Product__c,
                                                               s.Product__c,
                                                               s.Special_Event__r.Product__r.Dimension_1__c,
                                                               s.Special_Event__r.Product__r.Dimension_2__c,
                                                               s.Special_Event__r.Dimension_4__c,
                                                               s.OPL_ID__c, 
                                                               s.Invoice_Status__c, 
                                                               s.Event_Start_Date__c, 
                                                               s.Credited_Status__c, 
                                                               s.Contact__r.FirstName,
                                                               s.Contact__r.LastName, 
                                                               s.Booking_Fee__c From Special_Event_Booking__c s
                                                               where s.OPL_ID__c IN:oppLineId
                                                               and Type__c!='In-Company Additional' ])                                               
                {
                    
                    for(OpportunityExt oppExt :currentAcc.opportunityExtList)   
                    {
                        if(!oppExt.oppLineItemExtList.isEmpty())
                        {
                            for(OppLineItemExt oppLineItemExt: oppExt.oppLineItemExtList)
                            {
                                if(oppLineItemExt.oppLineItem.Id == booking.OPL_ID__c)
                                    oppLineItemExt.bookingExtList.add(new BookingExt(booking));
    
                            }
                        }
                        
                        if(!oppExt.creditOppLineItemExtList.isEmpty())
                        {
                            for(OppLineItemExt oppLineItemExt: oppExt.creditOppLineItemExtList)
                            {
                                if(oppLineItemExt.oppLineItem.Id == booking.OPL_ID__c)
                                    oppLineItemExt.bookingExtList.add(new BookingExt(booking));
    
                            }
                        }
                        
                    }
                        
                }
                
                //Subscription lines
                for(Subscription_Line__c subsLine :[Select s.Subscription__r.Sub_Ref__c, 
                                                           s.Subscription__r.Account_Name__r.Name,
                                                           s.Quantity__c, 
                                                           s.Product__c, 
                                                           s.Product_Sales_Price__c, 
                                                           s.OPL_ID__c, 
                                                           s.Name, 
                                                           s.Invoice_Status__c, 
                                                           s.Credited_Status__c 
                                                           from Subscription_Line__c s
                                                           where s.OPL_ID__c IN:oppLineId ])                                               
                {
                    
                    for(OpportunityExt oppExt :currentAcc.opportunityExtList)   
                    {
                        if(!oppExt.oppLineItemExtList.isEmpty())
                        {
                            for(OppLineItemExt oppLineItemExt: oppExt.oppLineItemExtList)
                            {
                                if(oppLineItemExt.oppLineItem.Id == subsLine.OPL_ID__c)
                                    oppLineItemExt.subscriptionLineExtList.add(new SubscriptionLineExt(subsLine));
    
                            }
                        }
                        
                        if(!oppExt.creditOppLineItemExtList.isEmpty())
                        {
                            for(OppLineItemExt oppLineItemExt: oppExt.creditOppLineItemExtList)
                            {
                                if(oppLineItemExt.oppLineItem.Id == subsLine.OPL_ID__c)
                                    oppLineItemExt.subscriptionLineExtList.add(new SubscriptionLineExt(subsLine));
    
                            }
                        }
                    }
                        
                }
                
            }
            //currentAcc.stage = 'Default';
            accontExtList.add(currentAcc);      
        }
        else{
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Id missing'); 
            ApexPages.addMessage(myMsg);
        }  
    }
    
    
    public List<OpportunityExt> copyOpportunityExt(List<OpportunityExt> inExt)
    {
        List<OpportunityExt> copyList = new List<OpportunityExt>();
        for(OpportunityExt oppExt:inExt)
        {
            OpportunityExt oppExtCopy = new OpportunityExt(oppExt.opp);
            oppExtCopy.creditOppLineItemExtList = new List<OppLineItemExt>(oppExt.creditOppLineItemExtList);
            oppExtCopy.oppLineItemExtList = new List<OppLineItemExt>(oppExt.oppLineItemExtList);
            copyList.add(oppExtCopy);
        }
        return copyList;
    }
    
    //Check if it's an id of an Opportunity record
    public boolean isOpportunity(String id)
    {
        Schema.DescribeSObjectResult result = Opportunity.SObjectType.getDescribe();
        return(id.startsWith(result.getKeyPrefix()));

    }
    
    
    //Check if it's an id of an Account record
    public boolean isAccount(String id)
    {
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        return(id.startsWith(result.getKeyPrefix()));

    }
    
    public boolean containsAccount(Id accId)
    {
        if(!accontExtList.isEmpty())
        {
            for(AccountExt accExt:accontExtList)
            {
                if(accExt.acc.Id == accId)
                {
                    return true;
                    
                }
            }
        }
        return false;
    }
    
    public boolean containsOppLineItem(Id oppLineId)
    {
        if(!accontExtList.isEmpty())
        {
            for(AccountExt accExt:this.accontExtList)
            {
                for(OpportunityExt oppExt :accExt.opportunityExtList)
                {
                    for(OppLineItemExt oppLineItemExt: oppExt.oppLineItemExtList)
                    {
                        if(oppLineItemExt.oppLineItem.Id == oppLineId)
                             return true;
                     }
                } 
            } 
        }
        return false;
    }
    
    // populate the booking list for each opportunity line item
    public void populateBookingList(Set<String> oppLineId)
    {
        for(Special_Event_Booking__c booking : [Select s.Status__c, 
                                                               s.Special_Event__r.Status__c,
                                                               s.Special_Event__c,
                                                               s.Special_Event__r.Name,
                                                               s.Special_Event__r.Product__c, 
                                                               s.Name,
                                                               s.Special_Event__r.Product__r.Dimension_1__c,
                                                               s.Special_Event__r.Product__r.Dimension_2__c,
                                                               s.Special_Event__r.Dimension_4__c,
                                                               s.Product__c, 
                                                               s.Invoice_Status__c, 
                                                               s.Event_Start_Date__c, 
                                                               s.Credited_Status__c, 
                                                               s.Contact__r.FirstName,
                                                               s.Contact__r.LastName,
                                                               s.OPL_ID__c, 
                                                               s.Booking_Fee__c From Special_Event_Booking__c s
                                                               where s.OPL_ID__c IN:oppLineId
                                                               and Type__c!='In-Company Additional' ])                                               
                {
                    
                    for(AccountExt accExt:this.accontExtList)
                    {
                        for(OpportunityExt oppExt :accExt.opportunityExtList)
                        {
                            //Default view
                            for(OppLineItemExt oppLineItemExt: oppExt.oppLineItemExtList)
                            {
                                if(oppLineItemExt.oppLineItem.Id == booking.OPL_ID__c && oppLineItemExt.bookingExtList.isEmpty())
                                    oppLineItemExt.bookingExtList.add(new BookingExt(booking));
                            }
                            //Credited view
                            for(OppLineItemExt oppLineItemExt: oppExt.creditOppLineItemExtList)
                            {
                                if(oppLineItemExt.oppLineItem.Id == booking.OPL_ID__c)
                                    oppLineItemExt.bookingExtList.add(new BookingExt(booking));
    
                            }
                            
                        } 
               
                    } 
                    
                }
    }
    
    // populate the subscription line list for each opportunity line item
    public void populateSubsLineList(Set<String> oppLineId)
    {
        //All Subscription lines
                for(Subscription_Line__c subsLine :[Select s.Subscription__r.Sub_Ref__c, 
                                                           s.Subscription__r.Account_Name__r.Name,
                                                           s.Quantity__c, 
                                                           s.Product__c, 
                                                           s.Product_Sales_Price__c, 
                                                           s.OPL_ID__c, 
                                                           s.Name, 
                                                           s.Invoice_Status__c, 
                                                           s.Credited_Status__c 
                                                           from Subscription_Line__c s
                                                           where s.OPL_ID__c IN:oppLineId ])                                               
                {
                    for(AccountExt accExt:this.accontExtList)
                    {
                        for(OpportunityExt oppExt :accExt.opportunityExtList)
                        {
                            for(OppLineItemExt oppLineItemExt: oppExt.oppLineItemExtList)
                            {
                                if(oppLineItemExt.oppLineItem.Id == subsLine.OPL_ID__c && oppLineItemExt.subscriptionLineExtList.isEmpty())
                                    oppLineItemExt.subscriptionLineExtList.add(new SubscriptionLineExt(subsLine));
                            }
                            for(OppLineItemExt oppLineItemExt: oppExt.creditOppLineItemExtList)
                            {
                                if(oppLineItemExt.oppLineItem.Id == subsLine.OPL_ID__c)
                                    oppLineItemExt.subscriptionLineExtList.add(new SubscriptionLineExt(subsLine));
    
                            }
                        } 
               
                    } 
                    
                    
                    
                }
        
    
    }
    
    //Create an invoice and invoice line items
    public PageReference createInvoice()
    {
        c2g.CODAAPICommon.Reference  result;
        Set<String> invoiceDescription = new Set<String>();
        List<Opportunity> updateOppList = new List<Opportunity>();
        List<OpportunityLineItem> updateOppLineItemList = new List<OpportunityLineItem>();
        //Webservice reference invoice 
        c2g.CODAAPIInvoiceTypes_4_0.Invoice invoice = new c2g.CODAAPIInvoiceTypes_4_0.Invoice()  ;
        invoice.InvoiceDate = Date.today();
        invoice.PrintedText1AllowEdit = false;
        invoice.PrintedText2AllowEdit = false;
        invoice.PrintedText3AllowEdit =  false;
        invoice.PrintedText4AllowEdit = false;
        invoice.PrintedText5AllowEdit = false;
        invoice.Usepartperiods = false;
        invoice.InvoiceDescription = '';
        invoice.DueDate = Date.today().addDays(30);
        invoice.Account = new c2g.CODAAPICommon.Reference();
        invoice.LineItems = new c2g.CODAAPIInvoiceLineItemTypes_4_0.InvoiceLineItems();
        invoice.LineItems.LineItemList = new List<c2g.CODAAPIInvoiceLineItemTypes_4_0.InvoiceLineItem>();
        
        //Specify the company to consider
        c2g.CODAAPICommon_4_0.Context context = new c2g.CODAAPICommon_4_0.Context();
        if(!GenerateInvoiceController.isTest)
        {
            List<String> companyName = c2g.CODAAPICompany_2_0.GetCurrentCompanies(new c2g.CODAAPICommon_2_0.Context());
            context.CompanyName = companyName.get(0);
        }
        if(accontExtList.size()>1)
            invoice.Account.Id = accontExtList.get(0).acc.Ultimate_Parent__c;
        else{
            invoice.Account.Id = accontExtList.get(0).acc.Id;
        }
            
        if(!this.accontExtList.isEmpty())
        {
            for(AccountExt accExt:this.accontExtList)
            {
               for(OpportunityExt oppExt :accExt.opportunityExtList)
               {
                 for(OppLineItemExt oppLineItemExt: oppExt.oppLineItemExtList)
                 {
                    //Create invoice invoice line item against a product line item selected
                    if(oppLineItemExt.selected && oppLineItemExt.bookingExtList.isEmpty() &&  oppLineItemExt.subscriptionLineExtList.isEmpty())
                    {
                        if(oppExt.opp.Purchase_Order_Reference__c!=null)
                            invoiceDescription.add(oppExt.opp.Purchase_Order_Reference__c);
                        c2g.CODAAPIInvoiceLineItemTypes_4_0.InvoiceLineItem lineItem = new c2g.CODAAPIInvoiceLineItemTypes_4_0.InvoiceLineItem();
                        lineItem.Product = new c2g.CODAAPICommon.Reference();
                        lineItem.Product.Id = oppLineItemExt.oppLineItem.PriceBookEntry.Product2Id;
                        lineItem.UnitPrice = oppLineItemExt.oppLineItem.UnitPrice;
                        if(oppLineItemExt.oppLineItem.Set_an_Invoice_Quantity__c == null)
                        {   
                            if(oppLineItemExt.oppLineItem.Quantity_Invoiced__c == null)
                                oppLineItemExt.oppLineItem.Quantity_Invoiced__c = 0;
                            if(oppLineItemExt.oppLineItem.Quantity_Credited__c == null)
                                oppLineItemExt.oppLineItem.Quantity_Credited__c = 0;
                            
                            lineItem.Quantity = oppLineItemExt.oppLineItem.Quantity - oppLineItemExt.oppLineItem.Quantity_Invoiced__c + oppLineItemExt.oppLineItem.Quantity_Credited__c;
                            
                        }   
                        else{
                            lineItem.Quantity = oppLineItemExt.oppLineItem.Set_an_Invoice_Quantity__c;
                        }
                        lineItem.LineDescription = oppLineItemExt.oppLineItem.Id+';void';
                        lineItem.UsePartPeriods = false;
                        invoice.LineItems.LineItemList.add(lineItem);
                        updateOppList.add(oppExt.opp);
                        updateOppLineItemList.add(oppLineItemExt.oppLineItem);
                    }   
                        //throw new Test_Exception('Done');
                        for(SubscriptionLineExt subsLineExt:oppLineItemExt.subscriptionLineExtList)
                        {
                            //Create invoice invoice line item against a susbscription line selected
                            if(subsLineExt.selected)
                            {
                                if(oppExt.opp.Purchase_Order_Reference__c!=null)
                                    invoiceDescription.add(oppExt.opp.Purchase_Order_Reference__c);
                                c2g.CODAAPIInvoiceLineItemTypes_4_0.InvoiceLineItem lineItem2 = new c2g.CODAAPIInvoiceLineItemTypes_4_0.InvoiceLineItem();
                                lineItem2.Product = new c2g.CODAAPICommon.Reference();
                                lineItem2.Product.Id = subsLineExt.subsLine.Product__c;
                                lineItem2.Quantity = 1;
                                lineItem2.UnitPrice = oppLineItemExt.oppLineItem.UnitPrice;
                                lineItem2.LineDescription = oppLineItemExt.oppLineItem.Id+';'+subsLineExt.subsLine.Id;
                                lineItem2.UsePartPeriods = false;
                                invoice.LineItems.LineItemList.add(lineItem2);
                                updateOppList.add(oppExt.opp);
                                updateOppLineItemList.add(oppLineItemExt.oppLineItem);
                            }
                        }
                          
                        for(BookingExt bookingExt:oppLineItemExt.bookingExtList)
                        {
                            //Create invoice invoice line item against a booking event selected
                            if(bookingExt.selected)
                            {
                                if(oppExt.opp.Purchase_Order_Reference__c!=null)
                                    invoiceDescription.add(oppExt.opp.Purchase_Order_Reference__c);
                                                               
                                c2g.CODAAPIInvoiceLineItemTypes_4_0.InvoiceLineItem lineItem2 = new c2g.CODAAPIInvoiceLineItemTypes_4_0.InvoiceLineItem();
                                lineItem2.Product = new c2g.CODAAPICommon.Reference();
                                lineItem2.Product.Id = bookingExt.bookingEvt.Special_Event__r.Product__c;
                                lineItem2.Quantity = 1;
                                lineItem2.UnitPrice = oppLineItemExt.oppLineItem.UnitPrice;
                                lineItem2.LineDescription = oppLineItemExt.oppLineItem.Id+';'+bookingExt.bookingEvt.Id+';'+bookingExt.bookingEvt.Special_Event__r.Name+';'+bookingExt.bookingEvt.Event_Start_Date__c;
                                lineItem2.UsePartPeriods = false;
                                if(bookingExt.bookingEvt.Special_Event__r.Dimension_4__c!=null)
                                {
                                    lineItem2.Dimension4 = new c2g.CODAAPICommon.Reference();
                                    lineItem2.Dimension4.Id  = bookingExt.bookingEvt.Special_Event__r.Dimension_4__c;
                                }
                                if(bookingExt.bookingEvt.Special_Event__r.Product__r.Dimension_2__c!=null)
                                {
                                    lineItem2.Dimension2 = new c2g.CODAAPICommon.Reference();
                                    lineItem2.Dimension2.Id  = bookingExt.bookingEvt.Special_Event__r.Product__r.Dimension_2__c;
                                }
                                if(bookingExt.bookingEvt.Special_Event__r.Product__r.Dimension_1__c!=null)
                                {
                                    lineItem2.Dimension1 = new c2g.CODAAPICommon.Reference();
                                    lineItem2.Dimension1.Id  = bookingExt.bookingEvt.Special_Event__r.Product__r.Dimension_1__c;
                                }
                                invoice.LineItems.LineItemList.add(lineItem2);
                                updateOppList.add(oppExt.opp);
                                updateOppLineItemList.add(oppLineItemExt.oppLineItem);
                            }
                        }   
                 }
               }
            }
            
            try
            {
                if(!GenerateInvoiceController.isTest)
                {    
                    if(!invoiceDescription.isEmpty())
                    {
                        //Populate description of the invoice
                        List<String> invoiceDescriptionList = new List<String>();
                        invoiceDescriptionList.addAll(invoiceDescription);
                        
                        for(Integer i = 0;i<invoiceDescriptionList.size()-1;i++)
                        {
                            invoice.InvoiceDescription += invoiceDescriptionList.get(i)+';';
                        }
                        invoice.InvoiceDescription += invoiceDescriptionList.get(invoiceDescriptionList.size()-1);
                        //throw new Test_Exception(invoice.InvoiceDescription);     
                    }
                    result=c2g.CODAAPISalesInvoice_4_0.CreateInvoice(context , invoice);
                    c2g__codaInvoice__c updateInvoice = [Select c.Id,c.c2g__CustomerReference__c From c2g__codaInvoice__c c where c.Id =:result.Id];
                    update updateInvoice;
                    return new PageReference('/'+result.Id);
                }
                
            }catch(Exception e)
            {
                if(result!=null)
                { 
                  return new PageReference('/'+result.Id);
                  
                }else{
                  ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()); 
                  ApexPages.addMessage(myMsg);
                }
            }
        }
        return null;  
    }
    
    //Reset the view to the default view
    public PageReference defaultView()
    {
        if(!accontExtList.isEmpty())
        {
            Integer j = 1;
            for(Integer i=1;i< accontExtList.size();i++)
            {
                accontExtList.get(i).clear();
            }
            while(j <accontExtList.size())
            {
                accontExtList.remove(j);
                j++;    
            }
            if(!defaultOppExtList.isEmpty())
            {   
                accontExtList.get(0).clear();
                accontExtList.get(0).opportunityExtList.addAll(defaultOppExtList);
                //Clear list in order to clear all reference objects
                defaultOppExtList.clear();
                //New list of object copied from the current list
                defaultOppExtList.addAll(copyOpportunityExt(accontExtList.get(0).opportunityExtList));
            }
        }
        
        stage = 'Default';
        return null;
    }
    //Activate the credited view
    public PageReference creditedView()
    {
        
        if(!this.accontExtList.isEmpty())
        {
            for(integer i = 0;i < this.accontExtList.size();i++)
            {
               AccountExt accExt = this.accontExtList.get(i);
               if(i==0 && defaultOppExtList.isEmpty())
                defaultOppExtList.addAll(copyOpportunityExt(accExt.opportunityExtList));
               for(OpportunityExt oppExt :accExt.opportunityExtList)
               {
                  for(OppLineItemExt oppLineItemExt: oppExt.creditOppLineItemExtList)
                  {
                     if(!containsOppLineItem(oppLineItemExt.oppLineItem.Id))
                        oppExt.oppLineItemExtList.add(oppLineItemExt);              
                  }                  
               }
            }                        
        }
        
        
        /*if(stage =='Hierarchy')
            stage = 'hierarchyCredited';
        if(stage!='hierarchyCredited')
            stage = 'Credited';*/
        
        return null;
    }
    //Display the hierarchy view
    public PageReference hierarchyView()
    {
        
        //stage = currentAcc.stage;
        system.debug('@@@'+currentAcc.stage);
        if(stage == 'Default')
        {
            
                
                Set<String> oppLineId = new  Set<String>();
                Set<String> oppId = new  Set<String>();
                //All accounts
                if(this.currentAcc.acc.Ultimate_Parent__c!=null)
                {
                    
                    for(Account acc:[Select Name,
                                            (Select Id,
                                                    Name,
                                                    CloseDate,
                                                    OwnerId, 
                                                    Owner.Name,
                                                    Purchase_Order_Reference__c,
                                                    AccountId 
                                                    from Opportunities
                                                   where (IsClosed = true 
                                                    or StageName = 'Part Invoiced'))
                                             from Account
                                             where Ultimate_Parent__c =:this.currentAcc.acc.Ultimate_Parent__c
                                             and Id!=:this.currentAcc.acc.Id ])
                    {
                    
                        if(!containsAccount(acc.Id))
                            this.accontExtList.add(new AccountExt(acc));
                        
                    }
                   
                    //All opportunities
                    if(!this.accontExtList.isEmpty())
                    {
                       for(AccountExt accExt:this.accontExtList)
                       {
                          
                          if(accExt.acc.Id != currentAcc.acc.Id /*&& accExt.opportunityExtList.isEmpty()*/)
                          {   
                              
                              for(Opportunity opp :accExt.acc.Opportunities)
                              {
                                  //throw new Test_Exception('done');
                                  oppId.add(opp.Id);
                                  accExt.opportunityExtList.add(new OpportunityExt(opp));
                              }
                          }
                       } 
                                    
                        //All Opportunity line items
                        for(OpportunityLineItem oppLineItem:[Select Id,
                                                                PriceBookEntry.Product2.Name,
                                                                PriceBookEntry.Product2Id, 
                                                                OpportunityId,
                                                                Quantity,
                                                                Set_an_Invoice_Quantity__c, 
                                                                Quantity_Invoiced__c,
                                                                Quantity_Credited__c,
                                                                UnitPrice from OpportunityLineItem
                                                                where OpportunityId IN:oppId])
                         {
                            
                            for(AccountExt accExt:this.accontExtList)
                            {
                                for(OpportunityExt oppExt :accExt.opportunityExtList)
                                {
                                    if(oppLineItem.OpportunityId == oppExt.opp.Id)
                                    
                                    {   
                                        //Can be invoiced
                                        if(oppLineItem.Quantity_Invoiced__c == null)
                                        {
                                            oppLineId.add(oppLineItem.Id);
                                            oppExt.oppLineItemExtList.add(new oppLineItemExt(oppLineItem));
                                        }
                                        else
                                        {
                                            if(oppLineItem.Quantity - oppLineItem.Quantity_Invoiced__c > 0)
                                            {
                                                oppLineId.add(oppLineItem.Id);
                                                oppExt.oppLineItemExtList.add(new oppLineItemExt(oppLineItem));
                                            }
                                        }
                                        //Credited opportunity line item
                                        if(oppLineItem.Quantity_Credited__c!=null && oppLineItem.Quantity_Credited__c > 0)
                                        {   
                                            oppExt.creditOppLineItemExtList.add(new oppLineItemExt(oppLineItem));
                                            if(!oppLineId.contains(oppLineItem.Id)) 
                                                oppLineId.add(oppLineItem.Id);
                                        } 
                                    }
                                } 
                       
                            } 
                            
                         }
                         
                         
                        populateBookingList(oppLineId);
                        populateSubsLineList(oppLineId);
                
                } 
                
                }
            
            
             stage = 'Hierarchy';   
        }
        return null;
    }
    

    
    public class AccountExt
    {
        public Account acc {get;private set;}
        public List<OpportunityExt> opportunityExtList {get; private set;}
        public String stage {get;private set;}
        public boolean selected {get;set;}
        
        
        
        public AccountExt (Account acc)
        {
            this.acc = acc;
            opportunityExtList = new List<OpportunityExt>();
            this.selected = false;
        }
        //Clear all list
        public void clear()
        {
            if(!opportunityExtList.isEmpty())
            {
               for(OpportunityExt oppExt :opportunityExtList)
               {
                    oppExt.clear();
               }
               
                opportunityExtList.clear();              
            }
        }
        
    }

    public class OpportunityExt
    {
        public Opportunity opp {get;private set;}
        public boolean selected {get;set;}
        
        public List<OppLineItemExt>  oppLineItemExtList{get;set;}
        public List<OppLineItemExt>  creditOppLineItemExtList{get;set;}
        
        public OpportunityExt(Opportunity opp)
        {
            this.opp = opp;
            this.oppLineItemExtList = new List<OppLineItemExt>();
            this.creditOppLineItemExtList = new List<OppLineItemExt>();
            this.selected = false;
        }
        //Clear all list
        public void clear()
        {
            if(!oppLineItemExtList.isEmpty())
            {
                for(OppLineItemExt oppLineItemExt: oppLineItemExtList)
                {
                    oppLineItemExt.clear();
                }
                oppLineItemExtList.clear(); 
            }
            
            if(!creditOppLineItemExtList.isEmpty())
            {
                for(OppLineItemExt oppLineItemExt: creditOppLineItemExtList)
                {
                    oppLineItemExt.clear();
                }
                creditOppLineItemExtList.clear(); 
            }
            
        }
    }
    
    
    public class OppLineItemExt
    {
        public OpportunityLineItem oppLineItem {get;private set;}
        public list<BookingExt> bookingExtList {get;set;}
        public list<SubscriptionLineExt> subscriptionLineExtList{get;set;}
        public Integer bookingLength {get{return bookingExtList.size(); } private set;}
        public Integer subsLineLength {get{return subscriptionLineExtList.size(); } private set;}
        public boolean selected {get;set;}
        
        public OppLineItemExt(OpportunityLineItem oppLineItem)
        {
            bookingExtList = new list<BookingExt>();
            subscriptionLineExtList = new List<SubscriptionLineExt>();
            this.selected = false;
            this.oppLineItem = oppLineItem;
        }
        //Clear all list
        public void clear()
        {
            subscriptionLineExtList.clear();
            bookingExtList.clear();
        }
    }

    
    
    //Customize booking event object
    public class SubscriptionLineExt
    {
        public Subscription_Line__c  subsLine {get; private set;}
        public boolean selected {get;set;}
        
        public SubscriptionLineExt(Subscription_Line__c susbLine)
        {
            this.subsLine = susbLine;
            this.selected = false;
        }       
    }
    
    //Customize booking event object
    public class BookingExt
    {
        public Special_Event_Booking__c bookingEvt{get; private set;}
        public boolean selected {get;set;}
        
        public BookingExt(Special_Event_Booking__c bookingEvt)
        {
            this.bookingEvt = bookingEvt;
            this.selected = false;
        }       
    }

    public testmethod static void testGenerateInvoiceController()
    {
    
        Opportunity opp = [Select Id,AccountId from Opportunity where Account.Ultimate_Parent__c!=null and isWon = true and HasOpportunityLineItem = true limit 1];
        PageReference pageRef = new PageReference('view');
        
        OpportunityLineItem lineItem = [Select id from OpportunityLineItem where OpportunityId=:opp.Id limit 1];
        Special_Event_Booking__c booking = [Select Id,OPL_ID__c from Special_Event_Booking__c limit 1];
        Subscription_Line__c susbLine = [Select Id,OPL_ID__c from Subscription_Line__c limit 1];
        booking.OPL_ID__c = lineItem.Id;
        susbLine.OPL_ID__c = lineItem.Id;
        update booking;
        update susbLine;
        
        pageRef.getParameters().put('id',opp.Id);
        Test.setCurrentPageReference(pageRef);
        GenerateInvoiceController ctr = new GenerateInvoiceController();
        GenerateInvoiceController.isTest = true;
        for(OpportunityExt oppExt:ctr.currentAcc.opportunityExtList)
        {
            for(OppLineItemExt oppLineExt:oppExt.oppLineItemExtList)
            {
                oppLineExt.selected = true;
            }
        }
        ctr.createInvoice(); 
        ctr.hierarchyView();
        ctr.creditedView();
        ctr.defaultView();
        
        pageRef.getParameters().put('id',opp.AccountId);
        Test.setCurrentPageReference(pageRef);
        GenerateInvoiceController ctr2 = new GenerateInvoiceController();
        
        
        
    }

}