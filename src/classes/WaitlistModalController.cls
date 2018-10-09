public without sharing class WaitlistModalController extends ComponentControllerBase {
  public boolean ModalVisible {get;set;}{ModalVisible=false;}
  private string productRatePlanIdValue = '';

  private List<zqu__ProductRatePlan__c> ratePlans = new List<zqu__ProductRatePlan__c>();
  private List<Waitlist__c> waitlists = new List<Waitlist__c>();
  private List<Inventory__c> accountsOnDeck = new List<Inventory__c>();

  public string SelectedWaitlistId {get;set;} {SelectedWaitlistId='';}
  public string SelectedInventoryId {get;set;} {SelectedInventoryId='';}

  public boolean ShowAddAccount {get;set;} {ShowAddAccount = false;}
  public Waitlist__c NewWaitlist {get;set;} {NewWaitlist = new Waitlist__c();}

  private Waitlist_Permission__c wlPerm = Waitlist_Permission__c.getInstance();
  private Inventory_Hold_Expiry_Date_Offsets__c inventoryHoldPerm;

  public Map<Id, integer> WaitlistSizeByProductRatePlanId = new Map<Id, integer>();

  public boolean getCanDeleteAnyWaitlist()
  {
    return wlPerm.Delete_Any__c;
  }

  public boolean getCanReorderAnyWaitlist()
  {
    return wlPerm.Reorder_Any__c;
  }

  public WaitlistModalController()
  {
    inventoryHoldPerm = Inventory_Hold_Expiry_Date_Offsets__c.getInstance();

    // during deployment and testing, this value may not exist.  create a local instance so the code can run.
    if (inventoryHoldPerm.Account_Day_Offset__c == null)
    {
      inventoryHoldPerm.Account_Day_Offset__c = 3;
    }
  }

  public void MoveUp()
  {
    for (integer i = 0; i < waitlists.size(); i++)
    {
      if (((String)waitlists[i].Id).left(15) == SelectedWaitlistId.left(15))
      {
        // check to see if we can move this any higher
        if (i-1 >= 0)
        {
          // this isn't the first in the list, it's ok to move
          waitlists[i].Sort_Order_Override__c = waitlists[i].Sort_Order_Override__c - 1;
          waitlists[i - 1].Sort_Order_Override__c = waitlists[i - 1].Sort_Order_Override__c + 1;
        }
        break;
      }
    }

    upsert waitlists;
    // refresh the list
    ProductRatePlanId = productRatePlanIdValue;
  }

  public void AddAccount()
  {
    ShowAddAccount = true;
    NewWaitlist = new Waitlist__c();
  }

  public void SaveNewWaitlist()
  {
    System.debug('inserting for account:' + NewWaitlist.Account__c);
    System.debug('inserting for rate plan:' + ProductRatePlanId);
    integer retVal = waitlists.size() + 1;
    NewWaitlist.Sort_Order_Override__c = waitlists.size() + 1;
    NewWaitlist.Product_Rate_Plan__c = ProductRatePlanId;
    upsert NewWaitlist;
    // refresh the list
    ProductRatePlanId = productRatePlanIdValue;
    ShowAddAccount = false;
    NewWaitlist = new Waitlist__c();
    WaitlistSizeByProductRatePlanId.put(productRatePlanIdValue, retVal);
  }

  public void SaveNewWaitlist(string prodRatePlanId, string acctId)
  {
    NewWaitlist = new Waitlist__c();
    NewWaitlist.Account__c = acctId;
    ProductRatePlanId = prodRatePlanId;
    SaveNewWaitlist();
  }

  public void MoveDown()
  {
    for (integer i = 0; i < waitlists.size(); i++)
    {
      if (((String)waitlists[i].Id).left(15) == SelectedWaitlistId.left(15))
      {
        // check to see if we can move this any lower
        if (i+1 < waitlists.size())
        {
          // this isn't the last in the list, it's ok to move
          waitlists[i].Sort_Order_Override__c = waitlists[i].Sort_Order_Override__c + 1;
          waitlists[i + 1].Sort_Order_Override__c = waitlists[i + 1].Sort_Order_Override__c - 1;
        }
        break;
      }

    }

    upsert waitlists;
    // refresh the list
    ProductRatePlanId = productRatePlanIdValue;

  }


  public zqu__ProductRatePlan__c getRatePlan()
  {
    return ratePlans[0];
  }

  public List<Waitlist__c> getWaitlists()
  {
    return waitlists;
  }

  public List<Inventory__c> getAccountsOnDeck()
  {
    return accountsOnDeck;
  }

  public void DeleteWaitlist()
  {
    System.Debug('waitlist id to delete - ' + SelectedWaitlistId);
    for (Waitlist__c wl : waitlists)
    {
      if (((String)wl.Id).left(15) == SelectedWaitlistId.left(15))
      {
        
        // CSP-3013 Waitlist Audit
        // If the local user remove the waitlist, we marked the waitlist to inactive
        wl.Is_Active__c = FALSE;
        wl.InActive_Date__c = Date.today();
        wl.Inactive_Reason__c = 'Deleted';
        // delete wl;
        update wl;
        break;
      }
    }
    // refresh the list
    ProductRatePlanId = productRatePlanIdValue;
  }

  public void DeleteInventory()
  {
    System.Debug('inventory id to delete - ' + SelectedInventoryId);
    for (Inventory__c inv : accountsOnDeck)
    {
      if (((String)inv.Id).left(15) == SelectedInventoryId.left(15))
      {
        delete inv;
        break;
      }
    }

    // refresh the list
    ProductRatePlanId = productRatePlanIdValue;
  }

  public void HoldInventory()
  {
    System.Debug('inventory id to hold - ' + SelectedInventoryId);
    for (Inventory__c inv : accountsOnDeck)
    {
      if (((String)inv.Id).left(15) == SelectedInventoryId.left(15))
      {
        integer holdDays = ((integer)inventoryHoldPerm.Account_Day_Offset__c) * 2;
        inv.Inventory_Hold_Expiry_Date__c = DateUtility.AddBusinessDays(inv.CreatedDate, holdDays);
        inv.Held_Until_Extended__c = true;
        update inv;
        break;
      }
    }

    // refresh the list
    ProductRatePlanId = productRatePlanIdValue;
  }

  public void MoveToBottom()
  {

    boolean foundIt = false;

    System.Debug('waitlist id to delete - ' + SelectedWaitlistId);
    for (Waitlist__c wl : waitlists)
    {
      if (((String)wl.Id).left(15) == SelectedWaitlistId.left(15))
      {
        foundIt = true;
        wl.Sort_Order_Override__c = waitlists.size();
      }
      else if (foundIt)
      {
        wl.Sort_Order_Override__c -= 1;
      }
    }

    update(waitlists);

    // refresh the list
    ProductRatePlanId = productRatePlanIdValue;
  }

  public string ProductRatePlanId {
    get
    {
      return productRatePlanIdValue; 
    }
    set
    {
      productRatePlanIdValue = value.left(15);

      // get the rateplan details from the db
      // CSP-2757 Waitlist Ordering Issue   
      // Should update the zqu__Product__c, zqu__Product__r.Name to zqu__ZProduct__c, zqu__ZProduct__r.Name if the ticket released before ZMPU
      ratePlans = [SELECT Id, Name, Available__c, Capacity__c, Inventory_Held__c, Number_Available__c, Waitlist_Count__c, 
                      Market__c, Category__c, zqu__Product__c, zqu__Product__r.Name, createddate 
                  FROM zqu__ProductRatePlan__c
                  WHERE id =:productRatePlanIdValue];

      // get the accounts on deck from inventory
      accountsOnDeck = [SELECT id, Held_By_Type__c, name, Waitlist_Account__c, Waitlist_Account__r.Name, Waitlist_Account__r.Owner.Name,
                          Quote_Rate_Plan__c, CreatedDate, Inventory_Hold_Expiry_Date__c, Product_Rate_Plan__c, Held_Until_Extended__c,
                          I_Am_the_Sales_Rep__c
                        FROM Inventory__c
                        WHERE Product_Rate_Plan__c =:productRatePlanIdValue
                          AND Held_By_Type__c = 'Account'
                          ORDER BY Inventory_Hold_Expiry_Date__c ASC
                          ];

      // get the waitlist from the db
      // CSP-3013 Waitlist Audit
      // For the waitlist audit, we only query the active waitlist to show on the deck
      waitlists = [SELECT Id, Name, Account__c, Account__r.Name, Sort_Order_Override__c, Sort_Order__c, 
                    Product_Rate_Plan__c, I_Am_the_Sales_Rep__c, createddate, Account__r.Owner.Name
                  FROM Waitlist__c
                  WHERE Product_Rate_Plan__c = :productRatePlanIdValue 
                    AND Is_Active__c = TRUE 
                    ORDER By Sort_Order__c ASC];

      // fix the waitlist sort.  To the system, having gaps in the sort doesn't matter, but to the user it looks sloppy.
      integer i = 1;
      for (Waitlist__c wl : waitlists)
      {
        wl.Sort_Order_Override__c = i++;
      }

      // CSP-2757 Waitlist Ordering Issue, 
      // when the waitlist sort has been changed, update the waitlist
      // avoid the Sort_Order_Override__c of new waitlist has been set to a small number.
      List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
      Database.SaveResult[] dbSaveResults = Database.Update(waitlists, false);

      xoExceptionList.addAll(ExceptionUtility.consumeException(dbSaveResults));

      if (!xoExceptionList.isEmpty()) {
        insert xoExceptionList;
      }
    }
  }

  public void OpenModal(string prodRatePlanId)
  {
    ProductRatePlanId = prodRatePlanId;
    ModalVisible=true;
  }

  public void CloseModal()
  {
    ModalVisible=false;
  }
}