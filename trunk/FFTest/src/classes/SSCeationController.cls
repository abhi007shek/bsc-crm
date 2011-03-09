public with sharing class SSCeationController
{  
  Public Subscription_Site__c SubscriptionSite {get; set; }
  public String    SubscriptionId        { get; set; }
  Public List<Subscription_Line__c> SubscriptionLines {get; set; }
  Public List<Subscription_Line__c> SubscriptionLines4Display {get; set; }
  Public List<Site_Product__c > SiteProducts {get; set; }
  Public List<Products2Add> Products2AddInfo {get; set; }
  Public List<AccountContact> AccountContacts {get; set; }
  Public  List<Contact> contact2Add;
  //public String[] SiteTypeCriteria { get; set; }
     
  public Integer pageNum { get; private set; }
  private final Integer maxPages = 3;
       
      //public SSCeationController ( ApexPages.StandardController stdController )
      public SSCeationController ( )
      {
        //this.SubscriptionSite =(Subscription_Site__c ) stdController.getrecord();
        this.SubscriptionSite =new Subscription_Site__c();

/*      SiteTypeCriteria = new String[] {};
        // Select all types as default
        for (SelectOption so : getSiteTypePicklistOptions())
        {
            SiteTypeCriteria.add(so.getValue());
        }
*/      

        if( System.currentPageReference().getParameters().get( 'SCid' ) != null )
        {
            this.SubscriptionId=System.currentPageReference().getParameters().get( 'SCid' );
        } 
            SubscriptionLines =[Select  Quantity__c,Quantity_Available__c, Product__c,Product__R.Id,Product__R.Name,Product__R.ProductCode,Subscription__c  From Subscription_Line__c  where         Subscription__c=:this.SubscriptionId];
           
           Products2AddInfo= new List<Products2Add>();
           SubscriptionLines4Display= new List<Subscription_Line__c>();
           if(SubscriptionLines.size()>0)
           {     
               for (Subscription_Line__c SL: SubscriptionLines)
               {
                  Products2Add NewProducts2Add=new Products2Add();
                  Subscription_Line__c SLNew= new Subscription_Line__c();
                  SLNew.Quantity__c= 0;//SL.Quantity__c;
                  SLNew.Quantity_Available__c=SL.Quantity_Available__c;
                  SLNew.Product__c=SL.Product__c;
                  NewProducts2Add.record=SLNew;
                  NewProducts2Add.recordRef=SL;
                  NewProducts2Add.ProductName=SL.Product__R.Name;
                  NewProducts2Add.ProductCode=SL.Product__R.ProductCode;                         
                  Products2AddInfo.add(NewProducts2Add);     
               }           
           }                          
        pageNum=1;    
      }
                                                                             
    Private boolean GetContactsforAccount()
    {                  
         boolean AtLeastOnePositiveQuantity=false;       
         for(Products2Add SLine :Products2AddInfo)
         {
            if(SLine.record.Quantity__c>SLine.record.Quantity_Available__c)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Quantity can not be greater than total quantity available for a product'));
                return false; 
            }      
            if(SLine.record.Quantity__c > 0.0)
            {
                AtLeastOnePositiveQuantity=true;
            }
         }
         
         if(AtLeastOnePositiveQuantity==false)
         {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please enter quantity of Product'));
                return false;        
         }
         
        if (SubscriptionSite.Site_Account__c==null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please select an Account for the subscription site'));
            return false;
        }
                 
        AccountContacts= new List<AccountContact>();
            for (Contact NewContact : [Select LastName, Id, FirstName From Contact   where  AccountId=:SubscriptionSite.Site_Account__c])
            {
                AccountContacts.add(new AccountContact(NewContact));
            }       
    
        return true;    
    }     
               
    public void next()
    {  
        if (pageNum < maxPages) pageNum++;
         
        if (pageNum == 2)  
        {  
            GetContactsforAccount();
        }     
        else if (pageNum == 3)  
        {
            //Boolean success = generateBSCEventUnits();
            //if (!success) pageNum--;
        }                   
    }                
    public PageReference savesite()
    {  
    Integer CntContacts=0;
    PageReference PageRef;
    Boolean CallFinal=true;
    contact2Add=new  List<Contact>();
    for(AccountContact ActContact:AccountContacts)
    {
        if(ActContact.selected == true)
        {  
            CntContacts=CntContacts+1;
            contact2Add.add(ActContact.record);         
        }
    }
    //Case 1447
    if (CntContacts>0&&SubscriptionSite.Site_Contact__c!=null)
    {
            CallFinal=false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Select only one contact from either Subscription site or Additional Subscription site '));
            return null;            	
    }
    //End of Case 1447  
               
    if(CntContacts>1)
    {
            CallFinal=false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Select only one contact '));
            return null;        
    }
    
    // Case 1447
    if(CntContacts==0&&SubscriptionSite.Site_Contact__c==null)
    {
            CallFinal=false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Select main contact '));
            return null;        
    }       
                        
    //Create Subscription Site First
    SubscriptionSite.Subscription__c=SubscriptionLines[0].Subscription__c;
    SubscriptionSite.Site_Account__c=SubscriptionSite.Site_Account__c;
    SubscriptionSite.Active__c=true;
    // Case 1447
    if (SubscriptionSite.Site_Contact__c==null)
    {
       SubscriptionSite.Site_Contact__c=contact2Add[0].id;
    }
    // End of Case 1447
    string StrProductCodes='';
     for(Products2Add SLine :Products2AddInfo)
     {
        if(SLine.record.Quantity__c>0)
        {
            StrProductCodes=StrProductCodes + ';' + SLine.ProductCode;
        }       
     }    
    StrProductCodes=StrProductCodes.substring(1,StrProductCodes.length());
    SubscriptionSite.Subscription_Site_Product_Codes__c=StrProductCodes;
    insert SubscriptionSite;

     //list<Account> Acct2Update=[Select Member__c  from Account where id=:SubscriptionSite.Site_Account__r.id and Member__c=false    limit 1];
     list<Account> Acct2Update=[Select Member__c  from Account where id=:SubscriptionSite.Site_Account__c and Member__c=false    limit 1];
     if (Acct2Update.size()==1)
        {
            Acct2Update[0].Member__c=true;
            update Acct2Update;
        }
    
    //Create Site Products 
     SiteProducts = new list<Site_Product__c>();
    list<Subscription_Line__c> SL2Update = new list<Subscription_Line__c>();
     for(Products2Add SLine :Products2AddInfo)
     {
        for (Integer i = 0; i < SLine.record.Quantity__c; i++)
        {
            Site_Product__c NewSiteProduct= new Site_Product__c();
            NewSiteProduct.Subscription__c=SubscriptionLines[0].Subscription__c;
            NewSiteProduct.Subscription_Site__c=SubscriptionSite.id;
            NewSiteProduct.Subscription_Line__c=SLine.Recordref.id;
            SiteProducts.add(NewSiteProduct);           
        }      
            SLine.Recordref.Quantity_Available__c=SLine.Recordref.Quantity_Available__c-SLine.Record.Quantity__c;
            SL2Update.add(SLine.Recordref);
     }             
     insert SiteProducts;
     update SL2Update;         

    // Redirect to newly created Subsscription Site
    return new PageReference('/' + SubscriptionSite.Id);         
    }

    public SelectOption[] getSiteTypePicklistOptions()
    {
        List<SelectOption> options = new List<SelectOption>();
        for (Schema.Picklistentry pe : Schema.SObjectType.Subscription_Site__c.fields.Type__c.getPicklistValues())
        {
            if (pe.isActive()) options.add(new SelectOption(pe.getValue(), pe.getLabel()));
        }
        return options;
    }
        
    public void prev()
    {
        if (pageNum > 1) pageNum--;
    }
  
    public PageReference cancel()
    {
        if (SubscriptionId != null)
            return new PageReference('/' + SubscriptionId);     
        return new PageReference('/home/home.jsp');
    }
            
    public class Products2Add
    {
        public Subscription_Line__c record { get;  set; }
        public Subscription_Line__c recordRef { get;  set; }
        Public String ProductName {get; set; }
        Public String ProductCode {get; set; }          
    }   
    
    public class AccountContact
    {
        public Contact record { get; private set; }
        public Boolean selected { get; set; }       
        public AccountContact(Contact target)
        {
            this.record = target;
            this.selected = false;
        }
    }   
       
    @IsTest
    private static void testSSCreation()
    {
        //Create a Product
        Product2 prod = new Product2();
        prod.Name = 'Test SSCreation Product';
        insert prod;

        //Create an Account
        Account NewAccount=new Account(name='Test SSCreation Account');
        insert NewAccount;      
        
        // Add a Contact to it
        Contact NewContact= new Contact(LastName='Test SSCreation Contact');
        NewContact.AccountId=NewAccount.id;
        insert NewContact;
                
        //a Create a Subscription
        Subscription__c NewSubscription= new Subscription__c();
        NewSubscription.Account_Name__c=NewAccount.id;
        insert NewSubscription;
        
        //Create a Subscription Line
        Subscription_Line__c NewSubscriptionLine= new Subscription_Line__c();
        NewSubscriptionLine.Subscription__c=NewSubscription.id;
        NewSubscriptionLine.Quantity__c=20.0;
        NewSubscriptionLine.Quantity_Available__c=20.0;
        NewSubscriptionLine.Product__c=prod.id;
        insert NewSubscriptionLine;
        
        PageReference PageRef=Page.SScreation;
        test.setCurrentPage(PageRef);
        ApexPages.currentPage().getParameters().put('SCid',NewSubscription.id);        
        SSCeationController controller= new SSCeationController();
        controller.SubscriptionSite.Site_Account__c=NewAccount.id;
        controller.Products2AddInfo[0].record.Quantity__c=1.0;      
        controller.next();        
        controller.AccountContacts[0].selected=true;
        controller.savesite();
        
        
        //Go to Next Page
        //controller.next();
        //controller.AccountContacts[0].selected=true;        
    }
  
}